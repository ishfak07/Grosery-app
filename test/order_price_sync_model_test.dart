import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/constants/app_constants.dart';
import 'package:grocerydelivery/src/models/models.dart';

void main() {
  group('AppConstants.autoPriceSyncOrderStatuses', () {
    // Must be kept in sync with functions/lib/orderPriceSync.js's
    // AUTO_SYNC_ORDER_STATUSES — this test guards against the two runtimes
    // silently drifting apart.
    test('is exactly the pre-bill-finalization active statuses', () {
      expect(
        AppConstants.autoPriceSyncOrderStatuses,
        {'Pending', 'Accepted', 'Need Clarification', 'Shopping Started'},
      );
    });

    test('excludes Bill Updated and Out for Delivery (frozen automatically)',
        () {
      expect(
        AppConstants.autoPriceSyncOrderStatuses,
        isNot(contains('Bill Updated')),
      );
      expect(
        AppConstants.autoPriceSyncOrderStatuses,
        isNot(contains('Out for Delivery')),
      );
    });

    test('is a subset of the statuses still eligible for a manual sync', () {
      for (final status in AppConstants.autoPriceSyncOrderStatuses) {
        expect(
          _order(orderStatus: status).canApplyCurrentProductPrice,
          isTrue,
          reason: '$status must remain manually syncable too',
        );
      }
    });

    test('never overlaps with the finalized/historical statuses', () {
      expect(
        AppConstants.autoPriceSyncOrderStatuses
            .intersection(AppConstants.finalizedOrderStatuses),
        isEmpty,
      );
    });
  });

  group('OrderModel.canApplyCurrentProductPrice', () {
    for (final status in [
      'Pending',
      'Accepted',
      'Need Clarification',
      'Shopping Started',
      'Bill Updated',
      'Out for Delivery',
    ]) {
      test('$status is eligible for a catalog price sync', () {
        expect(_order(orderStatus: status).canApplyCurrentProductPrice, isTrue);
      });
    }

    for (final status in ['Delivered', 'Cancelled', 'Rejected']) {
      test('$status is a finalized/historical status and never eligible', () {
        expect(
          _order(orderStatus: status).canApplyCurrentProductPrice,
          isFalse,
        );
      });
    }
  });

  group('OrderModel.applyCatalogPrices — active order', () {
    test('updates an eligible order\'s item price and recalculates totals',
        () {
      final order = _order(
        orderStatus: 'Accepted',
        items: [_item(productId: 'p1', price: 1200, quantity: 2)],
        deliveryCharge: 250,
        serviceCharge: 0,
      );

      final updated = order.applyCatalogPrices({'p1': 1300});

      expect(updated.items.single.price, 1300);
      expect(updated.items.single.originalPrice, 1200,
          reason: 'the price the customer originally saw must be preserved');
      expect(updated.items.single.lineTotal, 2600);
      expect(updated.cartItemsAmount, 2600);
      expect(updated.subtotal, 2600);
      expect(updated.totalAmount, 2850);
    });

    test('quantity 2: 2 x 1200 (2400) becomes 2 x 1300 (2600)', () {
      final order = _order(
        orderStatus: 'Pending',
        items: [_item(productId: 'p1', price: 1200, quantity: 2)],
      );
      expect(order.items.single.lineTotal, 2400);

      final updated = order.applyCatalogPrices({'p1': 1300});

      expect(updated.items.single.lineTotal, 2600);
      expect(updated.subtotal, 2600);
    });

    test('marks hasPriceChanged once synced, and shows both prices', () {
      final order = _order(
        orderStatus: 'Bill Updated',
        items: [_item(productId: 'p1', price: 1200, quantity: 1)],
      );

      final updated = order.applyCatalogPrices({'p1': 1300});

      expect(updated.items.single.hasPriceChanged, isTrue);
      expect(updated.items.single.price, 1300);
      expect(updated.items.single.originalPrice, 1200);
    });

    test('photo/manual list amounts and delivery/service charges carry '
        'through unchanged', () {
      final order = _order(
        orderStatus: 'Accepted',
        items: [_item(productId: 'p1', price: 1200, quantity: 1)],
        photoListAmount: 300,
        manualListAmount: 150,
        deliveryCharge: 250,
        serviceCharge: 50,
      );

      final updated = order.applyCatalogPrices({'p1': 1300});

      expect(updated.photoListAmount, 300);
      expect(updated.manualListAmount, 150);
      expect(updated.subtotal, 1300 + 300 + 150);
      expect(updated.totalAmount, 1300 + 300 + 150 + 250 + 50);
    });
  });

  group('OrderModel.applyCatalogPrices — historical/finalized orders', () {
    for (final status in ['Delivered', 'Cancelled', 'Rejected']) {
      test('a $status order is never repriced by a catalog change', () {
        final order = _order(
          orderStatus: status,
          items: [_item(productId: 'p1', price: 1200, quantity: 2)],
        );

        final updated = order.applyCatalogPrices({'p1': 1300});

        expect(identical(updated, order), isTrue);
        expect(updated.items.single.price, 1200);
        expect(updated.items.single.originalPrice, 1200);
        expect(updated.totalAmount, order.totalAmount);
      });
    }

    test(
        'a delivered order keeps its exact historical total even though the '
        'catalog price has since changed', () {
      final order = _order(
        orderStatus: 'Delivered',
        items: [_item(productId: 'p1', price: 1200, quantity: 2)],
        deliveryCharge: 250,
      );
      expect(order.subtotal, 2400);
      expect(order.totalAmount, 2650);

      final updated = order.applyCatalogPrices({'p1': 1300});

      expect(updated.subtotal, 2400);
      expect(updated.totalAmount, 2650);
    });
  });

  group('OrderModel.applyCatalogPrices — unrelated/multiple orders safety',
      () {
    test('an order that does not contain the changed product is untouched',
        () {
      final order = _order(
        orderStatus: 'Pending',
        items: [_item(productId: 'other-product', price: 500, quantity: 1)],
      );

      final updated = order.applyCatalogPrices({'p1': 1300});

      expect(identical(updated, order), isTrue);
      expect(updated.items.single.price, 500);
    });

    test('an empty price map is a no-op', () {
      final order = _order(
        orderStatus: 'Pending',
        items: [_item(productId: 'p1', price: 1200, quantity: 1)],
      );

      expect(identical(order.applyCatalogPrices(const {}), order), isTrue);
    });

    test('a catalog price equal to the current price is a no-op', () {
      final order = _order(
        orderStatus: 'Pending',
        items: [_item(productId: 'p1', price: 1200, quantity: 1)],
      );

      expect(identical(order.applyCatalogPrices({'p1': 1200}), order), isTrue);
    });

    test(
        'only the item whose product id changed is updated; a sibling item '
        'in the same order is left alone', () {
      final order = _order(
        orderStatus: 'Pending',
        items: [
          _item(productId: 'p1', price: 1200, quantity: 1),
          _item(productId: 'p2', price: 400, quantity: 3),
        ],
      );

      final updated = order.applyCatalogPrices({'p1': 1300});

      final p1 = updated.items.firstWhere((item) => item.productId == 'p1');
      final p2 = updated.items.firstWhere((item) => item.productId == 'p2');
      expect(p1.price, 1300);
      expect(p2.price, 400);
      expect(updated.cartItemsAmount, 1300 + 1200);
    });
  });

  group('OrderItem back-compat', () {
    test('an old stored item map without originalPrice treats price as both',
        () {
      final item = OrderItem.fromMap({
        'productId': 'p1',
        'name': 'Anchor Milk Powder 400g',
        'price': 1200,
        'quantity': 2,
      });

      expect(item.originalPrice, 1200);
      expect(item.hasPriceChanged, isFalse);
    });

    test('a stored item map with originalPrice round-trips both fields', () {
      final item = OrderItem.fromMap({
        'productId': 'p1',
        'name': 'Anchor Milk Powder 400g',
        'price': 1300,
        'originalPrice': 1200,
        'quantity': 2,
      });

      expect(item.price, 1300);
      expect(item.originalPrice, 1200);
      expect(item.hasPriceChanged, isTrue);

      final map = item.toMap();
      expect(map['price'], 1300);
      expect(map['originalPrice'], 1200);
    });
  });
}

