import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'service_exceptions.dart';

class StorageServiceException implements Exception {
  const StorageServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StorageService {
  StorageService({required bool firebaseAvailable})
      : _firebaseAvailable = firebaseAvailable;

  final bool _firebaseAvailable;

  FirebaseStorage get _storage {
    if (!_firebaseAvailable) {
      throw const FirebaseUnavailableException();
    }
    return FirebaseStorage.instance;
  }

  Future<String> uploadFile({
    required String localPath,
    required String storagePath,
  }) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      throw StateError('Selected file was not found.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('Selected image is empty.');
    }

    final extension = _imageExtension(localPath);
    final ref = _storage.ref(_storagePathWithExtension(
      storagePath: storagePath,
      extension: extension,
    ));
    final metadata = SettableMetadata(contentType: _contentType(extension));

    try {
      final upload = await ref.putData(bytes, metadata);
      return await _downloadUrlWithRetry(upload.ref);
    } on FirebaseException catch (error) {
      throw StorageServiceException(_storageErrorMessage(error));
    } on TimeoutException {
      throw const StorageServiceException(
        'Image uploaded but Firebase did not return the download URL in time. Try saving again.',
      );
    }
  }

  Future<String> _downloadUrlWithRetry(Reference ref) async {
    FirebaseException? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await ref.getDownloadURL().timeout(const Duration(seconds: 10));
      } on FirebaseException catch (error) {
        lastError = error;
        if (error.code != 'object-not-found') {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    }
    throw lastError ??
        FirebaseException(
          plugin: 'firebase_storage',
          code: 'object-not-found',
        );
  }

  String _imageExtension(String localPath) {
    final extension =
        path.extension(localPath).replaceFirst('.', '').toLowerCase();
    if (extension == 'jpeg' || extension == 'jpg') {
      return 'jpg';
    }
    if (extension == 'png' || extension == 'webp' || extension == 'gif') {
      return extension;
    }
    return 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  String _storagePathWithExtension({
    required String storagePath,
    required String extension,
  }) {
    final currentExtension = path.extension(storagePath);
    if (currentExtension.isNotEmpty) {
      return storagePath;
    }
    return '$storagePath.$extension';
  }

  String _storageErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'object-not-found':
        return 'Firebase Storage could not find the uploaded image. Make sure Firebase Storage is enabled for this project, deploy storage rules, then try again.';
      case 'unauthorized':
      case 'permission-denied':
        return 'Firebase Storage blocked this image upload. Deploy the latest storage.rules and login as admin again.';
      case 'bucket-not-found':
        return 'Firebase Storage bucket was not found. Create/enable Firebase Storage in the Firebase Console.';
      case 'quota-exceeded':
        return 'Firebase Storage quota is exceeded. Check Firebase Storage usage in the console.';
      case 'canceled':
        return 'Image upload was canceled.';
      case 'retry-limit-exceeded':
        return 'Image upload failed because the network was too slow. Try again.';
      default:
        return error.message ?? 'Image upload failed. Try again.';
    }
  }
}
