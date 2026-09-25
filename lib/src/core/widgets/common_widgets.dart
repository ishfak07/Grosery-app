import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/phone_utils.dart';
import '../utils/validators.dart';
import '../../state/app_state.dart';

const appRefreshScrollPhysics = AlwaysScrollableScrollPhysics(
  parent: ClampingScrollPhysics(),
);
const _appRefreshMinimumDuration = Duration(milliseconds: 650);
const appOfflineMessage =
    'No internet connection. Please check your connection and try again.';
const _appGenericErrorMessage = 'Something went wrong. Please try again.';

class FirebaseSetupBanner extends StatelessWidget {
  const FirebaseSetupBanner({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    if (appState.firebaseAvailable) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD89A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F3615).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        appState.firebaseError ??
            context.t(
              'Firebase is not configured. Login, database, functions, and FCM need real Firebase config files.',
            ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1EAE3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF173C2A).withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 34,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.t(title),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t(message),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF66736B),
                          height: 1.35,
                        ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 18),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1EAE3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF173C2A).withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 12),
            Text(
              context.t(message),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.child,
    this.onRefresh,
  });

  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      displacement: 48,
      notificationPredicate: (notification) =>
          notification.depth == 0 && notification.metrics.axis == Axis.vertical,
      onRefresh: () async {
        final appState = context.read<AppState>();
        final refresh = onRefresh ?? appState.refreshVisibleData;
        try {
          await Future.wait([
            () async {
              if (!await appState.verifyInternetConnection()) {
                return;
              }
              await refresh();
            }(),
            Future<void>.delayed(_appRefreshMinimumDuration),
          ]);
        } catch (error) {
          if (appFriendlyErrorMessage(error) == appOfflineMessage) {
            appState.markInternetUnavailable();
          }
        }
      },
      child: child,
    );
  }
}

class OfflineConnectionOverlay extends StatelessWidget {
  const OfflineConnectionOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isOffline = !appState.hasInternetConnection;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            reverseDuration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            // The message runs its own staggered entrance, so the switcher
            // only needs to fade the layer in and out.
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: isOffline
                ? _OfflineConnectionMessage(
                    key: const ValueKey('offline-message'),
                    onRetry: () async {
                      final recovered =
                          await appState.verifyInternetConnection();
                      if (recovered) {
                        await appState.refreshVisibleData();
                      }
                      return recovered;
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('online-message')),
          ),
        ),
      ],
    );
  }
}

const _offlineBrand = Color(0xFF176B45);
const _offlineBrandDeep = Color(0xFF0E4F32);
const _offlineInk = Color(0xFF10231A);
const _offlineMuted = Color(0xFF66736B);
const _offlineAlert = Color(0xFFE86F4A);
const _offlineAlertDeep = Color(0xFFC8502D);

class _OfflineConnectionMessage extends StatefulWidget {
  const _OfflineConnectionMessage({
    super.key,
    required this.onRetry,
  });

  /// Returns `true` when the connection came back.
  final Future<bool> Function() onRetry;

  @override
  State<_OfflineConnectionMessage> createState() =>
      _OfflineConnectionMessageState();
}

