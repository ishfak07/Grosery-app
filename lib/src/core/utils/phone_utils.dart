class PhoneUtils {
  const PhoneUtils._();

  static final RegExp _sriLankanMobilePattern = RegExp(r'^7[0-9]{8}$');

  static String normalizeSriLankanPhone(String raw) {
    final compact = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (compact.isEmpty) {
      return compact;
    }
    if (compact.startsWith('+')) {
      return '+${compact.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    final digits = compact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 9) {
      return '+94$digits';
    }
    if (digits.startsWith('0') && digits.length >= 9) {
      return '+94${digits.substring(1)}';
    }
    if (digits.startsWith('94')) {
      return '+$digits';
    }
    return '+$digits';
  }

  static bool isSriLankanMobile(String raw) {
    return _sriLankanMobilePattern.hasMatch(localSriLankanDigits(raw));
  }

  static String localSriLankanDigits(String raw) {
    final normalized = normalizeSriLankanPhone(raw);
    final digits = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('94') && digits.length > 2) {
      return digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length > 1) {
      return digits.substring(1);
    }
    return digits;
  }

  static String hiddenEmailForPhone(String phone) {
    final digits =
        normalizeSriLankanPhone(phone).replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@app.local';
  }
}
