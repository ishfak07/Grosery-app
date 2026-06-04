import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';

void main() {
  test('preserves zero checkout charges from admin settings', () {
    final settings = CheckoutChargeSettings.fromMap({
      'deliveryCharge': 0,
      'serviceCharge': 0,
    });

    expect(settings.deliveryCharge, 0);
    expect(settings.serviceCharge, 0);
    expect(settings.totalFor(250), 250);
  });
}
