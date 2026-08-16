import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lifecycle stages of a Google Play flexible in-app update, surfaced to the
/// UI so the user always knows what is happening.
enum InAppUpdateStage {
  idle,
  checking,
  available,
  pending,
  downloading,
  downloaded,
  installing,
  failed,

  /// Google Play's blocking Immediate Update UI is (or is about to be)
  /// shown for a CRITICAL update. Play owns the screen for this stage — the
  /// app doesn't render its own progress UI while it's active.
  immediateInProgress,

  /// A CRITICAL update's Immediate Update flow failed or was cancelled by
  /// the user. Unlike [failed], there is no "Later" option here — the app
  /// must keep prompting until the update completes.
  immediateFailed,
}

const _genericDownloadFailedMessage =
    'Update could not be downloaded. Please check your internet connection '
    'and try again.';

/// UI-friendly snapshot of the current in-app update. [downloadPercentage] is
/// only ever populated when the platform actually reports
/// bytesDownloaded/totalBytesToDownload — the installed `in_app_update`
/// package does not expose those, so it stays null and the UI falls back to
/// an indeterminate progress indicator instead of a fabricated percentage.
@immutable
class InAppUpdateState {
  const InAppUpdateState({
    this.stage = InAppUpdateStage.idle,
    this.downloadPercentage,
    this.errorMessage,
  });

  final InAppUpdateStage stage;
  final int? downloadPercentage;
  final String? errorMessage;

  bool get isActive =>
      stage == InAppUpdateStage.pending ||
      stage == InAppUpdateStage.downloading ||
      stage == InAppUpdateStage.downloaded ||
      stage == InAppUpdateStage.installing ||
      stage == InAppUpdateStage.immediateInProgress;

  InAppUpdateState copyWith({
    InAppUpdateStage? stage,
    int? downloadPercentage,
    bool clearDownloadPercentage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return InAppUpdateState(
      stage: stage ?? this.stage,
      downloadPercentage: clearDownloadPercentage
          ? null
          : downloadPercentage ?? this.downloadPercentage,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InAppUpdateState &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          downloadPercentage == other.downloadPercentage &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(stage, downloadPercentage, errorMessage);
}

class InAppUpdateService {
  InAppUpdateService._();

  static const _lastPromptShownKey = 'puttalam_drop_update_prompt_last_shown';
  static const _promptCooldown = Duration(hours: 24);

  /// UI-observable state of the current update. Widgets can listen to this
  /// directly instead of relying on the service showing dialogs itself.
  static final ValueNotifier<InAppUpdateState> state =
      ValueNotifier<InAppUpdateState>(const InAppUpdateState());

  static bool _hasCheckedThisSession = false;
  static bool _isPromptVisible = false;
  static bool _isUpdateRequestStarting = false;
  static bool _isCompletingUpdate = false;
  static bool _isImmediateUpdateStarting = false;
  static StreamSubscription<InstallStatus>? _installStatusSubscription;

  /// Google Play in-app-update priority (0-5, set per release via the Play
  /// Developer API / Play Console) at or above which an update is treated
  /// as CRITICAL and forced through the blocking Immediate Update flow
  /// instead of the dismissible Flexible flow. Google's own guidance is to
  /// reserve the top of the range (4-5) for must-install releases.
  ///
  /// This is the single place the "is this update critical?" decision is
  /// made. If the project later gains a backend-driven signal (Remote
  /// Config, a Firestore flag, a minimum-supported-version doc, etc.),
  /// change only [_isCriticalUpdate] — every call site already routes
  /// through it.
  static const int _criticalUpdatePriorityThreshold = 4;

  static bool _isCriticalUpdate(AppUpdateInfo updateInfo) {
    return updateInfo.updatePriority >= _criticalUpdatePriorityThreshold;
  }

  /// Exposes the critical-update decision for tests without weakening its
  /// visibility for the rest of the app.
  @visibleForTesting
  static bool isCriticalUpdateForTesting(AppUpdateInfo updateInfo) =>
      _isCriticalUpdate(updateInfo);

  static bool get _canUseInAppUpdates =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (!_canUseInAppUpdates || _hasCheckedThisSession) {
      return;
    }
    _hasCheckedThisSession = true;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (_syncInstallStatus(updateInfo.installStatus)) {
        return;
      }
      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        await _resumeInProgressUpdate(updateInfo);
        return;
      }
      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (_isCriticalUpdate(updateInfo) && updateInfo.immediateUpdateAllowed) {
        await _startImmediateUpdate();
        return;
      }

      if (!_isFlexibleUpdateAvailable(updateInfo)) {
        return;
      }

      final canShowPrompt = await shouldShowUpdatePrompt();
      if (!canShowPrompt || !context.mounted || _isPromptVisible) {
        return;
      }
      await _showUpdatePrompt(context);
    } catch (error) {
      _logError(error);
    }
  }

