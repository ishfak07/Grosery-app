import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });

  final String secureUrl;
  final String publicId;
}

class ImageUploadService {
  static const int maxUploadBytes = 8 * 1024 * 1024;
  static const Duration _uploadTimeout = Duration(seconds: 60);
  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  static Future<CloudinaryUploadResult> uploadUserImage({
    required File imageFile,
    required String ownerUid,
    required String folder,
    required String fileName,
  }) async {
    final uploadContext = _userUploadContext(
      ownerUid: ownerUid,
      folder: folder,
      fileName: fileName,
    );
    return _upload(
      imageFile: imageFile,
      signatureRequestData: uploadContext,
    );
  }

  static Future<CloudinaryUploadResult> uploadCatalogImage({
    required File imageFile,
    required String collection,
    required String entityId,
  }) async {
    final normalizedCollection = _sanitizePathSegment(collection);
    final uploadType = switch (normalizedCollection) {
      'offers' => 'catalog_offer',
      'products' => 'catalog_product',
      _ => throw const ImageUploadException(
          'Image upload failed: unsupported catalog image type.',
        ),
    };

    return _upload(
      imageFile: imageFile,
      signatureRequestData: {
        'uploadType': uploadType,
        'entityId': _requiredSafeId(entityId, 'item'),
      },
    );
  }

  static Future<void> deleteFirebaseImage(String imageUrl) async {
    // Kept for older call sites. Current uploads stay in Cloudinary.
  }

  static String uploadTypeForDiagnostics({
    required String folder,
    required String fileName,
  }) {
    return _userUploadContext(
      ownerUid: 'diagnostic-user',
      folder: folder,
      fileName: fileName,
    )['uploadType'] as String;
  }

