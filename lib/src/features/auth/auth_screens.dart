import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
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
                'Login with phone and password. OTP is only for registration and password reset.'),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _phone,
                    label: 'Phone number',
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                    prefixIcon: Icons.phone,
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
                          builder: (_) => const OtpVerificationScreen(
                            mode: OtpMode.registration,
                          ),
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
            phone: _phone.text,
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

enum OtpMode { registration, forgotPassword }

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.mode});

  final OtpMode mode;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String? _verificationId;
  var _isLoading = false;

  bool get _isCodeSent => _verificationId != null;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = widget.mode == OtpMode.registration;
    return Scaffold(
      appBar: AppBar(
        title: Text(isRegister ? 'Verify phone' : 'Forgot password'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                isRegister ? 'First-time registration' : 'Verify ownership',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isCodeSent
                    ? 'Enter the SMS OTP sent to ${_phone.text}.'
                    : 'Enter your phone number to receive a Firebase OTP.',
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _phone,
                label: 'Phone number',
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                prefixIcon: Icons.phone,
              ),
              if (_isCodeSent) ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _otp,
                  label: 'OTP code',
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      Validators.requiredText(value, 'OTP code'),
                  prefixIcon: Icons.password,
                ),
              ],
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: _isCodeSent ? 'Verify OTP' : 'Send OTP',
                icon: _isCodeSent ? Icons.verified_user : Icons.sms,
                isLoading: _isLoading,
                onPressed:
                    _isLoading ? null : (_isCodeSent ? _verifyOtp : _sendOtp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final verificationId = await context
          .read<AppState>()
          .authService
          .sendOtp(_phone.text.trim());
      if (!mounted) {
        return;
      }
      if (verificationId == 'AUTO_VERIFIED') {
        await _afterOtpVerified();
      } else {
        setState(() => _verificationId = verificationId);
        showSnack(context, 'OTP sent.');
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

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().authService.verifyOtp(
            verificationId: _verificationId!,
            smsCode: _otp.text.trim(),
          );
      if (mounted) {
        await _afterOtpVerified();
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

  Future<void> _afterOtpVerified() async {
    final normalizedPhone = PhoneUtils.normalizeSriLankanPhone(_phone.text);
    if (widget.mode == OtpMode.registration) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RegisterDetailsScreen(phone: normalizedPhone),
        ),
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(phone: normalizedPhone),
      ),
    );
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
              const Text('We will send an OTP before allowing a new password.'),
              const SizedBox(height: 20),
              AppTextField(
                controller: _phone,
                label: 'Phone number',
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                prefixIcon: Icons.phone,
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Send OTP',
                icon: Icons.sms,
                isLoading: _isLoading,
                onPressed: _sendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final verificationId = await context
          .read<AppState>()
          .authService
          .sendOtp(_phone.text.trim());
      if (!mounted) {
        return;
      }
      final phone = PhoneUtils.normalizeSriLankanPhone(_phone.text);
      if (verificationId == 'AUTO_VERIFIED') {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(phone: phone)),
        );
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordOtpScreen(
              phone: phone,
              verificationId: verificationId,
            ),
          ),
        );
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

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
  });

  final String phone;
  final String verificationId;

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('OTP sent to ${widget.phone}'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _otp,
                label: 'OTP code',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    Validators.requiredText(value, 'OTP code'),
                prefixIcon: Icons.password,
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Verify',
                icon: Icons.verified,
                isLoading: _isLoading,
                onPressed: _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().authService.verifyOtp(
            verificationId: widget.verificationId,
            smsCode: _otp.text.trim(),
          );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(phone: widget.phone),
        ),
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
  const RegisterDetailsScreen({super.key, required this.phone});

  final String phone;

  @override
  State<RegisterDetailsScreen> createState() => _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends State<RegisterDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
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
                'Phone verified',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(widget.phone),
              const SizedBox(height: 20),
              AppTextField(
                controller: _name,
                label: 'Full name',
                validator: (value) =>
                    Validators.requiredText(value, 'Full name'),
                prefixIcon: Icons.person,
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
            phone: widget.phone,
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
  var _isLoading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      await appState.authService.updatePasswordAfterOtp(_password.text);
      await appState.refreshProfile();
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
