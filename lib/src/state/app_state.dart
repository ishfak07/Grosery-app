import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../services/cloudinary_service.dart';
import '../core/constants/app_constants.dart';
import '../core/i18n/language_codes.dart';
import '../core/utils/phone_utils.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
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
  final ConnectivityService connectivityService = ConnectivityService();
  final LocalStorageService localStorageService = LocalStorageService();
  late final AuthService authService;

  final _uuid = const Uuid();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<CheckoutChargeSettings>?
      _checkoutChargeSettingsSubscription;
  StreamSubscription<PaymentSettings>? _paymentSettingsSubscription;

  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;
  bool _hasInternetConnection = true;
  UserProfile? _profile;
  List<CartItem> _cartItems = const <CartItem>[];
  String? _billImagePath;
  String _manualListText = '';
  CheckoutChargeSettings _checkoutChargeSettings =
      CheckoutChargeSettings.defaults;
  bool _hasLoadedCheckoutChargeSettings = false;
  PaymentSettings _paymentSettings = PaymentSettings.defaults;
  bool _hasLoadedPaymentSettings = false;
  String? _notificationsConfiguredForProfileKey;
  String _preferredLanguageCode = AppLanguageCodes.english;

  bool get isInitializing => _isInitializing;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasInternetConnection => _hasInternetConnection;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _profile != null;
  bool get isAdmin => _profile?.isAdmin ?? false;
  String get preferredLanguageCode => _preferredLanguageCode;
  String get effectiveLanguageCode =>
      isAdmin ? AppLanguageCodes.english : _preferredLanguageCode;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  String? get billImagePath => _billImagePath;
  bool get hasBillImage => _billImagePath != null && _billImagePath!.isNotEmpty;
  String get manualListText => _manualListText;
  bool get hasManualList => _manualListText.trim().isNotEmpty;
  CheckoutChargeSettings get checkoutChargeSettings => _checkoutChargeSettings;
  bool get hasLoadedCheckoutChargeSettings => _hasLoadedCheckoutChargeSettings;
  PaymentSettings get paymentSettings => _paymentSettings;
  bool get hasLoadedPaymentSettings => _hasLoadedPaymentSettings;
  int get cartCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal =>
      _cartItems.fold<double>(0, (sum, item) => sum + item.lineTotal);

  Future<void> initialize() async {
    unawaited(
      connectivityService.start(onStatusChanged: _setInternetConnection),
    );
    _cartItems = await localStorageService.loadCart();
    _billImagePath = await localStorageService.loadBillImagePath();
    _manualListText = await localStorageService.loadManualListText();
    _hasSeenOnboarding = await localStorageService.hasSeenOnboarding();
    _preferredLanguageCode =
        await localStorageService.loadPreferredLanguageCode();

    if (firebaseAvailable) {
      final requestNotificationPermission =
          !(await localStorageService.hasRequestedNotificationPermission());
      await notificationService.initialize(
        requestPermission: requestNotificationPermission,
      );
      if (requestNotificationPermission) {
        await localStorageService.setNotificationPermissionRequested();
      }
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
      await _checkoutChargeSettingsSubscription?.cancel();
      await _paymentSettingsSubscription?.cancel();
      _profile = null;
      _checkoutChargeSettings = CheckoutChargeSettings.defaults;
      _hasLoadedCheckoutChargeSettings = false;
      _paymentSettings = PaymentSettings.defaults;
      _hasLoadedPaymentSettings = false;
      _notificationsConfiguredForProfileKey = null;
      unawaited(notificationService.detachUser());
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _watchCheckoutChargeSettings();
    _watchPaymentSettings();

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
        await _applyProfileLanguage(profile);
        _isInitializing = false;
        notifyListeners();
        await _configureNotificationsForProfile(profile);
      },
    );
  }

  void _watchCheckoutChargeSettings() {
    if (!firebaseAvailable) {
      _checkoutChargeSettings = CheckoutChargeSettings.defaults;
      _hasLoadedCheckoutChargeSettings = true;
      return;
    }
    unawaited(_checkoutChargeSettingsSubscription?.cancel());
    _hasLoadedCheckoutChargeSettings = false;
    _checkoutChargeSettingsSubscription =
        firestoreService.watchCheckoutChargeSettings().listen(
      (settings) {
        _checkoutChargeSettings = settings;
        _hasLoadedCheckoutChargeSettings = true;
        notifyListeners();
      },
      onError: (_) {
        _hasLoadedCheckoutChargeSettings = true;
        notifyListeners();
      },
    );
  }

  void _watchPaymentSettings() {
    if (!firebaseAvailable) {
      _paymentSettings = PaymentSettings.defaults;
      _hasLoadedPaymentSettings = true;
      return;
    }
    unawaited(_paymentSettingsSubscription?.cancel());
    _hasLoadedPaymentSettings = false;
    _paymentSettingsSubscription =
        firestoreService.watchPaymentSettings().listen(
      (settings) {
        _paymentSettings = settings;
        _hasLoadedPaymentSettings = true;
        notifyListeners();
      },
      onError: (_) {
        _hasLoadedPaymentSettings = true;
        notifyListeners();
      },
    );
  }

  Future<void> _configureNotificationsForProfile(UserProfile? profile) async {
    if (profile == null) {
      return;
    }

    final profileKey = '${profile.uid}:${profile.role}';
    if (_notificationsConfiguredForProfileKey != profileKey) {
      _notificationsConfiguredForProfileKey = profileKey;
      await notificationService.configureForUser(
        uid: profile.uid,
        role: profile.role,
        notifications: firestoreService.watchNotifications(
          userId: profile.uid,
          role: profile.role,
        ),
      );
    }
  }

  Future<void> _applyProfileLanguage(UserProfile? profile) async {
    if (profile == null || profile.isAdmin) {
      return;
    }
    final languageCode =
        AppLanguageCodes.normalize(profile.preferredLanguageCode);
    if (_preferredLanguageCode == languageCode) {
      return;
    }
    _preferredLanguageCode = languageCode;
    await localStorageService.savePreferredLanguageCode(languageCode);
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
    await _applyProfileLanguage(_profile);
    notifyListeners();
  }

  Future<void> refreshVisibleData() async {
    if (!firebaseAvailable) {
      return;
    }
    if (!await verifyInternetConnection()) {
      return;
    }
    try {
      await refreshProfile();
    } catch (_) {
      await verifyInternetConnection();
      return;
    }
    final current = _profile;
    if (current == null) {
      return;
    }
    try {
      await firestoreService.refreshForProfile(current);
    } catch (_) {
      await verifyInternetConnection();
    }
  }

  Future<bool> verifyInternetConnection() async {
    final isOnline = await connectivityService.verifyNow();
    _setInternetConnection(isOnline);
    return isOnline;
  }

  void markInternetUnavailable() {
    _setInternetConnection(false);
  }

  void _setInternetConnection(bool isOnline) {
    if (_hasInternetConnection == isOnline) {
      return;
    }
    _hasInternetConnection = isOnline;
    notifyListeners();
    if (isOnline && firebaseAvailable && _profile != null) {
      unawaited(refreshVisibleData());
    }
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
    await _applyProfileLanguage(user);
    _watchCheckoutChargeSettings();
    _watchPaymentSettings();
    notifyListeners();
    await _configureNotificationsForProfile(user);
    return user;
  }

  Future<void> logout() async {
    final current = _profile;
    if (current != null) {
      try {
        await notificationService.clearTokenForUser(current.uid);
      } catch (_) {
        // Push-token cleanup should not block logout.
      }
    }
    _profile = null;
    _notificationsConfiguredForProfileKey = null;
    _checkoutChargeSettings = CheckoutChargeSettings.defaults;
    _hasLoadedCheckoutChargeSettings = false;
    _paymentSettings = PaymentSettings.defaults;
    _hasLoadedPaymentSettings = false;
    await _checkoutChargeSettingsSubscription?.cancel();
    await _paymentSettingsSubscription?.cancel();
    await authService.logout();
    notifyListeners();
  }

  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String address,
    required String password,
    required String preferredLanguageCode,
  }) async {
    final languageCode = AppLanguageCodes.normalize(preferredLanguageCode);
    _profile = await authService.completeRegistration(
      fullName: fullName,
      phone: phone,
      address: address,
      password: password,
      preferredLanguageCode: languageCode,
    );
    _preferredLanguageCode = languageCode;
    await localStorageService.savePreferredLanguageCode(languageCode);
    _watchCheckoutChargeSettings();
    _watchPaymentSettings();
    notifyListeners();
    await _configureNotificationsForProfile(_profile);
  }

  Future<void> updateCheckoutChargeSettings({
    required double deliveryCharge,
    required double serviceCharge,
  }) async {
    if (deliveryCharge.isNaN ||
        deliveryCharge.isInfinite ||
        deliveryCharge < 0 ||
        serviceCharge.isNaN ||
        serviceCharge.isInfinite ||
        serviceCharge < 0) {
      throw StateError('Enter valid checkout charges.');
    }
    final settings = CheckoutChargeSettings(
      deliveryCharge: deliveryCharge,
      serviceCharge: serviceCharge,
      updatedAt: DateTime.now(),
    );
    await firestoreService.saveCheckoutChargeSettings(settings);
    _checkoutChargeSettings = settings;
    _hasLoadedCheckoutChargeSettings = true;
    notifyListeners();
  }

  Future<void> updatePaymentSettings({
    required bool codEnabled,
    required bool bankTransferEnabled,
    required String bankAccountName,
    required String bankName,
    required String bankBranch,
    required String bankAccountNumber,
  }) async {
    if (bankAccountName.trim().isEmpty ||
        bankName.trim().isEmpty ||
        bankBranch.trim().isEmpty ||
        bankAccountNumber.trim().isEmpty) {
      throw StateError('Enter all bank transfer account details.');
    }
    final settings = PaymentSettings(
      codEnabled: codEnabled,
      bankTransferEnabled: bankTransferEnabled,
      bankAccountName: bankAccountName.trim(),
      bankName: bankName.trim(),
      bankBranch: bankBranch.trim(),
      bankAccountNumber: bankAccountNumber.trim(),
      updatedAt: DateTime.now(),
    );
    await firestoreService.savePaymentSettings(settings);
    _paymentSettings = settings;
    _hasLoadedPaymentSettings = true;
    notifyListeners();
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

  Future<void> updatePreferredLanguage(String preferredLanguageCode) async {
    final languageCode = AppLanguageCodes.normalize(preferredLanguageCode);
    final previousLanguageCode = _preferredLanguageCode;
    final previousProfile = _profile;
    if (_preferredLanguageCode != languageCode) {
      _preferredLanguageCode = languageCode;
      notifyListeners();
    }
    await localStorageService.savePreferredLanguageCode(languageCode);

    final current = _profile;
    if (current == null || current.isAdmin) {
      return;
    }
    try {
      await firestoreService.updatePreferredLanguage(
        uid: current.uid,
        preferredLanguageCode: languageCode,
      );
      _profile = current.copyWith(preferredLanguageCode: languageCode);
      notifyListeners();
    } catch (_) {
      _preferredLanguageCode = previousLanguageCode;
      _profile = previousProfile;
      await localStorageService.savePreferredLanguageCode(
        previousLanguageCode,
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addToCart(Product product) async {
    final index = _cartItems.indexWhere(
      (item) => item.productId == product.productId,
    );
    if (index >= 0) {
      final updated = [..._cartItems];
      updated[index] = CartItem.fromProduct(
        product,
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

  Future<void> clearCheckoutDraft() async {
    _cartItems = const <CartItem>[];
    _billImagePath = null;
    _manualListText = '';
    notifyListeners();
    await Future.wait([
      localStorageService.saveCart(_cartItems),
      localStorageService.saveBillImagePath(null),
      localStorageService.saveManualListText(''),
    ]);
  }

  Future<void> setBillImagePath(String? path) async {
    _billImagePath = path;
    notifyListeners();
    await localStorageService.saveBillImagePath(path);
  }

  Future<void> setManualListText(String value) async {
    _manualListText = value;
    notifyListeners();
    await localStorageService.saveManualListText(value);
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
    if (_cartItems.isEmpty && !hasBillImage && !hasManualList) {
      throw StateError(
        'Add products, upload a shopping list, or type a manual list before checkout.',
      );
    }
    if (!_paymentSettings.hasAvailablePaymentMethod) {
      throw StateError('Payment methods are temporarily unavailable.');
    }
    if (!_paymentSettings.isPaymentMethodEnabled(paymentMethod)) {
      throw StateError('This payment method is temporarily unavailable.');
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

    final charges = _checkoutChargeSettings;
    final subtotal = cartSubtotal;
    final total = charges.totalFor(subtotal);
    final now = DateTime.now();
    final order = OrderModel(
      orderId: orderId,
      userId: current.uid,
      customerName: customerName.trim(),
      customerPhone: PhoneUtils.normalizeSriLankanPhone(customerPhone),
      customerAddress: customerAddress.trim(),
      items: _cartItems.map(OrderItem.fromCart).toList(),
      uploadedImageUrl: uploadedImageUrl,
      manualListText: _manualListText.trim(),
      paymentReceiptImageUrl: paymentReceiptImageUrl,
      orderNotes: orderNotes.trim(),
      cartItemsAmount: subtotal,
      photoListAmount: 0,
      manualListAmount: 0,
      listAmountsReviewed: false,
      subtotal: subtotal,
      deliveryCharge: charges.deliveryCharge,
      serviceCharge: charges.serviceCharge,
      totalAmount: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == AppConstants.paymentMethodBankTransfer
          ? 'receipt uploaded'
          : 'pending',
      orderStatus: 'Pending',
      adminNotes: '',
      assignedDeliveryPerson: '',
      assignedDeliveryPhone: '',
      createdAt: now,
      updatedAt: now,
    );

    await firestoreService.createOrder(order);
    await clearCheckoutDraft();
    return order;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _checkoutChargeSettingsSubscription?.cancel();
    _paymentSettingsSubscription?.cancel();
    unawaited(connectivityService.dispose());
    notificationService.dispose();
    super.dispose();
  }
}
