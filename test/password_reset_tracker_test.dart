import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/features/auth/auth_screens.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/auth_service.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppState.refreshPasswordResetTracker resilience', () {
    testWidgets(
        'a transient failure (offline / callable not deployed yet) does '
        'not clear an existing tracker', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState(
        const FirebaseBootstrap(
          isReady: false,
          errorMessage: 'Firebase unavailable in this test',
        ),
      );
      await appState.trackPasswordResetRequest(_status('pending'));
      expect(appState.passwordResetTracker, isNotNull);

      // authService throws because Firebase is unavailable here - this must
      // be treated the same as "network/deploy hiccup", not "bad token".
      await appState.refreshPasswordResetTracker();

      expect(appState.passwordResetTracker, isNotNull);
      expect(appState.passwordResetTracker!.status, 'pending');
      expect(appState.isCheckingPasswordResetTracker, isFalse);
    });
  });

  group('Login page password-reset tracker', () {
    testWidgets('no reset request: tracker is hidden', (tester) async {
      final appState = _TrackerTestAppState(tracker: null);

      await tester.pumpWidget(_wrapWithAppState(appState));
      await tester.pumpAndSettle();

      expect(find.text('Password Reset Request'), findsNothing);
    });

    testWidgets('pending request: shows Pending status and Refresh Status',
        (tester) async {
      final appState = _TrackerTestAppState(tracker: _status('pending'));

      await tester.pumpWidget(_wrapWithAppState(appState));
      await tester.pumpAndSettle();

      expect(find.text('Password Reset Request'), findsOneWidget);
      expect(find.textContaining('Pending'), findsOneWidget);
      expect(find.text('Refresh status'), findsOneWidget);
      expect(find.text('Continue password reset'), findsNothing);
      expect(find.text('Submit new request'), findsNothing);

      await tester.ensureVisible(find.text('Refresh status'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh status'));
      await tester.pump();
      expect(appState.refreshCalls, 1);
    });

    testWidgets(
        'approved request: shows Continue Password Reset which opens the '
        'existing secure reset screen', (tester) async {
      final appState = _TrackerTestAppState(tracker: _status('approved'));

      await tester.pumpWidget(_wrapWithAppState(appState));
      await tester.pumpAndSettle();

      expect(find.textContaining('Approved'), findsOneWidget);
      expect(find.text('Continue password reset'), findsOneWidget);
      expect(find.text('Refresh status'), findsNothing);

      await tester.ensureVisible(find.text('Continue password reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue password reset'));
      await tester.pumpAndSettle();

      // Reuses the existing ResetPasswordScreen, not a new flow.
      expect(find.text('Set new password'), findsOneWidget);
    });

    testWidgets(
        'rejected request: shows rejection status and Submit New Request',
        (tester) async {
      final appState = _TrackerTestAppState(tracker: _status('rejected'));

      await tester.pumpWidget(_wrapWithAppState(appState));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rejected'), findsOneWidget);
      expect(find.text('Submit new request'), findsOneWidget);
      expect(find.text('Continue password reset'), findsNothing);
    });

    testWidgets('expired request: blocks reset and offers Submit New Request',
        (tester) async {
      final appState = _TrackerTestAppState(tracker: _status('expired'));

      await tester.pumpWidget(_wrapWithAppState(appState));
      await tester.pumpAndSettle();

      expect(find.textContaining('Expired'), findsOneWidget);
      expect(find.text('Submit new request'), findsOneWidget);
      expect(find.text('Continue password reset'), findsNothing);
    });

    testWidgets('completed request: no action buttons, nothing left to reuse',
        (tester) async {
      final appState = _TrackerTestAppState(tracker: _status('completed'));

      await tester.pumpWidget(_wrapWithAppState(appState));
      await tester.pumpAndSettle();

      expect(find.textContaining('Completed'), findsOneWidget);
      expect(find.text('Continue password reset'), findsNothing);
      expect(find.text('Submit new request'), findsNothing);
      expect(find.text('Refresh status'), findsNothing);
    });
  });

  group('PasswordResetStatusResult', () {
    test('status getters classify every known status', () {
      expect(_status('pending').isPending, isTrue);
      expect(_status('approved').isApproved, isTrue);
      expect(_status('rejected').isRejected, isTrue);
      expect(_status('completed').isCompleted, isTrue);
      expect(_status('expired').isExpired, isTrue);
    });
  });

  group('PasswordResetRequest.effectiveStatus (admin display)', () {
    test('approved request without expiresAt never auto-expires', () {
      final request = _adminRequest(status: 'approved', expiresAt: null);
      expect(request.isApprovalExpired, isFalse);
      expect(request.effectiveStatus, 'approved');
    });

    test('approved request expires once past expiresAt', () {
      final request = _adminRequest(
        status: 'approved',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(request.isApprovalExpired, isTrue);
      expect(request.effectiveStatus, 'expired');
    });

    test('approved request before expiresAt is still approved', () {
      final request = _adminRequest(
        status: 'approved',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(request.isApprovalExpired, isFalse);
      expect(request.effectiveStatus, 'approved');
    });

    test('non-approved statuses are never treated as expired', () {
      for (final status in ['pending', 'rejected', 'completed']) {
        final request = _adminRequest(
          status: status,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(request.isApprovalExpired, isFalse, reason: status);
        expect(request.effectiveStatus, status, reason: status);
      }
    });
  });
}

PasswordResetStatusResult _status(String status) {
  return PasswordResetStatusResult(
    requestId: 'request-1',
    status: status,
    phone: '+94770000000',
    customerName: 'Test Customer',
    message: 'message',
  );
}

PasswordResetRequest _adminRequest({
  required String status,
  required DateTime? expiresAt,
}) {
  final now = DateTime(2026);
  return PasswordResetRequest(
    requestId: 'request-1',
    userId: 'user-1',
    customerName: 'Test Customer',
    phone: '+94770000000',
    hiddenEmail: '94770000000@app.local',
    status: status,
    createdAt: now,
    updatedAt: now,
    expiresAt: expiresAt,
  );
}

Widget _wrapWithAppState(AppState appState) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: const MaterialApp(home: LoginScreen()),
  );
}

class _TrackerTestAppState extends AppState {
  _TrackerTestAppState({required this.tracker})
      : super(
          const FirebaseBootstrap(
            isReady: false,
            errorMessage: 'Firebase unavailable in tracker test',
          ),
        );

  PasswordResetStatusResult? tracker;
  var refreshCalls = 0;

  @override
  PasswordResetStatusResult? get passwordResetTracker => tracker;

  @override
  bool get isCheckingPasswordResetTracker => false;

  @override
  Future<void> refreshPasswordResetTracker() async {
    refreshCalls += 1;
  }
}
