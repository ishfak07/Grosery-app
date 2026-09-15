import 'package:shared_preferences/shared_preferences.dart';

import '../core/i18n/language_codes.dart';
import '../models/models.dart';

class LocalStorageService {
  static const _cartKey = 'cart_items';
  static const _photoListsKey = 'photo_lists';
  static const _manualListsKey = 'manual_lists';
  static const _onboardingKey = 'has_seen_onboarding';
  static const _addressDraftKey = 'address_draft';
  static const _preferredLanguageKey = 'preferred_language_code';
  static const _notificationPermissionRequestedKey =
      'notification_permission_requested';
  static const _passwordResetRequestIdKey = 'password_reset_request_id';
  static const _pendingOrderIdKey = 'pending_order_id';

  Future<List<CartItem>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_cartKey) ?? const <String>[])
        .map(CartItem.fromJson)
        .toList();
  }

  Future<void> saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cartKey,
      items.map((item) => item.toJson()).toList(),
    );
  }

  Future<List<DraftPhotoList>> loadPhotoLists() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_photoListsKey) ?? const <String>[])
        .map(DraftPhotoList.fromJson)
        .toList();
  }

  Future<void> savePhotoLists(List<DraftPhotoList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _photoListsKey,
      lists.map((list) => list.toJson()).toList(),
    );
  }

  Future<List<DraftManualList>> loadManualLists() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_manualListsKey) ?? const <String>[])
        .map(DraftManualList.fromJson)
        .toList();
  }

  Future<void> saveManualLists(List<DraftManualList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _manualListsKey,
      lists.map((list) => list.toJson()).toList(),
    );
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<void> saveAddressDraft(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressDraftKey, value);
  }

  Future<void> clearPrivateAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_cartKey),
      prefs.remove(_photoListsKey),
      prefs.remove(_manualListsKey),
      prefs.remove(_addressDraftKey),
      prefs.remove(_pendingOrderIdKey),
    ]);
  }

  Future<String?> loadAddressDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_addressDraftKey);
  }

  Future<String> loadPreferredLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguageCodes.normalize(prefs.getString(_preferredLanguageKey));
  }

  Future<void> savePreferredLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _preferredLanguageKey,
      AppLanguageCodes.normalize(languageCode),
    );
  }

  Future<bool> hasRequestedNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPermissionRequestedKey) ?? false;
  }

  Future<void> setNotificationPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermissionRequestedKey, true);
  }

  /// Only the opaque Firestore request id is kept — no phone number, no
  /// status, nothing else. The id alone lets the Login-page tracker re-check
  /// this request through a secure Cloud Function without storing anything
  /// sensitive on the device.
  Future<String?> loadPasswordResetRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordResetRequestIdKey);
  }

  Future<void> savePasswordResetRequestId(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordResetRequestIdKey, requestId);
  }

  Future<void> clearPasswordResetRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordResetRequestIdKey);
  }

  /// The client-generated order id reserved for the checkout attempt
  /// currently in flight (or that never got a confirmed response). Reusing
  /// this same id across retries — instead of generating a fresh one every
  /// call — is what lets order creation detect and no-op a retry instead of
  /// creating a duplicate order (see [FirestoreService.createOrder]).
  Future<String?> loadPendingOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingOrderIdKey);
  }

  Future<void> savePendingOrderId(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOrderIdKey, orderId);
  }

  Future<void> clearPendingOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOrderIdKey);
  }
}
