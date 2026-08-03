import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'service_exceptions.dart';

enum OrderCancellationWindowStatus {
  active,
  expired,
  accepted,
  unavailable,
  cancelled,
  inactive,
}

class OrderCancellationSnapshot {
  const OrderCancellationSnapshot({
    required this.status,
    required this.deadline,
    required this.remaining,
  });

  final OrderCancellationWindowStatus status;
  final DateTime? deadline;
  final Duration remaining;

  bool get isActive => status == OrderCancellationWindowStatus.active;

  @override
  bool operator ==(Object other) {
    return other is OrderCancellationSnapshot &&
        other.status == status &&
        other.deadline == deadline &&
        other.remaining.inSeconds == remaining.inSeconds;
  }

  @override
  int get hashCode => Object.hash(
        status,
        deadline,
        remaining.inSeconds,
      );
}

class OrderCancellationPolicy {
  const OrderCancellationPolicy._();

  static const window = Duration(minutes: 5);

  static DateTime? deadlineFor(OrderModel order) {
    if (!order.hasReliableCreatedAt) {
      return null;
    }
    return order.createdAt.add(window);
  }

  static OrderCancellationSnapshot snapshotFor(
    OrderModel order, {
    required DateTime now,
  }) {
    if (order.orderStatus == 'Cancelled') {
      return const OrderCancellationSnapshot(
        status: OrderCancellationWindowStatus.cancelled,
        deadline: null,
        remaining: Duration.zero,
      );
    }

    if (!order.hasReliableCreatedAt) {
      return const OrderCancellationSnapshot(
        status: OrderCancellationWindowStatus.unavailable,
        deadline: null,
        remaining: Duration.zero,
      );
    }

    final deadline = deadlineFor(order)!;
    final remaining = _positiveRemaining(deadline.difference(now));

    if (order.orderStatus == 'Pending') {
      return OrderCancellationSnapshot(
        status: remaining > Duration.zero
            ? OrderCancellationWindowStatus.active
            : OrderCancellationWindowStatus.expired,
        deadline: deadline,
        remaining: remaining,
      );
    }

    if (order.orderStatus == 'Accepted') {
      return OrderCancellationSnapshot(
        status: OrderCancellationWindowStatus.accepted,
        deadline: deadline,
        remaining: Duration.zero,
      );
    }

    return OrderCancellationSnapshot(
      status: OrderCancellationWindowStatus.inactive,
      deadline: deadline,
      remaining: Duration.zero,
    );
  }

  static String? customerMessageFor(OrderCancellationSnapshot snapshot) {
    switch (snapshot.status) {
      case OrderCancellationWindowStatus.expired:
        return expiredCustomerMessage;
      case OrderCancellationWindowStatus.accepted:
        return acceptedCustomerMessage;
      case OrderCancellationWindowStatus.unavailable:
        return unavailableCustomerMessage;
      case OrderCancellationWindowStatus.active:
      case OrderCancellationWindowStatus.cancelled:
      case OrderCancellationWindowStatus.inactive:
        return null;
    }
  }

  static String? adminMessageFor(OrderCancellationSnapshot snapshot) {
    switch (snapshot.status) {
      case OrderCancellationWindowStatus.expired:
        return adminExpiredMessage;
      case OrderCancellationWindowStatus.accepted:
        return adminAcceptedMessage;
      case OrderCancellationWindowStatus.active:
      case OrderCancellationWindowStatus.unavailable:
      case OrderCancellationWindowStatus.cancelled:
      case OrderCancellationWindowStatus.inactive:
        return null;
    }
  }

  static String formatRemaining(Duration remaining) {
    final totalSeconds = remaining.isNegative ? 0 : remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static Duration _positiveRemaining(Duration value) {
    return value.isNegative ? Duration.zero : value;
  }

  static const expiredCustomerMessage =
      'The cancellation period has expired. Please contact support if you need help cancelling this order.';
  static const acceptedCustomerMessage =
      'This order has already been accepted and can no longer be cancelled through the app. Please contact support if you need assistance.';
  static const unavailableCustomerMessage =
      'Online cancellation is unavailable for this order. Please contact support.';
  static const adminExpiredMessage = 'Customer cancellation window expired';
  static const adminAcceptedMessage =
      'Customer cancellation disabled because the order was accepted.';
}

class OrderCancellationException implements Exception {
  const OrderCancellationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderCancellationService {
  const OrderCancellationService({required bool firebaseAvailable})
      : _firebaseAvailable = firebaseAvailable;

  final bool _firebaseAvailable;

  FirebaseFunctions get _functions {
    if (!_firebaseAvailable) {
      throw const FirebaseUnavailableException();
    }
    return FirebaseFunctions.instance;
  }

  FirebaseFirestore get _db {
    if (!_firebaseAvailable) {
      throw const FirebaseUnavailableException();
    }
    return FirebaseFirestore.instance;
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _functions.httpsCallable('cancelOrderWithinWindow').call({
        'orderId': orderId,
      });
    } on FirebaseFunctionsException catch (error) {
      if (_isCallableFunctionNotDeployed(error)) {
        await _cancelOrderWithFirestoreTransaction(orderId);
        return;
      }
      throw OrderCancellationException(
        messageForFunctionError(error.code, error.message),
      );
    }
  }

