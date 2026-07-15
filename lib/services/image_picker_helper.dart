import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelectionException implements Exception {
  const ImageSelectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _productImageSourceMaxDimension = 4096.0;
const _productImageOutputSize = 1200;
const _productImageQuality = 85;
const _productAspectRatio = CropAspectRatio(ratioX: 1, ratioY: 1);

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

Future<File?> pickProductImageFromGalleryForCrop() {
  return _pickProductImageForCrop(source: ImageSource.gallery);
}

Future<File?> takeProductPhotoForCrop() {
  return _pickProductImageForCrop(source: ImageSource.camera);
}

Future<File?> cropProductImageFile({
  required BuildContext context,
  required File imageFile,
}) async {
  try {
    if (!imageFile.existsSync()) {
      throw const ImageSelectionException(
        'The selected image was not found. Please choose it again.',
      );
    }

    if (imageFile.lengthSync() <= 0) {
      throw const ImageSelectionException(
        'The selected image is empty. Please choose another product image.',
      );
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      maxWidth: _productImageOutputSize,
      maxHeight: _productImageOutputSize,
      aspectRatio: _productAspectRatio,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: _productImageQuality,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop product image',
          toolbarColor: const Color(0xFF176B45),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF176B45),
          backgroundColor: Colors.white,
          cropFrameColor: const Color(0xFF176B45),
          cropGridColor: Colors.white,
          showCropGrid: true,
          lockAspectRatio: true,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Crop product image',
          doneButtonTitle: 'Use image',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          resetButtonHidden: false,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.page,
          size: const CropperSize(width: 520, height: 520),
          viewwMode: WebViewMode.mode_1,
          dragMode: WebDragMode.move,
          initialAspectRatio: 1,
          movable: true,
          rotatable: true,
          scalable: true,
          zoomable: true,
          cropBoxMovable: false,
          cropBoxResizable: false,
          translations: const WebTranslations(
            title: 'Crop product image',
            rotateLeftTooltip: 'Rotate left',
            rotateRightTooltip: 'Rotate right',
            cancelButton: 'Cancel',
            cropButton: 'Use image',
          ),
        ),
      ],
    );

    if (croppedFile == null) {
      return null;
    }

    final croppedImage = File(croppedFile.path);
    if (!croppedImage.existsSync() || croppedImage.lengthSync() <= 0) {
      throw const ImageSelectionException(
        'The cropped image could not be prepared. Please try again.',
      );
    }
    return croppedImage;
  } on ImageSelectionException {
    rethrow;
  } on MissingPluginException {
    throw const ImageSelectionException(
      'The image cropper needs a fresh app restart after this update. Close the app completely, reopen it, and try again.',
    );
  } on PlatformException catch (error) {
    throw ImageSelectionException(_imageSelectionErrorMessage(error));
  } on FileSystemException {
    throw const ImageSelectionException(
      'The selected image could not be read. Please choose another image.',
    );
  }
}

Future<File?> _pickProductImageForCrop({
  required ImageSource source,
}) async {
  final picker = ImagePicker();

  try {
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: _productImageSourceMaxDimension,
      maxHeight: _productImageSourceMaxDimension,
    );

    if (pickedFile == null) return null;

    return File(pickedFile.path);
  } on PlatformException catch (error) {
    throw ImageSelectionException(_imageSelectionErrorMessage(error));
  }
}

String _imageSelectionErrorMessage(PlatformException error) {
  final details = [
    error.code,
    if (error.message != null) error.message!,
    if (error.details != null) error.details.toString(),
  ].join(' ').toLowerCase();

  if (details.contains('permission') || details.contains('denied')) {
    return 'Photo permission is required to select a product image.';
  }
  if (details.contains('camera')) {
    return 'The camera could not be opened. Please try again or choose an image from the gallery.';
  }
  if (details.contains('large') ||
      details.contains('memory') ||
      details.contains('bitmap') ||
      details.contains('decode')) {
    return 'This image is too large to process. Please choose a smaller product image.';
  }
  if (details.contains('format') ||
      details.contains('unsupported') ||
      details.contains('invalid')) {
    return 'This image format is not supported. Please choose another product image.';
  }

  return 'The product image could not be prepared. Please choose another image and try again.';
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
