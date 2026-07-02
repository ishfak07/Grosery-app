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

  test('shop hours default to open all day', () {
    final settings = ShopHoursSettings.fromMap(null);

    expect(settings.isOpenAllDay, isTrue);
    expect(settings.isOpenAt(DateTime(2026, 7, 2, 2)), isTrue);
    expect(settings.isOpenAt(DateTime(2026, 7, 2, 23, 30)), isTrue);
  });

  test('shop hours block checkout before opening and after closing', () {
    final settings = ShopHoursSettings.fromMap({
      'openingMinutes': 9 * 60,
      'closingMinutes': 19 * 60,
    });

    expect(settings.isOpenAt(DateTime(2026, 7, 2, 8, 59)), isFalse);
    expect(settings.isOpenAt(DateTime(2026, 7, 2, 9)), isTrue);
    expect(settings.isOpenAt(DateTime(2026, 7, 2, 18, 30)), isTrue);
    expect(settings.isOpenAt(DateTime(2026, 7, 2, 19, 1)), isFalse);
    expect(
        settings.closedMessage, 'Shop is closed. Please come back at 9:00 AM.');
  });

  test('shop hours support overnight schedules', () {
    final settings = ShopHoursSettings.fromMap({
      'openingMinutes': 20 * 60,
      'closingMinutes': 2 * 60,
    });

    expect(settings.isOpenAt(DateTime(2026, 7, 2, 21)), isTrue);
    expect(settings.isOpenAt(DateTime(2026, 7, 3, 1, 30)), isTrue);
    expect(settings.isOpenAt(DateTime(2026, 7, 2, 12)), isFalse);
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
