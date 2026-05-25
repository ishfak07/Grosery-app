import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
          'This MVP is configured for Android and iOS only.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
            'This MVP is configured for Android and iOS only.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDAtj58p_V5l9JcnkqC5SyoNXtSFgRFm1U',
    appId: '1:471895063005:android:9864a4a2f11d8e68859e34',
    messagingSenderId: '471895063005',
    projectId: 'grocery-delivery-app-388bc',
    storageBucket: 'grocery-delivery-app-388bc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB60FN0NH87vE7fN--t2kWDn12hVU4LYNw',
    appId: '1:471895063005:ios:12fdd5511cad0087859e34',
    messagingSenderId: '471895063005',
    projectId: 'grocery-delivery-app-388bc',
    storageBucket: 'grocery-delivery-app-388bc.firebasestorage.app',
    iosBundleId: 'com.ishi.grocerydelivery',
  );
}
