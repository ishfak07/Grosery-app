import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Cart follows the live catalog price', () {
    test(
        'an existing cart item recalculates to the new price once the admin '
        'changes the catalog, without being removed/re-added', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      await appState.updateCartQuantity('p1', 2);

      expect(appState.cartSubtotal, 2400);

      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      final cartItem = appState.cartItems.single;
      expect(appState.livePriceFor(cartItem), 1300);
      expect(appState.lineTotalFor(cartItem), 2600);
      expect(appState.cartSubtotal, 2600);
    });

    test('quantity math: 2 x 1200 (2400) becomes 2 x 1300 (2600)', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      await appState.updateCartQuantity('p1', 2);
      expect(appState.cartSubtotal, 2400);

      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      expect(appState.cartSubtotal, 2600);
    });

    test('the locally cached CartItem.price is not mutated by a live price '
        'change (only the derived total is)', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));

      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      expect(appState.cartItems.single.price, 1200);
      expect(appState.livePriceFor(appState.cartItems.single), 1300);
    });

    test('a product removed from the catalog falls back to the cached cart '
        'price instead of crashing or zeroing out', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      appState.debugSetProductCatalogForTesting(const []);

      expect(appState.livePriceFor(appState.cartItems.single), 1200);
      expect(appState.cartSubtotal, 1200);
    });

    test('an unrelated cart item (different product id) is unaffected by a '
        'price change on another product', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      await appState.addToCart(_product(id: 'p2', price: 400));

      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
        _product(id: 'p2', price: 400),
      ]);

      expect(appState.cartSubtotal, 1300 + 400);
    });
  });

  group('Checkout resolves the latest price before totals are shown', () {
    test('checkout subtotal/total reflect the live price, not the stale '
        'cart price', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));

      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      final total =
          appState.checkoutChargeSettings.totalFor(appState.cartSubtotal);

      expect(appState.cartSubtotal, 1300);
      expect(
        total,
        1300 + appState.checkoutChargeSettings.totalCharge,
      );
    });
  });

  group('Race-condition protection at order creation', () {
    test('resolved checkout items use the live catalog price even though '
        'the cart still carries the stale price it was added at', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      // Admin changes the price after the customer opened checkout.
      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      final resolvedItems = await appState.debugResolveCheckoutItemsForTesting();

      expect(resolvedItems.single.price, 1300);
      // The cart's own cached copy is untouched — only the resolution used
      // for order creation is guaranteed fresh.
      expect(appState.cartItems.single.price, 1200);
    });

    test('resolved checkout item totals recalculate for quantity > 1',
        () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      await appState.updateCartQuantity('p1', 2);
      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      final resolvedItems = await appState.debugResolveCheckoutItemsForTesting();

      expect(resolvedItems.single.lineTotal, 2600);
    });

    test('a product missing from the catalog snapshot still resolves via '
        'the cached cart price rather than failing checkout', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));

      final resolvedItems = await appState.debugResolveCheckoutItemsForTesting();

      expect(resolvedItems.single.price, 1200);
    });
  });
}

AppState _buildAppState() => AppState(
      const FirebaseBootstrap(
        isReady: false,
        errorMessage: 'Firebase unavailable in live-price-sync test',
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
