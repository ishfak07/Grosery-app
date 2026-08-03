import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/order_cancellation_service.dart';

void main() {
  group('customer cancellation policy', () {
    test('pending order inside the five-minute window is cancellable', () {
      final placedAt = DateTime(2026, 1, 1, 12);
      final order = _order(createdAt: placedAt);

      final snapshot = OrderCancellationPolicy.snapshotFor(
        order,
        now: placedAt.add(const Duration(seconds: 1)),
      );

      expect(snapshot.isActive, isTrue);
      expect(
        OrderCancellationPolicy.formatRemaining(snapshot.remaining),
        '04:59',
      );
    });

    test('pending order becomes unavailable when the deadline is reached', () {
      final placedAt = DateTime(2026, 1, 1, 12);
      final order = _order(createdAt: placedAt);

      final snapshot = OrderCancellationPolicy.snapshotFor(
        order,
        now: placedAt.add(OrderCancellationPolicy.window),
      );

      expect(snapshot.isActive, isFalse);
      expect(
        snapshot.status,
        OrderCancellationWindowStatus.expired,
      );
      expect(
        OrderCancellationPolicy.customerMessageFor(snapshot),
        OrderCancellationPolicy.expiredCustomerMessage,
      );
      expect(
        OrderCancellationPolicy.formatRemaining(snapshot.remaining),
        '00:00',
      );
    });

    test('pending order older than five minutes shows support guidance', () {
      final placedAt = DateTime(2026, 1, 1, 12);
      final order = _order(createdAt: placedAt);

      final snapshot = OrderCancellationPolicy.snapshotFor(
        order,
        now: placedAt.add(const Duration(minutes: 5, seconds: 1)),
      );

      expect(snapshot.status, OrderCancellationWindowStatus.expired);
      expect(
        OrderCancellationPolicy.customerMessageFor(snapshot),
        'The cancellation period has expired. Please contact support if you need help cancelling this order.',
      );
    });

    test('accepted order disables customer cancellation immediately', () {
      final placedAt = DateTime(2026, 1, 1, 12);
      final order = _order(orderStatus: 'Accepted', createdAt: placedAt);

      final snapshot = OrderCancellationPolicy.snapshotFor(
        order,
        now: placedAt.add(const Duration(minutes: 1)),
      );

      expect(snapshot.isActive, isFalse);
      expect(snapshot.status, OrderCancellationWindowStatus.accepted);
      expect(
        OrderCancellationPolicy.customerMessageFor(snapshot),
        OrderCancellationPolicy.acceptedCustomerMessage,
      );
    });

    test('cancelled order has no active timer or cancel action', () {
      final placedAt = DateTime(2026, 1, 1, 12);
      final order = _order(orderStatus: 'Cancelled', createdAt: placedAt);

      final snapshot = OrderCancellationPolicy.snapshotFor(
        order,
        now: placedAt.add(const Duration(minutes: 1)),
      );

      expect(snapshot.isActive, isFalse);
      expect(snapshot.status, OrderCancellationWindowStatus.cancelled);
      expect(OrderCancellationPolicy.customerMessageFor(snapshot), isNull);
    });

    test('missing createdAt makes online cancellation unavailable', () {
      final map = _order().toMap()..remove('createdAt');
      final order = OrderModel.fromMap(map, 'order-1');

      final snapshot = OrderCancellationPolicy.snapshotFor(
        order,
        now: DateTime(2026, 1, 1, 12),
      );

      expect(order.hasReliableCreatedAt, isFalse);
      expect(snapshot.status, OrderCancellationWindowStatus.unavailable);
      expect(
        OrderCancellationPolicy.customerMessageFor(snapshot),
        OrderCancellationPolicy.unavailableCustomerMessage,
      );
    });

    test('restart recalculates remaining time from stored createdAt', () {
      final placedAt = DateTime(2026, 1, 1, 12);
      final order = _order(createdAt: placedAt);

      final afterRestart = OrderCancellationPolicy.snapshotFor(
        order,
        now: placedAt.add(const Duration(minutes: 3)),
      );

      expect(afterRestart.isActive, isTrue);
      expect(
        OrderCancellationPolicy.formatRemaining(afterRestart.remaining),
        '02:00',
      );
    });

    test('cancelled metadata is readable after customer cancellation', () {
      final cancelledAt = DateTime(2026, 1, 1, 12, 2);
      final restored = OrderModel.fromMap(
        _order(
          orderStatus: 'Cancelled',
          cancelledAt: cancelledAt,
          cancelledBy: 'customer',
          cancellationReason: 'customer_cancelled_within_window',
        ).toMap(),
        'order-1',
      );

      expect(restored.orderStatus, 'Cancelled');
      expect(restored.cancelledAt, cancelledAt);
      expect(restored.cancelledBy, 'customer');
      expect(
        restored.cancellationReason,
        'customer_cancelled_within_window',
      );
    });
  });

  group('admin cancellation visibility policy', () {
    test('active, expired, accepted, and cancelled states are distinct', () {
      final placedAt = DateTime(2026, 1, 1, 12);

      final active = OrderCancellationPolicy.snapshotFor(
        _order(createdAt: placedAt),
        now: placedAt.add(const Duration(minutes: 1)),
      );
      final expired = OrderCancellationPolicy.snapshotFor(
        _order(createdAt: placedAt),
        now: placedAt.add(const Duration(minutes: 6)),
      );
      final accepted = OrderCancellationPolicy.snapshotFor(
        _order(orderStatus: 'Accepted', createdAt: placedAt),
        now: placedAt.add(const Duration(minutes: 1)),
      );
      final cancelled = OrderCancellationPolicy.snapshotFor(
        _order(orderStatus: 'Cancelled', createdAt: placedAt),
        now: placedAt.add(const Duration(minutes: 1)),
      );

      expect(active.status, OrderCancellationWindowStatus.active);
      expect(OrderCancellationPolicy.adminMessageFor(active), isNull);
      expect(
        OrderCancellationPolicy.adminMessageFor(expired),
        'Customer cancellation window expired',
      );
      expect(
        OrderCancellationPolicy.adminMessageFor(accepted),
        'Customer cancellation disabled because the order was accepted.',
      );
      expect(OrderCancellationPolicy.adminMessageFor(cancelled), isNull);
    });
  });

  group('server and rules guardrails', () {
    test('callable cancellation maps permission denial clearly', () {
      expect(
        OrderCancellationService.messageForFunctionError(
          'permission-denied',
          'You can only cancel your own orders.',
        ),
        'You can only cancel your own orders.',
      );
    });

    test('missing callable does not leak raw NOT_FOUND to customers', () {
      expect(
        OrderCancellationService.messageForFunctionError(
          'not-found',
          'NOT_FOUND',
        ),
        'Cancellation service is not available yet. Please contact support.',
      );
    });

    test('client fallback uses a Firestore transaction for missing callable',
        () {
      final source = File(
        'lib/src/services/order_cancellation_service.dart',
      ).readAsStringSync();

      expect(source, contains('_cancelOrderWithFirestoreTransaction'));
      expect(source, contains('runTransaction'));
      expect(source, contains("'orderStatus': 'Cancelled'"));
      expect(source, contains("'cancelledBy': 'customer'"));
      expect(source, contains('FieldValue.serverTimestamp()'));
    });

    test('callable cancellation uses a transaction and blocks repeats', () {
      final source = File('functions/index.js').readAsStringSync();

      expect(source, contains('exports.cancelOrderWithinWindow'));
      expect(source, contains('runTransaction'));
      expect(source, contains('order.orderStatus === "Accepted"'));
      expect(source, contains('order.orderStatus === "Cancelled"'));
      expect(source, contains('orderStatus: "Cancelled"'));
      expect(source, contains('cancelledBy: "customer"'));
      expect(
        source,
        contains('customer_cancelled_within_window'),
      );
    });

    test('firestore rules allow only narrow server-timed customer cancellation',
        () {
      final rules = File('firestore.rules').readAsStringSync();

      expect(
        rules,
        contains(
            'allow update: if isAdmin() || isValidCustomerCancellation();'),
      );
      expect(
          rules, contains("request.resource.data.orderStatus == 'Cancelled'"));
      expect(
          rules, contains('request.resource.data.cancelledAt == request.time'));
      expect(
          rules, contains('request.resource.data.updatedAt == request.time'));
      expect(
        rules,
        contains(
            "request.time < resource.data.createdAt + duration.value(5, 'm')"),
      );
      expect(
        rules,
        contains('.hasOnly(customerCancellationUpdateKeys())'),
      );
      expect(
        rules,
        contains('request.resource.data.createdAt == request.time'),
      );
      expect(
        rules,
        contains('request.resource.data.updatedAt == request.time'),
      );
    });
  });
}

OrderModel _order({
  DateTime? createdAt,
  String orderStatus = 'Pending',
  DateTime? cancelledAt,
  String cancelledBy = '',
  String cancellationReason = '',
}) {
  final now = createdAt ?? DateTime(2026, 1, 1, 12);
  return OrderModel(
    orderId: 'order-1',
    userId: 'user-1',
    customerName: 'Customer',
    customerPhone: '+94712345678',
    customerAddress: 'Puttalam',
    items: const <OrderItem>[],
    uploadedImageUrl: '',
    uploadedImagePublicId: '',
    manualListText: '',
    paymentReceiptImageUrl: '',
    paymentReceiptImagePublicId: '',
    orderNotes: '',
    cartItemsAmount: 0,
    photoListAmount: 0,
    manualListAmount: 0,
    listAmountsReviewed: false,
    subtotal: 0,
    deliveryCharge: 250,
    serviceCharge: 0,
    totalAmount: 250,
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
    cancelledAt: cancelledAt,
    cancelledBy: cancelledBy,
    cancellationReason: cancellationReason,
  );
}
