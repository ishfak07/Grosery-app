import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/features/auth/auth_screens.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  for (final size in const [Size(360, 640), Size(412, 915), Size(1024, 768)]) {
    testWidgets(
        'onboarding pages lay out without overflow at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final appState = _OnboardingTestAppState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );

      const titles = [
        'Everything you need in one place',
        'Upload a shopping list',
        'Cash on delivery',
      ];
      for (var page = 0; page < titles.length; page++) {
        // The illustrations loop forever, so advance with fixed pumps.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        expect(tester.takeException(), isNull);
        expect(find.text(titles[page]), findsOneWidget);
        final isLast = page == titles.length - 1;
        expect(find.text(isLast ? 'Get started' : 'Next'), findsOneWidget);
        await tester.tap(find.text(isLast ? 'Get started' : 'Next'));
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(appState.onboardingCompleted, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}

class _OnboardingTestAppState extends AppState {
  _OnboardingTestAppState()
      : super(
          const FirebaseBootstrap(
            isReady: false,
            errorMessage: 'Firebase unavailable in onboarding layout test',
          ),
        );

  var onboardingCompleted = false;

  @override
  Future<void> markOnboardingComplete() async {
    onboardingCompleted = true;
  }
}
