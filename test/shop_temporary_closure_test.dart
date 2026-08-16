import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/constants/app_constants.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/services/service_exceptions.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final normalHours = ShopHoursSettings(
    openingMinutes: 8 * 60, // 8:00 AM
    closingMinutes: 22 * 60, // 10:00 PM
    updatedAt: DateTime(2026, 1, 1),
  );
  final withinHours = DateTime(2026, 1, 1, 14); // 2:00 PM
  final outsideHours = DateTime(2026, 1, 1, 23); // 11:00 PM

  group('ShopHoursSettings.isOpenAt manual-closure override', () {
    test('closure OFF + within normal hours -> open', () {
      expect(normalHours.isOpenAt(withinHours), isTrue);
    });

    test('closure ON + within normal hours -> closed', () {
      final closed = normalHours.copyWith(
        isTemporarilyClosed: true,
        temporaryClosureReason: 'Maintenance',
      );
      expect(closed.isOpenAt(withinHours), isFalse);
    });

    test('closure ON + outside normal hours -> closed', () {
      final closed = normalHours.copyWith(
        isTemporarilyClosed: true,
        temporaryClosureReason: 'Maintenance',
      );
      expect(closed.isOpenAt(outsideHours), isFalse);
    });

    test(
        'closure OFF + outside normal hours -> existing hours block still works',
        () {
      expect(normalHours.isOpenAt(outsideHours), isFalse);
    });

    test('turning closure OFF restores normal shop-hours behaviour', () {
      final closed = normalHours.copyWith(
        isTemporarilyClosed: true,
        temporaryClosureReason: 'Maintenance',
      );
      final reopened = closed.copyWith(
        isTemporarilyClosed: false,
      );
      expect(reopened.isOpenAt(withinHours), isTrue);
      expect(reopened.isOpenAt(outsideHours), isFalse);
    });
  });

  group('Admin manual-closure validation', () {
    test('admin cannot activate closure without a reason', () async {
      final appState = _buildAppState();

      await expectLater(
        appState.updateShopManualClosure(
          isTemporarilyClosed: true,
          reason: '   ',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Please enter a reason before closing the shop.',
          ),
        ),
      );
    });

    test('admin can activate closure once a reason is provided', () async {
      final appState = _buildAppState();

      // Firebase is unavailable in this test environment, so persistence
      // itself fails past validation -- confirms the empty-reason guard is
      // not what rejected the call.
      await expectLater(
        appState.updateShopManualClosure(
          isTemporarilyClosed: true,
          reason: 'Stock unavailable',
        ),
        throwsA(isA<FirebaseUnavailableException>()),
      );
    });
  });

  group('Customer sees admin closure state', () {
    test('customer-facing getters expose the exact admin reason', () {
      final appState = _buildAppState();
      appState.debugSetShopHoursSettingsForTesting(
        normalHours.copyWith(
          isTemporarilyClosed: true,
          temporaryClosureReason: 'Emergency',
        ),
      );

      expect(appState.isShopManuallyClosed, isTrue);
      expect(appState.shopManualClosureReason, 'Emergency');
      expect(appState.isShopOpenNow, isFalse);
    });

    test('customer can still browse/cart while closed', () async {
      final appState = _buildAppState();
      appState.debugSetShopHoursSettingsForTesting(
        normalHours.copyWith(
          isTemporarilyClosed: true,
          temporaryClosureReason: 'Holiday',
        ),
      );

      await appState.addToCart(_product(id: 'p1', price: 200));

      expect(appState.cartItems, hasLength(1));
      expect(appState.cartSubtotal, 200);
    });
  });

  group('Order-placement guard (normal, photo list, manual list)', () {
    test(
        'createOrder is blocked while manually closed even inside normal hours',
        () async {
      final appState = _buildAppState();
      appState.debugSetProfileForTesting(_profile());
      appState.debugSetShopHoursSettingsForTesting(
        normalHours.copyWith(
          isTemporarilyClosed: true,
          temporaryClosureReason: 'Stock unavailable',
        ),
      );
      await appState.addToCart(
        _product(id: 'p1', price: AppConstants.minimumOrderValue + 500),
      );

      await expectLater(
        appState.createOrder(
          customerName: 'Test Customer',
          customerPhone: '+94770000000',
          customerAddress: 'Puttalam',
          orderNotes: '',
          paymentMethod: AppConstants.paymentMethodCod,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('temporarily closed'),
          ),
        ),
      );
    });

    test('photo list final order is blocked while manually closed', () async {
      final appState = _buildAppState();
      appState.debugSetProfileForTesting(_profile());
      appState.debugSetShopHoursSettingsForTesting(
        normalHours.copyWith(
          isTemporarilyClosed: true,
          temporaryClosureReason: 'Maintenance',
        ),
      );
      await appState.setBillImagePath('/tmp/list.jpg');

      await expectLater(
        appState.createOrder(
          customerName: 'Test Customer',
          customerPhone: '+94770000000',
          customerAddress: 'Puttalam',
          orderNotes: '',
          paymentMethod: AppConstants.paymentMethodCod,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('manual list final order is blocked while manually closed', () async {
      final appState = _buildAppState();
      appState.debugSetProfileForTesting(_profile());
      appState.debugSetShopHoursSettingsForTesting(
        normalHours.copyWith(
          isTemporarilyClosed: true,
          temporaryClosureReason: 'Custom reason',
        ),
      );
      await appState.setManualListText('2 kg rice');

      await expectLater(
        appState.createOrder(
          customerName: 'Test Customer',
          customerPhone: '+94770000000',
          customerAddress: 'Puttalam',
          orderNotes: '',
          paymentMethod: AppConstants.paymentMethodCod,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'closure OFF + open-all-day default hours lets order placement pass '
        'the shop-hours guard (fails later only on Firebase unavailability)',
        () async {
      final appState = _buildAppState();
      appState.debugSetProfileForTesting(_profile());
      await appState.addToCart(
        _product(id: 'p1', price: AppConstants.minimumOrderValue + 500),
      );

      await expectLater(
        appState.createOrder(
          customerName: 'Test Customer',
          customerPhone: '+94770000000',
          customerAddress: 'Puttalam',
          orderNotes: '',
          paymentMethod: AppConstants.paymentMethodCod,
        ),
        throwsA(isA<FirebaseUnavailableException>()),
      );
    });

    test('existing minimum-order rule still applies once reopened', () async {
      final appState = _buildAppState();
      appState.debugSetProfileForTesting(_profile());
      appState.debugSetShopHoursSettingsForTesting(
        normalHours.copyWith(isTemporarilyClosed: false),
      );
      await appState.addToCart(_product(id: 'p1', price: 100));

      expect(appState.meetsMinimumOrderValue, isFalse);
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
  });

  test('order statuses still include Rejected for the existing admin flow', () {
    expect(AppConstants.orderStatuses, contains('Rejected'));
    expect(AppConstants.selectableOrderStatuses, contains('Rejected'));
  });
}

AppState _buildAppState() => AppState(
      const FirebaseBootstrap(
        isReady: false,
        errorMessage: 'Firebase unavailable in shop-closure test',
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
