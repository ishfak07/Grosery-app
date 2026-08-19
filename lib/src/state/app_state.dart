import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../services/image_upload_service.dart';
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
import '../services/order_cancellation_service.dart';

/// Thrown by [AppState.createOrder] when a normal product-cart order's
/// eligible subtotal is below [AppConstants.minimumOrderValue]. Does not
/// apply to Photo List or Manual List orders (see
/// [AppState.isMinimumOrderCheckApplicable]).
class MinimumOrderNotMetException implements Exception {
  const MinimumOrderNotMetException({
    required this.minimumOrderValue,
    required this.remainingAmount,
  });

  final double minimumOrderValue;
  final double remainingAmount;

  @override
  String toString() =>
      'Your order must be at least Rs. ${AppConstants.formatRupees(minimumOrderValue)} to continue.';
}

class AppState extends ChangeNotifier {
  AppState(FirebaseBootstrap bootstrap)
      : firebaseAvailable = bootstrap.isReady,
        firebaseError = bootstrap.errorMessage,
        firestoreService =
            FirestoreService(firebaseAvailable: bootstrap.isReady),
        orderCancellationService =
            OrderCancellationService(firebaseAvailable: bootstrap.isReady),
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
  final OrderCancellationService orderCancellationService;
  final NotificationService notificationService;
  final ConnectivityService connectivityService = ConnectivityService();
  final LocalStorageService localStorageService = LocalStorageService();
  late final AuthService authService;

  final _uuid = const Uuid();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<CheckoutChargeSettings>?
      _checkoutChargeSettingsSubscription;
  StreamSubscription<ShopHoursSettings>? _shopHoursSettingsSubscription;
  StreamSubscription<PaymentSettings>? _paymentSettingsSubscription;
  StreamSubscription<List<Product>>? _productCatalogSubscription;

  bool _isInitializing = true;
  bool _isLoggingOut = false;
  bool _hasSeenOnboarding = false;
  bool _hasInternetConnection = true;
  UserProfile? _profile;
  List<CartItem> _cartItems = const <CartItem>[];
  Map<String, Product> _catalogById = const <String, Product>{};
  String? _billImagePath;
  String _manualListText = '';
  CheckoutChargeSettings _checkoutChargeSettings =
      CheckoutChargeSettings.defaults;
  bool _hasLoadedCheckoutChargeSettings = false;
  ShopHoursSettings _shopHoursSettings = ShopHoursSettings.defaults;
  bool _hasLoadedShopHoursSettings = false;
  PaymentSettings _paymentSettings = PaymentSettings.defaults;
  bool _hasLoadedPaymentSettings = false;
  String? _notificationsConfiguredForProfileKey;
  String _preferredLanguageCode = AppLanguageCodes.english;
  PasswordResetStatusResult? _passwordResetTracker;
  bool _isCheckingPasswordResetTracker = false;

  bool get isInitializing => _isInitializing;
  bool get isLoggingOut => _isLoggingOut;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasInternetConnection => _hasInternetConnection;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _profile != null;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isDeliveryBoy => _profile?.isDeliveryBoy ?? false;
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
  ShopHoursSettings get shopHoursSettings => _shopHoursSettings;
  bool get hasLoadedShopHoursSettings => _hasLoadedShopHoursSettings;
  bool get isShopOpenNow => _shopHoursSettings.isOpenAt(DateTime.now());
  bool get isShopManuallyClosed => _shopHoursSettings.isTemporarilyClosed;
  String get shopManualClosureReason =>
      _shopHoursSettings.temporaryClosureReason;
  PaymentSettings get paymentSettings => _paymentSettings;
  bool get hasLoadedPaymentSettings => _hasLoadedPaymentSettings;
  PasswordResetStatusResult? get passwordResetTracker => _passwordResetTracker;
  bool get isCheckingPasswordResetTracker => _isCheckingPasswordResetTracker;
  int get cartCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

  /// The product's live catalog price for [item], or its locally cached
  /// [CartItem.price] when the product is no longer in the catalog (e.g.
  /// deleted) or the catalog hasn't loaded yet. This is the single place
  /// cart/checkout pricing reads through, so an admin's price edit reaches
  /// every cart holding that product without the customer re-adding it.
  double livePriceFor(CartItem item) =>
      _catalogById[item.productId]?.price ?? item.price;

