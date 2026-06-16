import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/services/image_upload_service.dart';
import 'package:grocerydelivery/src/core/widgets/common_widgets.dart';

void main() {
  test('uses the configured Cloudinary upload endpoint by default', () {
    expect(
      ImageUploadService.cloudinaryUploadUriForDiagnostics().toString(),
      'https://api.cloudinary.com/v1_1/dbflkn1g/image/upload',
    );
  });

  test('turns Firestore unavailable errors into an offline message', () {
    expect(
      appFriendlyErrorMessage(
        '[cloud_firestore/unavailable] The service is currently unavailable.',
      ),
      appOfflineMessage,
    );
  });

  test('keeps normal user-facing state errors readable', () {
    expect(
      appFriendlyErrorMessage(
          'Bad state: Please login before placing an order.'),
      'Please login before placing an order.',
    );
  });

  test('does not turn storage permission upload failures into offline errors',
      () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Image upload failed (unauthorized). Please try again.',
        ),
      ),
      'Image upload failed. You are not allowed to upload this image. Please sign in again.',
    );
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Image upload failed: you are not allowed to upload this image. Please sign in again.',
        ),
      ),
      'Image upload failed. You are not allowed to upload this image. Please sign in again.',
    );
  });

  test('does not turn storage auth upload failures into offline errors', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Image upload failed: please sign in again before checkout.',
        ),
      ),
      'Image upload failed. Please sign in again before checkout.',
    );
  });

  test('keeps missing Firebase Storage setup out of offline errors', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Image upload failed: Firebase Storage is not set up for this app. Please contact support.',
        ),
      ),
      'Image uploads are not enabled yet. Please contact support.',
    );
  });

  test('keeps missing Cloudinary config out of offline errors', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Cloudinary upload is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.',
        ),
      ),
      'Cloudinary image upload is not configured. Please contact support.',
    );
  });

  test('keeps Cloudinary upload preset errors readable', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Cloudinary upload failed: Upload preset must be specified when using unsigned upload.',
        ),
      ),
      'Cloudinary upload preset is not ready. Please contact support.',
    );
  });

  test('keeps storage network upload failures as offline errors', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Image upload failed (network-request-failed). Please check your connection and try again.',
        ),
      ),
      appOfflineMessage,
    );
  });

  test('keeps Cloudinary network upload failures as offline errors', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Cloudinary upload failed (network-request-failed). Please check your connection and try again.',
        ),
      ),
      appOfflineMessage,
    );
  });

  test('keeps local image validation failures readable', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Image upload failed: select an image smaller than 8 MB.',
        ),
      ),
      'Image upload failed: select an image smaller than 8 MB.',
    );
  });
}
