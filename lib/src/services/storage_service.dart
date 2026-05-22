import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'service_exceptions.dart';

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

    final extension = path.extension(localPath).replaceFirst('.', '');
    final ref = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: extension.isEmpty ? null : 'image/$extension',
    );
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }
}
