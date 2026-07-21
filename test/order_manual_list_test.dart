import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';

void main() {
  test('order stores and restores typed manual list text', () {
    final order = _order(manualListText: '2 kg rice\n6 eggs');
    final map = order.toMap();

    expect(order.hasManualList, isTrue);
    expect(order.hasShoppingList, isTrue);
    expect(map.containsKey('manualListText'), isFalse);
    expect(
      map['orderNotes'],
      'Manual grocery list:\n2 kg rice\n6 eggs',
    );

    final restored = OrderModel.fromMap(map, order.orderId);

    expect(restored.manualListText, '2 kg rice\n6 eggs');
    expect(restored.effectiveManualListText, '2 kg rice\n6 eggs');
    expect(restored.hasManualList, isTrue);
    expect(restored.orderNotes, '');
    expect(restored.customerNotes, '');
  });

  test('manual list can be stored alongside normal order notes', () {
    final order = _order(
      orderNotes: 'Please call before delivery.',
      manualListText: '1 packet sugar',
    );

    final restored = OrderModel.fromMap(order.toMap(), order.orderId);

    expect(restored.orderNotes, 'Please call before delivery.');
    expect(restored.customerNotes, 'Please call before delivery.');
    expect(restored.manualListText, '1 packet sugar');
  });

  test('splits manual grocery list out of raw notes for admin display', () {
    final order = _order(
      orderNotes: 'Notes from customer\n\nManual grocery list:\nit 1\nit 2',
    );

    expect(order.customerNotes, 'Notes from customer');
    expect(order.effectiveManualListText, 'it 1\nit 2');
    expect(order.manualListLines, ['it 1', 'it 2']);
    expect(order.hasManualList, isTrue);
    expect(order.toMap()['orderNotes'],
        'Notes from customer\n\nManual grocery list:\nit 1\nit 2');
  });

  test('splits manual grocery list heading with extra spaces', () {
    final order = _order(
      orderNotes:
          'Customer note\r\n\r\n  MANUAL grocery list :\r\n it 1\r\n\r\nit 2',
    );

    expect(order.customerNotes, 'Customer note');
    expect(order.effectiveManualListText, 'it 1\r\n\r\nit 2');
    expect(order.manualListLines, ['it 1', 'it 2']);
  });

  test('old orders without manual list text remain readable', () {
    final map = _order().toMap();

    final restored = OrderModel.fromMap(map, 'order-1');

    expect(restored.manualListText, '');
    expect(restored.hasManualList, isFalse);
  });

  test('old cart-only orders keep their stored subtotal as cart amount', () {
    final map = _order(subtotal: 1150, totalAmount: 1400).toMap()
      ..remove('cartItemsAmount')
      ..remove('photoListAmount')
      ..remove('manualListAmount')
      ..remove('listAmountsReviewed');

    final restored = OrderModel.fromMap(map, 'order-1');

    expect(restored.cartItemsAmount, 1150);
    expect(restored.photoListAmount, 0);
    expect(restored.manualListAmount, 0);
    expect(restored.subtotal, 1150);
  });

  test('typed manual list orders need manual sales review in accounts', () {
    final order = _order(manualListText: '1 packet sugar');

    final record = AccountSaleRecord.fromOrder(
      order,
      deliveredAt: DateTime(2026),
      now: DateTime(2026),
    );

    expect(record.hasShoppingList, isTrue);
    expect(record.needsManualSalesAmount, isTrue);
    expect(record.orderMethod, 'Typed Shopping List');
  });

  test('order subtotal is split into cart, photo, and manual list amounts', () {
    final order = _order(
      manualListText: '1 packet sugar',
      uploadedImageUrl: 'https://example.com/list.jpg',
      cartItemsAmount: 400,
      photoListAmount: 250,
      manualListAmount: 100,
      listAmountsReviewed: true,
      subtotal: 750,
      totalAmount: 1000,
    );

    final restored = OrderModel.fromMap(order.toMap(), order.orderId);
    final record = AccountSaleRecord.fromOrder(
      restored,
      deliveredAt: DateTime(2026),
      now: DateTime(2026),
    );

    expect(restored.cartItemsAmount, 400);
    expect(restored.photoListAmount, 250);
    expect(restored.manualListAmount, 100);
    expect(restored.subtotal, 750);
    expect(record.cartSalesAmount, 400);
    expect(record.photoListSalesAmount, 250);
    expect(record.manualListSalesAmount, 100);
    expect(record.needsManualSalesAmount, isFalse);
  });

  test('order stores assigned delivery contact details', () {
    final order = _order(
      orderStatus: 'Out for Delivery',
      assignedDeliveryPerson: 'Nimal',
      assignedDeliveryPhone: '+94712345678',
    );

    final restored = OrderModel.fromMap(order.toMap(), order.orderId);

    expect(restored.assignedDeliveryPerson, 'Nimal');
    expect(restored.assignedDeliveryPhone, '+94712345678');
    expect(restored.hasAssignedDeliveryContact, isTrue);
  });

  test('order stores and restores rejection reason', () {
    final order = _order(
      orderStatus: 'Rejected',
      rejectionReason: 'Outside delivery area today.',
    );

    final restored = OrderModel.fromMap(order.toMap(), order.orderId);
    final legacyRestored = OrderModel.fromMap(
      order.toMap()..remove('rejectionReason'),
      order.orderId,
    );

    expect(restored.rejectionReason, 'Outside delivery area today.');
    expect(legacyRestored.rejectionReason, '');
  });

  test('order stores and restores delivery rating and review', () {
    final reviewedAt = DateTime(2026, 6, 9, 12, 30);
    final order = _order(
      orderStatus: 'Delivered',
      assignedDeliveryBoyId: 'driver-1',
      deliveryRating: 5,
      deliveryReview: 'Friendly and careful delivery.',
      deliveryReviewedAt: reviewedAt,
    );

    final restored = OrderModel.fromMap(order.toMap(), order.orderId);

    expect(restored.hasDeliveryReview, isTrue);
    expect(restored.deliveryRating, 5);
    expect(restored.deliveryReview, 'Friendly and careful delivery.');
    expect(restored.deliveryReviewedAt, reviewedAt);
  });
}

