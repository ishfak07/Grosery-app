import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/features/customer/customer_screens.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final globalHours = ShopHoursSettings(
    openingMinutes: 8 * 60,
    closingMinutes: 22 * 60,
    updatedAt: DateTime(2026),
  );

  group('Shop.allowedMethods', () {
    test('defaults to every method', () {
      expect(_shop().allowedMethods, Shop.allShoppingMethods);
      expect(_shop().hasMethodRestrictions, isFalse);
    });

    test('a restricted category reports only its enabled methods', () {
      final pharmacy = _shop(
        allowedMethods: const [
          OrderCategoryMethod.methodManual,
          OrderCategoryMethod.methodPhoto,
        ],
      );
      expect(pharmacy.allowsMethod(OrderCategoryMethod.methodItems), isFalse);
      expect(pharmacy.allowsMethod(OrderCategoryMethod.methodPhoto), isTrue);
      expect(pharmacy.hasMethodRestrictions, isTrue);
    });

    test('normalizes to canonical order and drops unknown methods', () {
      final shop = _shop(
        allowedMethods: const [
          OrderCategoryMethod.methodManual,
          'teleport',
          OrderCategoryMethod.methodItems,
        ],
      );
      expect(shop.allowedMethods, [
        OrderCategoryMethod.methodItems,
        OrderCategoryMethod.methodManual,
      ]);
    });

    test('an empty or missing list falls back to every method', () {
      expect(_shop(allowedMethods: const []).allowedMethods,
          Shop.allShoppingMethods);
      expect(
        Shop.fromMap(const {'shopName': 'Legacy'}, 'legacy').allowedMethods,
        Shop.allShoppingMethods,
      );
    });

    test('survives a Firestore round trip', () {
      final saved = _shop(
        allowedMethods: const [OrderCategoryMethod.methodPhoto],
      );
      final restored = Shop.fromMap(saved.toMap(), saved.shopId);
      expect(restored.allowedMethods, [OrderCategoryMethod.methodPhoto]);
    });
  });

  group('Shop.effectiveHours', () {
    test('falls back to the global hours without an override', () {
      expect(_shop().effectiveHours(globalHours), same(globalHours));
    });

    test('a category override replaces the global hours', () {
      final pharmacy = _shop(
        hoursOverride: ShopHoursSettings(
          openingMinutes: 0,
          closingMinutes: 0, // open all day
          updatedAt: DateTime(2026),
        ),
      );
      expect(pharmacy.isOpenAt(DateTime(2026, 1, 1, 23), globalHours), isTrue);
      expect(_shop().isOpenAt(DateTime(2026, 1, 1, 23), globalHours), isFalse);
    });

    test('a global temporary closure overrides every category override', () {
      final pharmacy = _shop(
        hoursOverride: ShopHoursSettings(
          openingMinutes: 0,
          closingMinutes: 0,
          updatedAt: DateTime(2026),
        ),
      );
      final closedGlobally = globalHours.copyWith(
        isTemporarilyClosed: true,
        temporaryClosureReason: 'Stocktake',
      );
      expect(pharmacy.isOpenAt(DateTime(2026, 1, 1, 14), closedGlobally),
          isFalse);
    });

    test('a per-category temporary closure closes only that category', () {
      final pharmacy = _shop(
        hoursOverride: globalHours.copyWith(
          isTemporarilyClosed: true,
          temporaryClosureReason: 'Pharmacist away',
        ),
      );
      expect(
          pharmacy.isOpenAt(DateTime(2026, 1, 1, 14), globalHours), isFalse);
      expect(_shop().isOpenAt(DateTime(2026, 1, 1, 14), globalHours), isTrue);
    });

    test('an override survives a Firestore round trip', () {
      final saved = _shop(
        hoursOverride: ShopHoursSettings(
          openingMinutes: 9 * 60,
          closingMinutes: 17 * 60,
          updatedAt: DateTime(2026),
        ),
      );
      final restored = Shop.fromMap(saved.toMap(), saved.shopId);
      expect(restored.hoursOverride!.openingMinutes, 9 * 60);
      expect(restored.hoursOverride!.closingMinutes, 17 * 60);
    });
  });

  group('AppState per-category enforcement', () {
    test('adding a disallowed method to a category is rejected', () async {
      final appState = _buildAppState();
      appState.debugSetCategoriesForTesting([
        _shop(
          id: 'pharmacy',
          name: 'Pharmacy',
          allowedMethods: const [
            OrderCategoryMethod.methodPhoto,
            OrderCategoryMethod.methodManual,
          ],
        ),
      ]);
      appState.setSelectedHomeCategory(_shop(id: 'pharmacy', name: 'Pharmacy'));

      expect(
        () => appState.addToCart(_product(shopId: 'pharmacy')),
        throwsA(isA<CategoryMethodNotAllowedException>()),
      );
      // The methods the admin did enable still work.
      await appState.setManualListText('Panadol');
      expect(
        appState.selectedMethodForCategory('pharmacy'),
        OrderCategoryMethod.methodManual,
      );
    });

    test('an unknown category accepts every method', () async {
      final appState = _buildAppState();
      appState.setSelectedHomeCategory(_shop(id: 'ghost', name: 'Ghost'));
      await appState.setManualListText('Something');
      expect(
        appState.selectedMethodForCategory('ghost'),
        OrderCategoryMethod.methodManual,
      );
    });

    test('resolves hours per category', () {
      final appState = _buildAppState();
      appState.debugSetShopHoursSettingsForTesting(globalHours);
      appState.debugSetCategoriesForTesting([
        _shop(id: 'grocery', name: 'Grocery'),
        _shop(
          id: 'pharmacy',
          name: 'Pharmacy',
          hoursOverride: globalHours.copyWith(
            isTemporarilyClosed: true,
            temporaryClosureReason: 'Pharmacist away',
          ),
        ),
      ]);

      expect(appState.isCategoryOpenNow('pharmacy'), isFalse);
      expect(
        appState.effectiveHoursForCategory('pharmacy').temporaryClosureReason,
        'Pharmacist away',
      );
      expect(appState.effectiveHoursForCategory('grocery'), same(globalHours));
    });

    test('allowedMethodsForCategory falls back for unknown ids', () {
      final appState = _buildAppState();
      expect(
        appState.allowedMethodsForCategory('nope'),
        Shop.allShoppingMethods,
      );
    });
  });

  group('CategoryMethodSelectionScreen', () {
    testWidgets('offers only the methods the admin enabled', (tester) async {
      final pharmacy = _shop(
        id: 'pharmacy',
        name: 'Pharmacy',
        allowedMethods: const [
          OrderCategoryMethod.methodPhoto,
          OrderCategoryMethod.methodManual,
        ],
      );
      final appState = _buildAppState();
      appState.debugSetCategoriesForTesting([pharmacy]);

      await tester.pumpWidget(
        _wrap(appState, CategoryMethodSelectionScreen(shop: pharmacy)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photo List'), findsOneWidget);
      expect(find.text('Manual List'), findsOneWidget);
      expect(find.text('Select Items'), findsNothing);
    });

    testWidgets('shows a closed notice for a closed category', (tester) async {
      final pharmacy = _shop(
        id: 'pharmacy',
        name: 'Pharmacy',
        hoursOverride: globalHours.copyWith(
          isTemporarilyClosed: true,
          temporaryClosureReason: 'Pharmacist away',
        ),
      );
      final appState = _buildAppState();
      appState.debugSetShopHoursSettingsForTesting(globalHours);
      appState.debugSetCategoriesForTesting([pharmacy]);

      await tester.pumpWidget(
        _wrap(appState, CategoryMethodSelectionScreen(shop: pharmacy)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Closed right now'), findsOneWidget);
      expect(find.text('Pharmacist away'), findsOneWidget);
    });
  });

  test('closedMessageFor names the category', () {
    final closed = globalHours.copyWith(
      isTemporarilyClosed: true,
      temporaryClosureReason: 'Pharmacist away',
    );
    expect(closed.closedMessageFor('Pharmacy'),
        'Pharmacy is temporarily closed.');
    expect(
      globalHours.closedMessageFor('Pharmacy'),
      'Pharmacy is closed. Please come back at 8:00 AM.',
    );
  });
}

Widget _wrap(AppState appState, Widget child) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(home: child),
  );
}

AppState _buildAppState() => AppState(
      const FirebaseBootstrap(
        isReady: false,
        errorMessage: 'Firebase unavailable in category policy test',
      ),
    );

Shop _shop({
  String id = 'veg',
  String name = 'Vegetables',
  List<String>? allowedMethods,
  ShopHoursSettings? hoursOverride,
}) {
  return Shop(
    shopId: id,
    shopName: name,
    address: '',
    phone: '',
    isActive: true,
    createdAt: DateTime(2026),
    allowedMethods: Shop.normalizeMethods(allowedMethods),
    hoursOverride: hoursOverride,
  );
}

Product _product({String shopId = 'veg', String shopName = 'Vegetables'}) {
  final now = DateTime(2026);
  return Product(
    productId: 'p1',
    shopId: shopId,
    shopName: shopName,
    name: 'Item',
    nameTamil: '',
    category: 'Other',
    description: '',
    descriptionTamil: '',
    price: 600,
    imageUrl: '',
    imagePublicId: '',
    unit: 'piece',
    stockStatus: 'available',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
