import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/services/firebase_bootstrap.dart';
import 'src/services/notification_service.dart';
import 'src/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseBootstrap = await FirebaseBootstrap.initialize();
  if (firebaseBootstrap.isReady) {
    NotificationService.registerBackgroundHandler();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(firebaseBootstrap)..initialize(),
      child: const GroceryDeliveryApp(),
    ),
  );
}
