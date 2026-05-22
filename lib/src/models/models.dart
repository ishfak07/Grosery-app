import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

Object _writeDate(DateTime value) => Timestamp.fromDate(value);

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.hiddenEmail,
    required this.role,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.isPhoneVerified,
    required this.isBlocked,
    this.fcmTokens = const <String>[],
  });

  final String uid;
  final String fullName;
  final String phone;
  final String hiddenEmail;
  final String role;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPhoneVerified;
  final bool isBlocked;
  final List<String> fcmTokens;

  bool get isAdmin => role == 'admin';

  UserProfile copyWith({
    String? fullName,
    String? address,
    String? role,
    bool? isBlocked,
    List<String>? fcmTokens,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone,
      hiddenEmail: hiddenEmail,
      role: role ?? this.role,
      address: address ?? this.address,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPhoneVerified: isPhoneVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'phone': phone,
      'hiddenEmail': hiddenEmail,
      'role': role,
      'address': address,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
      'isPhoneVerified': isPhoneVerified,
      'isBlocked': isBlocked,
      'fcmTokens': fcmTokens,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: map['uid'] as String? ?? uid,
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      hiddenEmail: map['hiddenEmail'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      address: map['address'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      isPhoneVerified: map['isPhoneVerified'] as bool? ?? false,
      isBlocked: map['isBlocked'] as bool? ?? false,
      fcmTokens: (map['fcmTokens'] as List<dynamic>? ?? const <dynamic>[])
          .map((token) => token.toString())
          .toList(),
    );
  }
}

class Shop {
  const Shop({
    required this.shopId,
    required this.shopName,
    required this.address,
    required this.phone,
    required this.isActive,
    required this.createdAt,
  });

  final String shopId;
  final String shopName;
  final String address;
  final String phone;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'address': address,
      'phone': phone,
      'isActive': isActive,
      'createdAt': _writeDate(createdAt),
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map, String id) {
    return Shop(
      shopId: map['shopId'] as String? ?? id,
      shopName: map['shopName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _readDate(map['createdAt']),
    );
  }
}

class Product {
  const Product({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.unit,
    required this.stockStatus,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String productId;
  final String shopId;
  final String shopName;
  final String name;
  final String category;
  final String description;
  final double price;
  final String imageUrl;
  final String unit;
  final String stockStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAvailable => isActive && stockStatus == 'available';

  Product copyWith({
    String? shopId,
    String? shopName,
    String? name,
    String? category,
    String? description,
    double? price,
    String? imageUrl,
    String? unit,
    String? stockStatus,
    bool? isActive,
  }) {
    return Product(
      productId: productId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      stockStatus: stockStatus ?? this.stockStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'shopId': shopId,
      'shopName': shopName,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'unit': unit,
      'stockStatus': stockStatus,
      'isActive': isActive,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      productId: map['productId'] as String? ?? id,
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      unit: map['unit'] as String? ?? 'piece',
      stockStatus: map['stockStatus'] as String? ?? 'available',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

class CartItem {
  const CartItem({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.name,
    required this.price,
    required this.unit,
    required this.quantity,
    this.imageUrl = '',
  });

  final String productId;
  final String shopId;
  final String shopName;
  final String name;
  final double price;
  final String unit;
  final int quantity;
  final String imageUrl;

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      shopId: shopId,
      shopName: shopName,
      name: name,
      price: price,
      unit: unit,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'shopId': shopId,
      'shopName': shopName,
      'name': name,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      productId: product.productId,
      shopId: product.shopId,
      shopName: product.shopName,
      name: product.name,
      price: product.price,
      unit: product.unit,
      quantity: quantity,
      imageUrl: product.imageUrl,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'piece',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CartItem.fromJson(String source) {
    return CartItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.shopId,
    required this.shopName,
    required this.unit,
    required this.price,
    required this.quantity,
    this.isAvailable = true,
  });

  final String productId;
  final String name;
  final String shopId;
  final String shopName;
  final String unit;
  final double price;
  final int quantity;
  final bool isAvailable;

  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'shopId': shopId,
      'shopName': shopName,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'isAvailable': isAvailable,
    };
  }

  factory OrderItem.fromCart(CartItem item) {
    return OrderItem(
      productId: item.productId,
      name: item.name,
      shopId: item.shopId,
      shopName: item.shopName,
      unit: item.unit,
      price: item.price,
      quantity: item.quantity,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      unit: map['unit'] as String? ?? 'piece',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      isAvailable: map['isAvailable'] as bool? ?? true,
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.uploadedImageUrl,
    required this.orderNotes,
    required this.subtotal,
    required this.deliveryCharge,
    required this.serviceCharge,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.adminNotes,
    required this.assignedDeliveryPerson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String orderId;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<OrderItem> items;
  final String uploadedImageUrl;
  final String orderNotes;
  final double subtotal;
  final double deliveryCharge;
  final double serviceCharge;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String adminNotes;
  final String assignedDeliveryPerson;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasUpload => uploadedImageUrl.isNotEmpty;

  OrderModel copyWith({
    List<OrderItem>? items,
    String? orderStatus,
    String? adminNotes,
    String? assignedDeliveryPerson,
    double? subtotal,
    double? deliveryCharge,
    double? serviceCharge,
    double? totalAmount,
    String? paymentStatus,
  }) {
    return OrderModel(
      orderId: orderId,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      items: items ?? this.items,
      uploadedImageUrl: uploadedImageUrl,
      orderNotes: orderNotes,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      adminNotes: adminNotes ?? this.adminNotes,
      assignedDeliveryPerson:
          assignedDeliveryPerson ?? this.assignedDeliveryPerson,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'uploadedImageUrl': uploadedImageUrl,
      'orderNotes': orderNotes,
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'serviceCharge': serviceCharge,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'adminNotes': adminNotes,
      'assignedDeliveryPerson': assignedDeliveryPerson,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      orderId: map['orderId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      items: (map['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromMap)
          .toList(),
      uploadedImageUrl: map['uploadedImageUrl'] as String? ?? '',
      orderNotes: map['orderNotes'] as String? ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      serviceCharge: (map['serviceCharge'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? 'COD',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      orderStatus: map['orderStatus'] as String? ?? 'Pending',
      adminNotes: map['adminNotes'] as String? ?? '',
      assignedDeliveryPerson: map['assignedDeliveryPerson'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.ticketId,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String ticketId;
  final String userId;
  final String customerName;
  final String phone;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'customerName': customerName,
      'phone': phone,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory SupportTicket.fromMap(Map<String, dynamic> map, String id) {
    return SupportTicket(
      ticketId: map['ticketId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.messageId,
    required this.ticketId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.imageUrl,
    required this.createdAt,
  });

  final String messageId;
  final String ticketId;
  final String senderId;
  final String senderRole;
  final String message;
  final String imageUrl;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'imageUrl': imageUrl,
      'createdAt': _writeDate(createdAt),
    };
  }

  factory SupportMessage.fromMap(Map<String, dynamic> map, String id) {
    return SupportMessage(
      messageId: map['messageId'] as String? ?? id,
      ticketId: map['ticketId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? 'user',
      message: map['message'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.userId,
    required this.recipientRole,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  final String notificationId;
  final String userId;
  final String recipientRole;
  final String title;
  final String body;
  final String type;
  final String relatedId;
  final bool isRead;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'recipientRole': recipientRole,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': _writeDate(createdAt),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      notificationId: map['notificationId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      recipientRole: map['recipientRole'] as String? ?? 'user',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? '',
      relatedId: map['relatedId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']),
    );
  }
}
