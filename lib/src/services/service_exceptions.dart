class FirebaseUnavailableException implements Exception {
  const FirebaseUnavailableException();

  @override
  String toString() {
    return 'Firebase is not configured yet. Add real Firebase config files and run flutterfire configure.';
  }
}
