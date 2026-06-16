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

  test('payment settings default to both checkout methods enabled', () {
    final settings = PaymentSettings.fromMap(null);

    expect(settings.codEnabled, isTrue);
    expect(settings.bankTransferEnabled, isTrue);
    expect(settings.availablePaymentMethods, [
      'COD',
      'Bank Transfer',
    ]);
  });

  test('payment settings select the first enabled method', () {
    final settings = PaymentSettings.fromMap({
      'codEnabled': false,
      'bankTransferEnabled': true,
      'bankAccountName': 'Store Account',
      'bankName': 'Test Bank',
      'bankBranch': 'Main',
      'bankAccountNumber': '123456',
    });

    expect(settings.isPaymentMethodEnabled('COD'), isFalse);
    expect(settings.isPaymentMethodEnabled('Bank Transfer'), isTrue);
    expect(settings.availablePaymentMethodOrNull('COD'), 'Bank Transfer');
  });

  test('payment settings can stop all payment methods', () {
    final settings = PaymentSettings.fromMap({
      'codEnabled': false,
      'bankTransferEnabled': false,
    });

    expect(settings.hasAvailablePaymentMethod, isFalse);
    expect(settings.availablePaymentMethodOrNull('COD'), isNull);
  });
}
