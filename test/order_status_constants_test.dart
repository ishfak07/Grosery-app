import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/constants/app_constants.dart';

void main() {
  test('customer tracking hides statuses that admin cannot select', () {
    expect(AppConstants.customerTrackingStatuses, isNot(contains('Cancelled')));
    expect(
      AppConstants.customerTrackingStatuses,
      isNot(contains('Item Unavailable')),
    );
    expect(AppConstants.customerTrackingStatuses, contains('Rejected'));
  });
}
