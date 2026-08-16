import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/in_app_update_service.dart';
import '../theme/app_theme.dart';

/// Persistent, non-blocking card that reflects the current Google Play
/// flexible in-app update state (STATE 2-6 of the update flow). It floats
/// above [child] without intercepting touches for the rest of the app, so
/// the user can keep using Puttalam Drop while an update downloads.
class InAppUpdateOverlay extends StatelessWidget {
  const InAppUpdateOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: ValueListenableBuilder<InAppUpdateState>(
              valueListenable: InAppUpdateService.state,
              builder: (context, updateState, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: _cardFor(updateState),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardFor(InAppUpdateState updateState) {
    switch (updateState.stage) {
      case InAppUpdateStage.pending:
        return const _UpdateStatusCard(
          key: ValueKey('update-pending'),
          title: 'Preparing update…',
          progressValue: null,
        );
      case InAppUpdateStage.downloading:
        final percentage = updateState.downloadPercentage;
        return _UpdateStatusCard(
          key: const ValueKey('update-downloading'),
          title: percentage != null
              ? 'Downloading update  $percentage%'
              : 'Downloading update',
          subtitle: 'Downloading update from Google Play…',
          progressValue: percentage != null ? percentage / 100 : null,
          footnote: 'You can continue using Puttalam Drop while the update '
              'downloads.',
        );
      case InAppUpdateStage.installing:
        return const _UpdateStatusCard(
          key: ValueKey('update-installing'),
          title: 'Installing update…',
          progressValue: null,
        );
      case InAppUpdateStage.downloaded:
        return const _UpdateReadyCard(key: ValueKey('update-downloaded'));
      case InAppUpdateStage.failed:
        return _UpdateFailedCard(
          key: const ValueKey('update-failed'),
          message: updateState.errorMessage ??
              'Update could not be downloaded. Please check your internet '
                  'connection and try again.',
        );
      case InAppUpdateStage.immediateFailed:
        return _ImmediateUpdateRequiredCard(
          key: const ValueKey('update-immediate-failed'),
          message: updateState.errorMessage ??
              'This update is required to continue using the app.',
        );
      case InAppUpdateStage.idle:
      case InAppUpdateStage.checking:
      case InAppUpdateStage.available:
      case InAppUpdateStage.immediateInProgress:
        // Google Play owns the full-screen Immediate Update UI while
        // `immediateInProgress` is active, so this overlay stays hidden.
        return const SizedBox.shrink(key: ValueKey('update-hidden'));
    }
  }
}

class _UpdateCardShell extends StatelessWidget {
  const _UpdateCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 6,
        shadowColor: Colors.black26,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE1EAE3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _UpdateStatusCard extends StatelessWidget {
  const _UpdateStatusCard({
    super.key,
    required this.title,
    required this.progressValue,
    this.subtitle,
    this.footnote,
  });

  final String title;
  final double? progressValue;
  final String? subtitle;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppExtraColors>()?.muted;
    return _UpdateCardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 8),
            Text(
              footnote!,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateReadyCard extends StatelessWidget {
  const _UpdateReadyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = theme.extension<AppExtraColors>()?.success;
    return _UpdateCardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: success ?? Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Update ready',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The latest version of Puttalam Drop has finished downloading. '
            'Restart the app to install the update.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                unawaited(InAppUpdateService.installDownloadedUpdate());
              },
              child: const Text('Install & restart'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown after a CRITICAL update's Immediate Update flow fails or the user
/// cancels out of Google Play's blocking screen. Deliberately has no
/// "Later" button — the app keeps asking until the update completes.
class _ImmediateUpdateRequiredCard extends StatelessWidget {
  const _ImmediateUpdateRequiredCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = theme.extension<AppExtraColors>()?.danger;
    return _UpdateCardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: danger ?? Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Update required',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                unawaited(InAppUpdateService.retryImmediateUpdate());
              },
              child: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateFailedCard extends StatelessWidget {
  const _UpdateFailedCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = theme.extension<AppExtraColors>()?.danger;
    return _UpdateCardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: danger ?? Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Update failed',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    unawaited(InAppUpdateService.dismissFailedState());
                  },
                  child: const Text('Later'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    unawaited(InAppUpdateService.retryDownload());
                  },
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
