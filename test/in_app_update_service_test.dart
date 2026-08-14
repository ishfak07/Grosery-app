import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/services/in_app_update_service.dart';
import 'package:grocerydelivery/src/core/theme/app_theme.dart';
import 'package:grocerydelivery/src/core/widgets/in_app_update_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mirrors the channel names used by the `in_app_update` package so we can
// fake Google Play's responses without touching real platform code.
const _methodChannel = MethodChannel('de.ffuf.in_app_update/methods');
const _eventChannel = EventChannel('de.ffuf.in_app_update/stateEvents');

Map<String, dynamic> _updateInfo({
  required int updateAvailability,
  required int installStatus,
  bool flexibleAllowed = true,
}) {
  return <String, dynamic>{
    'updateAvailability': updateAvailability,
    'immediateAllowed': false,
    'immediateAllowedPreconditions': <int>[],
    'flexibleAllowed': flexibleAllowed,
    'flexibleAllowedPreconditions': <int>[],
    'availableVersionCode': 42,
    'installStatus': installStatus,
    'packageName': 'com.puttalam.drop',
    'clientVersionStalenessDays': null,
    'updatePriority': 0,
  };
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

/// `pumpAndSettle` never returns while an indeterminate
/// [CircularProgressIndicator]/[LinearProgressIndicator] is animating (by
/// design, since real progress data isn't available), so state/pending/
/// downloading/installing cards must be settled with a couple of bounded
/// pumps instead.
Future<void> _settleIndeterminate(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  var checkForUpdateCalls = 0;
  var startFlexibleUpdateCalls = 0;
  var completeFlexibleUpdateCalls = 0;
  Object Function()? checkForUpdateResponse;
  Object? Function()? startFlexibleUpdateResponse;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await InAppUpdateService.resetForTesting();

    checkForUpdateCalls = 0;
    startFlexibleUpdateCalls = 0;
    completeFlexibleUpdateCalls = 0;
    checkForUpdateResponse = () => _updateInfo(
          updateAvailability: 2,
          installStatus: 0,
        );
    startFlexibleUpdateResponse = () => null;

    messenger.setMockMethodCallHandler(_methodChannel, (call) async {
      switch (call.method) {
        case 'checkForUpdate':
          checkForUpdateCalls++;
          return checkForUpdateResponse!();
        case 'startFlexibleUpdate':
          startFlexibleUpdateCalls++;
          final response = startFlexibleUpdateResponse!();
          if (response is PlatformException) {
            throw response;
          }
          return response;
        case 'completeFlexibleUpdate':
          completeFlexibleUpdateCalls++;
          return null;
        default:
          return null;
      }
    });

    messenger.setMockStreamHandler(
      _eventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {},
      ),
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_methodChannel, null);
    messenger.setMockStreamHandler(_eventChannel, null);
  });

  group('InAppUpdateState', () {
    test('isActive reflects only in-flight update stages', () {
      const activeStages = [
        InAppUpdateStage.pending,
        InAppUpdateStage.downloading,
        InAppUpdateStage.downloaded,
        InAppUpdateStage.installing,
      ];
      const inactiveStages = [
        InAppUpdateStage.idle,
        InAppUpdateStage.checking,
        InAppUpdateStage.available,
        InAppUpdateStage.failed,
      ];

      for (final stage in activeStages) {
        expect(InAppUpdateState(stage: stage).isActive, isTrue,
            reason: '$stage should be active');
      }
      for (final stage in inactiveStages) {
        expect(InAppUpdateState(stage: stage).isActive, isFalse,
            reason: '$stage should not be active');
      }
    });

    test('copyWith clears percentage and error only when requested', () {
      const original = InAppUpdateState(
        stage: InAppUpdateStage.downloading,
        downloadPercentage: 40,
        errorMessage: 'boom',
      );

      final clearedPercentage =
          original.copyWith(clearDownloadPercentage: true);
      expect(clearedPercentage.downloadPercentage, isNull);
      expect(clearedPercentage.errorMessage, 'boom');

      final clearedError = original.copyWith(clearErrorMessage: true);
      expect(clearedError.errorMessage, isNull);
      expect(clearedError.downloadPercentage, 40);
    });
  });

  group('Update available (STATE 1) + download tap (STATE 2)', () {
    testWidgets('shows dialog and switches to downloading immediately',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ElevatedButton(
                onPressed: () =>
                    InAppUpdateService.checkForUpdate(capturedContext),
                child: const Text('check'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Download update'), findsOneWidget);

      await tester.tap(find.text('Download update'));
      // The service flips its state to `downloading` synchronously, before
      // the dialog-dismiss frame even settles, so the caller never sees a
      // bare spinner.
      expect(
        InAppUpdateService.state.value.stage,
        InAppUpdateStage.downloading,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('Later respects the 24-hour cooldown', (tester) async {
      expect(await InAppUpdateService.shouldShowUpdatePrompt(), isTrue);

      late BuildContext capturedContext;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ElevatedButton(
                onPressed: () =>
                    InAppUpdateService.checkForUpdate(capturedContext),
                child: const Text('check'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(await InAppUpdateService.shouldShowUpdatePrompt(), isFalse);
    });
  });

  group('InAppUpdateOverlay UI states', () {
    testWidgets('idle stage renders nothing', (tester) async {
      await tester.pumpWidget(
        _wrap(const InAppUpdateOverlay(child: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('update-hidden')), findsOneWidget);
    });

    testWidgets('pending stage shows "Preparing update…"', (tester) async {
      InAppUpdateService.state.value =
          const InAppUpdateState(stage: InAppUpdateStage.pending);

      await tester.pumpWidget(
        _wrap(const InAppUpdateOverlay(child: SizedBox.shrink())),
      );
      await _settleIndeterminate(tester);

      expect(find.text('Preparing update…'), findsOneWidget);
    });

    testWidgets(
        'downloading without byte progress shows indeterminate bar and '
        'no fake percentage', (tester) async {
      InAppUpdateService.state.value =
          const InAppUpdateState(stage: InAppUpdateStage.downloading);

      await tester.pumpWidget(
        _wrap(const InAppUpdateOverlay(child: SizedBox.shrink())),
      );
      await _settleIndeterminate(tester);

      expect(find.text('Downloading update'), findsOneWidget);
      expect(
        find.text('Downloading update from Google Play…'),
        findsOneWidget,
      );
      expect(
        find.text(
          'You can continue using Puttalam Drop while the update '
          'downloads.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('%'), findsNothing);

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, isNull);
    });

    testWidgets('downloading only shows a percentage when real data exists',
        (tester) async {
      InAppUpdateService.state.value = const InAppUpdateState(
        stage: InAppUpdateStage.downloading,
        downloadPercentage: 62,
      );

      await tester.pumpWidget(
        _wrap(const InAppUpdateOverlay(child: SizedBox.shrink())),
      );
      await _settleIndeterminate(tester);

      expect(find.textContaining('62%'), findsOneWidget);
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.62, 0.0001));
    });

    testWidgets(
        'downloaded stage shows Install & restart and calls '
        'completeFlexibleUpdate', (tester) async {
      InAppUpdateService.state.value =
          const InAppUpdateState(stage: InAppUpdateStage.downloaded);

      await tester.pumpWidget(
        _wrap(const InAppUpdateOverlay(child: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update ready'), findsOneWidget);
      expect(find.text('Install & restart'), findsOneWidget);

      await tester.tap(find.text('Install & restart'));
      await _settleIndeterminate(tester);

      expect(completeFlexibleUpdateCalls, 1);
      expect(
        InAppUpdateService.state.value.stage,
        InAppUpdateStage.installing,
      );
    });

    testWidgets('failed stage shows a friendly message with Later/Try again',
        (tester) async {
      InAppUpdateService.state.value = const InAppUpdateState(
        stage: InAppUpdateStage.failed,
        errorMessage: 'Update could not be downloaded. Please check your '
            'internet connection and try again.',
      );

      await tester.pumpWidget(
        _wrap(const InAppUpdateOverlay(child: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Update could not be downloaded. Please check your internet '
          'connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(InAppUpdateService.state.value.stage, InAppUpdateStage.idle);
      expect(await InAppUpdateService.shouldShowUpdatePrompt(), isFalse);
    });

    testWidgets('Try again on the failed card starts a new download',
        (tester) async {
      InAppUpdateService.state.value = const InAppUpdateState(
        stage: InAppUpdateStage.failed,
        errorMessage: 'boom',
      );

      await tester.pumpWidget(
        _wrap(const InAppUpdateOverlay(child: SizedBox.shrink())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Try again'));
      expect(
        InAppUpdateService.state.value.stage,
        InAppUpdateStage.downloading,
      );

      await _settleIndeterminate(tester);
      expect(startFlexibleUpdateCalls, 1);
    });
  });

  group('InAppUpdateService flows', () {
    test('duplicate download taps only start a single flexible update',
        () async {
      unawaited(InAppUpdateService.startFlexibleUpdate());
      unawaited(InAppUpdateService.startFlexibleUpdate());

      await pumpEventQueue();

      expect(startFlexibleUpdateCalls, 1);
      expect(checkForUpdateCalls, 1);
    });

    test('user cancellation returns to idle without crashing', () async {
      startFlexibleUpdateResponse =
          () => PlatformException(code: 'USER_DENIED_UPDATE');

      await InAppUpdateService.startFlexibleUpdate();

      expect(InAppUpdateService.state.value.stage, InAppUpdateStage.idle);
      expect(InAppUpdateService.state.value.errorMessage, isNull);
    });

    test('a download failure surfaces a friendly message, not the raw error',
        () async {
      startFlexibleUpdateResponse =
          () => PlatformException(code: 'IN_APP_UPDATE_FAILED');

      await InAppUpdateService.startFlexibleUpdate();

      expect(InAppUpdateService.state.value.stage, InAppUpdateStage.failed);
      expect(
        InAppUpdateService.state.value.errorMessage,
        isNot(contains('PlatformException')),
      );
      expect(
        InAppUpdateService.state.value.errorMessage,
        contains('Please check your internet connection'),
      );
    });

    test('app resume restores an in-progress download without restarting it',
        () async {
      checkForUpdateResponse = () => _updateInfo(
            updateAvailability: 3, // developerTriggeredUpdateInProgress
            installStatus: 2, // downloading
          );

      await InAppUpdateService.refreshStateOnResume();

      expect(
        InAppUpdateService.state.value.stage,
        InAppUpdateStage.downloading,
      );
      expect(startFlexibleUpdateCalls, 0);
    });

    test('app resume reflects a completed download as "downloaded"', () async {
      checkForUpdateResponse = () => _updateInfo(
            updateAvailability: 3,
            installStatus: 11, // downloaded
          );

      await InAppUpdateService.refreshStateOnResume();

      expect(
        InAppUpdateService.state.value.stage,
        InAppUpdateStage.downloaded,
      );
    });
  });
}