  /// The live catalog price for a product id, or null when that product
  /// isn't in the current catalog snapshot (not yet loaded, or deleted).
  /// Used by the admin order-details screen to detect and preview a
  /// changed price on an already-placed order's items.
  double? catalogPriceForProductId(String productId) =>
      _catalogById[productId]?.price;

  double lineTotalFor(CartItem item) => livePriceFor(item) * item.quantity;

  /// True when the catalog price has moved away from what was cached in
  /// the cart when the item was added.
  bool isCartItemPriceStale(CartItem item) =>
      livePriceFor(item) != item.price;

  double get cartSubtotal =>
      _cartItems.fold<double>(0, (sum, item) => sum + lineTotalFor(item));

  /// The minimum-order-value rule only applies to normal catalog cart
  /// orders. Photo List and Manual List orders are priced by the admin
  /// after review, so they are exempt (a list may be attached alongside
  /// cart items in a mixed order, in which case the rule is skipped too).
  bool get isMinimumOrderCheckApplicable => !hasBillImage && !hasManualList;

  /// Rs. remaining to reach [AppConstants.minimumOrderValue], never
  /// negative. Always based on [cartSubtotal] (catalog items only, before
  /// delivery/service charges).
  double get minimumOrderRemainingAmount {
    if (!isMinimumOrderCheckApplicable) {
      return 0;
    }
    final remaining = AppConstants.minimumOrderValue - cartSubtotal;
    return remaining > 0 ? remaining : 0;
  }

  bool get meetsMinimumOrderValue =>
      !isMinimumOrderCheckApplicable ||
      cartSubtotal >= AppConstants.minimumOrderValue;

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
      // Fire-and-forget: the Login page should not wait on a network round
      // trip to render. It rebuilds via notifyListeners() once this
      // resolves, so the tracker just pops in when ready.
      unawaited(_loadPasswordResetTracker());
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
    if (_isLoggingOut && user != null) {
      return;
    }
    if (!_isCurrentAuthUser(user)) {
      return;
    }
    await _profileSubscription?.cancel();
    if (!_isCurrentAuthUser(user)) {
      return;
    }
    if (user == null) {
      await _checkoutChargeSettingsSubscription?.cancel();
      await _shopHoursSettingsSubscription?.cancel();
      await _paymentSettingsSubscription?.cancel();
      await _productCatalogSubscription?.cancel();
      if (!_isCurrentAuthUser(user)) {
        return;
      }
      _profile = null;
      _checkoutChargeSettings = CheckoutChargeSettings.defaults;
      _hasLoadedCheckoutChargeSettings = false;
      _shopHoursSettings = ShopHoursSettings.defaults;
      _hasLoadedShopHoursSettings = false;
      _paymentSettings = PaymentSettings.defaults;
      _hasLoadedPaymentSettings = false;
      _catalogById = const <String, Product>{};
      _notificationsConfiguredForProfileKey = null;
      unawaited(notificationService.detachUser());
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _watchCheckoutChargeSettings();
    _watchShopHoursSettings();
    _watchPaymentSettings();
    _watchProductCatalog();

    _profileSubscription = firestoreService.watchUserProfile(user.uid).listen(
      (profile) async {
        if (_isLoggingOut || !_isCurrentAuthUser(user)) {
          return;
        }
        _profile = profile;
        await _applyProfileLanguage(profile);
        if (!_isCurrentAuthUser(user)) {
          return;
        }
        _isInitializing = false;
        notifyListeners();
        await _configureNotificationsForProfile(profile);
      },
    );
  }

  bool _isCurrentAuthUser(User? expectedUser) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (expectedUser == null) {
      return currentUser == null;
    }
    return currentUser?.uid == expectedUser.uid;
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

