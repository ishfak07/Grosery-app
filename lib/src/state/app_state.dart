import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../services/cloudinary_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/phone_utils.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  AppState(FirebaseBootstrap bootstrap)
      : firebaseAvailable = bootstrap.isReady,
        firebaseError = bootstrap.errorMessage,
        firestoreService =
            FirestoreService(firebaseAvailable: bootstrap.isReady),
        notificationService =
            NotificationService(firebaseAvailable: bootstrap.isReady) {
    authService = AuthService(
      firebaseAvailable: bootstrap.isReady,
      firestoreService: firestoreService,
    );
  }

  final bool firebaseAvailable;
  final String? firebaseError;
  final FirestoreService firestoreService;
  final NotificationService notificationService;
  final LocalStorageService localStorageService = LocalStorageService();
  late final AuthService authService;

  final _uuid = const Uuid();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;
  UserProfile? _profile;
  List<CartItem> _cartItems = const <CartItem>[];
  String? _billImagePath;
  String? _notificationsConfiguredForUid;

  bool get isInitializing => _isInitializing;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _profile != null;
  bool get isAdmin => _profile?.isAdmin ?? false;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  String? get billImagePath => _billImagePath;
  bool get hasBillImage => _billImagePath != null && _billImagePath!.isNotEmpty;
  int get cartCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal =>
      _cartItems.fold<double>(0, (sum, item) => sum + item.lineTotal);

  Future<void> initialize() async {
    _cartItems = await localStorageService.loadCart();
    _billImagePath = await localStorageService.loadBillImagePath();
    _hasSeenOnboarding = await localStorageService.hasSeenOnboarding();

    if (firebaseAvailable) {
      _authSubscription =
          authService.authStateChanges().listen(_handleAuthUser);
    } else {
      _isInitializing = false;
    }
    notifyListeners();
  }

  Future<void> _handleAuthUser(User? user) async {
    await _profileSubscription?.cancel();
    if (user == null) {
      _profile = null;
      _notificationsConfiguredForUid = null;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    if (authService.isBootstrapAdminUser(user)) {
      _profile = authService.bootstrapAdminProfile(user.uid);
      _isInitializing = false;
      notifyListeners();
      await _configureNotificationsForProfile(_profile);
      return;
    }

    _profileSubscription = firestoreService.watchUserProfile(user.uid).listen(
      (profile) async {
        _profile = profile;
        _isInitializing = false;
        notifyListeners();
        await _configureNotificationsForProfile(profile);
      },
    );
  }

  Future<void> _configureNotificationsForProfile(UserProfile? profile) async {
    if (profile != null && _notificationsConfiguredForUid != profile.uid) {
      _notificationsConfiguredForUid = profile.uid;
      await notificationService.configureForUser(profile.uid);
    }
  }

  Future<void> markOnboardingComplete() async {
    _hasSeenOnboarding = true;
    notifyListeners();
    await localStorageService.setOnboardingSeen();
  }

  Future<void> refreshProfile() async {
    if (!firebaseAvailable) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _profile = null;
      notifyListeners();
      return;
    }
    if (authService.isBootstrapAdminUser(user)) {
      _profile = authService.bootstrapAdminProfile(user.uid);
      notifyListeners();
      return;
    }
    _profile = await firestoreService.fetchUserProfile(user.uid);
    notifyListeners();
  }

  Future<void> refreshVisibleData() async {
    if (!firebaseAvailable) {
      return;
    }
    await refreshProfile();
    final current = _profile;
    if (current == null) {
      return;
    }
    await firestoreService.refreshForProfile(current);
  }

  Future<UserProfile> login({
    required String phone,
    required String password,
  }) async {
    final user = await authService.loginWithPhonePassword(
      phone: phone,
      password: password,
    );
    _profile = user;
    notifyListeners();
    await _configureNotificationsForProfile(user);
    return user;
  }

  Future<void> logout() async {
    _profile = null;
    await authService.logout();
    notifyListeners();
  }

  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String address,
    required String password,
  }) async {
    _profile = await authService.completeRegistration(
      fullName: fullName,
      phone: phone,
      address: address,
      password: password,
    );
    notifyListeners();
    await _configureNotificationsForProfile(_profile);
  }

  Future<void> updateProfile({
    required String fullName,
    required String address,
  }) async {
    final current = _profile;
    if (current == null) {
      return;
    }
    await firestoreService.updateUserProfile(
      uid: current.uid,
      fullName: fullName,
      address: address,
    );
    _profile = current.copyWith(fullName: fullName, address: address);
    notifyListeners();
  }

  Future<void> addToCart(Product product) async {
    final index = _cartItems.indexWhere(
      (item) => item.productId == product.productId,
    );
    if (index >= 0) {
      final updated = [..._cartItems];
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      _cartItems = updated;
    } else {
      _cartItems = [..._cartItems, CartItem.fromProduct(product)];
    }
    notifyListeners();
    await localStorageService.saveCart(_cartItems);
  }

  Future<void> updateCartQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    _cartItems = _cartItems
        .map(
          (item) => item.productId == productId
              ? item.copyWith(quantity: quantity)
              : item,
        )
        .toList();
    notifyListeners();
    await localStorageService.saveCart(_cartItems);
  }

  Future<void> removeFromCart(String productId) async {
    _cartItems =
        _cartItems.where((item) => item.productId != productId).toList();
    notifyListeners();
    await localStorageService.saveCart(_cartItems);
  }

  Future<void> clearCart() async {
    _cartItems = const <CartItem>[];
    notifyListeners();
    await localStorageService.saveCart(_cartItems);
  }

  Future<void> setBillImagePath(String? path) async {
    _billImagePath = path;
    notifyListeners();
    await localStorageService.saveBillImagePath(path);
  }

  Future<OrderModel> createOrder({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String orderNotes,
    required String paymentMethod,
    String? paymentReceiptImagePath,
  }) async {
    final current = _profile;
    if (current == null) {
      throw StateError('Please login before placing an order.');
    }
    if (current.isBlocked) {
      throw StateError('Blocked users cannot place orders.');
    }
    if (_cartItems.isEmpty && !hasBillImage) {
      throw StateError(
          'Add products or upload a shopping list before checkout.');
    }
    if (paymentMethod == AppConstants.paymentMethodBankTransfer &&
        (paymentReceiptImagePath == null ||
            paymentReceiptImagePath.trim().isEmpty)) {
      throw StateError('Upload the bank transfer receipt before checkout.');
    }

    final orderId = _uuid.v4();
    String uploadedImageUrl = '';
    if (hasBillImage) {
      uploadedImageUrl =
          await CloudinaryService.uploadImage(File(_billImagePath!));
    }
    String paymentReceiptImageUrl = '';
    if (paymentMethod == AppConstants.paymentMethodBankTransfer &&
        paymentReceiptImagePath != null &&
        paymentReceiptImagePath.trim().isNotEmpty) {
      paymentReceiptImageUrl =
          await CloudinaryService.uploadImage(File(paymentReceiptImagePath));
    }

    final subtotal = cartSubtotal;
    final total = subtotal +
        AppConstants.defaultDeliveryCharge +
        AppConstants.defaultServiceCharge;
    final now = DateTime.now();
    final order = OrderModel(
      orderId: orderId,
      userId: current.uid,
      customerName: customerName.trim(),
      customerPhone: PhoneUtils.normalizeSriLankanPhone(customerPhone),
      customerAddress: customerAddress.trim(),
      items: _cartItems.map(OrderItem.fromCart).toList(),
      uploadedImageUrl: uploadedImageUrl,
      paymentReceiptImageUrl: paymentReceiptImageUrl,
      orderNotes: orderNotes.trim(),
      subtotal: subtotal,
      deliveryCharge: AppConstants.defaultDeliveryCharge,
      serviceCharge: AppConstants.defaultServiceCharge,
      totalAmount: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == AppConstants.paymentMethodBankTransfer
          ? 'receipt uploaded'
          : 'pending',
      orderStatus: 'Pending',
      adminNotes: '',
      assignedDeliveryPerson: '',
      createdAt: now,
      updatedAt: now,
    );

    await firestoreService.createOrder(order);
    await clearCart();
    await setBillImagePath(null);
    return order;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    notificationService.dispose();
    super.dispose();
  }
}
