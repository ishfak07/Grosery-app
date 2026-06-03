import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/services/cloudinary_service.dart';
import 'package:grocerydelivery/src/core/widgets/common_widgets.dart';

void main() {
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

  test('turns Cloudinary upload failures into an image upload message', () {
    expect(
      appFriendlyErrorMessage(
        const CloudinaryUploadException(
          'Cloudinary upload failed with status 413.',
        ),
      ),
      'Image upload failed. Please check your connection and try again.',
    );
  });
}
