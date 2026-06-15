import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/features/customer/customer_screens.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('profile logout rebuild does not show a red error screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appState = _LogoutTestAppState(_customerProfile());

    await tester.pumpWidget(_wrapWithAppState(appState, const ProfileScreen()));
    await tester.pumpAndSettle();

    final logoutButton = find.ancestor(
      of: find.text('Logout'),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );
    await tester.ensureVisible(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Logging out...'), findsOneWidget);
  });

  testWidgets('customer home tolerates profile clearing during logout',
      (tester) async {
    final appState = _LogoutTestAppState(_customerProfile());

    await tester.pumpWidget(
      _wrapWithAppState(appState, const CustomerHomeScreen()),
    );
    await tester.pump();

    appState.clearProfile();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Logging out...'), findsOneWidget);
  });

  testWidgets('profile does not reveal home while logout is still running',
      (tester) async {
    final appState = _DelayedLogoutTestAppState(_customerProfile());

    await tester.pumpWidget(
      _wrapWithAppState(
        appState,
        const Scaffold(body: Center(child: Text('Customer home'))),
      ),
    );
    final rootContext = tester.element(find.text('Customer home'));
    Navigator.of(rootContext).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pump();

    expect(appState.logoutStarted, isTrue);
    expect(find.text('Logging out...'), findsOneWidget);
    expect(find.text('Customer home'), findsNothing);

    appState.completeLogout();
    await tester.pumpAndSettle();

    expect(find.text('Customer home'), findsOneWidget);
  });
}

Widget _wrapWithAppState(AppState appState, Widget child) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(home: child),
  );
}

UserProfile _customerProfile() {
  final now = DateTime(2026);
  return UserProfile(
    uid: 'customer-1',
    fullName: 'Test Customer',
    phone: '+94770000000',
    hiddenEmail: '94770000000@app.local',
    role: 'user',
    address: 'Puttalam',
    createdAt: now,
    updatedAt: now,
    isPhoneVerified: true,
    isBlocked: false,
  );
}

class _LogoutTestAppState extends AppState {
  _LogoutTestAppState(this._testProfile)
      : super(
          const FirebaseBootstrap(
            isReady: false,
            errorMessage: 'Firebase unavailable in logout transition test',
          ),
        );

  UserProfile? _testProfile;

  @override
  UserProfile? get profile => _testProfile;

  @override
  bool get isLoggedIn => _testProfile != null;

  @override
  bool get isAdmin => _testProfile?.isAdmin ?? false;

  @override
  Future<void> logout() async {
    clearProfile();
  }

  void clearProfile() {
    _testProfile = null;
    notifyListeners();
  }
}

class _DelayedLogoutTestAppState extends _LogoutTestAppState {
  _DelayedLogoutTestAppState(super.profile);

  final _logoutCompleter = Completer<void>();
  var logoutStarted = false;

  @override
  Future<void> logout() async {
    logoutStarted = true;
    await _logoutCompleter.future;
  }

  void completeLogout() {
    _logoutCompleter.complete();
  }
}
