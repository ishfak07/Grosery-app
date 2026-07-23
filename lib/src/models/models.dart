import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/i18n/language_codes.dart';

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

DateTime? _readOptionalDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

Object _writeDate(DateTime value) => Timestamp.fromDate(value);

double _readNonNegativeDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    final amount = value.toDouble();
    if (!amount.isNaN && !amount.isInfinite && amount >= 0) {
      return amount;
    }
  }
  return fallback;
}

class CheckoutChargeSettings {
  const CheckoutChargeSettings({
    required this.deliveryCharge,
    required this.serviceCharge,
    required this.updatedAt,
  });

  static CheckoutChargeSettings get defaults => CheckoutChargeSettings(
        deliveryCharge: AppConstants.defaultDeliveryCharge,
        serviceCharge: AppConstants.defaultServiceCharge,
        updatedAt: DateTime.now(),
      );

  final double deliveryCharge;
  final double serviceCharge;
  final DateTime updatedAt;

  double get totalCharge => deliveryCharge + serviceCharge;
  double totalFor(double subtotal) => subtotal + totalCharge;

  CheckoutChargeSettings copyWith({
    double? deliveryCharge,
    double? serviceCharge,
    DateTime? updatedAt,
  }) {
    return CheckoutChargeSettings(
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryCharge': deliveryCharge,
      'serviceCharge': serviceCharge,
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory CheckoutChargeSettings.fromMap(Map<String, dynamic>? map) {
    final fallback = CheckoutChargeSettings.defaults;
    if (map == null) {
      return fallback;
    }
    return CheckoutChargeSettings(
      deliveryCharge: _readNonNegativeAmount(
        map['deliveryCharge'],
        fallback.deliveryCharge,
      ),
      serviceCharge: _readNonNegativeAmount(
        map['serviceCharge'],
        fallback.serviceCharge,
      ),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static double _readNonNegativeAmount(dynamic value, double fallback) {
    if (value is num) {
      final amount = value.toDouble();
      if (!amount.isNaN && !amount.isInfinite && amount >= 0) {
        return amount;
      }
    }
    return fallback;
  }
}

class ShopHoursSettings {
  const ShopHoursSettings({
    required this.openingMinutes,
    required this.closingMinutes,
    required this.updatedAt,
  });

  static const int minutesPerDay = 24 * 60;

  static ShopHoursSettings get defaults => ShopHoursSettings(
        openingMinutes: 0,
        closingMinutes: 0,
        updatedAt: DateTime.now(),
      );

  final int openingMinutes;
  final int closingMinutes;
  final DateTime updatedAt;

  bool get isOpenAllDay => openingMinutes == closingMinutes;
  String get openingTimeLabel => formatMinutes(openingMinutes);
  String get closingTimeLabel => formatMinutes(closingMinutes);
  String get rangeLabel =>
      isOpenAllDay ? 'Open all day' : '$openingTimeLabel - $closingTimeLabel';
  String get closedMessage =>
      'Shop is closed. Please come back at $openingTimeLabel.';

  bool isOpenAt(DateTime value) {
    if (isOpenAllDay) {
      return true;
    }
    final currentMinutes = value.hour * 60 + value.minute;
    if (openingMinutes < closingMinutes) {
      return currentMinutes >= openingMinutes &&
          currentMinutes <= closingMinutes;
    }
    return currentMinutes >= openingMinutes || currentMinutes <= closingMinutes;
  }

  ShopHoursSettings copyWith({
    int? openingMinutes,
    int? closingMinutes,
    DateTime? updatedAt,
  }) {
    return ShopHoursSettings(
      openingMinutes: openingMinutes ?? this.openingMinutes,
      closingMinutes: closingMinutes ?? this.closingMinutes,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'openingMinutes': openingMinutes,
      'closingMinutes': closingMinutes,
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory ShopHoursSettings.fromMap(Map<String, dynamic>? map) {
    final fallback = ShopHoursSettings.defaults;
    if (map == null) {
      return fallback;
    }
    return ShopHoursSettings(
      openingMinutes: _readMinuteOfDay(
        map['openingMinutes'] ?? map['openingTime'],
        fallback.openingMinutes,
      ),
      closingMinutes: _readMinuteOfDay(
        map['closingMinutes'] ?? map['closingTime'],
        fallback.closingMinutes,
      ),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String formatMinutes(int minutes) {
    final normalized = minutes.clamp(0, minutesPerDay - 1);
    final hour24 = normalized ~/ 60;
    final minute = normalized % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  static int _readMinuteOfDay(dynamic value, int fallback) {
    if (value is num) {
      final minutes = value.toInt();
      if (minutes >= 0 && minutes < minutesPerDay) {
        return minutes;
      }
    }
    if (value is String) {
      final parsed = _tryParseTimeText(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  static int? _tryParseTimeText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$').firstMatch(trimmed);
    if (match == null) {
      return null;
    }
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null || minute < 0 || minute > 59) {
      return null;
    }
    final period = match.group(3)?.toUpperCase();
    if (period == null) {
      if (hour < 0 || hour > 23) {
        return null;
      }
      return hour * 60 + minute;
    }
    if (hour < 1 || hour > 12) {
      return null;
    }
    final hour24 = period == 'AM'
        ? (hour == 12 ? 0 : hour)
        : (hour == 12 ? 12 : hour + 12);
    return hour24 * 60 + minute;
  }
}

class PaymentSettings {
  const PaymentSettings({
    required this.codEnabled,
    required this.bankTransferEnabled,
    required this.bankAccountName,
    required this.bankName,
    required this.bankBranch,
    required this.bankAccountNumber,
    required this.updatedAt,
  });

  static PaymentSettings get defaults => PaymentSettings(
        codEnabled: true,
        bankTransferEnabled: true,
        bankAccountName: AppConstants.bankAccountName,
        bankName: AppConstants.bankName,
        bankBranch: AppConstants.bankBranch,
        bankAccountNumber: AppConstants.bankAccountNumber,
        updatedAt: DateTime.now(),
      );

  final bool codEnabled;
  final bool bankTransferEnabled;
  final String bankAccountName;
  final String bankName;
  final String bankBranch;
  final String bankAccountNumber;
  final DateTime updatedAt;

  bool get hasAvailablePaymentMethod => codEnabled || bankTransferEnabled;

  List<String> get availablePaymentMethods => <String>[
        if (codEnabled) AppConstants.paymentMethodCod,
        if (bankTransferEnabled) AppConstants.paymentMethodBankTransfer,
      ];

  bool isPaymentMethodEnabled(String paymentMethod) {
    switch (paymentMethod) {
      case AppConstants.paymentMethodCod:
        return codEnabled;
      case AppConstants.paymentMethodBankTransfer:
        return bankTransferEnabled;
      default:
        return false;
    }
  }

  String? availablePaymentMethodOrNull(String preferredPaymentMethod) {
    if (isPaymentMethodEnabled(preferredPaymentMethod)) {
      return preferredPaymentMethod;
    }
    final methods = availablePaymentMethods;
    return methods.isEmpty ? null : methods.first;
  }

  PaymentSettings copyWith({
    bool? codEnabled,
    bool? bankTransferEnabled,
    String? bankAccountName,
    String? bankName,
    String? bankBranch,
    String? bankAccountNumber,
    DateTime? updatedAt,
  }) {
    return PaymentSettings(
      codEnabled: codEnabled ?? this.codEnabled,
      bankTransferEnabled: bankTransferEnabled ?? this.bankTransferEnabled,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankName: bankName ?? this.bankName,
      bankBranch: bankBranch ?? this.bankBranch,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codEnabled': codEnabled,
      'bankTransferEnabled': bankTransferEnabled,
      'bankAccountName': bankAccountName,
      'bankName': bankName,
      'bankBranch': bankBranch,
      'bankAccountNumber': bankAccountNumber,
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory PaymentSettings.fromMap(Map<String, dynamic>? map) {
    final fallback = PaymentSettings.defaults;
    if (map == null) {
      return fallback;
    }
    return PaymentSettings(
      codEnabled: _readBool(map['codEnabled'], fallback.codEnabled),
      bankTransferEnabled: _readBool(
        map['bankTransferEnabled'],
        fallback.bankTransferEnabled,
      ),
      bankAccountName: _readText(
        map['bankAccountName'],
        fallback.bankAccountName,
      ),
      bankName: _readText(map['bankName'], fallback.bankName),
      bankBranch: _readText(map['bankBranch'], fallback.bankBranch),
      bankAccountNumber: _readText(
        map['bankAccountNumber'],
        fallback.bankAccountNumber,
      ),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static bool _readBool(dynamic value, bool fallback) {
    return value is bool ? value : fallback;
  }

  static String _readText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

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
    this.preferredLanguageCode = AppLanguageCodes.english,
    this.fcmToken = '',
    this.fcmTokens = const <String>[],
    this.deliveryRewardStars = 0,
    this.deliveryRewardStarsInitialized = false,
    this.deliveryRewardCount = 0,
    this.deliveryRewardsPaidLkr = 0,
    this.deliveryRewardLastPaidAt,
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
  final String preferredLanguageCode;
  final String fcmToken;
  final List<String> fcmTokens;
  final int deliveryRewardStars;
  final bool deliveryRewardStarsInitialized;
  final int deliveryRewardCount;
  final int deliveryRewardsPaidLkr;
  final DateTime? deliveryRewardLastPaidAt;

  bool get isAdmin => role == 'admin';
  bool get isDeliveryBoy =>
      role == 'delivery_boy' || role == 'deliveryBoy' || role == 'delivery';

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? hiddenEmail,
    String? address,
    String? role,
    bool? isBlocked,
    String? preferredLanguageCode,
    String? fcmToken,
    List<String>? fcmTokens,
    int? deliveryRewardStars,
    bool? deliveryRewardStarsInitialized,
    int? deliveryRewardCount,
    int? deliveryRewardsPaidLkr,
    DateTime? deliveryRewardLastPaidAt,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      hiddenEmail: hiddenEmail ?? this.hiddenEmail,
      role: role ?? this.role,
      address: address ?? this.address,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPhoneVerified: isPhoneVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      preferredLanguageCode: AppLanguageCodes.normalize(
        preferredLanguageCode ?? this.preferredLanguageCode,
      ),
      fcmToken: fcmToken ?? this.fcmToken,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      deliveryRewardStars: deliveryRewardStars ?? this.deliveryRewardStars,
      deliveryRewardStarsInitialized:
          deliveryRewardStarsInitialized ?? this.deliveryRewardStarsInitialized,
      deliveryRewardCount: deliveryRewardCount ?? this.deliveryRewardCount,
      deliveryRewardsPaidLkr:
          deliveryRewardsPaidLkr ?? this.deliveryRewardsPaidLkr,
      deliveryRewardLastPaidAt:
          deliveryRewardLastPaidAt ?? this.deliveryRewardLastPaidAt,
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
      'preferredLanguageCode':
          AppLanguageCodes.normalize(preferredLanguageCode),
      'fcmToken': fcmToken,
      'fcmTokens': fcmTokens,
      'deliveryRewardStars': deliveryRewardStars,
      'deliveryRewardStarsInitialized': deliveryRewardStarsInitialized,
      'deliveryRewardCount': deliveryRewardCount,
      'deliveryRewardsPaidLkr': deliveryRewardsPaidLkr,
      'deliveryRewardLastPaidAt': deliveryRewardLastPaidAt == null
          ? null
          : _writeDate(deliveryRewardLastPaidAt!),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    final fcmTokens = (map['fcmTokens'] as List<dynamic>? ?? const <dynamic>[])
        .map((token) => token.toString())
        .toList();
    final documentUid = uid.trim();
    return UserProfile(
      uid: documentUid.isNotEmpty ? documentUid : map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      hiddenEmail: map['hiddenEmail'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      address: map['address'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      isPhoneVerified: map['isPhoneVerified'] as bool? ?? false,
      isBlocked: map['isBlocked'] as bool? ?? false,
      preferredLanguageCode: AppLanguageCodes.normalize(
        map['preferredLanguageCode'] as String?,
      ),
      fcmToken: map['fcmToken'] as String? ??
          (fcmTokens.isEmpty ? '' : fcmTokens.first),
      fcmTokens: fcmTokens,
      deliveryRewardStars: (map['deliveryRewardStars'] as num?)?.toInt() ?? 0,
      deliveryRewardStarsInitialized:
          map['deliveryRewardStarsInitialized'] == true,
      deliveryRewardCount: (map['deliveryRewardCount'] as num?)?.toInt() ?? 0,
      deliveryRewardsPaidLkr:
          (map['deliveryRewardsPaidLkr'] as num?)?.toInt() ?? 0,
      deliveryRewardLastPaidAt:
          _readOptionalDate(map['deliveryRewardLastPaidAt']),
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

class Offer {
  const Offer({
    required this.offerId,
    required this.title,
    required this.tamilTitle,
    required this.caption,
    required this.tamilCaption,
    required this.imageUrl,
    required this.imagePublicId,
    required this.createdAt,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  final String offerId;
  final String title;
  final String tamilTitle;
  final String caption;
  final String tamilCaption;
  final String imageUrl;
  final String imagePublicId;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  String localizedTitle(String languageCode) {
    if (AppLanguageCodes.normalize(languageCode) == AppLanguageCodes.tamil &&
        tamilTitle.trim().isNotEmpty) {
      return tamilTitle;
    }
    return title;
  }

  String localizedCaption(String languageCode) {
    if (AppLanguageCodes.normalize(languageCode) == AppLanguageCodes.tamil &&
        tamilCaption.trim().isNotEmpty) {
      return tamilCaption;
    }
    return caption;
  }

  bool isCurrentlyActive(DateTime now) {
    if (!isActive) {
      return false;
    }
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'offerId': offerId,
      'title': title,
      'tamilTitle': tamilTitle,
      'caption': caption,
      'tamilCaption': tamilCaption,
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'createdAt': _writeDate(createdAt),
      'isActive': isActive,
      'startDate': startDate == null ? null : _writeDate(startDate!),
      'endDate': endDate == null ? null : _writeDate(endDate!),
    };
  }

  factory Offer.fromMap(Map<String, dynamic> map, String id) {
    return Offer(
      offerId: map['offerId'] as String? ?? id,
      title: map['title'] as String? ?? '',
      tamilTitle: map['tamilTitle'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      tamilCaption: map['tamilCaption'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      imagePublicId: map['imagePublicId'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      isActive: map['isActive'] as bool? ?? true,
      startDate: _readOptionalDate(map['startDate']),
      endDate: _readOptionalDate(map['endDate']),
    );
  }
}

class Product {
  const Product({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.name,
    required this.nameTamil,
    required this.category,
    required this.description,
    required this.descriptionTamil,
    required this.price,
    required this.imageUrl,
    required this.imagePublicId,
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
  final String nameTamil;
  final String category;
  final String description;
  final String descriptionTamil;
  final double price;
  final String imageUrl;
  final String imagePublicId;
  final String unit;
  final String stockStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAvailable => isActive && stockStatus == 'available';

  String localizedName(String languageCode) {
    if (AppLanguageCodes.normalize(languageCode) == AppLanguageCodes.tamil &&
        nameTamil.trim().isNotEmpty) {
      return nameTamil;
    }
    return name;
  }

  String localizedDescription(String languageCode) {
    if (AppLanguageCodes.normalize(languageCode) == AppLanguageCodes.tamil &&
        descriptionTamil.trim().isNotEmpty) {
      return descriptionTamil;
    }
    return description;
  }

  Product copyWith({
    String? shopId,
    String? shopName,
    String? name,
    String? nameTamil,
    String? category,
    String? description,
    String? descriptionTamil,
    double? price,
    String? imageUrl,
    String? imagePublicId,
    String? unit,
    String? stockStatus,
    bool? isActive,
  }) {
    return Product(
      productId: productId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      name: name ?? this.name,
      nameTamil: nameTamil ?? this.nameTamil,
      category: category ?? this.category,
      description: description ?? this.description,
      descriptionTamil: descriptionTamil ?? this.descriptionTamil,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePublicId: imagePublicId ?? this.imagePublicId,
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
      'nameTamil': nameTamil,
      'category': category,
      'description': description,
      'descriptionTamil': descriptionTamil,
      'price': price,
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
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
      nameTamil: map['nameTamil'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      description: map['description'] as String? ?? '',
      descriptionTamil: map['descriptionTamil'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      imagePublicId: map['imagePublicId'] as String? ?? '',
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
    this.nameTamil = '',
    this.imageUrl = '',
  });

  final String productId;
  final String shopId;
  final String shopName;
  final String name;
  final String nameTamil;
  final double price;
  final String unit;
  final int quantity;
  final String imageUrl;

  double get lineTotal => price * quantity;

  String localizedName(String languageCode) {
    if (AppLanguageCodes.normalize(languageCode) == AppLanguageCodes.tamil &&
        nameTamil.trim().isNotEmpty) {
      return nameTamil;
    }
    return name;
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      shopId: shopId,
      shopName: shopName,
      name: name,
      nameTamil: nameTamil,
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
      'nameTamil': nameTamil,
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
      nameTamil: product.nameTamil,
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
      nameTamil: map['nameTamil'] as String? ?? '',
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
    required this.nameTamil,
    required this.shopId,
    required this.shopName,
    required this.unit,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
    this.isAvailable = true,
  });

  final String productId;
  final String name;
  final String nameTamil;
  final String shopId;
  final String shopName;
  final String unit;
  final double price;
  final int quantity;
  final String imageUrl;
  final bool isAvailable;

  double get lineTotal => price * quantity;

  String localizedName(String languageCode) {
    if (AppLanguageCodes.normalize(languageCode) == AppLanguageCodes.tamil &&
        nameTamil.trim().isNotEmpty) {
      return nameTamil;
    }
    return name;
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'nameTamil': nameTamil,
      'shopId': shopId,
      'shopName': shopName,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  factory OrderItem.fromCart(CartItem item) {
    return OrderItem(
      productId: item.productId,
      name: item.name,
      nameTamil: item.nameTamil,
      shopId: item.shopId,
      shopName: item.shopName,
      unit: item.unit,
      price: item.price,
      quantity: item.quantity,
      imageUrl: item.imageUrl,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameTamil: map['nameTamil'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      unit: map['unit'] as String? ?? 'piece',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: map['imageUrl'] as String? ?? '',
      isAvailable: map['isAvailable'] as bool? ?? true,
    );
  }
}

class OrderModel {
  static const _manualListNotesHeader = 'Manual grocery list:';
  static final _manualListNotesHeaderPattern = RegExp(
    r'(^|\r?\n)\s*manual\s+grocery\s+list\s*:',
    caseSensitive: false,
  );

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.uploadedImageUrl,
    required this.uploadedImagePublicId,
    required this.manualListText,
    required this.paymentReceiptImageUrl,
    required this.paymentReceiptImagePublicId,
    required this.orderNotes,
    required this.cartItemsAmount,
    required this.photoListAmount,
    required this.manualListAmount,
    required this.listAmountsReviewed,
    required this.subtotal,
    required this.deliveryCharge,
    required this.serviceCharge,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.adminNotes,
    required this.rejectionReason,
    required this.assignedDeliveryBoyId,
    required this.assignedDeliveryPerson,
    required this.assignedDeliveryPhone,
    required this.deliveryRating,
    required this.deliveryReview,
    required this.deliveryReviewedAt,
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
  final String uploadedImagePublicId;
  final String manualListText;
  final String paymentReceiptImageUrl;
  final String paymentReceiptImagePublicId;
  final String orderNotes;
  final double cartItemsAmount;
  final double photoListAmount;
  final double manualListAmount;
  final bool listAmountsReviewed;
  final double subtotal;
  final double deliveryCharge;
  final double serviceCharge;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String adminNotes;
  final String rejectionReason;
  final String assignedDeliveryBoyId;
  final String assignedDeliveryPerson;
  final String assignedDeliveryPhone;
  final int deliveryRating;
  final String deliveryReview;
  final DateTime? deliveryReviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasUpload => uploadedImageUrl.isNotEmpty;
  String get customerNotes => _orderNotesWithoutManualList(orderNotes);
  String get effectiveManualListText {
    final cleanedManualListText = manualListText.trim();
    if (cleanedManualListText.isNotEmpty) {
      return cleanedManualListText;
    }
    return _manualListTextFromNotes(orderNotes);
  }

  bool get hasManualList => effectiveManualListText.isNotEmpty;
  double get splitSubtotal =>
      cartItemsAmount + photoListAmount + manualListAmount;
  List<String> get manualListLines => effectiveManualListText
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  bool get hasShoppingList => hasUpload || hasManualList;
  bool get hasPaymentReceipt => paymentReceiptImageUrl.isNotEmpty;
  bool get hasAssignedDeliveryContact =>
      (orderStatus == 'Out for Delivery' || orderStatus == 'Delivered') &&
      (assignedDeliveryPerson.trim().isNotEmpty ||
          assignedDeliveryPhone.trim().isNotEmpty);
  bool get hasDeliveryReview => deliveryRating >= 1 && deliveryRating <= 5;

  OrderModel copyWith({
    List<OrderItem>? items,
    String? paymentReceiptImageUrl,
    String? paymentReceiptImagePublicId,
    String? orderStatus,
    String? adminNotes,
    String? rejectionReason,
    String? assignedDeliveryBoyId,
    String? assignedDeliveryPerson,
    String? assignedDeliveryPhone,
    int? deliveryRating,
    String? deliveryReview,
    DateTime? deliveryReviewedAt,
    double? cartItemsAmount,
    double? photoListAmount,
    double? manualListAmount,
    bool? listAmountsReviewed,
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
      uploadedImagePublicId: uploadedImagePublicId,
      manualListText: manualListText,
      paymentReceiptImageUrl:
          paymentReceiptImageUrl ?? this.paymentReceiptImageUrl,
      paymentReceiptImagePublicId:
          paymentReceiptImagePublicId ?? this.paymentReceiptImagePublicId,
      orderNotes: orderNotes,
      cartItemsAmount: cartItemsAmount ?? this.cartItemsAmount,
      photoListAmount: photoListAmount ?? this.photoListAmount,
      manualListAmount: manualListAmount ?? this.manualListAmount,
      listAmountsReviewed: listAmountsReviewed ?? this.listAmountsReviewed,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      assignedDeliveryBoyId:
          assignedDeliveryBoyId ?? this.assignedDeliveryBoyId,
      assignedDeliveryPerson:
          assignedDeliveryPerson ?? this.assignedDeliveryPerson,
      assignedDeliveryPhone:
          assignedDeliveryPhone ?? this.assignedDeliveryPhone,
      deliveryRating: deliveryRating ?? this.deliveryRating,
      deliveryReview: deliveryReview ?? this.deliveryReview,
      deliveryReviewedAt: deliveryReviewedAt ?? this.deliveryReviewedAt,
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
      'uploadedImagePublicId': uploadedImagePublicId,
      'paymentReceiptImageUrl': paymentReceiptImageUrl,
      'paymentReceiptImagePublicId': paymentReceiptImagePublicId,
      'orderNotes': _orderNotesForStorage(
        orderNotes: customerNotes,
        manualListText: effectiveManualListText,
      ),
      'cartItemsAmount': cartItemsAmount,
      'photoListAmount': photoListAmount,
      'manualListAmount': manualListAmount,
      'listAmountsReviewed': listAmountsReviewed,
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'serviceCharge': serviceCharge,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'adminNotes': adminNotes,
      'rejectionReason': rejectionReason,
      'assignedDeliveryBoyId': assignedDeliveryBoyId,
      'assignedDeliveryPerson': assignedDeliveryPerson,
      'assignedDeliveryPhone': assignedDeliveryPhone,
      'deliveryRating': deliveryRating,
      'deliveryReview': deliveryReview,
      'deliveryReviewedAt':
          deliveryReviewedAt == null ? null : _writeDate(deliveryReviewedAt!),
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final rawOrderNotes = map['orderNotes'] as String? ?? '';
    final storedManualListText = map['manualListText'] as String?;
    final manualListText =
        storedManualListText ?? _manualListTextFromNotes(rawOrderNotes);
    final items = (map['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(OrderItem.fromMap)
        .toList();
    final uploadedImageUrl = map['uploadedImageUrl'] as String? ?? '';
    final storedSubtotal = _readNonNegativeDouble(map['subtotal']);
    final derivedCartAmount = items.fold<double>(
      0.0,
      (total, item) => total + item.lineTotal,
    );
    final hasPhotoList = uploadedImageUrl.isNotEmpty;
    final hasManualList = manualListText.trim().isNotEmpty;
    final hasShoppingList = hasPhotoList || hasManualList;
    final hasSplitAmounts = map.containsKey('cartItemsAmount') ||
        map.containsKey('photoListAmount') ||
        map.containsKey('manualListAmount');
    final cartItemsAmount = hasSplitAmounts
        ? _readNonNegativeDouble(map['cartItemsAmount'], derivedCartAmount)
        : hasShoppingList
            ? derivedCartAmount
            : storedSubtotal;
    final unsplitListAmount = storedSubtotal > cartItemsAmount
        ? storedSubtotal - cartItemsAmount
        : 0.0;
    final photoListAmount = hasSplitAmounts
        ? _readNonNegativeDouble(map['photoListAmount'])
        : hasPhotoList
            ? unsplitListAmount
            : 0.0;
    final manualListAmount = hasSplitAmounts
        ? _readNonNegativeDouble(map['manualListAmount'])
        : !hasPhotoList && hasManualList
            ? unsplitListAmount
            : 0.0;
    final splitSubtotal = cartItemsAmount + photoListAmount + manualListAmount;
    final subtotal = hasSplitAmounts ? splitSubtotal : storedSubtotal;
    return OrderModel(
      orderId: map['orderId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      items: items,
      uploadedImageUrl: uploadedImageUrl,
      uploadedImagePublicId: map['uploadedImagePublicId'] as String? ?? '',
      manualListText: manualListText,
      paymentReceiptImageUrl: map['paymentReceiptImageUrl'] as String? ?? '',
      paymentReceiptImagePublicId:
          map['paymentReceiptImagePublicId'] as String? ?? '',
      orderNotes: _orderNotesWithoutManualList(rawOrderNotes),
      cartItemsAmount: cartItemsAmount,
      photoListAmount: photoListAmount,
      manualListAmount: manualListAmount,
      listAmountsReviewed: map['listAmountsReviewed'] as bool? ??
          ((!hasPhotoList && !hasManualList) ||
              photoListAmount + manualListAmount > 0),
      subtotal: subtotal,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      serviceCharge: (map['serviceCharge'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? 'COD',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      orderStatus: map['orderStatus'] as String? ?? 'Pending',
      adminNotes: map['adminNotes'] as String? ?? '',
      rejectionReason: map['rejectionReason'] as String? ?? '',
      assignedDeliveryBoyId: map['assignedDeliveryBoyId'] as String? ?? '',
      assignedDeliveryPerson: map['assignedDeliveryPerson'] as String? ?? '',
      assignedDeliveryPhone: map['assignedDeliveryPhone'] as String? ?? '',
      deliveryRating: (map['deliveryRating'] as num?)?.toInt() ?? 0,
      deliveryReview: map['deliveryReview'] as String? ?? '',
      deliveryReviewedAt: _readOptionalDate(map['deliveryReviewedAt']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String _orderNotesForStorage({
    required String orderNotes,
    required String manualListText,
  }) {
    final cleanedNotes = _orderNotesWithoutManualList(orderNotes).trim();
    final cleanedList = manualListText.trim();
    if (cleanedList.isEmpty) {
      return cleanedNotes;
    }
    final manualListSection = '$_manualListNotesHeader\n$cleanedList';
    if (cleanedNotes.isEmpty) {
      return manualListSection;
    }
    return '$cleanedNotes\n\n$manualListSection';
  }

  static String _manualListTextFromNotes(String orderNotes) {
    final headerMatch = _manualListNotesHeaderPattern.firstMatch(orderNotes);
    if (headerMatch == null) {
      return '';
    }
    return orderNotes.substring(headerMatch.end).trim();
  }

  static String _orderNotesWithoutManualList(String orderNotes) {
    final headerMatch = _manualListNotesHeaderPattern.firstMatch(orderNotes);
    if (headerMatch == null) {
      return orderNotes.trim();
    }
    return orderNotes.substring(0, headerMatch.start).trim();
  }
}

class AccountSaleRecord {
  const AccountSaleRecord({
    required this.recordId,
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.orderMethod,
    required this.hasCartItems,
    required this.hasPhotoList,
    required this.hasManualList,
    required this.hasShoppingList,
    required this.itemCount,
    required this.cartSalesAmount,
    required this.photoListSalesAmount,
    required this.manualListSalesAmount,
    required this.manualSalesReviewed,
    required this.deliveryCharge,
    required this.serviceCharge,
    required this.costAmount,
    required this.expenseAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.adminNotes,
    required this.accountNotes,
    required this.orderCreatedAt,
    required this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String recordId;
  final String orderId;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String orderMethod;
  final bool hasCartItems;
  final bool hasPhotoList;
  final bool hasManualList;
  final bool hasShoppingList;
  final int itemCount;
  final double cartSalesAmount;
  final double photoListSalesAmount;
  final double manualListSalesAmount;
  final bool manualSalesReviewed;
  final double deliveryCharge;
  final double serviceCharge;
  final double costAmount;
  final double expenseAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String adminNotes;
  final String accountNotes;
  final DateTime orderCreatedAt;
  final DateTime deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get manualSalesAmount => photoListSalesAmount + manualListSalesAmount;
  double get itemSalesAmount => cartSalesAmount + manualSalesAmount;
  double get chargeAmount => deliveryCharge + serviceCharge;
  double get totalSalesAmount => itemSalesAmount + chargeAmount;
  double get totalCostAmount => costAmount + expenseAmount;
  double get profitOrLoss => totalSalesAmount - totalCostAmount;
  bool get hasManualSales => manualSalesAmount > 0;
  bool get needsManualSalesAmount => hasShoppingList && !manualSalesReviewed;
  bool get hasProfitInputs => costAmount > 0 || expenseAmount > 0;

  AccountSaleRecord copyWith({
    double? photoListSalesAmount,
    double? manualListSalesAmount,
    bool? manualSalesReviewed,
    double? costAmount,
    double? expenseAmount,
    String? accountNotes,
    String? paymentStatus,
    String? orderStatus,
    DateTime? updatedAt,
  }) {
    return AccountSaleRecord(
      recordId: recordId,
      orderId: orderId,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      orderMethod: orderMethod,
      hasCartItems: hasCartItems,
      hasPhotoList: hasPhotoList,
      hasManualList: hasManualList,
      hasShoppingList: hasShoppingList,
      itemCount: itemCount,
      cartSalesAmount: cartSalesAmount,
      photoListSalesAmount: photoListSalesAmount ?? this.photoListSalesAmount,
      manualListSalesAmount:
          manualListSalesAmount ?? this.manualListSalesAmount,
      manualSalesReviewed: manualSalesReviewed ?? this.manualSalesReviewed,
      deliveryCharge: deliveryCharge,
      serviceCharge: serviceCharge,
      costAmount: costAmount ?? this.costAmount,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      adminNotes: adminNotes,
      accountNotes: accountNotes ?? this.accountNotes,
      orderCreatedAt: orderCreatedAt,
      deliveredAt: deliveredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'orderId': orderId,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'orderMethod': orderMethod,
      'hasCartItems': hasCartItems,
      'hasPhotoList': hasPhotoList,
      'hasManualList': hasManualList,
      'hasShoppingList': hasShoppingList,
      'itemCount': itemCount,
      'cartSalesAmount': cartSalesAmount,
      'photoListSalesAmount': photoListSalesAmount,
      'manualListSalesAmount': manualListSalesAmount,
      'manualSalesAmount': manualSalesAmount,
      'manualSalesReviewed': manualSalesReviewed,
      'deliveryCharge': deliveryCharge,
      'serviceCharge': serviceCharge,
      'itemSalesAmount': itemSalesAmount,
      'chargeAmount': chargeAmount,
      'totalSalesAmount': totalSalesAmount,
      'costAmount': costAmount,
      'expenseAmount': expenseAmount,
      'totalCostAmount': totalCostAmount,
      'profitOrLoss': profitOrLoss,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'adminNotes': adminNotes,
      'accountNotes': accountNotes,
      'orderCreatedAt': _writeDate(orderCreatedAt),
      'deliveredAt': _writeDate(deliveredAt),
      'createdAt': _writeDate(createdAt),
      'updatedAt': _writeDate(updatedAt),
    };
  }

  factory AccountSaleRecord.fromOrder(
    OrderModel order, {
    AccountSaleRecord? existing,
    required DateTime deliveredAt,
    required DateTime now,
    bool preserveManualSalesAmount = false,
  }) {
    final hasCartItems = order.items.isNotEmpty;
    final hasPhotoList = order.hasUpload;
    final hasManualList = order.hasManualList;
    final hasShoppingList = order.hasShoppingList;
    final cartSalesAmount = order.cartItemsAmount;
    final photoListSalesAmount = preserveManualSalesAmount && existing != null
        ? existing.photoListSalesAmount
        : order.photoListAmount;
    final manualListSalesAmount = preserveManualSalesAmount && existing != null
        ? existing.manualListSalesAmount
        : order.manualListAmount;
    final manualSalesAmount = photoListSalesAmount + manualListSalesAmount;
    final manualSalesReviewed = existing?.manualSalesReviewed == true ||
        order.listAmountsReviewed ||
        manualSalesAmount > 0;

    return AccountSaleRecord(
      recordId: order.orderId,
      orderId: order.orderId,
      userId: order.userId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerAddress: order.customerAddress,
      orderMethod: orderMethodLabel(
        hasCartItems: hasCartItems,
        hasPhotoList: hasPhotoList,
        hasManualList: hasManualList,
      ),
      hasCartItems: hasCartItems,
      hasPhotoList: hasPhotoList,
      hasManualList: hasManualList,
      hasShoppingList: hasShoppingList,
      itemCount:
          order.items.fold<int>(0, (total, item) => total + item.quantity),
      cartSalesAmount: cartSalesAmount,
      photoListSalesAmount: photoListSalesAmount,
      manualListSalesAmount: manualListSalesAmount,
      manualSalesReviewed: !hasShoppingList || manualSalesReviewed,
      deliveryCharge: order.deliveryCharge,
      serviceCharge: order.serviceCharge,
      costAmount: existing?.costAmount ?? 0,
      expenseAmount: existing?.expenseAmount ?? 0,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      orderStatus: order.orderStatus,
      adminNotes: order.adminNotes,
      accountNotes: existing?.accountNotes ?? '',
      orderCreatedAt: order.createdAt,
      deliveredAt: existing?.deliveredAt ?? deliveredAt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  factory AccountSaleRecord.fromMap(Map<String, dynamic> map, String id) {
    final orderMethod = map['orderMethod'] as String? ?? 'Cart checkout';
    final hasPhotoList = (map['hasPhotoList'] as bool?) ??
        orderMethod.toLowerCase().contains('photo');
    final hasManualList = (map['hasManualList'] as bool?) ??
        (orderMethod.toLowerCase().contains('typed') ||
            orderMethod.toLowerCase().contains('manual'));
    final hasShoppingList =
        (map['hasShoppingList'] as bool?) ?? (hasPhotoList || hasManualList);
    final legacyManualSalesAmount =
        _readNonNegativeDouble(map['manualSalesAmount']);
    final hasSplitSalesAmounts = map.containsKey('photoListSalesAmount') ||
        map.containsKey('manualListSalesAmount');
    final photoListSalesAmount = hasSplitSalesAmounts
        ? _readNonNegativeDouble(map['photoListSalesAmount'])
        : hasPhotoList
            ? legacyManualSalesAmount
            : 0.0;
    final manualListSalesAmount = hasSplitSalesAmounts
        ? _readNonNegativeDouble(map['manualListSalesAmount'])
        : !hasPhotoList && hasManualList
            ? legacyManualSalesAmount
            : 0.0;
    return AccountSaleRecord(
      recordId: map['recordId'] as String? ?? id,
      orderId: map['orderId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      orderMethod: orderMethod,
      hasCartItems: map['hasCartItems'] as bool? ?? true,
      hasPhotoList: hasPhotoList,
      hasManualList: hasManualList,
      hasShoppingList: hasShoppingList,
      itemCount: (map['itemCount'] as num?)?.toInt() ?? 0,
      cartSalesAmount: (map['cartSalesAmount'] as num?)?.toDouble() ?? 0,
      photoListSalesAmount: photoListSalesAmount,
      manualListSalesAmount: manualListSalesAmount,
      manualSalesReviewed: map['manualSalesReviewed'] as bool? ??
          (!hasShoppingList || legacyManualSalesAmount > 0),
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      serviceCharge: (map['serviceCharge'] as num?)?.toDouble() ?? 0,
      costAmount: (map['costAmount'] as num?)?.toDouble() ?? 0,
      expenseAmount: (map['expenseAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? 'COD',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      orderStatus: map['orderStatus'] as String? ?? 'Delivered',
      adminNotes: map['adminNotes'] as String? ?? '',
      accountNotes: map['accountNotes'] as String? ?? '',
      orderCreatedAt: _readDate(map['orderCreatedAt']),
      deliveredAt: _readDate(map['deliveredAt']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String orderMethodLabel({
    required bool hasCartItems,
    required bool hasPhotoList,
    required bool hasManualList,
  }) {
    if (hasCartItems && hasPhotoList && hasManualList) {
      return 'Cart + Photo + Typed List';
    }
    if (hasCartItems && hasPhotoList) {
      return 'Cart + Shopping List Photo';
    }
    if (hasCartItems && hasManualList) {
      return 'Cart + Typed List';
    }
    if (hasPhotoList && hasManualList) {
      return 'Photo + Typed List';
    }
    if (hasPhotoList) {
      return 'Shopping List Photo';
    }
    if (hasManualList) {
      return 'Typed Shopping List';
    }
    return 'Cart Checkout';
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
    required this.imagePublicId,
    required this.createdAt,
  });

  final String messageId;
  final String ticketId;
  final String senderId;
  final String senderRole;
  final String message;
  final String imageUrl;
  final String imagePublicId;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
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
      imagePublicId: map['imagePublicId'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
    );
  }
}

class PasswordResetRequest {
  const PasswordResetRequest({
    required this.requestId,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.hiddenEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.approvedBy = '',
    this.rejectedBy = '',
    this.completedAt,
    this.rejectedAt,
    this.approvedAt,
  });

  final String requestId;
  final String userId;
  final String customerName;
  final String phone;
  final String hiddenEmail;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String approvedBy;
  final String rejectedBy;
  final DateTime? completedAt;
  final DateTime? rejectedAt;
  final DateTime? approvedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  factory PasswordResetRequest.fromMap(Map<String, dynamic> map, String id) {
    return PasswordResetRequest(
      requestId: map['requestId'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      hiddenEmail: map['hiddenEmail'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      approvedBy: map['approvedBy'] as String? ?? '',
      rejectedBy: map['rejectedBy'] as String? ?? '',
      approvedAt:
          map['approvedAt'] == null ? null : _readDate(map['approvedAt']),
      rejectedAt:
          map['rejectedAt'] == null ? null : _readDate(map['rejectedAt']),
      completedAt:
          map['completedAt'] == null ? null : _readDate(map['completedAt']),
    );
  }
}

class AccountDeletionRequest {
  const AccountDeletionRequest({
    required this.requestId,
    required this.customerName,
    required this.phone,
    required this.details,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String requestId;
  final String customerName;
  final String phone;
  final String details;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'pending';

  factory AccountDeletionRequest.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return AccountDeletionRequest(
      requestId: id,
      customerName: map['customerName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      details: map['details'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
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
