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
    expect(restored.hasManualList, isTrue);
    expect(restored.orderNotes, '');
  });

  test('manual list can be stored alongside normal order notes', () {
    final order = _order(
      orderNotes: 'Please call before delivery.',
      manualListText: '1 packet sugar',
    );

    final restored = OrderModel.fromMap(order.toMap(), order.orderId);

    expect(restored.orderNotes, 'Please call before delivery.');
    expect(restored.manualListText, '1 packet sugar');
  });

  test('old orders without manual list text remain readable', () {
    final map = _order().toMap();

    final restored = OrderModel.fromMap(map, 'order-1');

    expect(restored.manualListText, '');
    expect(restored.hasManualList, isFalse);
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
}

OrderModel _order({
  String orderNotes = '',
  String manualListText = '',
}) {
  final now = DateTime(2026);
  return OrderModel(
    orderId: 'order-1',
    userId: 'user-1',
    customerName: 'Customer',
    customerPhone: '+94712345678',
    customerAddress: 'Puttalam',
    items: const <OrderItem>[],
    uploadedImageUrl: '',
    manualListText: manualListText,
    paymentReceiptImageUrl: '',
    orderNotes: orderNotes,
    subtotal: 0,
    deliveryCharge: 250,
    serviceCharge: 0,
    totalAmount: 250,
    paymentMethod: 'COD',
    paymentStatus: 'pending',
    orderStatus: 'Pending',
    adminNotes: '',
    assignedDeliveryPerson: '',
    createdAt: now,
    updatedAt: now,
  );
}