class _OfflineConnectionMessageState extends State<_OfflineConnectionMessage>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _ripple;
  late final AnimationController _signal;
  late final AnimationController _float;
  late final AnimationController _shake;
  late final AnimationController _spin;
  var _isRetrying = false;
  var _stillOffline = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _signal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _ripple.stop();
      _signal.stop();
      _float.stop();
      _entrance.value = 1;
      return;
    }
    if (!_ripple.isAnimating) {
      _ripple.repeat();
    }
    if (!_signal.isAnimating) {
      _signal.repeat();
    }
    if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ripple.dispose();
    _signal.dispose();
    _float.dispose();
    _shake.dispose();
    _spin.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_isRetrying) {
      return;
    }
    setState(() {
      _isRetrying = true;
      _stillOffline = false;
    });
    _spin.repeat();
    var recovered = false;
    try {
      recovered = await widget.onRetry();
    } catch (_) {
      recovered = false;
    } finally {
      _spin
        ..stop()
        ..reset();
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _stillOffline = !recovered;
        });
        if (!recovered) {
          HapticFeedback.lightImpact();
          _shake.forward(from: 0);
        }
      }
    }
  }

  /// Progress (0..1) of one staggered entrance step.
  double _step(double begin, double end, [Curve curve = Curves.easeOutCubic]) {
    return Interval(begin, end, curve: curve).transform(_entrance.value);
  }

  Widget _reveal({
    required double begin,
    required double end,
    required Widget child,
    double offsetY = 16,
  }) {
    return AnimatedBuilder(
      animation: _entrance,
      child: child,
      builder: (context, child) {
        final t = _step(begin, end);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 1,
      maxScaleFactor: 1.15,
    );
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (context, _) {
                final t = _step(0, 0.55, Curves.easeOut);
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7 * t, sigmaY: 7 * t),
                  child: ColoredBox(
                    color: _offlineInk.withValues(alpha: 0.42 * t),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: media.size.width < 480 ? media.size.width : 400,
                  ),
                  child: MediaQuery(
                    data: media.copyWith(textScaler: textScaler),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_entrance, _shake]),
                      child: _buildCard(context, theme),
                      builder: (context, child) {
                        final enter = _step(0, 0.7, Curves.easeOutBack);
                        final fade = _step(0, 0.4);
                        final shake = _shake.value;
                        final shakeX =
                            math.sin(shake * math.pi * 6) * 12 * (1 - shake);
                        return Opacity(
                          opacity: fade,
                          child: Transform.translate(
                            offset: Offset(shakeX, 48 * (1 - enter)),
                            child: Transform.scale(
                              scale: 0.88 + 0.12 * enter,
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _offlineInk.withValues(alpha: 0.28),
            blurRadius: 44,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFEEE7), Colors.white],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Center(child: _buildIllustration()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 2, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _reveal(
                  begin: 0.3,
                  end: 0.7,
                  child: Center(child: _buildStatusPill()),
                ),
                const SizedBox(height: 12),
                _reveal(
                  begin: 0.36,
                  end: 0.76,
                  child: Text(
                    context.t('No Internet Connection'),
                    textAlign: TextAlign.center,
                    style: (theme.textTheme.titleLarge ??
                            const TextStyle(fontSize: 20))
                        .copyWith(
                      color: _offlineInk,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _reveal(
                  begin: 0.42,
                  end: 0.82,
                  child: Text(
                    context.t(
                      "Looks like you're offline. Check your network and we'll get you back to shopping.",
                    ),
                    textAlign: TextAlign.center,
                    style: (theme.textTheme.bodyMedium ??
                            const TextStyle(fontSize: 14))
                        .copyWith(
                      color: _offlineMuted,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _reveal(
                  begin: 0.5,
                  end: 0.9,
                  child: _buildQuickChecks(theme),
                ),
                const SizedBox(height: 18),
                _reveal(
                  begin: 0.58,
                  end: 1,
                  offsetY: 22,
                  child: _buildRetryButton(context),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _stillOffline
                        ? Padding(
                            key: const ValueKey('still-offline'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: _offlineAlertDeep,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    context.t(
                                      'Still offline. Please try again in a moment.',
                                    ),
                                    style: const TextStyle(
                                      color: _offlineAlertDeep,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('still-offline-hidden'),
                            width: double.infinity,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _OfflineRipplePainter(
                  progress: _ripple,
                  color: _offlineAlert,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_entrance, _float]),
            builder: (context, child) {
              final pop = _step(0.12, 0.62, Curves.elasticOut);
              final bob = Curves.easeInOut.transform(_float.value);
              return Transform.translate(
                offset: Offset(0, -5 + 10 * bob),
                child: Transform.scale(scale: pop, child: child),
              );
            },
            child: SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFFFF3EE)],
                      ),
                      border: Border.all(
                        color: _offlineAlert.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _offlineAlert.withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: const Size(48, 48),
                          painter: _WifiSignalPainter(
                            progress: _signal,
                            idleColor: _offlineMuted.withValues(alpha: 0.22),
                            activeColor: _offlineAlert,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: 2,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_entrance, _ripple]),
                      builder: (context, child) {
                        final pop = _step(0.4, 0.8, Curves.elasticOut);
                        final beat = 1 +
                            0.08 * math.sin(_ripple.value * math.pi * 2).abs();
                        return Transform.scale(scale: pop * beat, child: child);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_offlineAlert, _offlineAlertDeep],
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _offlineAlertDeep.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: _offlineAlert.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _offlineAlert.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _signal,
            builder: (context, child) {
              final blink = 0.5 + 0.5 * math.cos(_signal.value * math.pi * 2);
              return Opacity(opacity: 0.35 + 0.65 * blink, child: child);
            },
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _offlineAlertDeep,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            context.t('Offline'),
            style: const TextStyle(
              color: _offlineAlertDeep,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChecks(ThemeData theme) {
    const checks = [
      (Icons.wifi_rounded, 'Wi-Fi'),
      (Icons.signal_cellular_alt_rounded, 'Mobile data'),
      (Icons.airplanemode_inactive_rounded, 'Airplane mode'),
    ];
    return Row(
      children: [
        for (var i = 0; i < checks.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (context, child) {
                final t =
                    _step(0.52 + i * 0.08, 0.86 + i * 0.05, Curves.easeOutBack);
                return Transform.scale(
                  scale: 0.7 + 0.3 * t,
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE1EAE3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _offlineBrand.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        checks[i].$1,
                        size: 17,
                        color: _offlineBrand,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.t(checks[i].$2),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _offlineInk,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isRetrying ? 0.86 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_offlineBrand, _offlineBrandDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: _offlineBrand.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _isRetrying ? null : _retry,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.18),
            child: SizedBox(
              height: 54,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey(_isRetrying),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: _spin,
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        context.t(_isRetrying ? 'Checking...' : 'Retry'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft rings that keep radiating out from behind the offline badge.
class _OfflineRipplePainter extends CustomPainter {
  _OfflineRipplePainter({required this.progress, required this.color})
      : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  static const _ringCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final minRadius = maxRadius * 0.56;
    for (var i = 0; i < _ringCount; i++) {
      final t = (progress.value + i / _ringCount) % 1;
      final radius =
          minRadius + (maxRadius - minRadius) * Curves.easeOut.transform(t);
      final alpha = (1 - t) * 0.32;
      canvas
        ..drawCircle(
          center,
          radius,
          Paint()..color = color.withValues(alpha: alpha * 0.35),
        )
        ..drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = color.withValues(alpha: alpha),
        );
    }
  }

  @override
  bool shouldRepaint(_OfflineRipplePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

/// Wi-Fi glyph whose bars light up one after another, like a device
/// searching for a signal.
class _WifiSignalPainter extends CustomPainter {
  _WifiSignalPainter({
    required this.progress,
    required this.idleColor,
    required this.activeColor,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color idleColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.84);
    final stroke = size.width * 0.1;
    // Four signal elements (dot + three arcs) plus one beat of rest.
    final phase = progress.value * 5;

    Color colorFor(int index) {
      final glow = (1 - (phase - index).abs()).clamp(0.0, 1.0);
      return Color.lerp(idleColor, activeColor, glow)!;
    }

    canvas.drawCircle(center, stroke * 0.8, Paint()..color = colorFor(0));
    for (var i = 1; i <= 3; i++) {
      final radius = size.width * 0.22 * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75,
        math.pi * 0.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colorFor(i),
      );
    }
  }

  @override
  bool shouldRepaint(_WifiSignalPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.idleColor != idleColor ||
      oldDelegate.activeColor != activeColor;
}

class RefreshableCenteredContent extends StatelessWidget {
  const RefreshableCenteredContent({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackHeight = MediaQuery.sizeOf(context).height;
        final height = constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0
            ? constraints.maxHeight
            : fallbackHeight;
        return ListView(
          physics: appRefreshScrollPhysics,
          padding: padding,
          children: [
            SizedBox(
              height: height,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

Future<void> performAppRefresh(BuildContext context) {
  return context.read<AppState>().refreshVisibleData();
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status, Theme.of(context).colorScheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.t(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _statusColor(String status, Color fallback) {
    switch (status) {
      case 'Delivered':
        return const Color(0xFF1E8E5A);
      case 'Cancelled':
      case 'Rejected':
      case 'Item Unavailable':
        return const Color(0xFFC83A2B);
      case 'Pending':
      case 'Need Clarification':
      case 'Bill Updated':
        return const Color(0xFFB66D00);
      default:
        return fallback;
    }
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t(title),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(context.t(actionLabel!)),
          ),
      ],
    );
  }
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final IconData? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: (value) {
        final error = widget.validator?.call(value);
        return error == null ? null : context.tNow(error);
      },
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      decoration: InputDecoration(
        labelText: context.t(widget.label),
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: context.t(
                  _obscureText ? 'Show password' : 'Hide password',
                ),
                onPressed: () => setState(() {
                  _obscureText = !_obscureText;
                }),
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    );
  }
}

class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.controller,
    this.label = 'Phone number',
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final prefixColor = enabled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).disabledColor;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: (value) {
        final error = Validators.phone(value);
        return error == null ? null : context.tNow(error);
      },
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      maxLength: 9,
      inputFormatters: const [_SriLankanPhoneInputFormatter()],
      decoration: InputDecoration(
        labelText: context.t(label),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone, color: prefixColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '+94',
                style: TextStyle(
                  color: prefixColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        counterText: '',
      ),
    );
  }
}

class _SriLankanPhoneInputFormatter extends TextInputFormatter {
  const _SriLankanPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('94') || digits.startsWith('0')) {
      digits = PhoneUtils.localSriLankanDigits(newValue.text);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 52,
  });

  final double size;

  /// The logo artwork already carries its own rounded green frame and
  /// transparent corners, so it is drawn as-is - no tile, border, padding
  /// or shadow around it.
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.appLogoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  context.t(label),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: const Color(0xFFC8D7CD),
        disabledForegroundColor: Colors.white,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: child,
      ),
    );
  }
}

String appFriendlyErrorMessage(Object? error, {String? fallback}) {
  if (error == null) {
    return fallback ?? _appGenericErrorMessage;
  }
  if (error is TimeoutException || error is SocketException) {
    return appOfflineMessage;
  }
  if (error is FirebaseException) {
    return _firebaseFriendlyMessage(error.code, fallback: fallback);
  }

  final message = _stripExceptionPrefix(error.toString().trim());
  if (message.isEmpty) {
    return fallback ?? _appGenericErrorMessage;
  }

  final lower = message.toLowerCase();
  if (_looksLikeNetworkError(lower)) {
    return appOfflineMessage;
  }
  if (lower.contains('permission-denied') ||
      lower.contains('permission denied') ||
      lower.contains('unauthenticated')) {
    return 'You are not allowed to perform this action.';
  }
  if (lower.contains('failed-precondition') || lower.contains('index')) {
    return 'This request is not ready yet.';
  }
  if (lower.contains('firebase is not configured') ||
      lower.contains('firebaseunavailableexception')) {
    return 'Service setup is not complete. Please contact support.';
  }
  if (lower.contains('image upload failed')) {
    return _imageUploadFriendlyMessage(message, lower);
  }
  if (lower.contains('cloudinary upload')) {
    return _cloudinaryUploadFriendlyMessage(message, lower);
  }
  if (_looksLikeTechnicalFirebaseError(lower)) {
    return fallback ?? _appGenericErrorMessage;
  }

  return message;
}

String _cloudinaryUploadFriendlyMessage(String message, String lower) {
  if (_looksLikeNetworkError(lower)) {
    return appOfflineMessage;
  }
  if (lower.contains('not configured') ||
      lower.contains('cloudinary_cloud_name') ||
      lower.contains('cloudinary_upload_preset')) {
    return 'Cloudinary image upload is not configured. Please contact support.';
  }
  if (lower.contains('service is not deployed')) {
    return 'Cloudinary image upload service is not deployed. Please contact support.';
  }
  if (lower.contains('service is unavailable')) {
    return appOfflineMessage;
  }
  if (lower.contains('upload preset')) {
    return 'Cloudinary upload preset is not ready. Please contact support.';
  }
  if (lower.contains('invalid signature') || lower.contains('string to sign')) {
    return 'Image upload setup is invalid. Please contact support.';
  }
  if (lower.contains('invalid api key') || lower.contains('unknown api key')) {
    return 'Cloudinary image upload setup is invalid. Please contact support.';
  }
  return message.contains(':')
      ? message
      : 'Image upload failed. Please try again.';
}

String _imageUploadFriendlyMessage(String message, String lower) {
  if (_looksLikeNetworkError(lower)) {
    return appOfflineMessage;
  }
  if (lower.contains('unauthenticated') ||
      lower.contains('sign in again before checkout')) {
    return 'Image upload failed. Please sign in again before checkout.';
  }
  if (lower.contains('unauthorized') ||
      lower.contains('permission-denied') ||
      lower.contains('permission denied') ||
      lower.contains('not allowed to upload this image')) {
    return 'Image upload failed. You are not allowed to upload this image. Please sign in again.';
  }
  if (lower.contains('bucket-not-found') ||
      lower.contains('object-not-found') ||
      lower.contains('project-not-found') ||
      lower.contains('invalid-argument') ||
      lower.contains('storage is not ready') ||
      lower.contains('firebase storage is not set up')) {
    return 'Image uploads are not enabled yet. Please contact support.';
  }
  if (lower.contains('quota-exceeded') ||
      lower.contains('storage limit reached')) {
    return 'Image upload storage limit reached. Please contact support.';
  }
  if (lower.contains('cancelled') || lower.contains('canceled')) {
    return 'Image upload was cancelled. Please try again.';
  }
  if (lower.contains('not found') ||
      lower.contains('empty') ||
      lower.contains('smaller than 8 mb')) {
    return message;
  }
  return 'Image upload failed. Please try again.';
}

String _firebaseFriendlyMessage(String code, {String? fallback}) {
  switch (code) {
    case 'unavailable':
    case 'network-request-failed':
      return appOfflineMessage;
    case 'permission-denied':
    case 'unauthenticated':
      return 'You are not allowed to perform this action.';
    case 'failed-precondition':
      return 'This request is not ready yet.';
    default:
      return fallback ?? _appGenericErrorMessage;
  }
}

String _stripExceptionPrefix(String message) {
  var cleaned = message;
  const prefixes = [
    'Bad state: ',
    'Exception: ',
    'FirebaseException: ',
  ];
  for (final prefix in prefixes) {
    if (cleaned.startsWith(prefix)) {
      cleaned = cleaned.substring(prefix.length).trim();
    }
  }
  return cleaned;
}

bool _looksLikeNetworkError(String message) {
  const markers = [
    'cloud_firestore/unavailable',
    'cloud_functions/unavailable',
    'firebase_auth/network-request-failed',
    'network-request-failed',
    'socketexception',
    'clientexception',
    'timeoutexception',
    'failed host lookup',
    'connection refused',
    'connection reset',
    'connection closed',
    'network is unreachable',
    'software caused connection abort',
    'xmlhttprequest error',
    'failed to fetch',
    'no address associated with hostname',
  ];
  return markers.any(message.contains);
}

bool _looksLikeTechnicalFirebaseError(String message) {
  const markers = [
    '[cloud_firestore/',
    '[cloud_functions/',
    '[firebase_auth/',
    '[firebase_storage/',
    'firebaseexception',
  ];
  return markers.any(message.contains);
}

/// Shows a friendly, animated toast for general status/error messages
/// (e.g. validation errors, "Cart cleared."). Replaces the previous bare
/// [SnackBar], which rendered as a flat unstyled black bar with no
/// animation beyond Flutter's default slide.
void showSnack(BuildContext context, Object? message) {
  final friendlyMessage = appFriendlyErrorMessage(message);
  if (friendlyMessage == appOfflineMessage) {
    context.read<AppState>().markInternetUnavailable();
    return;
  }
  final isError = friendlyMessage != message;
  _showToast(
    context,
    message: friendlyMessage,
    icon: isError ? Icons.error_outline_rounded : Icons.info_rounded,
    anchorTop: false,
    background: isError ? const Color(0xFF3A1414) : const Color(0xFF10231A),
    foreground: Colors.white,
    iconBackground: Colors.white.withValues(alpha: 0.14),
    iconColor: isError ? const Color(0xFFFF9E8A) : Colors.white,
  );
}

/// Shows a polished, self-dismissing confirmation banner for cart actions
/// (e.g. "Added to cart."). It is inserted into the root [Overlay] rather
/// than shown as a [SnackBar], so it always renders above any per-screen
/// bottom action bar/navigation instead of getting hidden behind it.
void showCartConfirmation(
  BuildContext context, {
  String message = 'Added to cart.',
  IconData icon = Icons.check_circle_rounded,
}) {
  final success = Theme.of(context).extension<AppExtraColors>()?.success ??
      const Color(0xFF1E8E5A);
  _showToast(
    context,
    message: message,
    icon: icon,
    anchorTop: true,
    background: Colors.white,
    foreground: const Color(0xFF10231A),
    iconBackground: success.withValues(alpha: 0.12),
    iconColor: success,
    border: success.withValues(alpha: 0.18),
  );
}

OverlayEntry? _activeToastEntry;

/// Shared implementation behind [showSnack] and [showCartConfirmation]: a
/// slide + fade toast rendered in the root [Overlay] so it always floats
/// above bottom nav bars/action bars, self-dismisses after a few seconds,
/// and can be tapped or swiped away early.
void _showToast(
  BuildContext context, {
  required String message,
  required IconData icon,
  required bool anchorTop,
  required Color background,
  required Color foreground,
  required Color iconBackground,
  required Color iconColor,
  Color? border,
}) {
  final overlayState = Overlay.of(context, rootOverlay: true);

  _activeToastEntry?.remove();
  _activeToastEntry = null;

  late final OverlayEntry entry;
  void removeEntry() {
    if (identical(_activeToastEntry, entry)) {
      _activeToastEntry = null;
    }
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (overlayContext) => _AppToast(
      message: message,
      icon: icon,
      anchorTop: anchorTop,
      background: background,
      foreground: foreground,
      iconBackground: iconBackground,
      iconColor: iconColor,
      border: border,
      onDismissed: removeEntry,
    ),
  );

  _activeToastEntry = entry;
  overlayState.insert(entry);
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.icon,
    required this.anchorTop,
    required this.background,
    required this.foreground,
    required this.iconBackground,
    required this.iconColor,
    required this.onDismissed,
    this.border,
  });

  final String message;
  final IconData icon;
  final bool anchorTop;
  final Color background;
  final Color foreground;
  final Color iconBackground;
  final Color iconColor;
  final Color? border;
  final VoidCallback onDismissed;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoDismissTimer;
  var _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.anchorTop ? -1 : 1),
      end: Offset.zero,
    ).animate(curved);
    _fade = curved;
    _controller.forward();
    _autoDismissTimer = Timer(const Duration(milliseconds: 2800), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_isDismissing) {
      return;
    }
    _isDismissing = true;
    _autoDismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 1,
      maxScaleFactor: 1.2,
    );

    return Positioned(
      top: widget.anchorTop ? 0 : null,
      bottom: widget.anchorTop ? null : 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: widget.anchorTop,
        bottom: !widget.anchorTop,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Align(
            alignment:
                widget.anchorTop ? Alignment.topCenter : Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                widget.anchorTop ? 10 : 0,
                16,
                widget.anchorTop ? 0 : 14,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Material(
                      color: Colors.transparent,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _dismiss,
                        onVerticalDragEnd: (_) => _dismiss(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: widget.background,
                            borderRadius: BorderRadius.circular(14),
                            border: widget.border == null
                                ? null
                                : Border.all(color: widget.border!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: widget.iconBackground,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.iconColor,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.t(widget.message),
                                  style: TextStyle(
                                    color: widget.foreground,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: widget.foreground.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a themed, animated confirm/cancel dialog with a pop-in scale+fade
/// transition and an icon-in-circle header — a drop-in, better-looking
/// replacement for a bare [AlertDialog] with a title/message/two actions.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  required String confirmLabel,
  IconData icon = Icons.help_outline_rounded,
  IconData confirmIcon = Icons.check_rounded,
  bool isDestructive = false,
  bool barrierDismissible = true,
}) async {
  final theme = Theme.of(context);
  final danger =
      theme.extension<AppExtraColors>()?.danger ?? const Color(0xFFC83A2B);
  final accent = isDestructive ? danger : theme.colorScheme.primary;

  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: title,
    barrierColor: const Color(0xFF10231A).withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, _, __) {
      return _AppConfirmDialog(
        title: title,
        message: message,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        icon: icon,
        confirmIcon: confirmIcon,
        accent: accent,
      );
    },
    transitionBuilder: (dialogContext, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class _AppConfirmDialog extends StatelessWidget {
  const _AppConfirmDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.icon,
    required this.confirmIcon,
    required this.accent,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final IconData icon;
  final IconData confirmIcon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            elevation: 12,
            shadowColor: const Color(0xFF10231A).withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t(title),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF10231A),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t(message),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF66736B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(context.t(cancelLabel)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          icon: Icon(confirmIcon, size: 18),
                          label: Text(context.t(confirmLabel)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
