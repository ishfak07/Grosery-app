import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/constants/app_constants.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the F8 fix: order creation must not create a duplicate order when
/// the same logical checkout attempt is retried (app killed mid-submit,
/// network retry, double invocation, ...). The actual Firestore-level
/// dedup (FirestoreService.createOrder no-oping when a document already
/// exists at the reserved id) can't be exercised without a real/emulated
/// Firestore backend, which isn't available in this environment - these
/// tests cover the client-side half that *is* fully testable in isolation:
/// the reserved order id staying stable across retries of the same
/// attempt, and persisting across an app relaunch.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pending order id reservation (F8)', () {
    test(
        'reserving twice within the same AppState instance returns the '
        'same id', () async {
      final appState = _buildAppState();

      final first = await appState.debugReservePendingOrderIdForTesting();
      final second = await appState.debugReservePendingOrderIdForTesting();

      expect(first, isNotEmpty);
      expect(first, second);
    });

    test(
        'the reserved id survives an app relaunch (a fresh AppState '
        'instance reading the same persisted local storage)', () async {
      final firstLaunch = _buildAppState();
      final reservedOnFirstLaunch =
          await firstLaunch.debugReservePendingOrderIdForTesting();

      // SharedPreferences' test backend is shared process-wide once
      // initialized, so a second AppState here reads the same persisted
      // value a real app relaunch would - without re-seeding mock values.
      final afterRelaunch = _buildAppState();
      final reservedAfterRelaunch =
          await afterRelaunch.debugReservePendingOrderIdForTesting();

      expect(reservedAfterRelaunch, reservedOnFirstLaunch);
    });

    test(
        'createOrder reuses the same reserved order id across two failed '
        'attempts for the same checkout draft (a retry), instead of a '
        'fresh id every call', () async {
      final appState = _buildAppState();
      appState.debugSetProfileForTesting(_profile());
      await appState.addToCart(_product(id: 'p1', price: 1200));
      // The item becomes unavailable right before the write would happen -
      // this fails createOrder deep enough (past order-id reservation) to
      // prove the id survives a real retry path, without needing Firestore.
      appState.debugSetLatestProductsForTesting({
        'p1': _product(id: 'p1', price: 1200, isActive: false),
      });

      Future<void> attempt() => appState.createOrder(
            customerName: 'Kasun Perera',
            customerPhone: '0771234567',
            customerAddress: '12 Lake Road, Puttalam',
            orderNotes: '',
            paymentMethod: AppConstants.paymentMethodCod,
          );

      await expectLater(
          attempt(), throwsA(isA<CartItemsUnavailableException>()));
      final firstId = await appState.debugReservePendingOrderIdForTesting();

      await expectLater(
          attempt(), throwsA(isA<CartItemsUnavailableException>()));
      final secondId = await appState.debugReservePendingOrderIdForTesting();

      expect(firstId, isNotEmpty);
      expect(firstId, secondId);
    });
  });
}

AppState _buildAppState() => AppState(
      const FirebaseBootstrap(
        isReady: false,
        errorMessage: 'Firebase unavailable in order-idempotency test',
      ),
    );

UserProfile _profile() {
  final now = DateTime(2026);
  return UserProfile(
    uid: 'customer-1',
    fullName: 'Kasun Perera',
    phone: '0771234567',
    hiddenEmail: '94771234567@app.local',
    role: 'user',
    address: '12 Lake Road, Puttalam',
    createdAt: now,
    updatedAt: now,
    isPhoneVerified: true,
    isBlocked: false,
  );
}

Product _product({
  required String id,
  required double price,
  bool isActive = true,
}) {
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
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}
