import 'package:shared_preferences/shared_preferences.dart';

import '../core/i18n/language_codes.dart';
import '../models/models.dart';

class LocalStorageService {
  static const _cartKey = 'cart_items';
  static const _billImageKey = 'bill_image_path';
  static const _onboardingKey = 'has_seen_onboarding';
  static const _addressDraftKey = 'address_draft';
  static const _preferredLanguageKey = 'preferred_language_code';

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

  Future<String?> loadBillImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_billImageKey);
  }

  Future<void> saveBillImagePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_billImageKey);
      return;
    }
    await prefs.setString(_billImageKey, path);
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
}
