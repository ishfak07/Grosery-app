import 'dart:io';

import 'package:image_picker/image_picker.dart';

Future<File?> pickImageFromGallery() async {
  final picker = ImagePicker();

  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 70,
    maxWidth: 1200,
  );

  if (pickedFile == null) return null;

  return File(pickedFile.path);
}

Future<File?> takePhotoFromCamera() async {
  final picker = ImagePicker();

  final pickedFile = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 70,
    maxWidth: 1200,
  );

  if (pickedFile == null) return null;

  return File(pickedFile.path);
}
