import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/shop_order_pdf_service.dart';

void main() {
  test('order item keeps product image for shop order sheets', () {
    const item = OrderItem(
      productId: 'product-1',
      name: 'Rice',
      nameTamil: '',
      shopId: 'shop-1',
      shopName: 'Main Shop',
      unit: 'kg',
      price: 450,
      quantity: 2,
      imageUrl: 'https://example.com/rice.jpg',
    );

    final restored = OrderItem.fromMap(item.toMap());

    expect(restored.imageUrl, item.imageUrl);
    expect(restored.lineTotal, 900);
  });

  test('builds a valid combined shop order PDF without remote images',
      () async {
    final bytes = await ShopOrderPdfService.buildFromImages(_order());

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(
      ShopOrderPdfService.fileName(_order()),
      'shop-order-order-123.pdf',
    );
  });
}

OrderModel _order() {
  final now = DateTime(2026, 6, 9, 14, 30);
  return OrderModel(
    orderId: 'order-123',
    userId: 'user-1',
    customerName: 'Customer',
    customerPhone: '+94712345678',
    customerAddress: 'Puttalam',
    items: const [
      OrderItem(
        productId: 'product-1',
        name: 'Rice',
        nameTamil: '',
        shopId: 'shop-1',
        shopName: 'Main Shop',
        unit: 'kg',
        price: 450,
        quantity: 2,
      ),
    ],
    uploadedImageUrl: '',
    uploadedImagePublicId: '',
    manualListText: '6 eggs\n1 packet sugar',
    paymentReceiptImageUrl: '',
    paymentReceiptImagePublicId: '',
    orderNotes: 'Call before buying.',
    cartItemsAmount: 900,
    photoListAmount: 0,
    manualListAmount: 0,
    listAmountsReviewed: false,
    subtotal: 900,
    deliveryCharge: 250,
    serviceCharge: 0,
    totalAmount: 1150,
    paymentMethod: 'COD',
    paymentStatus: 'pending',
    orderStatus: 'Pending',
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
