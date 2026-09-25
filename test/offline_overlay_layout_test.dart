import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/widgets/common_widgets.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  for (final size in const [
    Size(320, 568),
    Size(360, 640),
    Size(412, 915),
    Size(1024, 768),
  ]) {
    testWidgets(
        'offline overlay lays out without overflow at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final appState = AppState(
        const FirebaseBootstrap(
          isReady: false,
          errorMessage: 'Firebase unavailable in offline overlay test',
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            builder: (context, child) =>
                OfflineConnectionOverlay(child: child!),
            home: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      expect(find.text('No Internet Connection'), findsNothing);

      appState.markInternetUnavailable();
      // The illustration loops forever, so advance with fixed pumps.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Airplane mode'), findsOneWidget);
    });
  }
}
