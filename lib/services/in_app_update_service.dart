import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppUpdateService {
  InAppUpdateService._();

  static const _lastPromptShownKey = 'puttalam_drop_update_prompt_last_shown';
  static const _promptCooldown = Duration(hours: 24);

  static bool _hasCheckedThisSession = false;
  static bool _isPromptVisible = false;
  static bool _isUpdateRequestStarting = false;
  static bool _isUpdateInProgress = false;
  static bool _isCompletingUpdate = false;
  static StreamSubscription<InstallStatus>? _installStatusSubscription;

  static bool get _canUseInAppUpdates =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (!_canUseInAppUpdates || _hasCheckedThisSession) {
      return;
    }
    _hasCheckedThisSession = true;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (await _completeIfDownloaded(updateInfo)) {
        return;
      }
      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        _isUpdateInProgress = true;
        _listenForInstallStatus();
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

  static Future<void> startFlexibleUpdate(BuildContext context) async {
    if (!_canUseInAppUpdates ||
        _isUpdateRequestStarting ||
        _isUpdateInProgress) {
      return;
    }

    _isUpdateRequestStarting = true;
    _isUpdateInProgress = true;
    VoidCallback? dismissStartingIndicator;

    try {
      if (context.mounted) {
        dismissStartingIndicator = await _showStartingIndicator(context);
      }

      final updateInfo = await InAppUpdate.checkForUpdate();
      if (await _completeIfDownloaded(updateInfo)) {
        return;
      }
      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        _listenForInstallStatus();
        return;
      }
      if (!_isFlexibleUpdateAvailable(updateInfo)) {
        _isUpdateInProgress = false;
        return;
      }

      _listenForInstallStatus();
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        await completeDownloadedUpdate();
        return;
      }

      _isUpdateInProgress = false;
    } catch (error) {
      _isUpdateInProgress = false;
      _logError(error);
    } finally {
      dismissStartingIndicator?.call();
      _isUpdateRequestStarting = false;
    }
  }

  static Future<void> completeDownloadedUpdate() async {
    if (!_canUseInAppUpdates || _isCompletingUpdate) {
      return;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (await _completeIfDownloaded(updateInfo)) {
        return;
      }
      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        _isUpdateInProgress = true;
        _listenForInstallStatus();
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

  static Future<bool> _completeIfDownloaded(AppUpdateInfo updateInfo) async {
    if (updateInfo.installStatus != InstallStatus.downloaded) {
      return false;
    }

    await _completeFlexibleUpdate();
    return true;
  }

  static Future<void> _completeFlexibleUpdate() async {
    if (_isCompletingUpdate) {
      return;
    }

    _isCompletingUpdate = true;
    try {
      await InAppUpdate.completeFlexibleUpdate();
      _isUpdateInProgress = false;
      await _cancelInstallStatusListener();
    } catch (error) {
      _isUpdateInProgress = false;
      _logError(error);
    } finally {
      _isCompletingUpdate = false;
    }
  }

  static void _listenForInstallStatus() {
    _installStatusSubscription ??= InAppUpdate.installUpdateListener.listen(
      (status) {
        switch (status) {
          case InstallStatus.downloaded:
            unawaited(_completeFlexibleUpdate());
            break;
          case InstallStatus.failed:
          case InstallStatus.canceled:
          case InstallStatus.installed:
            _isUpdateInProgress = false;
            unawaited(_cancelInstallStatusListener());
            break;
          case InstallStatus.unknown:
          case InstallStatus.pending:
          case InstallStatus.downloading:
          case InstallStatus.installing:
            break;
        }
      },
      onError: (Object error) {
        _isUpdateInProgress = false;
        _logError(error);
      },
    );
  }

  static Future<void> _cancelInstallStatusListener() async {
    await _installStatusSubscription?.cancel();
    _installStatusSubscription = null;
  }

  static Future<void> _showUpdatePrompt(BuildContext context) async {
    _isPromptVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Update available'),
            content: const Text(
              'A new version of Puttalam Drop is available with important '
              'fixes and improvements. Please update the app for the best '
              'experience.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await saveLaterSelection();
                },
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    await startFlexibleUpdate(context);
                  }
                },
                child: const Text('Update now'),
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

  static Future<VoidCallback?> _showStartingIndicator(
    BuildContext context,
  ) async {
    BuildContext? dialogContext;
    var dismissed = false;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return const PopScope(
            canPop: false,
            child: AlertDialog(
              content: SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                ),
              ),
            ),
          );
        },
      ).then<void>((_) {}).catchError((Object error) {
        _logError(error);
      }),
    );

    await Future<void>.delayed(const Duration(milliseconds: 80));
    return () {
      if (dismissed) {
        return;
      }
      dismissed = true;
      final currentDialogContext = dialogContext;
      if (currentDialogContext != null && currentDialogContext.mounted) {
        Navigator.of(currentDialogContext, rootNavigator: true).pop();
      }
    };
  }

  static void _logError(Object error) {
    debugPrint('In-app update error: $error');
  }
}
