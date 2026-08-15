import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/constants/app_constants.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('minimum order value constant is Rs. 500', () {
    expect(AppConstants.minimumOrderValue, 500);
  });

  test('order statuses still include Rejected for the existing admin flow', () {
    expect(AppConstants.orderStatuses, contains('Rejected'));
    expect(AppConstants.selectableOrderStatuses, contains('Rejected'));
  });

  test('cart subtotal of Rs. 100 is below the minimum order value', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 100));

    expect(appState.cartSubtotal, 100);
    expect(appState.meetsMinimumOrderValue, isFalse);
  });

  test('cart subtotal of Rs. 499 is below the minimum order value', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 499));

    expect(appState.meetsMinimumOrderValue, isFalse);
  });

  test('cart subtotal of Rs. 500 meets the minimum order value', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 500));

    expect(appState.meetsMinimumOrderValue, isTrue);
  });

  test('cart subtotal above the minimum order value is allowed', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 750));

    expect(appState.meetsMinimumOrderValue, isTrue);
  });

  test('Rs. 320 subtotal shows Rs. 180 remaining', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 320));

    expect(appState.minimumOrderRemainingAmount, 180);
  });

  test('Rs. 450 subtotal shows Rs. 50 remaining', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 450));

    expect(appState.minimumOrderRemainingAmount, 50);
  });

  test('Rs. 500 exactly shows no remaining-amount warning', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 500));

    expect(appState.minimumOrderRemainingAmount, 0);
  });

  test('remaining amount is never negative once above the minimum', () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 900));

    expect(appState.minimumOrderRemainingAmount, 0);
  });

  test('delivery charge does not count toward the eligible product subtotal',
      () async {
    final appState = _buildAppState();
    // Products = Rs. 470, default delivery charge = Rs. 250 -> total 720,
    // but the eligible product subtotal used for the minimum check must
    // stay 470 and still fail the Rs. 500 minimum.
    await appState.addToCart(_product(id: 'p1', price: 470));

    final total =
        appState.checkoutChargeSettings.totalFor(appState.cartSubtotal);

    expect(appState.cartSubtotal, 470);
    expect(total, 720);
    expect(appState.meetsMinimumOrderValue, isFalse);
    expect(appState.minimumOrderRemainingAmount, 30);
  });

  test('photo list order is not blocked by the normal-cart minimum', () async {
    final appState = _buildAppState();
    await appState.setBillImagePath('/tmp/list.jpg');

    expect(appState.cartSubtotal, 0);
    expect(appState.isMinimumOrderCheckApplicable, isFalse);
    expect(appState.meetsMinimumOrderValue, isTrue);
  });

  test('manual list order is not blocked by the normal-cart minimum', () async {
    final appState = _buildAppState();
    await appState.setManualListText('2 kg rice');

    expect(appState.isMinimumOrderCheckApplicable, isFalse);
    expect(appState.meetsMinimumOrderValue, isTrue);
  });

  test(
      'mixed order: below-minimum cart items plus a photo list are not blocked',
      () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 100));
    await appState.setBillImagePath('/tmp/list.jpg');

    expect(appState.cartSubtotal, 100);
    expect(appState.isMinimumOrderCheckApplicable, isFalse);
    expect(appState.meetsMinimumOrderValue, isTrue);
  });

  test(
      'mixed order: below-minimum cart items plus a manual list are not blocked',
      () async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 100));
    await appState.setManualListText('2 kg rice');

    expect(appState.isMinimumOrderCheckApplicable, isFalse);
    expect(appState.meetsMinimumOrderValue, isTrue);
  });

  test(
      'final order-placement validation blocks a below-minimum normal cart order',
      () async {
    final appState = _buildAppState();
    appState.debugSetProfileForTesting(_profile());
    await appState.addToCart(_product(id: 'p1', price: 100));

    await expectLater(
      appState.createOrder(
        customerName: 'Test Customer',
        customerPhone: '+94770000000',
        customerAddress: 'Puttalam',
        orderNotes: '',
        paymentMethod: AppConstants.paymentMethodCod,
      ),
      throwsA(isA<MinimumOrderNotMetException>()),
    );
  });

  test('final order-placement validation reports the correct remaining amount',
      () async {
    final appState = _buildAppState();
    appState.debugSetProfileForTesting(_profile());
    await appState.addToCart(_product(id: 'p1', price: 320));

    try {
      await appState.createOrder(
        customerName: 'Test Customer',
        customerPhone: '+94770000000',
        customerAddress: 'Puttalam',
        orderNotes: '',
        paymentMethod: AppConstants.paymentMethodCod,
      );
      fail('Expected MinimumOrderNotMetException');
    } on MinimumOrderNotMetException catch (error) {
      expect(error.remainingAmount, 180);
      expect(error.minimumOrderValue, 500);
    }
  });
}

AppState _buildAppState() => AppState(
      const FirebaseBootstrap(
        isReady: false,
        errorMessage: 'Firebase unavailable in minimum-order-value test',
      ),
    );

Product _product({required String id, required double price}) {
  final now = DateTime(2026);
  return Product(
    productId: id,
    shopId: 'shop-1',
    shopName: 'Puttalam Drop',
    name: 'Item $id',
    nameTamil: '',
    category: 'Other',
    description: '',
    descriptionTamil: '',
    price: price,
    imageUrl: '',
    imagePublicId: '',
    unit: 'piece',
    stockStatus: 'available',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

UserProfile _profile() {
  final now = DateTime(2026);
  return UserProfile(
    uid: 'customer-1',
    fullName: 'Test Customer',
    phone: '+94770000000',
    hiddenEmail: '94770000000@app.local',
    role: 'user',
    address: 'Puttalam',
    createdAt: now,
    updatedAt: now,
    isPhoneVerified: true,
    isBlocked: false,
  );
}
