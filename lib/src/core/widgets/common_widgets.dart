import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../i18n/app_localizations.dart';
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
            color: const Color(0xFF4F3615).withOpacity(0.06),
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
                  color: const Color(0xFF173C2A).withOpacity(0.07),
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
                          .withOpacity(0.1),
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
              color: const Color(0xFF173C2A).withOpacity(0.06),
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
            duration: const Duration(milliseconds: 280),
            reverseDuration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                  child: child,
                ),
              );
            },
            child: isOffline
                ? _OfflineConnectionMessage(
                    key: const ValueKey('offline-message'),
                    onRetry: () async {
                      final recovered =
                          await appState.verifyInternetConnection();
                      if (recovered) {
                        await appState.refreshVisibleData();
                      }
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('online-message')),
          ),
        ),
      ],
    );
  }
}

class _OfflineConnectionMessage extends StatefulWidget {
  const _OfflineConnectionMessage({
    super.key,
    required this.onRetry,
  });

  final Future<void> Function() onRetry;

  @override
  State<_OfflineConnectionMessage> createState() =>
      _OfflineConnectionMessageState();
}

class _OfflineConnectionMessageState extends State<_OfflineConnectionMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  var _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_isRetrying) {
      return;
    }
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 1,
      maxScaleFactor: 1.18,
    );
    return Material(
      color: const Color(0xFF10231A).withOpacity(0.22),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: media.size.width < 520 ? media.size.width - 40 : 420,
              ),
              child: MediaQuery(
                data: media.copyWith(textScaler: textScaler),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10231A).withOpacity(0.98),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10231A).withOpacity(0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE86F4A).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              color: Color(0xFFFFC9BA),
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.t('No Internet Connection'),
                          textAlign: TextAlign.center,
                          style: (theme.textTheme.titleMedium ??
                                  const TextStyle(fontSize: 16))
                              .copyWith(
                            color: Colors.white,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          context.t('Check your connection and try again.'),
                          textAlign: TextAlign.center,
                          style: (theme.textTheme.bodyMedium ??
                                  const TextStyle(fontSize: 14))
                              .copyWith(
                            color: Colors.white.withOpacity(0.78),
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w700,
                            height: 1.32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isRetrying ? null : _retry,
                            icon: _isRetrying
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(context.t('Retry')),
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
      ),
    );
  }
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
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.t(status),
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
    this.padding = 3,
    this.showShadow = false,
    this.borderRadius = 8,
  });

  final double size;
  final double padding;
  final bool showShadow;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageRadius = borderRadius > padding ? borderRadius - padding : 4.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFDDE8DF)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF163526).withOpacity(0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(imageRadius),
        child: Image.asset(
          AppConstants.appLogoAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
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
  if (lower.contains('image upload failed') ||
      lower.contains('cloudinary upload')) {
    return 'Image upload failed. Please check your connection and try again.';
  }
  if (_looksLikeTechnicalFirebaseError(lower)) {
    return fallback ?? _appGenericErrorMessage;
  }

  return message;
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

void showSnack(BuildContext context, Object? message) {
  final friendlyMessage = appFriendlyErrorMessage(message);
  if (friendlyMessage == appOfflineMessage) {
    context.read<AppState>().markInternetUnavailable();
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.tNow(friendlyMessage))));
}
