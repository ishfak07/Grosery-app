import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/order_receipt_pdf_service.dart';

void main() {
  test('builds a valid delivered-order receipt PDF without remote assets',
      () async {
    final bytes = await OrderReceiptPdfService.buildWithAssets(_order());

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(
      OrderReceiptPdfService.fileName(_order()),
      'puttalam-drop-receipt-order-123.pdf',
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
    manualListText: '',
    paymentReceiptImageUrl: '',
    paymentReceiptImagePublicId: '',
    orderNotes: '',
    cartItemsAmount: 900,
    photoListAmount: 0,
    manualListAmount: 0,
    listAmountsReviewed: true,
    subtotal: 900,
    deliveryCharge: 250,
    serviceCharge: 0,
    totalAmount: 1150,
    paymentMethod: 'COD',
    paymentStatus: 'paid',
    orderStatus: 'Delivered',
    adminNotes: '',
    rejectionReason: '',
    assignedDeliveryBoyId: 'delivery-1',
    assignedDeliveryPerson: 'Kumar',
    assignedDeliveryPhone: '+94770000000',
    deliveryRating: 0,
    deliveryReview: '',
    deliveryReviewedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}
