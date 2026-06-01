import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'service_exceptions.dart';

class FirestoreService {
  FirestoreService({required bool firebaseAvailable})
      : _firebaseAvailable = firebaseAvailable;

  final bool _firebaseAvailable;
  final _uuid = const Uuid();

  FirebaseFirestore get _db {
    if (!_firebaseAvailable) {
      throw const FirebaseUnavailableException();
    }
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _accountSales =>
      _db.collection('account_sales');
  CollectionReference<Map<String, dynamic>> get _tickets =>
      _db.collection('support_tickets');
  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('support_messages');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _passwordResetRequests =>
      _db.collection('password_reset_requests');

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserProfile.fromMap(doc.data()!, doc.id);
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    if (!_firebaseAvailable) {
      return Stream<UserProfile?>.value(null);
    }
    return _users.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }
      return UserProfile.fromMap(data, doc.id);
    });
  }

  Future<void> saveUserProfile(UserProfile profile) {
    return _users
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String address,
  }) {
    return _users.doc(uid).update({
      'fullName': fullName.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser(String uid, bool isBlocked) {
    return _users.doc(uid).update({
      'isBlocked': isBlocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<UserProfile>> watchUsers() {
    if (!_firebaseAvailable) {
      return Stream<List<UserProfile>>.value(const <UserProfile>[]);
    }
    return _users.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      return users;
    });
  }

  Stream<List<Shop>> watchShops({bool activeOnly = true}) {
    if (!_firebaseAvailable) {
      return Stream<List<Shop>>.value(const <Shop>[]);
    }
    Query<Map<String, dynamic>> query = _shops;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final shops = snapshot.docs
          .map((doc) => Shop.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.shopName.compareTo(b.shopName));
      return shops;
    });
  }

  Future<void> refreshForProfile(UserProfile profile) async {
    if (!_firebaseAvailable) {
      return;
    }
    if (profile.isAdmin) {
      await _refreshAdminData();
      return;
    }
    await _refreshCustomerData(profile.uid);
  }

  Future<void> refreshSupportMessages(String ticketId) async {
    if (!_firebaseAvailable) {
      return;
    }
    await _fromServer(
      _messages.where('ticketId', isEqualTo: ticketId).get(
            const GetOptions(source: Source.server),
          ),
    );
  }

  Future<void> _refreshAdminData() async {
    await Future.wait([
      _fromServer(_users.get(const GetOptions(source: Source.server))),
      _fromServer(_shops.get(const GetOptions(source: Source.server))),
      _fromServer(_products.get(const GetOptions(source: Source.server))),
      _fromServer(_orders.get(const GetOptions(source: Source.server))),
      _fromServer(_accountSales.get(const GetOptions(source: Source.server))),
      _fromServer(_tickets.get(const GetOptions(source: Source.server))),
      _fromServer(_passwordResetRequests.get(
        const GetOptions(source: Source.server),
      )),
      _fromServer(
        _notifications
            .where('recipientRole', isEqualTo: 'admin')
            .get(const GetOptions(source: Source.server)),
      ),
    ]);
  }

  Future<void> _refreshCustomerData(String userId) async {
    await Future.wait([
      _fromServer(_users.doc(userId).get(
            const GetOptions(source: Source.server),
          )),
      _fromServer(
        _shops
            .where('isActive', isEqualTo: true)
            .get(const GetOptions(source: Source.server)),
      ),
      _fromServer(_products.get(const GetOptions(source: Source.server))),
      _fromServer(
        _orders
            .where('userId', isEqualTo: userId)
            .get(const GetOptions(source: Source.server)),
      ),
      _fromServer(
        _tickets
            .where('userId', isEqualTo: userId)
            .get(const GetOptions(source: Source.server)),
      ),
      _fromServer(
        _notifications
            .where('recipientRole', isEqualTo: 'user')
            .where('userId', isEqualTo: userId)
            .get(const GetOptions(source: Source.server)),
      ),
    ]);
  }

  Future<void> _fromServer(Future<Object?> request) async {
    await request;
  }

  Future<void> saveShop(Shop shop) {
    return _shops.doc(shop.shopId).set(shop.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleShop(String shopId, bool isActive) {
    return _shops.doc(shopId).update({'isActive': isActive});
  }

  Stream<List<Product>> watchProducts({
    String? shopId,
    String? category,
    bool activeOnly = true,
  }) {
    if (!_firebaseAvailable) {
      return Stream<List<Product>>.value(const <Product>[]);
    }
    return _products.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .where(
            (product) =>
                (!activeOnly || product.isActive) &&
                (shopId == null ||
                    shopId.isEmpty ||
                    product.shopId == shopId) &&
                (category == null ||
                    category.isEmpty ||
                    product.category == category),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return products;
    });
  }

  Future<void> saveProduct(Product product) {
    return _products
        .doc(product.productId)
        .set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> disableProduct(String productId, bool isActive) {
    return _products.doc(productId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createOrder(OrderModel order) async {
    final batch = _db.batch();
    batch.set(_orders.doc(order.orderId), order.toMap());
    final notificationId = _uuid.v4();
    batch.set(
      _notifications.doc(notificationId),
      AppNotification(
        notificationId: notificationId,
        userId: '',
        recipientRole: 'admin',
        title: 'New order received',
        body: '${order.customerName} placed order ${order.orderId}',
        type: 'order',
        relatedId: order.orderId,
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    await batch.commit();
  }

  Stream<List<OrderModel>> watchOrdersForUser(String userId) {
    if (!_firebaseAvailable) {
      return Stream<List<OrderModel>>.value(const <OrderModel>[]);
    }
    return _orders.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      },
    );
  }

  Stream<List<OrderModel>> watchAllOrders() {
    if (!_firebaseAvailable) {
      return Stream<List<OrderModel>>.value(const <OrderModel>[]);
    }
    return _orders.snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<AccountSaleRecord>> watchAccountSales() {
    if (!_firebaseAvailable) {
      return Stream<List<AccountSaleRecord>>.value(
        const <AccountSaleRecord>[],
      );
    }
    return _accountSales.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => AccountSaleRecord.fromMap(doc.data(), doc.id))
          .where((record) => record.orderStatus == 'Delivered')
          .toList()
        ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
      return records;
    });
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    if (!_firebaseAvailable) {
      return Stream<OrderModel?>.value(null);
    }
    return _orders.doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return OrderModel.fromMap(data, doc.id);
    });
  }

  Future<void> updateOrderStatus({
    required OrderModel order,
    required String status,
    String? adminNotes,
    String? assignedDeliveryPerson,
  }) async {
    if (status == 'Delivered' &&
        order.orderStatus != 'Out for Delivery' &&
        order.orderStatus != 'Delivered') {
      throw StateError('Order must be out for delivery before delivered.');
    }

    final now = DateTime.now();
    final updatedOrder = order.copyWith(
      orderStatus: status,
      adminNotes: adminNotes,
      assignedDeliveryPerson: assignedDeliveryPerson,
    );
    final accountRecord = status == 'Delivered'
        ? await _accountSaleRecordForOrder(
            updatedOrder,
            now: now,
            preserveManualSalesAmount: true,
          )
        : null;

    final batch = _db.batch();
    batch.update(_orders.doc(order.orderId), {
      'orderStatus': status,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (assignedDeliveryPerson != null)
        'assignedDeliveryPerson': assignedDeliveryPerson,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (accountRecord != null) {
      batch.set(
        _accountSales.doc(order.orderId),
        accountRecord.toMap(),
        SetOptions(merge: true),
      );
    } else if (order.orderStatus == 'Delivered' && status != 'Delivered') {
      batch.delete(_accountSales.doc(order.orderId));
    }

    final notificationId = _uuid.v4();
    batch.set(
      _notifications.doc(notificationId),
      AppNotification(
        notificationId: notificationId,
        userId: order.userId,
        recipientRole: 'user',
        title: 'Order ${order.orderId} updated',
        body: 'Status changed to $status',
        type: 'order',
        relatedId: order.orderId,
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    await batch.commit();
  }

  Future<void> updateOrderFinancials({
    required OrderModel order,
    required double subtotal,
    required double deliveryCharge,
    required double serviceCharge,
    required String paymentStatus,
  }) async {
    final total = subtotal + deliveryCharge + serviceCharge;
    final updatedOrder = order.copyWith(
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      serviceCharge: serviceCharge,
      totalAmount: total,
      paymentStatus: paymentStatus,
    );
    final accountRecord = order.orderStatus == 'Delivered'
        ? await _accountSaleRecordForOrder(
            updatedOrder,
            now: DateTime.now(),
          )
        : null;

    final batch = _db.batch();
    batch.update(_orders.doc(order.orderId), {
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'serviceCharge': serviceCharge,
      'totalAmount': total,
      'paymentStatus': paymentStatus,
      'orderStatus':
          order.orderStatus == 'Pending' ? 'Bill Updated' : order.orderStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (accountRecord != null) {
      batch.set(
        _accountSales.doc(order.orderId),
        accountRecord.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    await notifyUser(
      userId: order.userId,
      title: 'Final bill updated',
      body: 'Your order total is ${total.toStringAsFixed(2)}.',
      relatedId: order.orderId,
      type: 'order',
    );
  }

  Future<void> updateAccountSaleManuals({
    required AccountSaleRecord record,
    required double manualSalesAmount,
    required double costAmount,
    required double expenseAmount,
    required String accountNotes,
  }) async {
    final normalizedManual = _nonNegative(manualSalesAmount);
    final normalizedCost = _nonNegative(costAmount);
    final normalizedExpense = _nonNegative(expenseAmount);
    final updatedRecord = record.copyWith(
      manualSalesAmount: normalizedManual,
      manualSalesReviewed: true,
      costAmount: normalizedCost,
      expenseAmount: normalizedExpense,
      accountNotes: accountNotes.trim(),
      updatedAt: DateTime.now(),
    );
    final orderSubtotal = record.cartSalesAmount + normalizedManual;
    final orderTotal =
        orderSubtotal + record.deliveryCharge + record.serviceCharge;

    final batch = _db.batch();
    batch.set(
      _accountSales.doc(record.recordId),
      updatedRecord.toMap(),
      SetOptions(merge: true),
    );
    if (record.orderId.isNotEmpty) {
      batch.update(_orders.doc(record.orderId), {
        'subtotal': orderSubtotal,
        'totalAmount': orderTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<AccountSaleRecord?> _existingAccountSaleRecord(String orderId) async {
    final doc = await _accountSales.doc(orderId).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }
    return AccountSaleRecord.fromMap(data, doc.id);
  }

  Future<AccountSaleRecord> _accountSaleRecordForOrder(
    OrderModel order, {
    required DateTime now,
    bool preserveManualSalesAmount = false,
  }) async {
    final existing = await _existingAccountSaleRecord(order.orderId);
    return AccountSaleRecord.fromOrder(
      order,
      existing: existing,
      deliveredAt: now,
      now: now,
      preserveManualSalesAmount: preserveManualSalesAmount,
    );
  }

  double _nonNegative(double value) {
    if (value.isNaN || value.isNegative) {
      return 0;
    }
    return value;
  }

  Future<SupportTicket> createSupportTicket({
    required UserProfile user,
    required String subject,
    required String message,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final ticket = SupportTicket(
      ticketId: id,
      userId: user.uid,
      customerName: user.fullName,
      phone: user.phone,
      subject: subject.trim(),
      message: message.trim(),
      status: 'open',
      createdAt: now,
      updatedAt: now,
    );

    final firstMessage = SupportMessage(
      messageId: _uuid.v4(),
      ticketId: id,
      senderId: user.uid,
      senderRole: user.role,
      message: message.trim(),
      imageUrl: '',
      createdAt: now,
    );

    final batch = _db.batch();
    batch.set(_tickets.doc(id), ticket.toMap());
    batch.set(_messages.doc(firstMessage.messageId), firstMessage.toMap());
    final notificationId = _uuid.v4();
    batch.set(
      _notifications.doc(notificationId),
      AppNotification(
        notificationId: notificationId,
        userId: '',
        recipientRole: 'admin',
        title: 'New support message',
        body: '${user.fullName}: $subject',
        type: 'support',
        relatedId: id,
        isRead: false,
        createdAt: now,
      ).toMap(),
    );
    await batch.commit();
    return ticket;
  }

  Stream<List<SupportTicket>> watchTickets({
    String? userId,
    bool allTickets = false,
  }) {
    if (!_firebaseAvailable) {
      return Stream<List<SupportTicket>>.value(const <SupportTicket>[]);
    }
    Query<Map<String, dynamic>> query = _tickets;
    if (!allTickets && userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots().map((snapshot) {
      final tickets = snapshot.docs
          .map((doc) => SupportTicket.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tickets;
    });
  }

  Stream<List<SupportMessage>> watchSupportMessages(String ticketId) {
    if (!_firebaseAvailable) {
      return Stream<List<SupportMessage>>.value(const <SupportMessage>[]);
    }
    return _messages.where('ticketId', isEqualTo: ticketId).snapshots().map(
      (snapshot) {
        final messages = snapshot.docs
            .map((doc) => SupportMessage.fromMap(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      },
    );
  }

  Future<void> sendSupportMessage({
    required SupportTicket ticket,
    required UserProfile sender,
    required String message,
    String imageUrl = '',
  }) async {
    final supportMessage = SupportMessage(
      messageId: _uuid.v4(),
      ticketId: ticket.ticketId,
      senderId: sender.uid,
      senderRole: sender.role,
      message: message.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    final recipientRole = sender.isAdmin ? 'user' : 'admin';
    final recipientId = sender.isAdmin ? ticket.userId : '';
    final batch = _db.batch();
    batch.set(_messages.doc(supportMessage.messageId), supportMessage.toMap());
    batch.update(_tickets.doc(ticket.ticketId), {
      'status': sender.isAdmin ? 'replied' : 'open',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final notificationId = _uuid.v4();
    batch.set(
      _notifications.doc(notificationId),
      AppNotification(
        notificationId: notificationId,
        userId: recipientId,
        recipientRole: recipientRole,
        title: sender.isAdmin ? 'Admin replied' : 'New support message',
        body: message.trim(),
        type: 'support',
        relatedId: ticket.ticketId,
        isRead: false,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    await batch.commit();
  }

  Future<void> closeTicket(String ticketId) {
    return _tickets.doc(ticketId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PasswordResetRequest>> watchPasswordResetRequests() {
    if (!_firebaseAvailable) {
      return Stream<List<PasswordResetRequest>>.value(
        const <PasswordResetRequest>[],
      );
    }
    return _passwordResetRequests.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => PasswordResetRequest.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    required String role,
  }) {
    if (!_firebaseAvailable) {
      return Stream<List<AppNotification>>.value(const <AppNotification>[]);
    }
    final query = role == 'admin'
        ? _notifications.where('recipientRole', isEqualTo: 'admin')
        : _notifications
            .where('recipientRole', isEqualTo: 'user')
            .where('userId', isEqualTo: userId);
    return query.snapshots().map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  Future<void> notifyUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String relatedId,
  }) {
    final id = _uuid.v4();
    return _notifications.doc(id).set(
          AppNotification(
            notificationId: id,
            userId: userId,
            recipientRole: 'user',
            title: title,
            body: body,
            type: type,
            relatedId: relatedId,
            isRead: false,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }
}