  Future<void> _cancelOrderWithFirestoreTransaction(String orderId) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final notificationRef = _db.collection('notifications').doc();

    try {
      await _db.runTransaction((transaction) async {
        final orderDoc = await transaction.get(orderRef);
        final orderData = orderDoc.data();
        if (!orderDoc.exists || orderData == null) {
          throw const OrderCancellationException('Order not found');
        }

        final order = OrderModel.fromMap(orderData, orderDoc.id);
        final snapshot = OrderCancellationPolicy.snapshotFor(
          order,
          now: DateTime.now(),
        );
        switch (snapshot.status) {
          case OrderCancellationWindowStatus.active:
            break;
          case OrderCancellationWindowStatus.cancelled:
            throw const OrderCancellationException(
              'This order has already been cancelled.',
            );
          case OrderCancellationWindowStatus.accepted:
            throw const OrderCancellationException(
              OrderCancellationPolicy.acceptedCustomerMessage,
            );
          case OrderCancellationWindowStatus.expired:
            throw const OrderCancellationException(
              OrderCancellationPolicy.expiredCustomerMessage,
            );
          case OrderCancellationWindowStatus.unavailable:
            throw const OrderCancellationException(
              OrderCancellationPolicy.unavailableCustomerMessage,
            );
          case OrderCancellationWindowStatus.inactive:
            throw const OrderCancellationException(
              'Only pending orders can be cancelled through the app.',
            );
        }

        transaction.update(orderRef, {
          'orderStatus': 'Cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': 'customer',
          'cancellationReason': 'customer_cancelled_within_window',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(notificationRef, {
          'notificationId': notificationRef.id,
          'userId': '',
          'recipientRole': 'admin',
          'title': 'Order cancelled by customer',
          'body':
              '${order.customerName.isEmpty ? 'Customer' : order.customerName} cancelled order $orderId',
          'type': 'order',
          'relatedId': orderId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on OrderCancellationException {
      rethrow;
    } on FirebaseException catch (error) {
      throw OrderCancellationException(
        messageForFirestoreError(error.code, error.message),
      );
    }
  }

  static String messageForFunctionError(String code, String? message) {
    if (_isCallableFunctionNotDeployedValues(code, message)) {
      return 'Cancellation service is not available yet. Please contact support.';
    }
    final cleanedMessage = message?.trim();
    if (cleanedMessage != null && cleanedMessage.isNotEmpty) {
      return cleanedMessage;
    }

    switch (code) {
      case 'failed-precondition':
        return OrderCancellationPolicy.expiredCustomerMessage;
      case 'permission-denied':
      case 'unauthenticated':
        return 'You are not allowed to perform this action.';
      case 'not-found':
        return 'Order not found';
      case 'unavailable':
        return 'Service is unavailable. Try again shortly.';
      default:
        return 'Unable to cancel this order. Please try again.';
    }
  }

  static String messageForFirestoreError(String code, String? message) {
    final cleanedMessage = message?.trim();
    switch (code) {
      case 'permission-denied':
        return 'Cancellation is not available yet. Please update the app backend or contact support.';
      case 'not-found':
        return 'Order not found';
      case 'unavailable':
        return 'Service is unavailable. Try again shortly.';
      default:
        return cleanedMessage != null && cleanedMessage.isNotEmpty
            ? cleanedMessage
            : 'Unable to cancel this order. Please try again.';
    }
  }

  static bool _isCallableFunctionNotDeployed(
    FirebaseFunctionsException error,
  ) {
    return _isCallableFunctionNotDeployedValues(error.code, error.message);
  }

  static bool _isCallableFunctionNotDeployedValues(
    String code,
    String? message,
  ) {
    final cleanedMessage = message?.trim();
    return code == 'not-found' &&
        (cleanedMessage == null ||
            cleanedMessage.isEmpty ||
            cleanedMessage.toUpperCase() == 'NOT_FOUND');
  }
}
