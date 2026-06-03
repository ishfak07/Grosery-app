import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryService {
  static const String cloudName = 'dbflkn1ig';
  static const String uploadPreset = 'grocery_unsigned';
  static const Duration uploadTimeout = Duration(seconds: 25);
  static const int maxUploadBytes = 8 * 1024 * 1024;

  static Future<String> uploadImage(
    File imageFile, {
    http.Client? client,
  }) async {
    if (!await imageFile.exists()) {
      throw const CloudinaryUploadException(
        'Cloudinary upload failed: image file was not found.',
      );
    }

    final byteLength = await imageFile.length();
    if (byteLength <= 0) {
      throw const CloudinaryUploadException(
        'Cloudinary upload failed: image file is empty.',
      );
    }
    if (byteLength > maxUploadBytes) {
      throw const CloudinaryUploadException(
        'Cloudinary upload failed: image is too large.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'grocery_app'
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    final shouldCloseClient = client == null;
    final uploadClient = client ?? http.Client();

    try {
      final response = await uploadClient.send(request).timeout(uploadTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final secureUrl = data['secure_url'];

        if (secureUrl == null || secureUrl.toString().isEmpty) {
          throw const CloudinaryUploadException(
            'Cloudinary upload failed: secure image URL is missing.',
          );
        }

        return secureUrl.toString();
      }

      throw CloudinaryUploadException(
        'Cloudinary upload failed with status ${response.statusCode}.',
      );
    } on CloudinaryUploadException {
      rethrow;
    } on SocketException {
      throw const CloudinaryUploadException(
        'Cloudinary upload failed: network is unavailable.',
      );
    } on http.ClientException {
      throw const CloudinaryUploadException(
        'Cloudinary upload failed: network request failed.',
      );
    } on TimeoutException {
      throw const CloudinaryUploadException(
        'Cloudinary upload failed: upload timed out.',
      );
    } on FormatException {
      throw const CloudinaryUploadException(
        'Cloudinary upload failed: upload response was invalid.',
      );
    } finally {
      if (shouldCloseClient) {
        uploadClient.close();
      }
    }
  }
}
