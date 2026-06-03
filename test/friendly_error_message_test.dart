import 'package:flutter_test/flutter_test.dart';
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
}
