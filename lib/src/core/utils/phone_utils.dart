class PhoneUtils {
  const PhoneUtils._();

  static String normalizeSriLankanPhone(String raw) {
    final compact = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (compact.isEmpty) {
      return compact;
    }
    if (compact.startsWith('+')) {
      return '+${compact.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    final digits = compact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length >= 9) {
      return '+94${digits.substring(1)}';
    }
    if (digits.startsWith('94')) {
      return '+$digits';
    }
    return '+$digits';
  }

  static String hiddenEmailForPhone(String phone) {
    final digits =
        normalizeSriLankanPhone(phone).replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@app.local';
  }
}
