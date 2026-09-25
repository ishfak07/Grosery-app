import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/features/auth/auth_screens.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // The auth scenes loop forever, so settle with fixed pumps.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('back from Login shows the intro screens, back again returns',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = _AuthFlowTestAppState();
    await appState.markOnboardingComplete();
    await tester.pumpWidget(_TestRoot(appState: appState));
    await settle(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(appState.isReplayingOnboarding, isTrue);

    // Page 2 -> back goes to page 1, not Login.
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Upload a shopping list'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Everything you need in one place'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(appState.hasSeenOnboarding, isTrue);
    expect(appState.isReplayingOnboarding, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('How it works on Login opens the intro screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = _AuthFlowTestAppState();
    await appState.markOnboardingComplete();
    await tester.pumpWidget(_TestRoot(appState: appState));
    await settle(tester);

    await tester.tap(find.text('How it works'));
    await settle(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating an account shows the success popup, then Login',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = _AuthFlowTestAppState();
    await appState.markOnboardingComplete();
    await tester.pumpWidget(_TestRoot(appState: appState));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
    await settle(tester);
    expect(find.byType(RegisterDetailsScreen), findsOneWidget);

    final fields = find.descendant(
      of: find.byType(RegisterDetailsScreen),
      matching: find.byType(EditableText),
    );
    await tester.enterText(fields.at(0), 'Test Customer');
    await tester.enterText(fields.at(1), '771234567');
    await tester.enterText(fields.at(2), '12 Main Street');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.enterText(fields.at(4), 'secret123');
    await tester.tap(find.byIcon(Icons.check_circle));
    await settle(tester);

    expect(appState.registrationCalls, 1);
    expect(appState.isLoggedIn, isFalse);
    expect(find.text('Account created successfully!'), findsOneWidget);

    await tester.tap(find.text('Go to login'));
    await settle(tester);
    expect(find.text('Account created successfully!'), findsNothing);
    expect(find.byType(RegisterDetailsScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestRoot extends StatelessWidget {
  const _TestRoot({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        home: Consumer<AppState>(
          builder: (context, state, _) => state.hasSeenOnboarding
              ? const LoginScreen()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}

class _AuthFlowTestAppState extends AppState {
  _AuthFlowTestAppState()
      : super(
          const FirebaseBootstrap(
            isReady: false,
            errorMessage: 'Firebase unavailable in auth flow test',
          ),
        );

  var registrationCalls = 0;

  // The Create account button is disabled without Firebase.
  @override
  bool get firebaseAvailable => true;

  @override
  Future<void> completeRegistration({
    required String fullName,
    required String phone,
    required String address,
    required String password,
    required String preferredLanguageCode,
  }) async {
    registrationCalls++;
  }
}
