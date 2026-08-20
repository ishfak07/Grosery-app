import 'dart:convert';
import 'dart:typed_data';

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

  testWidgets(
      'builds the receipt with the real bundled logo without excessive '
      'memory use', (tester) async {
    // Exercises the actual asset-loading path (`build`, not
    // `buildWithAssets`), which decodes assets/images/puttalam_drop_logo.png
    // — a large (2500x2500px) source PNG. Regression guard for a real
    // production bug where embedding that file at full resolution caused
    // the receipt PDF to fail/hang on lower-end phones; `_loadLogo` must
    // downsample it before handing it to the pdf package.
    //
    // `runAsync` is required here: image decoding goes through the engine
    // on real timers, which never fire on `testWidgets`' fake clock unless
    // the work is escaped into it — without this the test hangs until the
    // suite timeout instead of failing fast.
    late Uint8List bytes;
    await tester.runAsync(() async {
      bytes = await OrderReceiptPdfService.build(_order());
    });

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
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
