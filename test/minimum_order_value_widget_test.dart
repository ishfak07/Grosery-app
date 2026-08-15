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

  testWidgets('Cart screen blocks checkout below the minimum order value',
      (tester) async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 300));

    await tester.pumpWidget(_wrap(appState, const CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Minimum Order Value'), findsOneWidget);
    expect(
      find.text('Add Rs. 200 more to reach the minimum order value.'),
      findsOneWidget,
    );
    expect(_checkoutButton(tester).onPressed, isNull);
  });

  testWidgets('Cart screen allows checkout at the minimum order value',
      (tester) async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 500));

    await tester.pumpWidget(_wrap(appState, const CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Minimum Order Value'), findsNothing);
    expect(_checkoutButton(tester).onPressed, isNotNull);
  });

  testWidgets('Cart screen allows checkout above the minimum order value',
      (tester) async {
    final appState = _buildAppState();
    await appState.addToCart(_product(id: 'p1', price: 750));

    await tester.pumpWidget(_wrap(appState, const CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Minimum Order Value'), findsNothing);
    expect(_checkoutButton(tester).onPressed, isNotNull);
  });

  testWidgets(
      'Cart screen does not apply the cart minimum to a photo list order',
      (tester) async {
    final appState = _buildAppState();
    await appState.setBillImagePath('/tmp/list.jpg');

    await tester.pumpWidget(_wrap(appState, const CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Minimum Order Value'), findsNothing);
    expect(_checkoutButton(tester).onPressed, isNotNull);
  });

  testWidgets(
      'Cart screen does not apply the cart minimum to a manual list order',
      (tester) async {
    final appState = _buildAppState();
    await appState.setManualListText('2 kg rice');

    await tester.pumpWidget(_wrap(appState, const CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Minimum Order Value'), findsNothing);
    expect(_checkoutButton(tester).onPressed, isNotNull);
  });

  testWidgets('Photo List screen displays the important order notice',
      (tester) async {
    final appState = _buildAppState();

    // UploadBillScreen has decorative looping animations, so pump a fixed
    // number of frames instead of pumpAndSettle (which never settles).
    await tester.pumpWidget(_wrap(appState, const UploadBillScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Important Order Notice'), findsOneWidget);
    expect(
      find.text(
        'Please include multiple grocery items in your photo list. '
        'Orders containing only one or very few items may be rejected by the admin.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Photo List screen remains usable despite the warning',
      (tester) async {
    final appState = _buildAppState();

    await tester.pumpWidget(_wrap(appState, const UploadBillScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final chooseButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Choose photo'),
    );
    expect(chooseButton.onPressed, isNotNull);
  });

  testWidgets('Manual List screen displays the important order notice',
      (tester) async {
    final appState = _buildAppState();

    await tester.pumpWidget(_wrap(appState, const ManualListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Important Order Notice'), findsOneWidget);
    expect(
      find.text(
        'Please include multiple grocery items in your manual list. '
        'Orders containing only one or very few items may be rejected by the admin.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Manual List screen remains usable despite the warning',
      (tester) async {
    final appState = _buildAppState();

    await tester.pumpWidget(_wrap(appState, const ManualListScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '2 kg rice');
    await tester.pump();
    // Flush the manual-list save debounce timer before the test tears down.
    await tester.pump(const Duration(milliseconds: 600));

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue to checkout'),
    );
    expect(continueButton.onPressed, isNotNull);
  });

  testWidgets('Checkout screen blocks placing a below-minimum normal order',
      (tester) async {
    final appState = _buildAppState();
    appState.debugSetProfileForTesting(_profile());
    await appState.addToCart(_product(id: 'p1', price: 300));

    await tester.pumpWidget(_wrap(appState, const CheckoutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Minimum Order Value'), findsOneWidget);
    final placeOrderButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Place COD order'),
    );
    expect(placeOrderButton.onPressed, isNull);
  });

  testWidgets('Checkout screen allows placing an order at the minimum',
      (tester) async {
    final appState = _buildAppState();
    appState.debugSetProfileForTesting(_profile());
    await appState.addToCart(_product(id: 'p1', price: 500));

    await tester.pumpWidget(_wrap(appState, const CheckoutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Minimum Order Value'), findsNothing);
    final placeOrderButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Place COD order'),
    );
    expect(placeOrderButton.onPressed, isNotNull);
  });
}

ElevatedButton _checkoutButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Checkout'),
  );
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
