import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap({
    required this.isReady,
    this.errorMessage,
  });

  final bool isReady;
  final String? errorMessage;

  static Future<FirebaseBootstrap> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (_isPlaceholder(options)) {
        return const FirebaseBootstrap(
          isReady: false,
          errorMessage:
              'Firebase is not configured yet. Run flutterfire configure and replace the platform config files.',
        );
      }

      if (Firebase.apps.isNotEmpty) {
        return const FirebaseBootstrap(isReady: true);
      }

      await Firebase.initializeApp(options: options);
      return const FirebaseBootstrap(isReady: true);
    } catch (error) {
      if (error is FirebaseException && error.code == 'duplicate-app') {
        return const FirebaseBootstrap(isReady: true);
      }

      return FirebaseBootstrap(
        isReady: false,
        errorMessage: error.toString(),
      );
    }
  }

  static bool _isPlaceholder(FirebaseOptions options) {
    return options.projectId == 'replace-with-firebase-project' ||
        options.apiKey.startsWith('REPLACE_WITH_') ||
        options.messagingSenderId == '000000000000';
  }
}
