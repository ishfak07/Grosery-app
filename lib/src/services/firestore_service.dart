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
  CollectionReference<Map<String, dynamic>> get _offers =>
      _db.collection('offers');
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
  CollectionReference<Map<String, dynamic>> get _appSettings =>
      _db.collection('app_settings');

  DocumentReference<Map<String, dynamic>> get _checkoutChargesDoc =>
      _appSettings.doc('checkout_charges');
  DocumentReference<Map<String, dynamic>> get _paymentSettingsDoc =>
      _appSettings.doc('payment_methods');

  Stream<CheckoutChargeSettings> watchCheckoutChargeSettings() {
    if (!_firebaseAvailable) {
      return Stream<CheckoutChargeSettings>.value(
        CheckoutChargeSettings.defaults,
      );
    }
    return _checkoutChargesDoc.snapshots().map(
          (doc) => CheckoutChargeSettings.fromMap(doc.data()),
        );
  }

  Future<void> saveCheckoutChargeSettings(
    CheckoutChargeSettings settings,
  ) {
    return _checkoutChargesDoc.set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<PaymentSettings> watchPaymentSettings() {
    if (!_firebaseAvailable) {
      return Stream<PaymentSettings>.value(PaymentSettings.defaults);
    }
    return _paymentSettingsDoc.snapshots().map(
          (doc) => PaymentSettings.fromMap(doc.data()),
        );
  }

  Future<void> savePaymentSettings(PaymentSettings settings) {
    return _paymentSettingsDoc.set(settings.toMap(), SetOptions(merge: true));
  }

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

  Future<void> updatePreferredLanguage({
    required String uid,
    required String preferredLanguageCode,
  }) {
    return _users.doc(uid).update({
      'preferredLanguageCode': preferredLanguageCode,
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

  Stream<List<UserProfile>> watchDeliveryBoys({bool activeOnly = false}) {
    if (!_firebaseAvailable) {
      return Stream<List<UserProfile>>.value(const <UserProfile>[]);
    }
    return _users.snapshots().map(
      (snapshot) {
        final users = snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
            .where((user) => _isDeliveryBoyRole(user.role))
            .where((user) => !activeOnly || !user.isBlocked)
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
        return users;
      },
    );
  }

  bool _isDeliveryBoyRole(String role) {
    return role == 'delivery_boy' || role == 'deliveryBoy' || role == 'delivery';
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
    if (profile.isDeliveryBoy) {
      await _refreshDeliveryBoyData(profile.uid);
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
      _fromServer(_offers.get(const GetOptions(source: Source.server))),
      _fromServer(_products.get(const GetOptions(source: Source.server))),
      _fromServer(_orders.get(const GetOptions(source: Source.server))),
      _fromServer(_accountSales.get(const GetOptions(source: Source.server))),
      _fromServer(_appSettings.get(const GetOptions(source: Source.server))),
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
      _fromServer(
        _offers
            .where('isActive', isEqualTo: true)
            .get(const GetOptions(source: Source.server)),
      ),
      _fromServer(_products.get(const GetOptions(source: Source.server))),
      _fromServer(_appSettings.get(const GetOptions(source: Source.server))),
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
            .where('userId', isEqualTo: userId)
            .get(const GetOptions(source: Source.server)),
      ),
      _fromServer(
        _notifications
            .where('recipientRole', isEqualTo: 'broadcast')
            .get(const GetOptions(source: Source.server)),
      ),
    ]);
  }

  Future<void> _refreshDeliveryBoyData(String userId) async {
    await Future.wait([
      _fromServer(_users.doc(userId).get(
            const GetOptions(source: Source.server),
          )),
      _fromServer(
        _orders
            .where('assignedDeliveryBoyId', isEqualTo: userId)
            .get(const GetOptions(source: Source.server)),
      ),
      _fromServer(
        _notifications
            .where('userId', isEqualTo: userId)
            .get(const GetOptions(source: Source.server)),
      ),
    ]);
  }

  Future<void> _fromServer(Future<Object?> request) async {
    try {
      await request.timeout(const Duration(seconds: 8));
    } catch (_) {
      // Pull-to-refresh warms the local cache only. Live streams keep rendering
      // current data, so transient refresh failures should not interrupt users.
    }
  }

  Future<void> saveShop(Shop shop) {
    return _shops.doc(shop.shopId).set(shop.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleShop(String shopId, bool isActive) {
    return _shops.doc(shopId).update({'isActive': isActive});
  }

  Stream<List<Offer>> watchOffers({bool activeOnly = true}) {
    if (!_firebaseAvailable) {
      return Stream<List<Offer>>.value(const <Offer>[]);
    }
    Query<Map<String, dynamic>> query = _offers;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final now = DateTime.now();
      final offers = snapshot.docs
          .map((doc) => Offer.fromMap(doc.data(), doc.id))
          .where((offer) => !activeOnly || offer.isCurrentlyActive(now))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return offers;
    });
  }

  Future<void> saveOffer(Offer offer) {
    return _offers
        .doc(offer.offerId)
        .set(offer.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleOffer(String offerId, bool isActive) {
    return _offers.doc(offerId).update({'isActive': isActive});
  }

  Future<void> deleteOffer(String offerId) {
    return _offers.doc(offerId).delete();
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

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }

  Future<void> createOrder(OrderModel order) async {
    final orderMap = order.toMap();
    try {
      await _commitOrderCreate(order, orderMap);
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
      // Allows the updated app to keep creating orders until deployed
      // Firestore rules include the split bill amount keys.
      await _commitOrderCreate(order, _legacyOrderCreateMap(orderMap));
    }
  }

  Future<void> _commitOrderCreate(
    OrderModel order,
    Map<String, dynamic> orderMap,
  ) async {
    final batch = _db.batch();
    batch.set(_orders.doc(order.orderId), orderMap);
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

  Map<String, dynamic> _legacyOrderCreateMap(Map<String, dynamic> orderMap) {
    return Map<String, dynamic>.from(orderMap)
      ..remove('cartItemsAmount')
      ..remove('photoListAmount')
      ..remove('manualListAmount')
      ..remove('listAmountsReviewed')
      ..remove('rejectionReason')
      ..remove('assignedDeliveryBoyId')
      ..remove('assignedDeliveryPhone');
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

  Stream<List<OrderModel>> watchOrdersForDeliveryBoy(String deliveryBoyId) {
    if (!_firebaseAvailable) {
      return Stream<List<OrderModel>>.value(const <OrderModel>[]);
    }
    return _orders
        .where('assignedDeliveryBoyId', isEqualTo: deliveryBoyId)
        .snapshots()
        .map(
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
    String? rejectionReason,
    String? assignedDeliveryBoyId,
    String? assignedDeliveryPerson,
    String? assignedDeliveryPhone,
  }) async {
    if (status == 'Delivered' &&
        order.orderStatus != 'Out for Delivery' &&
        order.orderStatus != 'Delivered') {
      throw StateError('Order must be out for delivery before delivered.');
    }
    final normalizedRejectionReason =
        status == 'Rejected' ? (rejectionReason ?? '').trim() : '';
    if (status == 'Rejected' && normalizedRejectionReason.isEmpty) {
      throw StateError('Enter the rejection reason before rejecting.');
    }
    if (status == 'Out for Delivery') {
      if ((assignedDeliveryBoyId ?? order.assignedDeliveryBoyId).isEmpty ||
          (assignedDeliveryPerson ?? order.assignedDeliveryPerson)
              .trim()
              .isEmpty ||
          (assignedDeliveryPhone ?? order.assignedDeliveryPhone)
              .trim()
              .isEmpty) {
        throw StateError('Select a delivery boy before sending delivery.');
      }
    }

    final now = DateTime.now();
    final updatedOrder = order.copyWith(
      orderStatus: status,
      adminNotes: adminNotes,
      rejectionReason: normalizedRejectionReason,
      assignedDeliveryBoyId: assignedDeliveryBoyId,
      assignedDeliveryPerson: assignedDeliveryPerson,
      assignedDeliveryPhone: assignedDeliveryPhone,
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
      'rejectionReason': normalizedRejectionReason,
      if (assignedDeliveryPerson != null)
        'assignedDeliveryPerson': assignedDeliveryPerson,
      if (assignedDeliveryPhone != null)
        'assignedDeliveryPhone': assignedDeliveryPhone,
      if (assignedDeliveryBoyId != null)
        'assignedDeliveryBoyId': assignedDeliveryBoyId,
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
    final deliveryBoyId = assignedDeliveryBoyId ?? order.assignedDeliveryBoyId;
    if (status == 'Out for Delivery' && deliveryBoyId.isNotEmpty) {
      final deliveryNotificationId = _uuid.v4();
      batch.set(
        _notifications.doc(deliveryNotificationId),
        AppNotification(
          notificationId: deliveryNotificationId,
          userId: deliveryBoyId,
          recipientRole: 'delivery_boy',
          title: 'Order assigned',
          body: '${order.customerName} - ${order.totalAmount.toStringAsFixed(2)}',
          type: 'order',
          relatedId: order.orderId,
          isRead: false,
          createdAt: DateTime.now(),
        ).toMap(),
      );
    }
    await batch.commit();
  }

  Future<void> updateOrderFinancials({
    required OrderModel order,
    required double cartItemsAmount,
    required double photoListAmount,
    required double manualListAmount,
    required double deliveryCharge,
    required double serviceCharge,
    required String paymentStatus,
  }) async {
    final normalizedCartItemsAmount = _nonNegative(cartItemsAmount);
    final normalizedPhotoListAmount = _nonNegative(photoListAmount);
    final normalizedManualListAmount = _nonNegative(manualListAmount);
    final normalizedSubtotal = normalizedCartItemsAmount +
        normalizedPhotoListAmount +
        normalizedManualListAmount;
    final normalizedDeliveryCharge = _nonNegative(deliveryCharge);
    final normalizedServiceCharge = _nonNegative(serviceCharge);
    final total =
        normalizedSubtotal + normalizedDeliveryCharge + normalizedServiceCharge;
    final updatedOrder = order.copyWith(
      cartItemsAmount: normalizedCartItemsAmount,
      photoListAmount: normalizedPhotoListAmount,
      manualListAmount: normalizedManualListAmount,
      listAmountsReviewed: true,
      subtotal: normalizedSubtotal,
      deliveryCharge: normalizedDeliveryCharge,
      serviceCharge: normalizedServiceCharge,
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
      'cartItemsAmount': normalizedCartItemsAmount,
      'photoListAmount': normalizedPhotoListAmount,
      'manualListAmount': normalizedManualListAmount,
      'listAmountsReviewed': true,
      'subtotal': normalizedSubtotal,
      'deliveryCharge': normalizedDeliveryCharge,
      'serviceCharge': normalizedServiceCharge,
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
    required double photoListSalesAmount,
    required double manualListSalesAmount,
    required double costAmount,
    required double expenseAmount,
    required String accountNotes,
  }) async {
    final normalizedPhotoList = _nonNegative(photoListSalesAmount);
    final normalizedManualList = _nonNegative(manualListSalesAmount);
    final normalizedCost = _nonNegative(costAmount);
    final normalizedExpense = _nonNegative(expenseAmount);
    final updatedRecord = record.copyWith(
      photoListSalesAmount: normalizedPhotoList,
      manualListSalesAmount: normalizedManualList,
      manualSalesReviewed: true,
      costAmount: normalizedCost,
      expenseAmount: normalizedExpense,
      accountNotes: accountNotes.trim(),
      updatedAt: DateTime.now(),
    );
    final orderSubtotal =
        record.cartSalesAmount + normalizedPhotoList + normalizedManualList;
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
        'cartItemsAmount': record.cartSalesAmount,
        'photoListAmount': normalizedPhotoList,
        'manualListAmount': normalizedManualList,
        'listAmountsReviewed': true,
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
    required DateTime accountCreatedAt,
  }) {
    if (!_firebaseAvailable) {
      return Stream<List<AppNotification>>.value(const <AppNotification>[]);
    }
    if (role == 'admin') {
      return _notifications
          .where('recipientRole', isEqualTo: 'admin')
          .snapshots()
          .map(_notificationsFromSnapshot);
    }
    if (role == 'delivery_boy') {
      return _notifications
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map(_notificationsFromSnapshot)
          .map(
            (notifications) => notificationsCreatedOnOrAfter(
              notifications,
              accountCreatedAt,
            ),
          );
    }

    final userNotifications = _notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => _roleNotificationsFromSnapshot(snapshot, role))
        .map(
          (notifications) => notificationsCreatedOnOrAfter(
            notifications,
            accountCreatedAt,
          ),
        );
    final broadcastNotifications = _notifications
        .where('recipientRole', isEqualTo: 'broadcast')
        .snapshots()
        .map(_notificationsFromSnapshot)
        .map(
          (notifications) => notificationsCreatedOnOrAfter(
            notifications,
            accountCreatedAt,
          ),
        );
    return _mergeNotificationStreams(
      userNotifications,
      broadcastNotifications,
    );
  }

  List<AppNotification> _notificationsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AppNotification> _roleNotificationsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String role,
  ) {
    return _notificationsFromSnapshot(snapshot)
        .where((notification) => notification.recipientRole == role)
        .toList();
  }

  static List<AppNotification> notificationsCreatedOnOrAfter(
    List<AppNotification> notifications,
    DateTime accountCreatedAt,
  ) {
    return notifications
        .where(
          (notification) => !notification.createdAt.isBefore(accountCreatedAt),
        )
        .toList();
  }

  Stream<List<AppNotification>> _mergeNotificationStreams(
    Stream<List<AppNotification>> first,
    Stream<List<AppNotification>> second,
  ) {
    late final StreamController<List<AppNotification>> controller;
    StreamSubscription<List<AppNotification>>? firstSubscription;
    StreamSubscription<List<AppNotification>>? secondSubscription;
    var firstItems = const <AppNotification>[];
    var secondItems = const <AppNotification>[];
    var hasFirstItems = false;
    var hasSecondItems = false;

    void emitIfReady() {
      if (!hasFirstItems || !hasSecondItems) {
        return;
      }
      final notificationsById = <String, AppNotification>{};
      for (final notification in [...firstItems, ...secondItems]) {
        notificationsById[notification.notificationId] = notification;
      }
      final merged = notificationsById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(merged);
    }

    controller = StreamController<List<AppNotification>>(
      onListen: () {
        firstSubscription = first.listen(
          (items) {
            firstItems = items;
            hasFirstItems = true;
            emitIfReady();
          },
          onError: controller.addError,
        );
        secondSubscription = second.listen(
          (items) {
            secondItems = items;
            hasSecondItems = true;
            emitIfReady();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await firstSubscription?.cancel();
        await secondSubscription?.cancel();
      },
    );

    return controller.stream;
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

  Future<void> broadcastToUsers({
    required String title,
    required String body,
  }) {
    final id = _uuid.v4();
    return _notifications.doc(id).set(
          AppNotification(
            notificationId: id,
            userId: '',
            recipientRole: 'broadcast',
            title: title,
            body: body,
            type: 'broadcast',
            relatedId: '',
            isRead: false,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }
}
