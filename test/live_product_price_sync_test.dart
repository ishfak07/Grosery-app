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

    test(
        'the locally cached CartItem.price is not mutated by a live price '
        'change (only the derived total is)', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));

      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      expect(appState.cartItems.single.price, 1200);
      expect(appState.livePriceFor(appState.cartItems.single), 1300);
    });

    test(
        'a product removed from the catalog falls back to the cached cart '
        'price instead of crashing or zeroing out', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      appState.debugSetProductCatalogForTesting(const []);

      expect(appState.livePriceFor(appState.cartItems.single), 1200);
      expect(appState.cartSubtotal, 1200);
    });

    test(
        'an unrelated cart item (different product id) is unaffected by a '
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
    test(
        'checkout subtotal/total reflect the live price, not the stale '
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
    test(
        'resolved checkout items use the live catalog price even though '
        'the cart still carries the stale price it was added at', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      // Admin changes the price after the customer opened checkout.
      appState.debugSetProductCatalogForTesting([
        _product(id: 'p1', price: 1300),
      ]);

      final resolvedItems =
          await appState.debugResolveCheckoutItemsForTesting();

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

      final resolvedItems =
          await appState.debugResolveCheckoutItemsForTesting();

      expect(resolvedItems.single.lineTotal, 2600);
    });

    test(
        'a product missing from the catalog snapshot still resolves via '
        'the cached cart price rather than failing checkout', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));

      final resolvedItems =
          await appState.debugResolveCheckoutItemsForTesting();

      expect(resolvedItems.single.price, 1200);
    });
  });

  group('Checkout availability recheck (F7)', () {
    test('a product that is still available resolves normally', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      appState.debugSetLatestProductsForTesting({
        'p1': _product(id: 'p1', price: 1200),
      });

      final resolvedItems =
          await appState.debugResolveCheckoutItemsForTesting();

      expect(resolvedItems.single.productId, 'p1');
    });

    test(
        'a product the admin disabled after it was added to the cart '
        'blocks checkout with the unavailable item named', () async {
      final appState = _buildAppState();
      await appState.addToCart(
        _product(id: 'p1', price: 1200, name: 'Milk Powder'),
      );
      appState.debugSetLatestProductsForTesting({
        'p1': _product(
          id: 'p1',
          price: 1200,
          name: 'Milk Powder',
          isActive: false,
        ),
      });

      await expectLater(
        appState.debugResolveCheckoutItemsForTesting(),
        throwsA(
          isA<CartItemsUnavailableException>().having(
            (error) => error.unavailableItemNames,
            'unavailableItemNames',
            ['Milk Powder'],
          ),
        ),
      );
    });

    test(
        'a product out of stock (inactive flag still true) also blocks '
        'checkout', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      appState.debugSetLatestProductsForTesting({
        'p1': _product(id: 'p1', price: 1200, stockStatus: 'unavailable'),
      });

      await expectLater(
        appState.debugResolveCheckoutItemsForTesting(),
        throwsA(isA<CartItemsUnavailableException>()),
      );
    });

    test(
        'a product deleted from the catalog entirely (missing from the '
        'authoritative snapshot) blocks checkout rather than silently '
        'ordering a phantom product', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      // The authoritative fetch ran and simply found nothing for p1 - a
      // real deletion, not "the fetch didn't happen" (see the offline
      // fallback test above, which never calls
      // debugSetLatestProductsForTesting at all).
      appState.debugSetLatestProductsForTesting(const {});

      await expectLater(
        appState.debugResolveCheckoutItemsForTesting(),
        throwsA(isA<CartItemsUnavailableException>()),
      );
    });

    test(
        'with two items, only the one that became unavailable is named, '
        'and the other is left alone', () async {
      final appState = _buildAppState();
      await appState.addToCart(
        _product(id: 'p1', price: 1200, name: 'Milk Powder'),
      );
      await appState.addToCart(
        _product(id: 'p2', price: 400, name: 'Rice'),
      );
      appState.debugSetLatestProductsForTesting({
        'p1': _product(
          id: 'p1',
          price: 1200,
          name: 'Milk Powder',
          isActive: false,
        ),
        'p2': _product(id: 'p2', price: 400, name: 'Rice'),
      });

      await expectLater(
        appState.debugResolveCheckoutItemsForTesting(),
        throwsA(
          isA<CartItemsUnavailableException>().having(
            (error) => error.unavailableItemNames,
            'unavailableItemNames',
            ['Milk Powder'],
          ),
        ),
      );
    });

    test(
        'a price change and an availability change on the same item both '
        'surface: availability blocks before a stale price can be used',
        () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      appState.debugSetLatestProductsForTesting({
        'p1': _product(id: 'p1', price: 1500, isActive: false),
      });

      await expectLater(
        appState.debugResolveCheckoutItemsForTesting(),
        throwsA(isA<CartItemsUnavailableException>()),
      );
    });

    test(
        'when Firebase is unavailable (demo/offline mode), the '
        'availability recheck is skipped and checkout falls back to the '
        'cached cart data, same as the price fallback', () async {
      final appState = _buildAppState();
      await appState.addToCart(_product(id: 'p1', price: 1200));
      // No debugSetLatestProductsForTesting call - the authoritative fetch
      // path is never exercised, matching a real offline/misconfigured
      // Firebase session where fetchLatestProducts short-circuits.

      final resolvedItems =
          await appState.debugResolveCheckoutItemsForTesting();

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

Product _product({
  required String id,
  required double price,
  String? name,
  bool isActive = true,
  String stockStatus = 'available',
}) {
  final now = DateTime(2026);
  return Product(
    productId: id,
    shopId: 'shop-1',
    shopName: 'Puttalam Drop',
    name: name ?? 'Item $id',
    nameTamil: '',
    category: 'Other',
    description: '',
    descriptionTamil: '',
    price: price,
    imageUrl: '',
    imagePublicId: '',
    unit: 'piece',
    stockStatus: stockStatus,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}
