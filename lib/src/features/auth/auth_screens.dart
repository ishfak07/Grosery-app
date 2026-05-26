import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.local_grocery_store,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('Local groceries, lists, pickup, and COD delivery.'),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  final _items = const [
    _OnboardingItem(
      Icons.storefront,
      'Order from trusted local shops',
      'Browse products from partner shops and keep your daily groceries simple.',
    ),
    _OnboardingItem(
      Icons.receipt_long,
      'Upload a shopping list',
      'Send a handwritten or printed list photo when catalog items are not enough.',
    ),
    _OnboardingItem(
      Icons.payments,
      'Cash on delivery',
      'Admin reviews the bill, buys items, delivers, and collects cash.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FirebaseSetupBanner(appState: appState),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 90,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.message,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF66736B),
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _page == index ? 26 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _page == index
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFD7DED8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryActionButton(
                label: _page == _items.length - 1 ? 'Get started' : 'Next',
                icon: Icons.arrow_forward,
                onPressed: () async {
                  if (_page == _items.length - 1) {
                    await context.read<AppState>().markOnboardingComplete();
                    return;
                  }
                  await _controller.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem(this.icon, this.title, this.message);

  final IconData icon;
  final String title;
  final String message;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FirebaseSetupBanner(appState: appState),
            const SizedBox(height: 16),
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
                'Login with phone and password. Registration and password reset do not use OTP.'),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppPhoneField(
                    controller: _phone,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _password,
                    label: 'Password',
                    obscureText: true,
                    validator: Validators.password,
                    prefixIcon: Icons.lock,
                  ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(
                    label: 'Login',
                    icon: Icons.login,
                    isLoading: _isLoading,
                    onPressed: appState.firebaseAvailable ? _login : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: appState.firebaseAvailable
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterDetailsScreen(),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.person_add),
              label: const Text('Create account'),
            ),
            TextButton(
              onPressed: appState.firebaseAvailable
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPhoneScreen(),
                        ),
                      )
                  : null,
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().login(
            phone: PhoneUtils.normalizeSriLankanPhone(_phone.text),
            password: _password.text,
          );
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class ForgotPasswordPhoneScreen extends StatefulWidget {
  const ForgotPasswordPhoneScreen({super.key});

  @override
  State<ForgotPasswordPhoneScreen> createState() =>
      _ForgotPasswordPhoneScreenState();
}

class _ForgotPasswordPhoneScreenState extends State<ForgotPasswordPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Reset securely',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                  'Request approval from admin. After approval, you can set a new password here.'),
              const SizedBox(height: 20),
              AppPhoneField(
                controller: _phone,
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Request reset',
                icon: Icons.lock_reset,
                isLoading: _isLoading,
                onPressed: _requestReset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final phone = PhoneUtils.normalizeSriLankanPhone(_phone.text);
      final status = await context
          .read<AppState>()
          .authService
          .requestPasswordReset(phone);
      if (!mounted) {
        return;
      }
      showSnack(context, status.message);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(phone: phone)),
      );
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class RegisterDetailsScreen extends StatefulWidget {
  const RegisterDetailsScreen({super.key});

  @override
  State<RegisterDetailsScreen> createState() => _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends State<RegisterDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Create account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              const Text('Enter your details. No OTP is required.'),
              const SizedBox(height: 20),
              AppTextField(
                controller: _name,
                label: 'Full name',
                validator: (value) =>
                    Validators.requiredText(value, 'Full name'),
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 12),
              AppPhoneField(
                controller: _phone,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Delivery address',
                validator: (value) =>
                    Validators.requiredText(value, 'Delivery address'),
                maxLines: 3,
                prefixIcon: Icons.home,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _password,
                label: 'Password',
                obscureText: true,
                validator: Validators.password,
                prefixIcon: Icons.lock,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmPassword,
                label: 'Confirm password',
                obscureText: true,
                validator: (value) =>
                    Validators.confirmPassword(value, _password.text),
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Create account',
                icon: Icons.check_circle,
                isLoading: _isLoading,
                onPressed: _completeRegistration,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().completeRegistration(
            fullName: _name.text,
            phone: PhoneUtils.normalizeSriLankanPhone(_phone.text),
            address: _address.text,
            password: _password.text,
          );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.phone});

  final String phone;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  PasswordResetStatusResult? _status;
  var _isLoading = false;
  var _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final isApproved = status?.isApproved ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.phone,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_statusMessage(status)),
              const SizedBox(height: 16),
              if (isApproved) ...[
                AppTextField(
                  controller: _password,
                  label: 'New password',
                  obscureText: true,
                  validator: Validators.password,
                  prefixIcon: Icons.lock,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirmPassword,
                  label: 'Confirm new password',
                  obscureText: true,
                  validator: (value) =>
                      Validators.confirmPassword(value, _password.text),
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 18),
                PrimaryActionButton(
                  label: 'Update password',
                  icon: Icons.save,
                  isLoading: _isLoading,
                  onPressed: _reset,
                ),
              ] else ...[
                PrimaryActionButton(
                  label: _isChecking ? 'Checking' : 'Check approval',
                  icon: Icons.refresh,
                  isLoading: _isChecking,
                  onPressed: _checkStatus,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusMessage(PasswordResetStatusResult? status) {
    if (_isChecking && status == null) {
      return 'Checking admin approval...';
    }
    if (status == null) {
      return 'Waiting for admin approval.';
    }
    if (status.message.isNotEmpty) {
      return status.message;
    }
    if (status.isApproved) {
      return 'Approved. Set your new password.';
    }
    if (status.isRejected) {
      return 'Rejected. Contact admin support.';
    }
    if (status.isCompleted) {
      return 'Password was already updated. Login with the new password.';
    }
    return 'Pending admin approval.';
  }

  Future<void> _checkStatus() async {
    if (_isChecking || _isLoading) {
      return;
    }
    setState(() => _isChecking = true);
    try {
      final status = await context
          .read<AppState>()
          .authService
          .fetchPasswordResetStatus(widget.phone);
      if (mounted) {
        setState(() => _status = status);
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      await appState.authService.completeApprovedPasswordReset(
        phone: widget.phone,
        newPassword: _password.text,
      );
      await appState.login(phone: widget.phone, password: _password.text);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        showSnack(context, 'Password updated.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
