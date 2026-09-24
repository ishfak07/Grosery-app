import 'dart:async';
import 'dart:io';

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
      color: const Color(0xFF10231A).withValues(alpha: 0.22),
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
                    color: const Color(0xFF10231A).withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10231A).withValues(alpha: 0.28),
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
                              color: const Color(0xFFE86F4A)
                                  .withValues(alpha: 0.18),
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
                            color: Colors.white.withValues(alpha: 0.78),
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
