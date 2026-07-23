import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/language_codes.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

const _authBackground = Color(0xFFF7FAF5);
const _authSurface = Color(0xFFFFFFFF);
const _authInk = Color(0xFF10231A);
const _authMuted = Color(0xFF66736B);
const _authLine = Color(0xFFDDE8DF);
const _authPrimary = Color(0xFF176B45);
const _authPrimaryLight = Color(0xFFE9F7EF);
const _authAccent = Color(0xFFE86F4A);

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFBFDF9),
            Color(0xFFEFF7F2),
            Color(0xFFFFF8F3),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.children,
    this.appBarTitle,
  });

  final String title;
  final String? appBarTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authBackground,
      appBar: appBarTitle == null
          ? null
          : AppBar(
              title: Text(context.t(appBarTitle!)),
              backgroundColor: _authBackground.withValues(alpha: 0.96),
              shape: const Border(bottom: BorderSide(color: _authLine)),
            ),
      body: _AuthBackdrop(
        child: AppRefreshIndicator(
          child: SafeArea(
            top: appBarTitle == null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 720 ? 24.0 : 16.0;
                return ListView(
                  physics: appRefreshScrollPhysics,
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (appBarTitle == null) ...[
                              const _AuthBrandMark(),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              context.t(title),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: _authInk,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard(
      {required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _authSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _authLine),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163526).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthBrandMark extends StatelessWidget {
  const _AuthBrandMark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppLogoMark(size: 52, padding: 2, showShadow: true),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            AppConstants.appName,
            style: TextStyle(
              color: _authInk,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF163D2C),
            Color(0xFF176B45),
            Color(0xFFE86F4A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _authPrimary.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t(message),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

class _AuthLanguageSelector extends StatelessWidget {
  const _AuthLanguageSelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalized = AppLanguageCodes.normalize(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.translate, color: _authPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              context.t('Preferred language'),
              style: const TextStyle(
                color: _authInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: AppLanguageCodes.english,
                label: Text(context.t('English')),
              ),
              ButtonSegment<String>(
                value: AppLanguageCodes.tamil,
                label: Text(context.t('Tamil')),
              ),
            ],
            selected: {normalized},
            onSelectionChanged: (selected) => onChanged(selected.first),
          ),
        ),
      ],
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authBackground,
      body: _AuthBackdrop(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _AuthCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: const AppLogoMark(
                        size: 96,
                        padding: 4,
                        showShadow: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _authInk,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t(
                        'Local groceries, lists, pickup, and COD delivery.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _authMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  ],
                ),
              ),
            ),
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
      'Everything you need in one place',
      'Browse our carefully selected products and enjoy a simple grocery shopping experience.',
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
      backgroundColor: _authBackground,
      body: _AuthBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              FirebaseSetupBanner(appState: appState),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _AuthBrandMark(),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF163D2C),
                                  Color(0xFF176B45),
                                  Color(0xFFE86F4A),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _authPrimary.withValues(alpha: 0.2),
                                  blurRadius: 28,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 94,
                                  height: 94,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  context.t(item.title),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.t(item.message),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _OnboardingChip(
                                icon: Icons.eco_outlined,
                                label: 'Fresh',
                              ),
                              _OnboardingChip(
                                icon: Icons.flash_on_outlined,
                                label: 'Fast',
                              ),
                              _OnboardingChip(
                                icon: Icons.verified_outlined,
                                label: 'Trusted',
                              ),
                            ],
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
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: _page == index ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _page == index ? _authPrimary : _authLine,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: PrimaryActionButton(
                    label: _page == _items.length - 1 ? 'Get started' : 'Next',
                    icon: Icons.arrow_forward,
                    onPressed: () async {
                      if (_page == _items.length - 1) {
                        await context.read<AppState>().markOnboardingComplete();
                        return;
                      }
                      await _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingChip extends StatelessWidget {
  const _OnboardingChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _authLine),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163526).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: _authPrimary),
          const SizedBox(width: 6),
          Text(
            context.t(label),
            style: const TextStyle(
              color: _authInk,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
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
    return _AuthScaffold(
      title: 'Welcome back',
      children: [
        FirebaseSetupBanner(appState: appState),
        const _AuthHeroPanel(
          icon: Icons.shopping_bag_outlined,
          title: 'Fresh groceries are waiting',
          message:
              'Login with your phone and password to reorder, track deliveries, and send shopping lists.',
        ),
        const SizedBox(height: 16),
        _AuthCard(
          child: Form(
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
          label: Text(context.t('Create account')),
        ),
        TextButton(
          onPressed: appState.firebaseAvailable
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPhoneScreen(),
                    ),
                  )
              : null,
          child: Text(context.t('Forgot password?')),
        ),
      ],
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
    return _AuthScaffold(
      appBarTitle: 'Forgot password',
      title: 'Reset securely',
      children: [
        const _AuthHeroPanel(
          icon: Icons.lock_reset,
          title: 'Admin-approved reset',
          message:
              'Request approval first. Once approved, you can set a new password here.',
        ),
        const SizedBox(height: 16),
        _AuthCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
      ],
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
  var _preferredLanguageCode = AppLanguageCodes.english;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _preferredLanguageCode = context.read<AppState>().preferredLanguageCode;
  }

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
    return _AuthScaffold(
      appBarTitle: 'Complete profile',
      title: 'Create account',
      children: [
        const _AuthHeroPanel(
          icon: Icons.person_add_alt,
          title: 'Your grocery profile',
          message:
              'Add your delivery details once and checkout faster on every order.',
        ),
        const SizedBox(height: 16),
        _AuthCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                _AuthLanguageSelector(
                  value: _preferredLanguageCode,
                  onChanged: (value) async {
                    setState(() => _preferredLanguageCode = value);
                    await context.read<AppState>().updatePreferredLanguage(
                          value,
                        );
                  },
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
      ],
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
            preferredLanguageCode: _preferredLanguageCode,
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
    return _AuthScaffold(
      appBarTitle: 'Set new password',
      title: 'Password reset',
      children: [
        _AuthCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      isApproved ? _authPrimaryLight : const Color(0xFFFFF5E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isApproved ? Icons.verified_outlined : Icons.hourglass_top,
                  color: isApproved ? _authPrimary : _authAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.phone,
                      style: const TextStyle(
                        color: _authInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.t(_statusMessage(status)),
                      style: const TextStyle(
                        color: _authMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AuthCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
      ],
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
