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

/// Thrown by [AppState.createOrder] when the server-authoritative recheck in
/// [AppState._resolveCheckoutItems] finds that one or more cart items are no
/// longer orderable — the admin disabled/depleted the product, or deleted it
/// outright, after it was added to the cart. The order is never created and
/// the cart is left untouched, so the customer can remove/replace the item
/// and try again.
class CartItemsUnavailableException implements Exception {
  const CartItemsUnavailableException(this.unavailableItemNames);

  /// Display names (English) of every cart item that failed the
  /// availability recheck, in cart order.
  final List<String> unavailableItemNames;

  @override
  String toString() {
    final names = unavailableItemNames.join(', ');
    return unavailableItemNames.length == 1
        ? '$names is no longer available. Remove it from your cart to continue.'
        : 'These items are no longer available: $names. Remove them from your cart to continue.';
  }
}

class CategoryMethodConflictException implements Exception {
  const CategoryMethodConflictException({
    required this.categoryName,
    required this.currentMethod,
    required this.requestedMethod,
  });

  final String categoryName;
  final String currentMethod;
  final String requestedMethod;

  String get currentMethodLabel => AppState.shoppingMethodLabel(currentMethod);
  String get requestedMethodLabel =>
      AppState.shoppingMethodLabel(requestedMethod);

  @override
  String toString() =>
      '$categoryName category already uses $currentMethodLabel. Change the shopping method to continue.';
}

/// Thrown when a draft/checkout touches a category that is closed right now
/// — either by its own [Shop.hoursOverride] or by the global shop hours.
class CategoryClosedException implements Exception {
  const CategoryClosedException({
    required this.categoryName,
    required this.hours,
  });

  final String categoryName;
  final ShopHoursSettings hours;

  @override
  String toString() => hours.closedMessageFor(categoryName);
}

/// Thrown when a category is asked for a shopping method the admin did not
/// enable for it (see [Shop.allowedMethods]).
class CategoryMethodNotAllowedException implements Exception {
  const CategoryMethodNotAllowedException({
    required this.categoryName,
    required this.method,
  });

  final String categoryName;
  final String method;

  String get methodLabel => AppState.shoppingMethodLabel(method);

  @override
  String toString() =>
      '$categoryName does not accept $methodLabel orders. Choose another shopping method.';
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
  StreamSubscription<List<Shop>>? _categoriesSubscription;

  bool _isInitializing = true;
  bool _isLoggingOut = false;
  bool _hasSeenOnboarding = false;
  bool _hasInternetConnection = true;
  UserProfile? _profile;
  List<CartItem> _cartItems = const <CartItem>[];
  Map<String, Product> _catalogById = const <String, Product>{};
  List<Shop> _categories = const <Shop>[];
  List<DraftPhotoList> _photoLists = const <DraftPhotoList>[];
  List<DraftManualList> _manualLists = const <DraftManualList>[];
  Shop? _selectedHomeCategory;
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

  /// Every attached photo list, one per category — a Groceries photo and a
  /// Vegetables photo can coexist. See [currentPhotoList] for the entry
  /// scoped to whatever category is selected on Home right now.
  List<DraftPhotoList> get photoLists => List.unmodifiable(_photoLists);

  /// Every typed manual list, one per category. See [currentManualList].
  List<DraftManualList> get manualLists => List.unmodifiable(_manualLists);

  bool get hasBillImage => _photoLists.isNotEmpty;
  bool get hasManualList => _manualLists.isNotEmpty;
  Shop? get selectedHomeCategory => _selectedHomeCategory;

  /// The category key drafts are read/written under: the selected Home
  /// category's shop id, or '' (a shared "uncategorized" bucket) when none
  /// is selected — matching how [CategoryGroup]'s fallback bucket works
  /// everywhere else in the app.
  String _draftCategoryKey() => _selectedHomeCategory?.shopId ?? '';
  String _draftCategoryName() => _selectedHomeCategory?.shopName ?? '';

