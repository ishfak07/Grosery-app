import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/features/auth/auth_screens.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  final screens = <String, (Widget, List<String>)>{
    'login': (
      const LoginScreen(),
      ['Welcome back', 'Login', 'Create account', 'Forgot password?'],
    ),
    'create account': (
      const RegisterDetailsScreen(),
      ['Create account', 'Full name', 'Delivery address', 'Confirm password'],
    ),
    'forgot password': (
      const ForgotPasswordPhoneScreen(),
      ['Reset securely'],
    ),
  };

  for (final MapEntry(key: name, value: (screen, texts)) in screens.entries) {
    for (final size in const [
      Size(360, 640),
      Size(412, 915),
      Size(1024, 768)
    ]) {
      testWidgets(
          '$name screen lays out without overflow at '
          '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: AppState(
              const FirebaseBootstrap(
                isReady: false,
                errorMessage: 'Firebase unavailable in auth layout test',
              ),
            ),
            child: MaterialApp(home: screen),
          ),
        );
        // The header art loops forever, so advance with fixed pumps.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }

        expect(tester.takeException(), isNull);
        final scrollable = find.byType(Scrollable).first;
        for (final text in texts) {
          await tester.scrollUntilVisible(
            find.text(text).last,
            150,
            scrollable: scrollable,
          );
          expect(find.text(text), findsWidgets);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