OrderModel _order({
  String orderNotes = '',
  String manualListText = '',
  String uploadedImageUrl = '',
  String assignedDeliveryBoyId = '',
  String assignedDeliveryPerson = '',
  String assignedDeliveryPhone = '',
  int deliveryRating = 0,
  String deliveryReview = '',
  DateTime? deliveryReviewedAt,
  String orderStatus = 'Pending',
  String rejectionReason = '',
  double cartItemsAmount = 0,
  double photoListAmount = 0,
  double manualListAmount = 0,
  bool listAmountsReviewed = false,
  double subtotal = 0,
  double totalAmount = 250,
}) {
  final now = DateTime(2026);
  return OrderModel(
    orderId: 'order-1',
    userId: 'user-1',
    customerName: 'Customer',
    customerPhone: '+94712345678',
    customerAddress: 'Puttalam',
    items: const <OrderItem>[],
    uploadedImageUrl: uploadedImageUrl,
    uploadedImagePublicId: '',
    manualListText: manualListText,
    paymentReceiptImageUrl: '',
    paymentReceiptImagePublicId: '',
    orderNotes: orderNotes,
    cartItemsAmount: cartItemsAmount,
    photoListAmount: photoListAmount,
    manualListAmount: manualListAmount,
    listAmountsReviewed: listAmountsReviewed,
    subtotal: subtotal,
    deliveryCharge: 250,
    serviceCharge: 0,
    totalAmount: totalAmount,
    paymentMethod: 'COD',
    paymentStatus: 'pending',
    orderStatus: orderStatus,
    adminNotes: '',
    rejectionReason: rejectionReason,
    assignedDeliveryBoyId: assignedDeliveryBoyId,
    assignedDeliveryPerson: assignedDeliveryPerson,
    assignedDeliveryPhone: assignedDeliveryPhone,
    deliveryRating: deliveryRating,
    deliveryReview: deliveryReview,
    deliveryReviewedAt: deliveryReviewedAt,
    createdAt: now,
    updatedAt: now,
  );
}