  /// The photo list entry for the currently selected Home category (or the
  /// uncategorized bucket), if any. [UploadBillScreen] reads/edits this —
  /// switching category before opening it scopes it to a different entry,
  /// so attaching a Vegetables photo never overwrites a Groceries one.
  DraftPhotoList? get currentPhotoList {
    final key = _draftCategoryKey();
    for (final entry in _photoLists) {
      if (entry.shopId == key) {
        return entry;
      }
    }
    return null;
  }

  /// The manual list entry for the currently selected Home category (or the
  /// uncategorized bucket), if any. See [currentPhotoList].
  DraftManualList? get currentManualList {
    final key = _draftCategoryKey();
    for (final entry in _manualLists) {
      if (entry.shopId == key) {
        return entry;
      }
    }
    return null;
  }

  static String shoppingMethodLabel(String method) {
    switch (method) {
      case OrderCategoryMethod.methodPhoto:
        return 'Photo List';
      case OrderCategoryMethod.methodManual:
        return 'Manual List';
      case OrderCategoryMethod.methodItems:
        return 'Item Selection';
      default:
        return method;
    }
  }

  String? selectedMethodForCategory(String shopId) {
    final key = shopId.trim();
    if (_photoLists.any((entry) => entry.shopId == key)) {
      return OrderCategoryMethod.methodPhoto;
    }
    if (_manualLists.any((entry) => entry.shopId == key)) {
      return OrderCategoryMethod.methodManual;
    }
    if (_cartItems.any((item) => item.shopId == key)) {
      return OrderCategoryMethod.methodItems;
    }
    return null;
  }

  bool categoryHasDraftData(String shopId) =>
      selectedMethodForCategory(shopId) != null;

  String _categoryDisplayName(String shopId, String fallback) {
    final key = shopId.trim();
    final name = fallback.trim();
    if (name.isNotEmpty) {
      return name;
    }
    for (final entry in _photoLists) {
      if (entry.shopId == key && entry.shopName.trim().isNotEmpty) {
        return entry.shopName;
      }
    }
    for (final entry in _manualLists) {
      if (entry.shopId == key && entry.shopName.trim().isNotEmpty) {
        return entry.shopName;
      }
    }
    for (final item in _cartItems) {
      if (item.shopId == key && item.shopName.trim().isNotEmpty) {
        return item.shopName;
      }
    }
    return 'This';
  }

  void _ensureCategoryMethod({
    required String shopId,
    required String shopName,
    required String requestedMethod,
  }) {
    if (!isMethodAllowedForCategory(shopId, requestedMethod)) {
      throw CategoryMethodNotAllowedException(
        categoryName: _categoryDisplayName(shopId, shopName),
        method: requestedMethod,
      );
    }
    final currentMethod = selectedMethodForCategory(shopId);
    if (currentMethod == null || currentMethod == requestedMethod) {
      return;
    }
    throw CategoryMethodConflictException(
      categoryName: _categoryDisplayName(shopId, shopName),
      currentMethod: currentMethod,
      requestedMethod: requestedMethod,
    );
  }

  Future<void> clearCategoryDraft(String shopId) async {
    final key = shopId.trim();
    _cartItems = _cartItems.where((item) => item.shopId != key).toList();
    _photoLists = _photoLists.where((entry) => entry.shopId != key).toList();
    _manualLists = _manualLists.where((entry) => entry.shopId != key).toList();
    notifyListeners();
    await Future.wait([
      localStorageService.saveCart(_cartItems),
      localStorageService.savePhotoLists(_photoLists),
      localStorageService.saveManualLists(_manualLists),
    ]);
  }

  Future<void> changeCategoryMethod({
    required String shopId,
    required String method,
  }) async {
    await clearCategoryDraft(shopId);
  }

  CheckoutChargeSettings get checkoutChargeSettings => _checkoutChargeSettings;
  bool get hasLoadedCheckoutChargeSettings => _hasLoadedCheckoutChargeSettings;
  ShopHoursSettings get shopHoursSettings => _shopHoursSettings;
  bool get hasLoadedShopHoursSettings => _hasLoadedShopHoursSettings;
  bool get isShopOpenNow => _shopHoursSettings.isOpenAt(DateTime.now());
  bool get isShopManuallyClosed => _shopHoursSettings.isTemporarilyClosed;
  String get shopManualClosureReason =>
      _shopHoursSettings.temporaryClosureReason;

