import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImageUploadService {
  static const int maxUploadBytes = 8 * 1024 * 1024;

  static Future<String> uploadUserImage({
    required File imageFile,
    required String ownerUid,
    required String folder,
    required String fileName,
  }) {
    return _upload(
      imageFile: imageFile,
      storagePath: 'user_uploads/$ownerUid/$folder/$fileName',
    );
  }

  static Future<String> uploadCatalogImage({
    required File imageFile,
    required String collection,
    required String entityId,
  }) {
    return _upload(
      imageFile: imageFile,
      storagePath: 'catalog/$collection/$entityId/image',
    );
  }

  static Future<void> deleteFirebaseImage(String imageUrl) async {
    if (!imageUrl.startsWith('https://firebasestorage.googleapis.com/') &&
        !imageUrl.startsWith('gs://')) {
      return;
    }
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  static Future<String> _upload({
    required File imageFile,
    required String storagePath,
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

    try {
      final reference = FirebaseStorage.instance.ref(storagePath);
      await reference.putFile(
        imageFile,
        SettableMetadata(contentType: _contentType(imageFile.path)),
      );
      return reference.getDownloadURL();
    } on FirebaseException catch (error) {
      throw ImageUploadException(
        'Image upload failed (${error.code}). Please try again.',
      );
    }
  }

  static String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }
}
