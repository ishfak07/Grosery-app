import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/in_app_update_service.dart';
import 'core/constants/app_constants.dart';
import 'core/i18n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common_widgets.dart';
import 'features/admin/admin_screens.dart';
import 'features/auth/auth_screens.dart';
import 'features/customer/customer_screens.dart';
import 'features/delivery/delivery_boy_screens.dart';
import 'state/app_state.dart';

class GroceryDeliveryApp extends StatelessWidget {
  const GroceryDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) => OfflineConnectionOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomeGate(),
    );
  }
}

class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> with WidgetsBindingObserver {
  AppState? _appState;
  bool _hasScheduledUpdateCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextAppState = context.read<AppState>();
    if (_appState != nextAppState) {
      _appState?.removeListener(_scheduleUpdateCheckIfReady);
      _appState = nextAppState;
      nextAppState.addListener(_scheduleUpdateCheckIfReady);
    }
    _scheduleUpdateCheckIfReady();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(InAppUpdateService.completeDownloadedUpdate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState?.removeListener(_scheduleUpdateCheckIfReady);
    super.dispose();
  }

  void _scheduleUpdateCheckIfReady() {
    if (!mounted || _hasScheduledUpdateCheck) {
      return;
    }
    final appState = _appState;
    if (appState == null || appState.isInitializing || appState.isLoggingOut) {
      return;
    }

    _hasScheduledUpdateCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(InAppUpdateService.checkForUpdate(context));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isInitializing) {
      return const SplashScreen();
    }
    if (!appState.hasSeenOnboarding) {
      return const OnboardingScreen();
    }
    if (appState.isLoggingOut) {
      return const Scaffold(
        body: LoadingView(message: 'Logging out...'),
      );
    }
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }
    if (appState.profile?.isBlocked ?? false) {
      return BlockedAccountScreen(onLogout: appState.logout);
    }
    if (appState.isAdmin) {
      return const AdminDashboardScreen();
    }
    if (appState.isDeliveryBoy) {
      return const DeliveryBoyDashboardScreen();
    }
    return const CustomerHomeScreen();
  }
}

class BlockedAccountScreen extends StatelessWidget {
  const BlockedAccountScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: AppRefreshIndicator(
        child: RefreshableCenteredContent(
          child: EmptyState(
            icon: Icons.block,
            title: 'Account blocked',
            message: 'Please contact support before placing new orders.',
            action: ElevatedButton.icon(
              onPressed: () => onLogout(),
              icon: const Icon(Icons.logout),
              label: Text(context.t('Logout')),
            ),
          ),
        ),
      ),
    );
  }
}