  /// Every category, active or not, mirrored from the `shops` collection so
  /// that per-category shopping methods and hours can be resolved without a
  /// stream lookup at every call site.
  List<Shop> get categories => _categories;

  Shop? categoryById(String shopId) {
    final key = shopId.trim();
    if (key.isEmpty) {
      return null;
    }
    for (final category in _categories) {
      if (category.shopId == key) {
        return category;
      }
    }
    return null;
  }

  /// The hours governing [shopId] right now: its own override when it has
  /// one, otherwise the global shop hours. An unknown category (deleted, or
  /// the uncategorized bucket) falls back to the global hours.
  ShopHoursSettings effectiveHoursForCategory(String shopId) =>
      categoryById(shopId)?.effectiveHours(_shopHoursSettings) ??
      _shopHoursSettings;

  bool isCategoryOpenNow(String shopId) =>
      effectiveHoursForCategory(shopId).isOpenAt(DateTime.now());

  /// The methods [shopId] accepts. Unknown categories accept all of them so
  /// existing drafts are never stranded.
  List<String> allowedMethodsForCategory(String shopId) =>
      categoryById(shopId)?.allowedMethods ?? Shop.allShoppingMethods;

  bool isMethodAllowedForCategory(String shopId, String method) =>
      allowedMethodsForCategory(shopId).contains(method);

  /// [selectedHomeCategory] re-resolved against the live category list.
  /// [setSelectedHomeCategory] keeps the snapshot it was handed, so the
  /// stored copy can carry stale shopping-method/hours settings after an
  /// admin edit; call sites that read those must go through this.
  Shop? get liveSelectedHomeCategory {
    final selected = _selectedHomeCategory;
    if (selected == null) {
      return null;
    }
    return categoryById(selected.shopId) ?? selected;
  }

  PaymentSettings get paymentSettings => _paymentSettings;
  bool get hasLoadedPaymentSettings => _hasLoadedPaymentSettings;
  PasswordResetStatusResult? get passwordResetTracker => _passwordResetTracker;
  bool get isCheckingPasswordResetTracker => _isCheckingPasswordResetTracker;
  int get cartCount =>
      _cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

  /// True when the customer has staged anything for an order: picked
  /// products, an attached photo list, or a typed manual list. The cart
  /// reminder on the customer screens keys off this, so a photo-only or
  /// manual-only draft nudges just like a cart full of products.
  bool get hasCartDraft =>
      _cartItems.isNotEmpty ||
      _photoLists.isNotEmpty ||
      _manualLists.isNotEmpty;

  /// What the cart badge counts: product quantities plus one per attached
  /// photo list and typed manual list, so a photo-only draft still reads as
  /// "1" instead of showing an empty cart.
  int get cartBadgeCount =>
      cartCount + _photoLists.length + _manualLists.length;

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

  /// Whether [item]'s product is still orderable according to the live
  /// catalog snapshot — drives the Cart screen's soft "no longer
  /// available" indicator. Returns true (no warning shown) when the
  /// product isn't in the snapshot yet/at all, matching [livePriceFor]'s
  /// same "unknown -> don't alarm the customer" fallback; the actual
  /// authoritative gate is the server recheck in [_resolveCheckoutItems],
  /// which runs at checkout regardless of what this getter shows.
  bool isCartItemAvailable(CartItem item) =>
      _catalogById[item.productId]?.isAvailable ?? true;

  double lineTotalFor(CartItem item) => livePriceFor(item) * item.quantity;