OrderModel _order({
  required String orderStatus,
  List<OrderItem> items = const [],
  double photoListAmount = 0,
  double manualListAmount = 0,
  double deliveryCharge = 0,
  double serviceCharge = 0,
}) {
  final now = DateTime(2026, 1, 1);
  final cartItemsAmount =
      items.fold<double>(0, (total, item) => total + item.lineTotal);
  final subtotal = cartItemsAmount + photoListAmount + manualListAmount;
  final total = subtotal + deliveryCharge + serviceCharge;
  return OrderModel(
    orderId: 'order-1',
    userId: 'user-1',
    customerName: 'Test Customer',
    customerPhone: '+94770000000',
    customerAddress: 'Puttalam',
    items: items,
    uploadedImageUrl: '',
    uploadedImagePublicId: '',
    manualListText: '',
    paymentReceiptImageUrl: '',
    paymentReceiptImagePublicId: '',
    orderNotes: '',
    cartItemsAmount: cartItemsAmount,
    photoListAmount: photoListAmount,
    manualListAmount: manualListAmount,
    listAmountsReviewed: true,
    subtotal: subtotal,
    deliveryCharge: deliveryCharge,
    serviceCharge: serviceCharge,
    totalAmount: total,
    paymentMethod: 'COD',
    paymentStatus: 'pending',
    orderStatus: orderStatus,
    adminNotes: '',
    rejectionReason: '',
    assignedDeliveryBoyId: '',
    assignedDeliveryPerson: '',
    assignedDeliveryPhone: '',
    deliveryRating: 0,
    deliveryReview: '',
    deliveryReviewedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

OrderItem _item({
  required String productId,
  required double price,
  required int quantity,
}) {
  return OrderItem(
    productId: productId,
    name: 'Item $productId',
    nameTamil: '',
    shopId: 'shop-1',
    shopName: 'Puttalam Drop',
    unit: 'piece',
    price: price,
    quantity: quantity,
  );
}