  /// Called when Play reports `developerTriggeredUpdateInProgress` — this
  /// covers both a still-running flexible download and an immediate update
  /// flow the user backed out of before it finished. Resumes the correct
  /// flow instead of starting a duplicate one.
  static Future<void> _resumeInProgressUpdate(
    AppUpdateInfo updateInfo,
  ) async {
    if (_isCriticalUpdate(updateInfo) && updateInfo.immediateUpdateAllowed) {
      await _startImmediateUpdate();
      return;
    }
    _listenForInstallStatus();
  }

  /// Starts (or resumes) Google Play's blocking Immediate Update flow for a
  /// CRITICAL update. Play renders its own full-screen UI for this — there
  /// is no "Later" option, and the app does not become usable again until
  /// the update completes, fails, or the user cancels out of Play's screen.
  static Future<void> _startImmediateUpdate() async {
    if (!_canUseInAppUpdates || _isImmediateUpdateStarting) {
      return;
    }
    _isImmediateUpdateStarting = true;
    _setState(
      const InAppUpdateState(stage: InAppUpdateStage.immediateInProgress),
    );

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      switch (result) {
        case AppUpdateResult.success:
          // Play installs and restarts the app itself once an immediate
          // update succeeds; this line is mostly reached in tests/edge
          // cases where the process isn't actually killed.
          _setState(const InAppUpdateState());
        case AppUpdateResult.userDeniedUpdate:
          // A CRITICAL update was declined — leaving the app on an
          // outdated version isn't acceptable, so this surfaces a
          // mandatory-retry state rather than quietly falling back to the
          // normal app experience.
          _setState(
            const InAppUpdateState(
              stage: InAppUpdateStage.immediateFailed,
              errorMessage:
                  'This update is required to continue using the app.',
            ),
          );
        case AppUpdateResult.inAppUpdateFailed:
          _setState(
            const InAppUpdateState(
              stage: InAppUpdateStage.immediateFailed,
              errorMessage: _genericDownloadFailedMessage,
            ),
          );
      }
    } catch (error) {
      _logError(error);
      _setState(
        const InAppUpdateState(
          stage: InAppUpdateStage.immediateFailed,
          errorMessage: _genericDownloadFailedMessage,
        ),
      );
    } finally {
      _isImmediateUpdateStarting = false;
    }
  }

  /// Retries a CRITICAL update after [InAppUpdateStage.immediateFailed].
  /// There is deliberately no "Later"/dismiss path paired with this.
  static Future<void> retryImmediateUpdate() async {
    if (!_canUseInAppUpdates ||
        state.value.stage != InAppUpdateStage.immediateFailed) {
      return;
    }
    _setState(const InAppUpdateState());
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable ||
          updateInfo.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress) {
        await _startImmediateUpdate();
      }
    } catch (error) {
      _logError(error);
      _setState(
        const InAppUpdateState(
          stage: InAppUpdateStage.immediateFailed,
          errorMessage: _genericDownloadFailedMessage,
        ),
      );
    }
  }

  /// Starts (or resumes tracking of) a flexible update. The UI state is
  /// switched to "downloading" immediately, before any await, so the caller
  /// never has to show a bare spinner while this call is in flight.
  static Future<void> startFlexibleUpdate() async {
    if (!_canUseInAppUpdates ||
        _isUpdateRequestStarting ||
        state.value.isActive) {
      return;
    }

    _isUpdateRequestStarting = true;
    _setState(const InAppUpdateState(stage: InAppUpdateStage.downloading));

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (_syncInstallStatus(updateInfo.installStatus)) {
        return;
      }
      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        _listenForInstallStatus();
        return;
      }
      if (!_isFlexibleUpdateAvailable(updateInfo)) {
        _setState(const InAppUpdateState());
        return;
      }

      _listenForInstallStatus();
      final result = await InAppUpdate.startFlexibleUpdate();
      switch (result) {
        case AppUpdateResult.success:
          // Google Play keeps downloading in the background. The install
          // status listener (or a later refresh) will move the state to
          // `downloaded` once it actually finishes.
          break;
        case AppUpdateResult.userDeniedUpdate:
          // The user cancelled the Play update sheet — return to normal.
          await _cancelInstallStatusListener();
          _setState(const InAppUpdateState());
        case AppUpdateResult.inAppUpdateFailed:
          await _cancelInstallStatusListener();
          _setState(
            const InAppUpdateState(
              stage: InAppUpdateStage.failed,
              errorMessage: _genericDownloadFailedMessage,
            ),
          );
      }
    } catch (error) {
      _logError(error);
      await _cancelInstallStatusListener();
      _setState(
        const InAppUpdateState(
          stage: InAppUpdateStage.failed,
          errorMessage: _genericDownloadFailedMessage,
        ),
      );
    } finally {
      _isUpdateRequestStarting = false;
    }
  }

  /// Re-runs `startFlexibleUpdate` after a failure (STATE 6 "Try again").
  static Future<void> retryDownload() async {
    if (state.value.stage == InAppUpdateStage.failed) {
      _setState(const InAppUpdateState());
    }
    await startFlexibleUpdate();
  }

  /// Called when the user taps "Install & restart" once the update has
  /// finished downloading (STATE 4). This is the only place that calls
  /// `completeFlexibleUpdate`.
  static Future<void> installDownloadedUpdate() async {
    if (!_canUseInAppUpdates ||
        _isCompletingUpdate ||
        state.value.stage != InAppUpdateStage.downloaded) {
      return;
    }

    _isCompletingUpdate = true;
    _setState(state.value.copyWith(stage: InAppUpdateStage.installing));
    try {
      await InAppUpdate.completeFlexibleUpdate();
      await _cancelInstallStatusListener();
    } catch (error) {
      _logError(error);
      _setState(
        const InAppUpdateState(
          stage: InAppUpdateStage.failed,
          errorMessage: 'Update could not be installed. Please try again.',
        ),
      );
    } finally {
      _isCompletingUpdate = false;
    }
  }

  /// Dismisses a failed-state banner without retrying (STATE 6 "Later").
  static Future<void> dismissFailedState() async {
    if (state.value.stage == InAppUpdateStage.failed) {
      _setState(const InAppUpdateState());
    }
    await saveLaterSelection();
  }

  /// Called on app resume. Re-checks the real Play install state so a
  /// downloading/downloaded update is reflected correctly without starting a
  /// second download or showing a duplicate dialog.
  static Future<void> refreshStateOnResume() async {
    if (!_canUseInAppUpdates) {
      return;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      final handled = _syncInstallStatus(updateInfo.installStatus);
      if (!handled &&
          updateInfo.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress) {
        await _resumeInProgressUpdate(updateInfo);
      }
    } catch (error) {
      _logError(error);
    }
  }

  static Future<bool> shouldShowUpdatePrompt() async {
    if (!_canUseInAppUpdates) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShownMilliseconds = prefs.getInt(_lastPromptShownKey);
      if (lastShownMilliseconds == null) {
        return true;
      }

      final lastShown = DateTime.fromMillisecondsSinceEpoch(
        lastShownMilliseconds,
      );
      return DateTime.now().difference(lastShown) >= _promptCooldown;
    } catch (error) {
      _logError(error);
      return false;
    }
  }

  static Future<void> saveLaterSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastPromptShownKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (error) {
      _logError(error);
    }
  }

  static bool _isFlexibleUpdateAvailable(AppUpdateInfo updateInfo) {
    return updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable &&
        updateInfo.flexibleUpdateAllowed &&
        updateInfo.availableVersionCode != null;
  }

  /// Applies a raw Play [InstallStatus] to the observable [state]. Returns
  /// true when the status is terminal for the current flow (downloaded,
  /// failed, cancelled or installed) so callers can stop further handling.
  static bool _syncInstallStatus(InstallStatus status) {
    switch (status) {
      case InstallStatus.downloaded:
        _setState(const InAppUpdateState(stage: InAppUpdateStage.downloaded));
        return true;
      case InstallStatus.downloading:
        if (state.value.stage != InAppUpdateStage.downloading) {
          _setState(
            const InAppUpdateState(stage: InAppUpdateStage.downloading),
          );
        }
        return false;
      case InstallStatus.pending:
        _setState(const InAppUpdateState(stage: InAppUpdateStage.pending));
        return false;
      case InstallStatus.installing:
        _setState(const InAppUpdateState(stage: InAppUpdateStage.installing));
        return false;
      case InstallStatus.failed:
        unawaited(_cancelInstallStatusListener());
        _setState(
          const InAppUpdateState(
            stage: InAppUpdateStage.failed,
            errorMessage: _genericDownloadFailedMessage,
          ),
        );
        return true;
      case InstallStatus.canceled:
      case InstallStatus.installed:
        unawaited(_cancelInstallStatusListener());
        _setState(const InAppUpdateState());
        return true;
      case InstallStatus.unknown:
        return false;
    }
  }

  static void _listenForInstallStatus() {
    if (_installStatusSubscription != null) {
      // Never register a second listener for the same download.
      return;
    }
    _installStatusSubscription = InAppUpdate.installUpdateListener.listen(
      _syncInstallStatus,
      onError: (Object error) {
        _logError(error);
        unawaited(_cancelInstallStatusListener());
        _setState(
          const InAppUpdateState(
            stage: InAppUpdateStage.failed,
            errorMessage: _genericDownloadFailedMessage,
          ),
        );
      },
    );
  }

  static Future<void> _cancelInstallStatusListener() async {
    await _installStatusSubscription?.cancel();
    _installStatusSubscription = null;
  }

  static void _setState(InAppUpdateState next) {
    state.value = next;
  }

  static Future<void> _showUpdatePrompt(BuildContext context) async {
    _isPromptVisible = true;
    _setState(const InAppUpdateState(stage: InAppUpdateStage.available));
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Update available'),
            content: const Text(
              'A new version of Puttalam Drop is available with fixes and '
              'improvements.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await saveLaterSelection();
                  if (state.value.stage == InAppUpdateStage.available) {
                    _setState(const InAppUpdateState());
                  }
                },
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  unawaited(startFlexibleUpdate());
                },
                child: const Text('Download update'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _logError(error);
    } finally {
      _isPromptVisible = false;
    }
  }

  static void _logError(Object error) {
    debugPrint('In-app update error: $error');
  }

  /// Resets all static state. Only intended for use from tests so each test
  /// starts from a clean slate.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    _hasCheckedThisSession = false;
    _isPromptVisible = false;
    _isUpdateRequestStarting = false;
    _isCompletingUpdate = false;
    _isImmediateUpdateStarting = false;
    await _cancelInstallStatusListener();
    state.value = const InAppUpdateState();
  }
}