  static Future<CloudinaryUploadResult> _upload({
    required File imageFile,
    required Map<String, Object?> signatureRequestData,
  }) async {
    final validation = await _validateLocalImage(imageFile);
    final signature = await _requestSignedUpload(
      signatureRequestData: {
        ...signatureRequestData,
        'fileSizeBytes': validation.byteLength,
        'format': validation.extension,
        'contentType': validation.contentType,
      },
    );

    try {
      final request = http.MultipartRequest('POST', signature.uploadUri);
      signature.parameters.forEach((key, value) {
        request.fields[key] = value;
      });
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final response = await request.send().timeout(_uploadTimeout);
      final body =
          await response.stream.bytesToString().timeout(_uploadTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ImageUploadException(_cloudinaryErrorMessage(body));
      }

      final payload = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = payload['secure_url'] as String?;
      final publicId = payload['public_id'] as String?;
      final bytes = payload['bytes'];
      final format = payload['format']?.toString().toLowerCase();
      if (secureUrl == null || secureUrl.trim().isEmpty) {
        throw const ImageUploadException(
          'Cloudinary upload failed. Please try again.',
        );
      }
      if (publicId == null || publicId.trim().isEmpty) {
        throw const ImageUploadException(
          'Cloudinary upload failed: public id was not returned.',
        );
      }
      if (bytes is num && bytes > signature.maxFileSizeBytes) {
        throw const ImageUploadException(
          'Cloudinary upload failed: select an image smaller than 8 MB.',
        );
      }
      if (format != null &&
          format.isNotEmpty &&
          !signature.allowedFormats.contains(format)) {
        throw const ImageUploadException(
          'Cloudinary upload failed: unsupported image format.',
        );
      }
      return CloudinaryUploadResult(
        secureUrl: secureUrl.trim(),
        publicId: publicId.trim(),
      );
    } on TimeoutException {
      throw const ImageUploadException(
        'Cloudinary upload failed (network-request-failed). Please check your connection and try again.',
      );
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

  static Future<_SignedCloudinaryUpload> _requestSignedUpload({
    required Map<String, Object?> signatureRequestData,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('signCloudinaryUpload')
          .call(signatureRequestData);
      return _SignedCloudinaryUpload.fromMap(
        result.data as Map<dynamic, dynamic>,
      );
    } on FirebaseFunctionsException catch (error) {
      throw ImageUploadException(_cloudinarySignatureErrorMessage(error));
    } on TypeError {
      throw const ImageUploadException(
        'Cloudinary upload failed: signed upload service returned an invalid response.',
      );
    }
  }

  static Future<_LocalImageValidation> _validateLocalImage(
      File imageFile) async {
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

    final extension = _safeImageExtension(imageFile.path);
    if (!_allowedExtensions.contains(extension)) {
      throw const ImageUploadException(
        'Image upload failed: unsupported image format.',
      );
    }

    return _LocalImageValidation(
      byteLength: byteLength,
      extension: extension,
      contentType: _contentTypeForExtension(extension),
    );
  }

  static Map<String, Object?> _userUploadContext({
    required String ownerUid,
    required String folder,
    required String fileName,
  }) {
    if (ownerUid.trim().isEmpty) {
      throw const ImageUploadException(
        'Image upload failed: please sign in again before checkout.',
      );
    }

    final segments = _splitStoragePath(folder);
    if (segments.length == 2 && segments.first == 'orders') {
      final uploadType = fileName == 'payment-receipt'
          ? 'payment_receipt'
          : 'order_shopping_list';
      return {
        'uploadType': uploadType,
        'orderId': _requiredSafeId(segments[1], 'order'),
      };
    }
    if (segments.length == 2 && segments.first == 'support') {
      return {
        'uploadType': 'support_message',
        'ticketId': _requiredSafeId(segments[1], 'support ticket'),
      };
    }

    throw const ImageUploadException(
      'Image upload failed: unsupported upload destination.',
    );
  }

  static List<String> _splitStoragePath(String value) {
    return value
        .split(RegExp(r'[\\/]'))
        .map(_sanitizePathSegment)
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  static String _requiredSafeId(String value, String label) {
    final sanitized = _sanitizePathSegment(value);
    if (sanitized.isEmpty || sanitized != value.trim()) {
      throw ImageUploadException(
        'Image upload failed: invalid $label id.',
      );
    }
    return sanitized;
  }

  static String _sanitizePathSegment(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'(^[._-]+|[._-]+$)'), '');
  }

  static String _safeImageExtension(String imagePath) {
    final extension =
        path.extension(imagePath).toLowerCase().replaceAll('.', '');
    if (extension == 'jpeg') {
      return 'jpg';
    }
    return extension;
  }

  static String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  static String _cloudinarySignatureErrorMessage(
    FirebaseFunctionsException error,
  ) {
    final message = error.message;
    switch (error.code) {
      case 'invalid-argument':
        return message ?? 'Cloudinary upload request is invalid.';
      case 'failed-precondition':
        return message ?? 'Cloudinary upload is not configured.';
      case 'permission-denied':
      case 'unauthenticated':
        return message ?? 'Cloudinary upload failed: please sign in again.';
      case 'not-found':
        return message ?? 'Cloudinary upload service is not deployed.';
      case 'unavailable':
        return message ?? 'Cloudinary upload service is unavailable.';
      default:
        return message ?? 'Cloudinary upload failed. Please try again.';
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

class _LocalImageValidation {
  const _LocalImageValidation({
    required this.byteLength,
    required this.extension,
    required this.contentType,
  });

  final int byteLength;
  final String extension;
  final String contentType;
}

class _SignedCloudinaryUpload {
  const _SignedCloudinaryUpload({
    required this.uploadUri,
    required this.parameters,
    required this.maxFileSizeBytes,
    required this.allowedFormats,
  });

  final Uri uploadUri;
  final Map<String, String> parameters;
  final int maxFileSizeBytes;
  final Set<String> allowedFormats;

  factory _SignedCloudinaryUpload.fromMap(Map<dynamic, dynamic> map) {
    final uploadUrl = map['uploadUrl']?.toString() ?? '';
    final parameterMap = map['parameters'];
    if (uploadUrl.isEmpty || parameterMap is! Map) {
      throw const ImageUploadException(
        'Cloudinary upload failed: signed upload service returned an invalid response.',
      );
    }

    return _SignedCloudinaryUpload(
      uploadUri: Uri.parse(uploadUrl),
      parameters: parameterMap.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      maxFileSizeBytes: (map['maxFileSizeBytes'] as num?)?.toInt() ??
          ImageUploadService.maxUploadBytes,
      allowedFormats: (map['allowedFormats'] as List<dynamic>? ??
              ImageUploadService._allowedExtensions.toList())
          .map((format) => format.toString().toLowerCase())
          .toSet(),
    );
  }
}