  void _watchShopHoursSettings() {
    if (!firebaseAvailable) {
      _shopHoursSettings = ShopHoursSettings.defaults;
      _hasLoadedShopHoursSettings = true;
      return;
    }
    unawaited(_shopHoursSettingsSubscription?.cancel());
    _hasLoadedShopHoursSettings = false;
    _shopHoursSettingsSubscription =
        firestoreService.watchShopHoursSettings().listen(
      (settings) {
        _shopHoursSettings = settings;
        _hasLoadedShopHoursSettings = true;
        notifyListeners();
      },
      onError: (_) {
        _hasLoadedShopHoursSettings = true;
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

  /// Keeps [_catalogById] in sync with the live `products` collection so
  /// cart/checkout pricing (see [livePriceFor]) always reflects the
  /// current admin-set price, not a stale copy.
  void _watchProductCatalog() {
    if (!firebaseAvailable) {
      return;
    }
    unawaited(_productCatalogSubscription?.cancel());
    _productCatalogSubscription = firestoreService
        .watchProducts(activeOnly: false)
        .listen(
      (products) {
        _catalogById = {
          for (final product in products) product.productId: product,
        };
        notifyListeners();
      },
      onError: (_) {
        // Keep the last-known catalog snapshot; cart/checkout fall back to
        // each item's cached price when a product id is missing from it.
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
    _watchShopHoursSettings();
    _watchPaymentSettings();
    _watchProductCatalog();
    notifyListeners();
    await _configureNotificationsForProfile(user);
    // A password-reset tracker is only useful pre-login; once the customer
    // is back in the app (whether via normal login or the auto-login at the
    // end of a completed reset), it has done its job.
    await clearPasswordResetTracker();
    return user;
  }

  /// Called once after a Forgot Password submission returns a fresh or
  /// reused request, so the Login page can show it immediately without the
  /// customer navigating back into Forgot Password to check.
  Future<void> trackPasswordResetRequest(
    PasswordResetStatusResult status,
  ) async {
    if (status.requestId.isEmpty) {
      return;
    }
    await localStorageService.savePasswordResetRequestId(status.requestId);
    _passwordResetTracker = status;
    notifyListeners();
  }

  /// Re-fetches the tracked request's status through the secure
  /// requestId-based callable (never by phone number) and updates the
  /// Login-page tracker. Terminal states (rejected/expired/completed) clear
  /// the saved reference so a stale request doesn't linger forever, while
  /// still leaving the terminal result visible for this session so the
  /// customer sees why before it disappears.
  Future<void> refreshPasswordResetTracker() async {
    final requestId = _passwordResetTracker?.requestId ??
        await localStorageService.loadPasswordResetRequestId();
    if (requestId == null || requestId.isEmpty) {
      return;
    }
    _isCheckingPasswordResetTracker = true;
    notifyListeners();
    try {
      final status =
          await authService.fetchPasswordResetStatusByRequestId(requestId);
      _passwordResetTracker = status;
      if (status.isRejected || status.isExpired || status.isCompleted) {
        await localStorageService.clearPasswordResetRequestId();
      }
    } on PasswordResetRequestNotFoundException {
      // The server has explicitly confirmed this specific id is gone -
      // safe to drop, unlike any other failure below.
      await localStorageService.clearPasswordResetRequestId();
      _passwordResetTracker = null;
    } catch (_) {
      // A transient failure (offline, the callable not deployed yet, etc.)
      // is not proof the request is invalid - keep showing the last known
      // state instead of making an otherwise-valid tracker vanish.
    } finally {
      _isCheckingPasswordResetTracker = false;
      notifyListeners();
    }
  }

  Future<void> clearPasswordResetTracker() async {
    if (_passwordResetTracker == null) {
      return;
    }
    await localStorageService.clearPasswordResetRequestId();
    _passwordResetTracker = null;
    notifyListeners();
  }

  Future<void> _loadPasswordResetTracker() async {
    final requestId = await localStorageService.loadPasswordResetRequestId();
    if (requestId == null || requestId.isEmpty) {
      return;
    }
    await refreshPasswordResetTracker();
  }

  Future<void> logout() async {
    if (_isLoggingOut) {
      return;
    }
    _isLoggingOut = true;
    final current = _profile;
    final profileSubscription = _profileSubscription;
    _profileSubscription = null;
    _profile = null;
    _notificationsConfiguredForProfileKey = null;
    _checkoutChargeSettings = CheckoutChargeSettings.defaults;
    _hasLoadedCheckoutChargeSettings = false;
    _shopHoursSettings = ShopHoursSettings.defaults;
    _hasLoadedShopHoursSettings = false;
    _paymentSettings = PaymentSettings.defaults;
    _hasLoadedPaymentSettings = false;
    _catalogById = const <String, Product>{};
    notifyListeners();

    try {
      await profileSubscription?.cancel();
      if (current != null) {
        try {
          await notificationService.clearTokenForUser(current.uid);
        } catch (_) {
          // Push-token cleanup should not block logout.
        }
      }
      await _checkoutChargeSettingsSubscription?.cancel();
      await _shopHoursSettingsSubscription?.cancel();
      await _paymentSettingsSubscription?.cancel();
      await _productCatalogSubscription?.cancel();
      await authService.logout();
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomerAccount({required String password}) async {
    if (_isLoggingOut) {
      return;
    }
    _isLoggingOut = true;
    try {
      await authService.deleteCustomerAccount(password: password);
      await _profileSubscription?.cancel();
      _profileSubscription = null;
      await _checkoutChargeSettingsSubscription?.cancel();
      await _shopHoursSettingsSubscription?.cancel();
      await _paymentSettingsSubscription?.cancel();
      await _productCatalogSubscription?.cancel();
      await notificationService.detachUser();
      await localStorageService.clearPrivateAccountData();
      _profile = null;
      _cartItems = const <CartItem>[];
      _billImagePath = null;
      _manualListText = '';
      _notificationsConfiguredForProfileKey = null;
      _checkoutChargeSettings = CheckoutChargeSettings.defaults;
      _hasLoadedCheckoutChargeSettings = false;
      _shopHoursSettings = ShopHoursSettings.defaults;
      _hasLoadedShopHoursSettings = false;
      _paymentSettings = PaymentSettings.defaults;
      _hasLoadedPaymentSettings = false;
      _catalogById = const <String, Product>{};
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  Future<void> deleteDeliveryBoyAccount() async {
    if (_isLoggingOut) {
      return;
    }
    _isLoggingOut = true;
    try {
      await authService.deleteDeliveryBoyAccount();
      await _profileSubscription?.cancel();
      _profileSubscription = null;
      await _checkoutChargeSettingsSubscription?.cancel();
      await _shopHoursSettingsSubscription?.cancel();
      await _paymentSettingsSubscription?.cancel();
      await _productCatalogSubscription?.cancel();
      await notificationService.detachUser();
      await localStorageService.clearPrivateAccountData();
      _profile = null;
      _cartItems = const <CartItem>[];
      _billImagePath = null;
      _manualListText = '';
      _notificationsConfiguredForProfileKey = null;
      _checkoutChargeSettings = CheckoutChargeSettings.defaults;
      _hasLoadedCheckoutChargeSettings = false;
      _shopHoursSettings = ShopHoursSettings.defaults;
      _hasLoadedShopHoursSettings = false;
      _paymentSettings = PaymentSettings.defaults;
      _hasLoadedPaymentSettings = false;
      _catalogById = const <String, Product>{};
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
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
    _watchShopHoursSettings();
    _watchPaymentSettings();
    _watchProductCatalog();
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

  Future<void> updateShopHoursSettings({
    required int openingMinutes,
    required int closingMinutes,
  }) async {
    if (openingMinutes < 0 ||
        openingMinutes >= ShopHoursSettings.minutesPerDay ||
        closingMinutes < 0 ||
        closingMinutes >= ShopHoursSettings.minutesPerDay) {
      throw StateError('Enter valid shop opening and closing times.');
    }
    final settings = _shopHoursSettings.copyWith(
      openingMinutes: openingMinutes,
      closingMinutes: closingMinutes,
      updatedAt: DateTime.now(),
    );
    await firestoreService.saveShopHoursSettings(settings);
    _shopHoursSettings = settings;
    _hasLoadedShopHoursSettings = true;
    notifyListeners();
  }

  /// Simple manual ON/OFF switch for temporarily closing the shop. When
  /// [isTemporarilyClosed] is true, [reason] must be non-empty — this
  /// overrides the normal daily opening/closing hours while active.
  Future<void> updateShopManualClosure({
    required bool isTemporarilyClosed,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (isTemporarilyClosed && trimmedReason.isEmpty) {
      throw StateError('Please enter a reason before closing the shop.');
    }
    final settings = _shopHoursSettings.copyWith(
      updatedAt: DateTime.now(),
      isTemporarilyClosed: isTemporarilyClosed,
      temporaryClosureReason: trimmedReason,
    );
    await firestoreService.saveShopHoursSettings(settings);
    _shopHoursSettings = settings;
    _hasLoadedShopHoursSettings = true;
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
    if (!meetsMinimumOrderValue) {
      throw MinimumOrderNotMetException(
        minimumOrderValue: AppConstants.minimumOrderValue,
        remainingAmount: minimumOrderRemainingAmount,
      );
    }
    if (!_shopHoursSettings.isOpenAt(DateTime.now())) {
      throw StateError(_shopHoursSettings.closedMessage);
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
    CloudinaryUploadResult? uploadedImage;
    if (hasBillImage) {
      uploadedImage = await ImageUploadService.uploadUserImage(
        imageFile: File(_billImagePath!),
        ownerUid: current.uid,
        folder: 'orders/$orderId',
        fileName: 'shopping-list',
      );
    }
    CloudinaryUploadResult? paymentReceiptImage;
    if (paymentMethod == AppConstants.paymentMethodBankTransfer &&
        paymentReceiptImagePath != null &&
        paymentReceiptImagePath.trim().isNotEmpty) {
      paymentReceiptImage = await ImageUploadService.uploadUserImage(
        imageFile: File(paymentReceiptImagePath),
        ownerUid: current.uid,
        folder: 'orders/$orderId',
        fileName: 'payment-receipt',
      );
    }

    final resolvedItems = await _resolveCheckoutItems();

    final charges = _checkoutChargeSettings;
    final subtotal = resolvedItems.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final total = charges.totalFor(subtotal);
    final now = DateTime.now();
    final order = OrderModel(
      orderId: orderId,
      userId: current.uid,
      customerName: customerName.trim(),
      customerPhone: PhoneUtils.normalizeSriLankanPhone(customerPhone),
      customerAddress: customerAddress.trim(),
      items: resolvedItems,
      uploadedImageUrl: uploadedImage?.secureUrl ?? '',
      uploadedImagePublicId: uploadedImage?.publicId ?? '',
      manualListText: _manualListText.trim(),
      paymentReceiptImageUrl: paymentReceiptImage?.secureUrl ?? '',
      paymentReceiptImagePublicId: paymentReceiptImage?.publicId ?? '',
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
      rejectionReason: '',
      assignedDeliveryBoyId: '',
      assignedDeliveryPerson: '',
      assignedDeliveryPhone: '',
      deliveryRating: 0,
      deliveryReview: '',
      deliveryReviewedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await firestoreService.createOrder(order);
    await clearCheckoutDraft();
    return order;
  }

  /// Test-only seam: lets tests exercise [createOrder]'s validation (e.g.
  /// the minimum-order-value guard) without a real Firebase Auth session.
  @visibleForTesting
  void debugSetProfileForTesting(UserProfile? profile) {
    _profile = profile;
  }

  /// Test-only seam: lets tests exercise shop-hours/manual-closure
  /// validation in [createOrder] without a real Firestore stream.
  @visibleForTesting
  void debugSetShopHoursSettingsForTesting(ShopHoursSettings settings) {
    _shopHoursSettings = settings;
    _hasLoadedShopHoursSettings = true;
    notifyListeners();
  }

  /// Test-only seam: lets tests exercise live cart/checkout pricing
  /// ([livePriceFor], [cartSubtotal]) without a real Firestore stream.
  @visibleForTesting
  void debugSetProductCatalogForTesting(List<Product> products) {
    _catalogById = {
      for (final product in products) product.productId: product,
    };
    notifyListeners();
  }

  /// Builds the [OrderItem]s [createOrder] would write for the current
  /// cart: re-verifies each item's price against the Firestore server
  /// (falling back to the live-catalog/cached price only if that read is
  /// unavailable), so a stale cart price is never silently used.
  ///
  /// Exposed directly (rather than only inline inside [createOrder]) so
  /// this price-resolution/race-condition-guard behavior is unit
  /// testable without requiring a real Firestore write.
  Future<List<OrderItem>> _resolveCheckoutItems() async {
    final latestServerPrices = await firestoreService.fetchLatestProductPrices(
      _cartItems.map((item) => item.productId).toSet().toList(),
    );
    return _cartItems.map((item) {
      final resolvedPrice =
          latestServerPrices[item.productId] ?? livePriceFor(item);
      return OrderItem(
        productId: item.productId,
        name: item.name,
        nameTamil: item.nameTamil,
        shopId: item.shopId,
        shopName: item.shopName,
        unit: item.unit,
        price: resolvedPrice,
        quantity: item.quantity,
        imageUrl: item.imageUrl,
      );
    }).toList();
  }

  /// Test-only seam: lets tests assert on the race-condition-guarded
  /// checkout item resolution ([_resolveCheckoutItems]) directly.
  @visibleForTesting
  Future<List<OrderItem>> debugResolveCheckoutItemsForTesting() =>
      _resolveCheckoutItems();

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _checkoutChargeSettingsSubscription?.cancel();
    _shopHoursSettingsSubscription?.cancel();
    _paymentSettingsSubscription?.cancel();
    _productCatalogSubscription?.cancel();
    unawaited(connectivityService.dispose());
    notificationService.dispose();
    super.dispose();
  }
}
