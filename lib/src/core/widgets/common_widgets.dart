import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/phone_utils.dart';
import '../utils/validators.dart';
import '../../state/app_state.dart';

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
            'Firebase is not configured. Login, database, functions, and FCM need real Firebase config files.',
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
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
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
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
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
        status,
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
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
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _obscureText ? 'Show password' : 'Hide password',
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
      validator: Validators.phone,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      maxLength: 9,
      inputFormatters: const [_SriLankanPhoneInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
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
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
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

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