  /// True when the catalog price has moved away from what was cached in
  /// the cart when the item was added.
  bool isCartItemPriceStale(CartItem item) => livePriceFor(item) != item.price;

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
    _photoLists = await localStorageService.loadPhotoLists();
    _manualLists = await localStorageService.loadManualLists();
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
      await _categoriesSubscription?.cancel();
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
      _categories = const <Shop>[];
      _notificationsConfiguredForProfileKey = null;
      // Signed out (logout, expired or revoked session): this device must
      // stop receiving any account's pushes.
      unawaited(notificationService.releaseDevice());
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _watchCheckoutChargeSettings();
    _watchShopHoursSettings();
    _watchPaymentSettings();
    _watchProductCatalog();
    _watchCategories();

    _profileSubscription = firestoreService.watchUserProfile(user.uid).listen(
      (profile) async {
        if (_isLoggingOut || !_isCurrentAuthUser(user)) {
          return;
        }
        if (profile == null) {
          // The Firebase Auth session is live but its Firestore profile
          // document doesn't exist (an interrupted registration, or the
          // document was removed while the account was signed in). Without
          // signing out here, this same broken session would be restored
          // and hit this exact branch again on every future app launch,
          // leaving the customer stuck on a login screen with a session
          // that can never complete. logout() also cancels this very
          // subscription, which is safe to do from within its own
          // listener callback.
          await logout();
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
    _productCatalogSubscription =
        firestoreService.watchProducts(activeOnly: false).listen(
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

  /// Keeps [_categories] in sync with the live `shops` collection so
  /// per-category shopping methods and opening hours stay authoritative at
  /// checkout even if the admin changes them mid-session.
  void _watchCategories() {
    if (!firebaseAvailable) {
      return;
    }
    unawaited(_categoriesSubscription?.cancel());
    _categoriesSubscription =
        firestoreService.watchShops(activeOnly: false).listen(
      (shops) {
        _categories = shops;
        notifyListeners();
      },
      onError: (_) {
        // Keep the last-known category snapshot; the per-category helpers
        // fall back to the global hours and all methods when it is empty.
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
    _watchCategories();
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
    _categories = const <Shop>[];
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
      await notificationService.releaseDevice();
      await _checkoutChargeSettingsSubscription?.cancel();
      await _shopHoursSettingsSubscription?.cancel();
      await _paymentSettingsSubscription?.cancel();
      await _productCatalogSubscription?.cancel();
      await _categoriesSubscription?.cancel();
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
      await _categoriesSubscription?.cancel();
      await notificationService.releaseDevice();
      await localStorageService.clearPrivateAccountData();
      _profile = null;
      _cartItems = const <CartItem>[];
      _photoLists = const <DraftPhotoList>[];
      _manualLists = const <DraftManualList>[];
      _selectedHomeCategory = null;
      _notificationsConfiguredForProfileKey = null;
      _checkoutChargeSettings = CheckoutChargeSettings.defaults;
      _hasLoadedCheckoutChargeSettings = false;
      _shopHoursSettings = ShopHoursSettings.defaults;
      _hasLoadedShopHoursSettings = false;
      _paymentSettings = PaymentSettings.defaults;
      _hasLoadedPaymentSettings = false;
      _catalogById = const <String, Product>{};
      _categories = const <Shop>[];
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
      await _categoriesSubscription?.cancel();
      await notificationService.releaseDevice();
      await localStorageService.clearPrivateAccountData();
      _profile = null;
      _cartItems = const <CartItem>[];
      _photoLists = const <DraftPhotoList>[];
      _manualLists = const <DraftManualList>[];
      _selectedHomeCategory = null;
      _notificationsConfiguredForProfileKey = null;
      _checkoutChargeSettings = CheckoutChargeSettings.defaults;
      _hasLoadedCheckoutChargeSettings = false;
      _shopHoursSettings = ShopHoursSettings.defaults;
      _hasLoadedShopHoursSettings = false;
      _paymentSettings = PaymentSettings.defaults;
      _hasLoadedPaymentSettings = false;
      _catalogById = const <String, Product>{};
      _categories = const <Shop>[];
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
    _watchCategories();
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
    _ensureCategoryMethod(
      shopId: product.shopId,
      shopName: product.shopName,
      requestedMethod: OrderCategoryMethod.methodItems,
    );
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
    _photoLists = const <DraftPhotoList>[];
    _manualLists = const <DraftManualList>[];
    notifyListeners();
    await Future.wait([
      localStorageService.saveCart(_cartItems),
      localStorageService.savePhotoLists(_photoLists),
      localStorageService.saveManualLists(_manualLists),
    ]);
  }

  /// The category currently selected on the Home page, used to filter Fresh
  /// Picks/the "Items" shortcut and to scope which Photo List/Manual List
  /// entry [currentPhotoList]/[currentManualList]/[setBillImagePath]/
  /// [setManualListText] read and write. Held here (rather than as local
  /// widget state) because Photo List/Manual List are pushed as
  /// parameterless routes from several entry points and need a single,
  /// uniformly reachable source for "what category is selected right now."
  void setSelectedHomeCategory(Shop? shop) {
    if (_selectedHomeCategory?.shopId == shop?.shopId) {
      return;
    }
    _selectedHomeCategory = shop;
    notifyListeners();
  }

  /// Upserts (or, when [path] is empty, removes) the photo list entry for
  /// the currently selected Home category — every other category's entry
  /// is left untouched, so a Groceries photo and a Vegetables photo can
  /// coexist.
  Future<void> setBillImagePath(String? path) async {
    final key = _draftCategoryKey();
    if (path != null && path.isNotEmpty) {
      _ensureCategoryMethod(
        shopId: key,
        shopName: _draftCategoryName(),
        requestedMethod: OrderCategoryMethod.methodPhoto,
      );
    }
    final others = _photoLists.where((entry) => entry.shopId != key).toList();
    _photoLists = (path == null || path.isEmpty)
        ? others
        : [
            ...others,
            DraftPhotoList(
              shopId: key,
              shopName: _draftCategoryName(),
              imagePath: path,
            ),
          ];
    notifyListeners();
    await localStorageService.savePhotoLists(_photoLists);
  }

  /// Upserts (or, when [value] is blank, removes) the manual list entry for
  /// the currently selected Home category. See [setBillImagePath].
  Future<void> setManualListText(String value) async {
    final key = _draftCategoryKey();
    if (value.trim().isNotEmpty) {
      _ensureCategoryMethod(
        shopId: key,
        shopName: _draftCategoryName(),
        requestedMethod: OrderCategoryMethod.methodManual,
      );
    }
    final others = _manualLists.where((entry) => entry.shopId != key).toList();
    _manualLists = value.trim().isEmpty
        ? others
        : [
            ...others,
            DraftManualList(
              shopId: key,
              shopName: _draftCategoryName(),
              text: value,
            ),
          ];
    notifyListeners();
    await localStorageService.saveManualLists(_manualLists);
  }

  /// Removes one category's photo list entry, for the Cart screen's
  /// per-entry remove button.
  Future<void> removePhotoList(String shopId) async {
    _photoLists = _photoLists.where((entry) => entry.shopId != shopId).toList();
    notifyListeners();
    await localStorageService.savePhotoLists(_photoLists);
  }

  /// Removes one category's manual list entry. See [removePhotoList].
  Future<void> removeManualList(String shopId) async {
    _manualLists =
        _manualLists.where((entry) => entry.shopId != shopId).toList();
    notifyListeners();
    await localStorageService.saveManualLists(_manualLists);
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
    final incompleteCategory = _firstIncompleteCategoryName();
    if (incompleteCategory != null) {
      throw StateError(
        'Please complete the shopping method for $incompleteCategory.',
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
    _assertDraftCategoriesOrderable();
    if (!_paymentSettings.hasAvailablePaymentMethod) {
      throw StateError('Payment methods are temporarily unavailable.');
    }
    if (!_paymentSettings.isPaymentMethodEnabled(paymentMethod)) {
      throw StateError('This payment method is temporarily unavailable.');
    }
    final orderId = await _reservePendingOrderId();
    // Tracks every asset that finishes uploading below so that, if
    // anything after it fails (an item going unavailable, a dropped
    // connection, the write itself failing), those now-orphaned Cloudinary
    // assets can be reported for cleanup — see the catch block below (F11
    // fix). Never touched again once the order is actually created.
    final uploadedPublicIds = <String>[];
    try {
      final photoLists = <OrderPhotoList>[];
      for (final entry in _photoLists) {
        final uploaded = await ImageUploadService.uploadUserImage(
          imageFile: File(entry.imagePath),
          ownerUid: current.uid,
          folder: 'orders/$orderId',
          fileName:
              'shopping-list-${entry.shopId.isEmpty ? 'general' : entry.shopId}',
        );
        uploadedPublicIds.add(uploaded.publicId);
        photoLists.add(
          OrderPhotoList(
            shopId: entry.shopId,
            shopName: entry.shopName,
            imageUrl: uploaded.secureUrl,
            imagePublicId: uploaded.publicId,
          ),
        );
      }
      final manualLists = [
        for (final entry in _manualLists)
          OrderManualList(
            shopId: entry.shopId,
            shopName: entry.shopName,
            text: entry.text.trim(),
          ),
      ];
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
        uploadedPublicIds.add(paymentReceiptImage.publicId);
      }

      final resolvedItems = await _resolveCheckoutItems();
      final orderCategories = _buildOrderCategories(
        items: resolvedItems,
        photoLists: photoLists,
        manualLists: manualLists,
      );

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
        uploadedImageUrl: '',
        uploadedImagePublicId: '',
        manualListText: '',
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
            ? paymentReceiptImage == null
                ? 'pending'
                : 'receipt uploaded'
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
        photoLists: photoLists,
        manualLists: manualLists,
        categories: orderCategories,
      );

      await firestoreService.createOrder(order);
      _pendingOrderId = null;
      await localStorageService.clearPendingOrderId();
      await clearCheckoutDraft();
      return order;
    } catch (error) {
      if (uploadedPublicIds.isNotEmpty) {
        unawaited(ImageUploadService.reportOrphanedUploads(uploadedPublicIds));
      }
      rethrow;
    }
  }

  Future<void> uploadOrderPaymentReceipt({
    required OrderModel order,
    required String imagePath,
  }) async {
    final current = _profile;
    if (current == null) {
      throw StateError('Please login before uploading the receipt.');
    }
    if (current.isBlocked) {
      throw StateError('Blocked users cannot upload payment receipts.');
    }
    if (order.userId != current.uid) {
      throw StateError('You can only upload receipts for your own orders.');
    }
    if (order.paymentMethod != AppConstants.paymentMethodBankTransfer) {
      throw StateError(
          'Receipts can only be uploaded for bank transfer orders.');
    }
    if (order.hasPaymentReceipt) {
      throw StateError('A payment receipt has already been uploaded.');
    }
    if (!_canUploadPaymentReceiptForOrder(order)) {
      throw StateError(
        'Upload the receipt after the admin updates the final bill.',
      );
    }

    final uploaded = await ImageUploadService.uploadUserImage(
      imageFile: File(imagePath),
      ownerUid: current.uid,
      folder: 'orders/${order.orderId}',
      fileName: 'payment-receipt',
    );
    try {
      await firestoreService.updateOrderPaymentReceipt(
        order: order,
        imageUrl: uploaded.secureUrl,
        imagePublicId: uploaded.publicId,
      );
    } catch (error) {
      unawaited(ImageUploadService.reportOrphanedUploads([uploaded.publicId]));
      rethrow;
    }
  }

  bool _canUploadPaymentReceiptForOrder(OrderModel order) {
    const allowedStatuses = <String>{
      'Bill Updated',
      'Out for Delivery',
      'Delivered',
    };
    return allowedStatuses.contains(order.orderStatus);
  }

  String? _pendingOrderId;

  /// Returns the same order id across retries of the same checkout attempt
  /// (including across an app kill/relaunch, since it's persisted) instead
  /// of generating a fresh one every call. [FirestoreService.createOrder]
  /// uses this stability to recognize "this order already got created" and
  /// no-op instead of writing a duplicate. Cleared only once an order
  /// actually finishes creating successfully (see [createOrder]), so a
  /// later, genuinely separate order — even with identical cart contents —
  /// still gets its own fresh id.
  Future<String> _reservePendingOrderId() async {
    final existing =
        _pendingOrderId ??= await localStorageService.loadPendingOrderId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final reserved = _uuid.v4();
    _pendingOrderId = reserved;
    await localStorageService.savePendingOrderId(reserved);
    return reserved;
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

  /// Test-only seam: lets tests exercise per-category shopping methods and
  /// opening hours without a real Firestore stream.
  @visibleForTesting
  void debugSetCategoriesForTesting(List<Shop> categories) {
    _categories = categories;
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

  Map<String, Product>? _debugLatestProductsForTesting;

  /// Test-only seam: overrides what [_resolveCheckoutItems] treats as the
  /// server-authoritative product snapshot (price + availability), so the
  /// checkout recheck can be unit tested without a real Firestore
  /// connection. Pass `null` to clear the override.
  @visibleForTesting
  void debugSetLatestProductsForTesting(Map<String, Product>? products) {
    _debugLatestProductsForTesting = products;
  }

  /// Builds the [OrderItem]s [createOrder] would write for the current
  /// cart: re-verifies each item's price *and availability* against the
  /// Firestore server (falling back to the live-catalog/cached price only
  /// if that authoritative read itself is unavailable — e.g. offline, or
  /// [firebaseAvailable] is false), so neither a stale price nor an
  /// item the admin has since disabled/removed is silently carried into
  /// the order.
  ///
  /// Throws [CartItemsUnavailableException] — without creating anything —
  /// if the server confirms one or more items are no longer orderable.
  /// Only enforced when the authoritative snapshot was actually fetched
  /// (real or, in tests, injected via [debugSetLatestProductsForTesting]),
  /// so demo/offline mode (where [firebaseAvailable] is false and the
  /// fetch never runs at all) still falls back to the cached cart data
  /// instead of blocking checkout, the same way the price fallback
  /// already does.
  ///
  /// Exposed directly (rather than only inline inside [createOrder]) so
  /// this price-resolution/race-condition-guard behavior is unit
  /// testable without requiring a real Firestore write.
  Future<List<OrderItem>> _resolveCheckoutItems() async {
    final productIds =
        _cartItems.map((item) => item.productId).toSet().toList();
    final latestProducts = _debugLatestProductsForTesting ??
        await firestoreService.fetchLatestProducts(productIds);
    final hasAuthoritativeSnapshot =
        firebaseAvailable || _debugLatestProductsForTesting != null;

    if (hasAuthoritativeSnapshot) {
      final unavailableNames = <String>[];
      for (final item in _cartItems) {
        final latest = latestProducts[item.productId];
        if (latest == null || !latest.isAvailable) {
          unavailableNames.add(item.name);
        }
      }
      if (unavailableNames.isNotEmpty) {
        throw CartItemsUnavailableException(unavailableNames);
      }
    }

    return _cartItems.map((item) {
      final resolvedPrice =
          latestProducts[item.productId]?.price ?? livePriceFor(item);
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

  String? _firstIncompleteCategoryName() {
    for (final entry in _photoLists) {
      if (entry.imagePath.trim().isEmpty) {
        return _categoryDisplayName(entry.shopId, entry.shopName);
      }
    }
    for (final entry in _manualLists) {
      if (entry.text.trim().isEmpty) {
        return _categoryDisplayName(entry.shopId, entry.shopName);
      }
    }
    return null;
  }

  /// Re-checks every category in the current draft against the live
  /// category settings just before the order is written. The per-draft
  /// guards in [_ensureCategoryMethod] run when data is *added*, so a draft
  /// can go stale if the admin closes a category or drops one of its
  /// shopping methods while the customer is still shopping.
  void _assertDraftCategoriesOrderable() {
    final now = DateTime.now();
    final drafted = <String, ({String name, String method})>{};

    void touch(String shopId, String shopName, String method) {
      drafted.putIfAbsent(
        shopId.trim(),
        () => (name: _categoryDisplayName(shopId, shopName), method: method),
      );
    }

    for (final item in _cartItems) {
      touch(item.shopId, item.shopName, OrderCategoryMethod.methodItems);
    }
    for (final entry in _photoLists) {
      touch(entry.shopId, entry.shopName, OrderCategoryMethod.methodPhoto);
    }
    for (final entry in _manualLists) {
      touch(entry.shopId, entry.shopName, OrderCategoryMethod.methodManual);
    }

    for (final entry in drafted.entries) {
      final shopId = entry.key;
      final hours = effectiveHoursForCategory(shopId);
      if (!hours.isOpenAt(now)) {
        throw CategoryClosedException(
          categoryName: entry.value.name,
          hours: hours,
        );
      }
      if (!isMethodAllowedForCategory(shopId, entry.value.method)) {
        throw CategoryMethodNotAllowedException(
          categoryName: entry.value.name,
          method: entry.value.method,
        );
      }
    }
  }

  List<OrderCategoryMethod> _buildOrderCategories({
    required List<OrderItem> items,
    required List<OrderPhotoList> photoLists,
    required List<OrderManualList> manualLists,
  }) {
    final order = <String>[];
    final names = <String, String>{};
    final itemBuckets = <String, List<OrderItem>>{};
    final photoBuckets = <String, List<OrderPhotoList>>{};
    final manualBuckets = <String, List<OrderManualList>>{};

    void touch(String id, String name) {
      if (!names.containsKey(id)) {
        order.add(id);
        names[id] = name;
      } else if ((names[id] ?? '').trim().isEmpty && name.trim().isNotEmpty) {
        names[id] = name;
      }
    }

    for (final item in items) {
      touch(item.shopId, item.shopName);
      itemBuckets.putIfAbsent(item.shopId, () => <OrderItem>[]).add(item);
    }
    for (final list in photoLists) {
      touch(list.shopId, list.shopName);
      photoBuckets.putIfAbsent(list.shopId, () => <OrderPhotoList>[]).add(list);
    }
    for (final list in manualLists) {
      touch(list.shopId, list.shopName);
      manualBuckets
          .putIfAbsent(list.shopId, () => <OrderManualList>[])
          .add(list);
    }

    return [
      for (final id in order)
        OrderCategoryMethod(
          categoryId: id,
          categoryName: names[id] ?? '',
          selectedMethod: photoBuckets.containsKey(id)
              ? OrderCategoryMethod.methodPhoto
              : manualBuckets.containsKey(id)
                  ? OrderCategoryMethod.methodManual
                  : OrderCategoryMethod.methodItems,
          photoList: photoBuckets.containsKey(id)
              ? OrderCategoryPhotoList(images: photoBuckets[id]!)
              : null,
          manualList: manualBuckets.containsKey(id)
              ? OrderCategoryManualList(
                  text: manualBuckets[id]!
                      .map((entry) => entry.text.trim())
                      .join('\n'),
                )
              : null,
          selectedItems: itemBuckets[id] ?? const <OrderItem>[],
        ),
    ];
  }

  /// Test-only seam: lets tests assert on the race-condition-guarded
  /// checkout item resolution ([_resolveCheckoutItems]) directly.
  @visibleForTesting
  Future<List<OrderItem>> debugResolveCheckoutItemsForTesting() =>
      _resolveCheckoutItems();

  /// Test-only seam: exposes the id [_reservePendingOrderId] would return
  /// right now (reserving/persisting one first if none exists yet), so
  /// tests can assert it stays stable across a retried [createOrder] call.
  @visibleForTesting
  Future<String> debugReservePendingOrderIdForTesting() =>
      _reservePendingOrderId();

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _checkoutChargeSettingsSubscription?.cancel();
    _shopHoursSettingsSubscription?.cancel();
    _paymentSettingsSubscription?.cancel();
    _productCatalogSubscription?.cancel();
    _categoriesSubscription?.cancel();
    unawaited(connectivityService.dispose());
    notificationService.dispose();
    super.dispose();
  }
}
