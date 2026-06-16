import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;


class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImageUploadService {
  static const int maxUploadBytes = 8 * 1024 * 1024;
  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dbflkn1ig',
  );
  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'grocery_unsigned',
  );


  static Future<String> uploadUserImage({
    required File imageFile,
    required String ownerUid,
    required String folder,
    required String fileName,
  }) {
    return _upload(imageFile: imageFile);
  }

  static Future<String> uploadCatalogImage({
    required File imageFile,
    required String collection,
    required String entityId,
  }) {
    return _upload(imageFile: imageFile);
  }

  static Future<void> deleteFirebaseImage(String imageUrl) async {
    // Uploads now use Cloudinary. Keep this no-op for older call sites that
    // only need to avoid deleting non-Firebase images.
  }

  static Uri cloudinaryUploadUriForDiagnostics() {
    return Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload');
  }

  static Future<String> _upload({
    required File imageFile,
  }) async {
    if (!await imageFile.exists()) {
      throw const ImageUploadException(
        'Image upload failed: the selected file was not found.',
      );
    }

    final byteLength = await imageFile.length();
    if (byteLength <= 0) {
      throw const ImageUploadException(
        'Image upload failed: the selected file is empty.',
      );
    }
    if (byteLength > maxUploadBytes) {
      throw const ImageUploadException(
        'Image upload failed: select an image smaller than 8 MB.',
      );
    }
    if (_cloudName.trim().isEmpty || _uploadPreset.trim().isEmpty) {
      throw const ImageUploadException(
        'Cloudinary upload is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload'),
      )
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
          ),
        );
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ImageUploadException(_cloudinaryErrorMessage(body));
      }
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = payload['secure_url'] as String?;
      if (secureUrl == null || secureUrl.trim().isEmpty) {
        throw const ImageUploadException(
          'Cloudinary upload failed. Please try again.',
        );
      }
      return secureUrl;
    } on SocketException {
      throw const ImageUploadException(
        'Cloudinary upload failed (network-request-failed). Please check your connection and try again.',
      );
    } on HttpException {
      throw const ImageUploadException(
        'Cloudinary upload failed. Please try again.',
      );
    } on FormatException {
      throw const ImageUploadException(
        'Cloudinary upload failed. Please try again.',
      );
    }
  }


  static String _cloudinaryErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = payload['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return 'Cloudinary upload failed: ${message.trim()}';
        }
      }
    } on FormatException {
      // Fall through to the generic message below.
    }
    return 'Cloudinary upload failed. Please try again.';
  }
}
