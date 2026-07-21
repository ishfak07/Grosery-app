import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/services/image_upload_service.dart';
import 'package:grocerydelivery/src/core/widgets/common_widgets.dart';

void main() {
  test('routes checkout receipt images to signed Cloudinary receipts', () {
    expect(
      ImageUploadService.uploadTypeForDiagnostics(
        folder: 'orders/order-1',
        fileName: 'payment-receipt',
      ),
      'payment_receipt',
    );
  });

  test('routes checkout shopping list images to signed Cloudinary lists', () {
    expect(
      ImageUploadService.uploadTypeForDiagnostics(
        folder: 'orders/order-1',
        fileName: 'shopping-list',
      ),
      'order_shopping_list',
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
          'Cloudinary upload is not configured.',
        ),
      ),
      'Cloudinary image upload is not configured. Please contact support.',
    );
  });

  test('keeps missing Cloudinary signed upload function readable', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Cloudinary upload service is not deployed.',
        ),
      ),
      'Cloudinary image upload service is not deployed. Please contact support.',
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

  test('hides Cloudinary invalid signature diagnostics from users', () {
    expect(
      appFriendlyErrorMessage(
        const ImageUploadException(
          'Cloudinary upload failed: Invalid Signature abc123. String to sign - allowed_formats=jpg&timestamp=1.',
        ),
      ),
      'Image upload setup is invalid. Please contact support.',
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
