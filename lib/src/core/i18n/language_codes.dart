class AppLanguageCodes {
  const AppLanguageCodes._();

  static const english = 'en';
  static const tamil = 'ta';
  static const supported = <String>[english, tamil];

  static String normalize(String? languageCode) {
    return languageCode == tamil ? tamil : english;
  }

  static String englishName(String languageCode) {
    return normalize(languageCode) == tamil ? 'Tamil' : 'English';
  }

  static String nativeName(String languageCode) {
    return normalize(languageCode) == tamil ? 'தமிழ்' : 'English';
  }
}
