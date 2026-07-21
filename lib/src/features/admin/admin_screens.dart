import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../services/image_upload_service.dart';
import '../../../services/image_picker_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../customer/customer_screens.dart';
import 'admin_order_sheet_screen.dart';

const _adminBackground = Color(0xFFF4F7F4);
const _adminSurface = Color(0xFFFFFFFF);
const _adminInk = Color(0xFF14231C);
const _adminMuted = Color(0xFF627168);
const _adminLine = Color(0xFFDDE8DF);
const _adminPrimary = Color(0xFF176B45);
const _adminAccent = Color(0xFFE86F4A);
const _adminBlue = Color(0xFF356DAA);
const _adminViolet = Color(0xFF7656A6);
const _adminWarning = Color(0xFFD88413);
const _adminDanger = Color(0xFFC83A2B);
const _adminSuccess = _adminPrimary;
const _minimumOrderSearchLength = 4;
const _defaultAdminNote =
    'Kindly be patient \u{1F60A} Your order will be delivered soon by our '
    'delivery person. Thank you!';

Color _adminStatusColor(String status) {
  switch (status) {
    case 'Delivered':
    case 'available':
    case 'Active':
    case 'open':
    case 'completed':
      return _adminPrimary;
    case 'Cancelled':
    case 'Rejected':
    case 'Item Unavailable':
    case 'unavailable':
    case 'Blocked':
    case 'rejected':
      return const Color(0xFFC83A2B);
    case 'Pending':
    case 'Need Clarification':
    case 'Bill Updated':
    case 'pending':
    case 'receipt uploaded':
      return _adminWarning;
    case 'Accepted':
    case 'Out for Delivery':
    case 'replied':
    case 'approved':
      return _adminBlue;
    default:
      return _adminMuted;
  }
}

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _adminBackground,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: _adminInk,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        actions: actions,
        backgroundColor: _adminBackground.withValues(alpha: 0.96),
        foregroundColor: _adminInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _adminLine)),
      ),
      floatingActionButton: floatingActionButton,
      body: _AdminBackdrop(
        child: AppRefreshIndicator(child: body),
      ),
    );
  }
}

class _AdminBackdrop extends StatelessWidget {
  const _AdminBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FBF8),
            Color(0xFFEEF5F1),
            Color(0xFFFFF8F3),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _AdminLogoutTransition extends StatelessWidget {
  const _AdminLogoutTransition();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _adminBackground,
      body: _AdminBackdrop(
        child: LoadingView(message: 'Logging out...'),
      ),
    );
  }
}

class _AdminPage extends StatelessWidget {
  const _AdminPage({
    required this.child,
    this.maxWidth = 1120,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 720 ? 24.0 : 16.0;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.borderColor = _adminLine,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final card = Material(
      color: _adminSurface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163526).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: card,
    );
  }
}

class _AdminReveal extends StatelessWidget {
  const _AdminReveal({
    required this.child,
    this.index = 0,
  });

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final extra = index.clamp(0, 8) * 35;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + extra),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _AdminIconBadge extends StatelessWidget {
  const _AdminIconBadge({
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _AdminPill extends StatelessWidget {
  const _AdminPill({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminProgressPill extends StatelessWidget {
  const _AdminProgressPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  const _AdminSectionHeader({
    required this.title,
    this.icon,
  });

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            _AdminIconBadge(icon: icon!, color: _adminPrimary, size: 34),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _adminInk,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAppBarButton extends StatelessWidget {
  const _AdminAppBarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _adminInk,
          side: const BorderSide(color: _adminLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      padding: EdgeInsets.zero,
      borderColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF123E2B),
              Color(0xFF176B45),
              Color(0xFF245A77),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            const summary = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminPill(
                  label: 'Live operations',
                  color: Colors.white,
                  icon: Icons.bolt,
                ),
                _AdminPill(
                  label: 'Catalog control',
                  color: Color(0xFFFFD7C8),
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            );
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${profile.fullName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage orders, products, categories, customers, and support.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                summary,
              ],
            );

            final mark = Container(
              width: compact ? 82 : 108,
              height: compact ? 82 : 108,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Icon(
                Icons.admin_panel_settings_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: compact ? 42 : 54,
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mark,
                  const SizedBox(height: 16),
                  copy,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 20),
                mark,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Row(
        children: [
          _AdminIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _adminInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatsGrid extends StatelessWidget {
  const _AdminStatsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: count == 1 ? 4.3 : 3.3,
          children: children,
        );
      },
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    if (profile == null) {
      return const _AdminLogoutTransition();
    }
    return _AdminScaffold(
      title: 'Admin dashboard',
      actions: [
        _AdminAppBarButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: Icons.notifications_outlined,
        ),
        _AdminAppBarButton(
          tooltip: 'Logout',
          onPressed: () => appState.logout(),
          icon: Icons.logout,
        ),
      ],
      body: _AdminPage(
        child: ListView(
          physics: appRefreshScrollPhysics,
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
          children: [
            FirebaseSetupBanner(appState: appState),
            _AdminReveal(child: _DashboardHero(profile: profile)),
            const SizedBox(height: 18),
            _AdminActionGrid(
              children: [
                _AdminTile(
                  icon: Icons.receipt_long,
                  title: 'Orders',
                  subtitle: 'Current work, latest first',
                  accent: _adminPrimary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminOrdersScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.manage_search,
                  title: 'Find order',
                  subtitle: 'Search by number',
                  accent: _adminBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminOrdersScreen.find(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Accounts',
                  subtitle: 'Sales and reports',
                  accent: _adminAccent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminAccountsManagementScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.tune,
                  title: 'Checkout',
                  subtitle: 'Fees, payments, hours',
                  accent: _adminViolet,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminCheckoutChargeSettingsScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Products',
                  subtitle: 'Add, edit, disable',
                  accent: _adminBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminProductManagementScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Offers',
                  subtitle: 'Home banners',
                  accent: _adminWarning,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminOfferManagementScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.category_outlined,
                  title: 'Categories',
                  subtitle: 'Item groups',
                  accent: _adminAccent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminShopManagementScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.people_outline,
                  title: 'Customers',
                  subtitle: 'Block or unblock',
                  accent: _adminViolet,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminCustomerManagementScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.delivery_dining,
                  title: 'Delivery boys',
                  subtitle: 'Create and assign',
                  accent: _adminBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminDeliveryBoyManagementScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.lock_reset,
                  title: 'Password resets',
                  subtitle: 'Approve requests',
                  accent: _adminBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminPasswordResetScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin login',
                  subtitle: 'Reset password',
                  accent: _adminPrimary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminLoginPasswordResetScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.person_remove_outlined,
                  title: 'Account deletion',
                  subtitle: 'Review web requests',
                  accent: _adminAccent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminAccountDeletionScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.support_agent,
                  title: 'Support',
                  subtitle: 'Reply to tickets',
                  accent: _adminWarning,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminSupportScreen(),
                    ),
                  ),
                ),
                _AdminTile(
                  icon: Icons.campaign_outlined,
                  title: 'Broadcast',
                  subtitle: 'Notify customers',
                  accent: _adminPrimary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminBroadcastScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            StreamBuilder<List<OrderModel>>(
              stream: appState.firestoreService.watchAllOrders(),
              builder: (context, snapshot) {
                final allOrders = snapshot.data ?? const <OrderModel>[];
                final pendingOrders = allOrders
                    .where((order) => order.orderStatus == 'Pending')
                    .take(4)
                    .toList();
                final pendingCount = allOrders
                    .where((order) => order.orderStatus == 'Pending')
                    .length;
                final activeOrders =
                    allOrders.where(_isCurrentAdminOrder).length;
                final deliveredOrders = allOrders
                    .where((order) => order.orderStatus == 'Delivered')
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminStatsGrid(
                      children: [
                        _AdminMetricCard(
                          label: 'Total orders',
                          value: allOrders.length.toString(),
                          icon: Icons.receipt_long,
                          color: _adminPrimary,
                        ),
                        _AdminMetricCard(
                          label: 'Pending',
                          value: pendingCount.toString(),
                          icon: Icons.pending_actions,
                          color: _adminWarning,
                        ),
                        _AdminMetricCard(
                          label: 'Active work',
                          value: activeOrders.toString(),
                          icon: Icons.local_shipping_outlined,
                          color: _adminBlue,
                        ),
                        _AdminMetricCard(
                          label: 'Delivered',
                          value: deliveredOrders.toString(),
                          icon: Icons.verified_outlined,
                          color: _adminAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _AdminSectionHeader(
                      title: 'New orders',
                      icon: Icons.inbox_outlined,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: pendingOrders.isEmpty
                          ? const EmptyState(
                              icon: Icons.inbox_outlined,
                              title: 'No pending orders',
                              message: 'New customer orders will appear here.',
                            )
                          : Column(
                              key: ValueKey(pendingOrders.length),
                              children: [
                                for (var index = 0;
                                    index < pendingOrders.length;
                                    index++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == pendingOrders.length - 1
                                          ? 0
                                          : 10,
                                    ),
                                    child: _AdminReveal(
                                      index: index,
                                      child: AdminOrderTile(
                                        order: pendingOrders[index],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCheckoutChargeSettingsScreen extends StatefulWidget {
  const AdminCheckoutChargeSettingsScreen({super.key});

  @override
  State<AdminCheckoutChargeSettingsScreen> createState() =>
      _AdminCheckoutChargeSettingsScreenState();
}

class _AdminCheckoutChargeSettingsScreenState
    extends State<AdminCheckoutChargeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _delivery = TextEditingController();
  final _service = TextEditingController();
  final _bankAccountName = TextEditingController();
  final _bankName = TextEditingController();
  final _bankBranch = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  var _openingMinutes = 0;
  var _closingMinutes = 0;
  var _codEnabled = true;
  var _bankTransferEnabled = true;
  var _isSaving = false;
  var _isSyncingFields = false;
  var _hasUserEdited = false;

  @override
  void initState() {
    super.initState();
    _delivery.addListener(_markUserEdited);
    _service.addListener(_markUserEdited);
    _bankAccountName.addListener(_markUserEdited);
    _bankName.addListener(_markUserEdited);
    _bankBranch.addListener(_markUserEdited);
    _bankAccountNumber.addListener(_markUserEdited);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    if (!appState.hasLoadedCheckoutChargeSettings ||
        !appState.hasLoadedShopHoursSettings ||
        !appState.hasLoadedPaymentSettings ||
        _hasUserEdited) {
      return;
    }
    _syncFields(
      appState.checkoutChargeSettings,
      appState.shopHoursSettings,
      appState.paymentSettings,
    );
  }

  @override
  void dispose() {
    _delivery.dispose();
    _service.dispose();
    _bankAccountName.dispose();
    _bankName.dispose();
    _bankBranch.dispose();
    _bankAccountNumber.dispose();
    super.dispose();
  }

  void _markUserEdited() {
    if (!_isSyncingFields) {
      _hasUserEdited = true;
    }
  }

  void _syncFields(
    CheckoutChargeSettings chargeSettings,
    ShopHoursSettings shopHoursSettings,
    PaymentSettings paymentSettings,
  ) {
    final deliveryText = chargeSettings.deliveryCharge.toStringAsFixed(2);
    final serviceText = chargeSettings.serviceCharge.toStringAsFixed(2);
    if (_delivery.text == deliveryText &&
        _service.text == serviceText &&
        _openingMinutes == shopHoursSettings.openingMinutes &&
        _closingMinutes == shopHoursSettings.closingMinutes &&
        _bankAccountName.text == paymentSettings.bankAccountName &&
        _bankName.text == paymentSettings.bankName &&
        _bankBranch.text == paymentSettings.bankBranch &&
        _bankAccountNumber.text == paymentSettings.bankAccountNumber &&
        _codEnabled == paymentSettings.codEnabled &&
        _bankTransferEnabled == paymentSettings.bankTransferEnabled) {
      return;
    }
    _isSyncingFields = true;
    _delivery.text = deliveryText;
    _service.text = serviceText;
    _openingMinutes = shopHoursSettings.openingMinutes;
    _closingMinutes = shopHoursSettings.closingMinutes;
    _bankAccountName.text = paymentSettings.bankAccountName;
    _bankName.text = paymentSettings.bankName;
    _bankBranch.text = paymentSettings.bankBranch;
    _bankAccountNumber.text = paymentSettings.bankAccountNumber;
    _codEnabled = paymentSettings.codEnabled;
    _bankTransferEnabled = paymentSettings.bankTransferEnabled;
    _isSyncingFields = false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasLoadedSettings = appState.hasLoadedCheckoutChargeSettings &&
        appState.hasLoadedShopHoursSettings &&
        appState.hasLoadedPaymentSettings;
    return _AdminScaffold(
      title: 'Checkout settings',
      body: _AdminPage(
        maxWidth: 720,
        child: hasLoadedSettings
            ? ListView(
                physics: appRefreshScrollPhysics,
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
                children: [
                  _AdminReveal(
                    child: _AdminCard(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _AdminSectionHeader(
                              title: 'Checkout charges',
                              icon: Icons.payments_outlined,
                            ),
                            TextFormField(
                              controller: _delivery,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) => _amountError(
                                value,
                                'delivery charge',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Delivery charge',
                                prefixIcon: Icon(Icons.local_shipping_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _service,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) => _amountError(
                                value,
                                'service charge',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Service charge',
                                prefixIcon: Icon(Icons.receipt_outlined),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 18),
                            const _AdminSectionHeader(
                              title: 'Ordering hours',
                              icon: Icons.schedule_outlined,
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final opening = _ShopTimePicker(
                                  label: 'Opening time',
                                  time: ShopHoursSettings.formatMinutes(
                                    _openingMinutes,
                                  ),
                                  icon: Icons.wb_sunny_outlined,
                                  onTap: () => _pickShopTime(opening: true),
                                );
                                final closing = _ShopTimePicker(
                                  label: 'Closing time',
                                  time: ShopHoursSettings.formatMinutes(
                                    _closingMinutes,
                                  ),
                                  icon: Icons.nightlight_outlined,
                                  onTap: () => _pickShopTime(opening: false),
                                );
                                if (constraints.maxWidth >= 560) {
                                  return Row(
                                    children: [
                                      Expanded(child: opening),
                                      const SizedBox(width: 12),
                                      Expanded(child: closing),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    opening,
                                    const SizedBox(height: 12),
                                    closing,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 18),
                            const _AdminSectionHeader(
                              title: 'Payment methods',
                              icon: Icons.point_of_sale_outlined,
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _codEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _codEnabled = value;
                                  _hasUserEdited = true;
                                });
                              },
                              secondary: const Icon(Icons.payments_outlined),
                              title: const Text('Cash on Delivery'),
                              subtitle: const Text(
                                'Allow customers to place COD orders.',
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _bankTransferEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _bankTransferEnabled = value;
                                  _hasUserEdited = true;
                                });
                              },
                              secondary:
                                  const Icon(Icons.account_balance_outlined),
                              title: const Text('Bank transfer'),
                              subtitle: const Text(
                                'Allow customers to upload transfer receipts.',
                              ),
                            ),
                            if (!_codEnabled && !_bankTransferEnabled) ...[
                              const SizedBox(height: 10),
                              const _AdminNotice(
                                icon: Icons.pause_circle_outline,
                                color: _adminWarning,
                                message:
                                    'Both methods are off. Customers will not be able to place orders until one method is enabled.',
                              ),
                            ],
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 18),
                            const _AdminSectionHeader(
                              title: 'Bank transfer account',
                              icon: Icons.account_balance_outlined,
                            ),
                            TextFormField(
                              controller: _bankAccountName,
                              validator: (value) => Validators.requiredText(
                                value,
                                'Account name',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Account name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bankName,
                              validator: (value) => Validators.requiredText(
                                value,
                                'Bank name',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Bank name',
                                prefixIcon: Icon(Icons.account_balance),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bankBranch,
                              validator: (value) => Validators.requiredText(
                                value,
                                'Branch',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Branch',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bankAccountNumber,
                              validator: (value) => Validators.requiredText(
                                value,
                                'Account number',
                              ),
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'Account number',
                                prefixIcon:
                                    Icon(Icons.confirmation_number_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            PrimaryActionButton(
                              label: 'Save checkout settings',
                              icon: Icons.save,
                              isLoading: _isSaving,
                              onPressed: _isSaving ? null : _save,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const LoadingView(message: 'Loading checkout settings...'),
      ),
    );
  }

  String? _amountError(String? value, String label) {
    final amount = _readAmount(value);
    if (amount == null) {
      return 'Enter a valid $label.';
    }
    return null;
  }

  double? _readAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || amount.isNaN || amount.isInfinite || amount < 0) {
      return null;
    }
    return amount;
  }

  Future<void> _pickShopTime({required bool opening}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _timeOfDayFromMinutes(
        opening ? _openingMinutes : _closingMinutes,
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      if (opening) {
        _openingMinutes = _minutesFromTimeOfDay(selected);
      } else {
        _closingMinutes = _minutesFromTimeOfDay(selected);
      }
      _hasUserEdited = true;
    });
  }

  TimeOfDay _timeOfDayFromMinutes(int minutes) {
    final normalized = minutes.clamp(0, ShopHoursSettings.minutesPerDay - 1);
    return TimeOfDay(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }

  int _minutesFromTimeOfDay(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final delivery = _readAmount(_delivery.text)!;
    final service = _readAmount(_service.text)!;
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      await appState.updateCheckoutChargeSettings(
        deliveryCharge: delivery,
        serviceCharge: service,
      );
      await appState.updateShopHoursSettings(
        openingMinutes: _openingMinutes,
        closingMinutes: _closingMinutes,
      );
      await appState.updatePaymentSettings(
        codEnabled: _codEnabled,
        bankTransferEnabled: _bankTransferEnabled,
        bankAccountName: _bankAccountName.text,
        bankName: _bankName.text,
        bankBranch: _bankBranch.text,
        bankAccountNumber: _bankAccountNumber.text,
      );
      _hasUserEdited = false;
      if (mounted) {
        showSnack(context, 'Checkout settings saved.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ShopTimePicker extends StatelessWidget {
  const _ShopTimePicker({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String time;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FBF8),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _adminLine),
          ),
          child: Row(
            children: [
              _AdminIconBadge(icon: icon, color: _adminPrimary, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        color: _adminInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_outlined, color: _adminMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  var _isSending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminScaffold(
      title: 'Broadcast',
      body: _AdminPage(
        maxWidth: 720,
        child: ListView(
          physics: appRefreshScrollPhysics,
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
          children: [
            _AdminReveal(
              child: _AdminCard(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _AdminIconBadge(
                            icon: Icons.campaign_outlined,
                            color: _adminPrimary,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Broadcast notification',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: _adminInk,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'All active customers',
                                  style: TextStyle(
                                    color: _adminMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _title,
                        label: 'Title',
                        prefixIcon: Icons.title,
                        validator: (value) =>
                            Validators.requiredText(value, 'Title'),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _body,
                        label: 'Message',
                        maxLines: 4,
                        prefixIcon: Icons.notes_outlined,
                        validator: (value) =>
                            Validators.requiredText(value, 'Message'),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _isSending ? null : _sendBroadcast,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(
                            _isSending ? 'Sending' : 'Send broadcast',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await context.read<AppState>().firestoreService.broadcastToUsers(
            title: _title.text.trim(),
            body: _body.text.trim(),
          );
      if (mounted) {
        _title.clear();
        _body.clear();
        showSnack(context, 'Broadcast notification sent.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _AdminActionGrid extends StatelessWidget {
  const _AdminActionGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 960
            ? 5
            : constraints.maxWidth >= 680
                ? 3
                : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: count == 5 ? 1.18 : 1.08,
          children: [
            for (var index = 0; index < children.length; index++)
              _AdminReveal(index: index + 1, child: children[index]),
          ],
        );
      },
    );
  }
}

class _AdminTile extends StatefulWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  @override
  State<_AdminTile> createState() => _AdminTileState();
}

class _AdminTileState extends State<_AdminTile> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: _AdminCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AdminIconBadge(icon: widget.icon, color: widget.accent),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: widget.accent,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key})
      : _isFindMode = false,
        autofocusSearch = false;

  const AdminOrdersScreen.find({
    super.key,
    this.autofocusSearch = true,
  }) : _isFindMode = true;

  final bool _isFindMode;
  final bool autofocusSearch;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _orderSearch = TextEditingController();
  var _filter = 'All';
  DateTime? _selectedDate;
  String _submittedOrderSearch = '';

  @override
  void dispose() {
    _orderSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isFindMode = widget._isFindMode;
    final filters = [
      'All',
      'Pending',
      'Accepted',
      'Out for Delivery',
      'Delivered',
      'Rejected',
    ];
    return _AdminScaffold(
      title: isFindMode ? 'Find order' : 'Current orders',
      body: _AdminPage(
        child: StreamBuilder<List<OrderModel>>(
          stream: appState.firestoreService.watchAllOrders(),
          builder: (context, snapshot) {
            final allOrders = snapshot.data ?? const <OrderModel>[];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    allOrders.isEmpty;
            if (!isFindMode) {
              final currentOrders = allOrders
                  .where(_isCurrentAdminOrder)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return _AdminCurrentOrdersContent(
                isLoading: isLoading,
                orders: currentOrders,
              );
            }

            final orders = _filteredOrders(allOrders);
            final searchQuery =
                _normalizeOrderSearchInput(_submittedOrderSearch);
            final searchResults = _matchingOrderSearchResults(
              allOrders,
              searchQuery,
            );

            return _AdminOrdersContent(
              orderSearchController: _orderSearch,
              autofocusSearch: widget.autofocusSearch,
              hasSearch: _submittedOrderSearch.isNotEmpty,
              isLoading: isLoading,
              searchQuery: searchQuery,
              searchResults: searchResults,
              filters: filters,
              selectedFilter: _filter,
              selectedDate: _selectedDate,
              orders: orders,
              onSearch: () => _submitOrderSearch(
                allOrders,
                isLoading: isLoading,
              ),
              onClearSearch: _clearOrderSearch,
              onFilterSelected: (filter) => setState(() => _filter = filter),
              onPickDate: _pickOrderDate,
              onClearDate: _selectedDate == null
                  ? null
                  : () => setState(() => _selectedDate = null),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitOrderSearch(
    List<OrderModel> allOrders, {
    required bool isLoading,
  }) async {
    FocusScope.of(context).unfocus();
    final query = _normalizeOrderSearchInput(_orderSearch.text);
    setState(() => _submittedOrderSearch = query);
    if (query.isEmpty) {
      showSnack(context, 'Enter an order number.');
      return;
    }
    if (query.length < _minimumOrderSearchLength) {
      showSnack(
        context,
        'Enter at least $_minimumOrderSearchLength characters.',
      );
      return;
    }
    if (isLoading) {
      showSnack(context, 'Orders are still loading.');
      return;
    }
    final matches = _matchingOrderSearchResults(allOrders, query);
    if (matches.length == 1) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminOrderDetailsScreen(
            orderId: matches.single.orderId,
          ),
        ),
      );
      return;
    }
    if (matches.isEmpty) {
      showSnack(context, 'No order found for this number.');
      return;
    }
    showSnack(context, 'Multiple orders matched. Select the correct order.');
  }

  void _clearOrderSearch() {
    _orderSearch.clear();
    setState(() => _submittedOrderSearch = '');
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    return orders.where((order) {
      final matchesStatus = _filter == 'All' || order.orderStatus == _filter;
      final selectedDate = _selectedDate;
      final matchesDate =
          selectedDate == null || _isSameDate(order.createdAt, selectedDate);
      return matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> _pickOrderDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() => _selectedDate = _dateOnly(selected));
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

bool _isCurrentAdminOrder(OrderModel order) {
  return order.orderStatus != 'Delivered' &&
      order.orderStatus != 'Cancelled' &&
      order.orderStatus != 'Rejected';
}

class _AdminCurrentOrdersContent extends StatelessWidget {
  const _AdminCurrentOrdersContent({
    required this.isLoading,
    required this.orders,
  });

  final bool isLoading;
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: appRefreshScrollPhysics,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 2),
            child: _AdminCard(
              child: Row(
                children: [
                  const _AdminIconBadge(
                    icon: Icons.dynamic_feed_outlined,
                    color: _adminPrimary,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current orders',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: _adminInk,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoading
                              ? 'Loading current orders...'
                              : '${orders.length} active ${orders.length == 1 ? 'order' : 'orders'} - latest first',
                          style: const TextStyle(
                            color: _adminMuted,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _AdminPill(
                    label: 'Latest first',
                    color: _adminBlue,
                    icon: Icons.south,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingView(),
          )
        else if (orders.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.task_alt,
              title: 'No current orders',
              message: 'New and active customer orders will appear here.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final order = orders[index];
                  final isLatest = index == 0;
                  final isOldest = index == orders.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: isOldest ? 0 : 10,
                    ),
                    child: _AdminReveal(
                      index: index,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLatest || (isOldest && orders.length > 1)) ...[
                            _AdminPill(
                              label: isLatest
                                  ? 'Latest order'
                                  : 'Oldest current order',
                              color: isLatest ? _adminPrimary : _adminWarning,
                              icon: isLatest
                                  ? Icons.fiber_new_outlined
                                  : Icons.history,
                            ),
                            const SizedBox(height: 7),
                          ],
                          AdminOrderTile(order: order),
                        ],
                      ),
                    ),
                  );
                },
                childCount: orders.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminOrdersContent extends StatelessWidget {
  const _AdminOrdersContent({
    required this.orderSearchController,
    required this.autofocusSearch,
    required this.hasSearch,
    required this.isLoading,
    required this.searchQuery,
    required this.searchResults,
    required this.filters,
    required this.selectedFilter,
    required this.selectedDate,
    required this.orders,
    required this.onSearch,
    required this.onClearSearch,
    required this.onFilterSelected,
    required this.onPickDate,
    required this.onClearDate,
  });

  final TextEditingController orderSearchController;
  final bool autofocusSearch;
  final bool hasSearch;
  final bool isLoading;
  final String searchQuery;
  final List<OrderModel> searchResults;
  final List<String> filters;
  final String selectedFilter;
  final DateTime? selectedDate;
  final List<OrderModel> orders;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onPickDate;
  final VoidCallback? onClearDate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: appRefreshScrollPhysics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: _AdminOrderSearchSection(
            controller: orderSearchController,
            autofocus: autofocusSearch,
            hasSearch: hasSearch,
            isLoading: isLoading,
            onSearch: onSearch,
            onClear: onClearSearch,
          ),
        ),
        SliverToBoxAdapter(
          child: _AdminOrderSearchResults(
            query: searchQuery,
            visible: hasSearch && !isLoading,
            matches: searchResults,
          ),
        ),
        SliverToBoxAdapter(
          child: _AdminFilterBar(
            filters: filters,
            selected: selectedFilter,
            onSelected: onFilterSelected,
          ),
        ),
        SliverToBoxAdapter(
          child: _AdminOrderDateFilter(
            selectedDate: selectedDate,
            onPickDate: onPickDate,
            onClear: onClearDate,
          ),
        ),
        if (isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingView(),
          )
        else if (orders.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.receipt_long,
              title:
                  selectedDate == null ? 'No orders' : 'No orders on this date',
              message: selectedDate == null
                  ? 'Orders matching this filter will appear here.'
                  : 'Orders created on the selected date will appear here.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: 10);
                  }
                  final orderIndex = index ~/ 2;
                  return _AdminReveal(
                    index: orderIndex,
                    child: AdminOrderTile(order: orders[orderIndex]),
                  );
                },
                childCount: orders.length * 2 - 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminOrderSearchSection extends StatelessWidget {
  const _AdminOrderSearchSection({
    required this.controller,
    required this.autofocus,
    required this.hasSearch,
    required this.isLoading,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool autofocus;
  final bool hasSearch;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
      child: _AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AdminSectionHeader(
              title: 'Find order by number',
              icon: Icons.manage_search,
            ),
            TextField(
              controller: controller,
              autofocus: autofocus,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Order number',
                hintText: '#a1b2c3d4',
                prefixIcon: const Icon(Icons.receipt_long),
                suffixIcon: hasSearch
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
              onSubmitted: (_) => onSearch(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onSearch,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(isLoading ? 'Loading orders' : 'Search order'),
                  ),
                ),
                if (hasSearch) ...[
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: _adminInk,
                      side: const BorderSide(color: _adminLine),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOrderSearchResults extends StatelessWidget {
  const _AdminOrderSearchResults({
    required this.query,
    required this.visible,
    required this.matches,
  });

  final String query;
  final bool visible;
  final List<OrderModel> matches;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    if (query.length < _minimumOrderSearchLength) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: _AdminNotice(
          icon: Icons.info_outline,
          color: _adminWarning,
          message: 'Enter at least 4 characters from the order number.',
        ),
      );
    }
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _AdminNotice(
          icon: Icons.search_off,
          color: _adminWarning,
          message: 'No order found for #$query.',
        ),
      );
    }

    final visibleMatches = matches.take(2).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminNotice(
            icon: matches.length == 1
                ? Icons.check_circle_outline
                : Icons.rule_folder_outlined,
            color: matches.length == 1 ? _adminPrimary : _adminBlue,
            message: matches.length == 1
                ? 'Order found. Open it below for full details.'
                : matches.length == visibleMatches.length
                    ? '${matches.length} orders matched. Select the correct order.'
                    : '${matches.length} orders matched. Showing the first ${visibleMatches.length}. Enter more characters to narrow it down.',
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < visibleMatches.length; index++) ...[
            AdminOrderTile(order: visibleMatches[index]),
            if (index != visibleMatches.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AdminOrderDateFilter extends StatelessWidget {
  const _AdminOrderDateFilter({
    required this.selectedDate,
    required this.onPickDate,
    required this.onClear,
  });

  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final date = selectedDate;
    final label =
        date == null ? 'Select order date' : DateFormat.yMMMd().format(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: date == null ? _adminInk : _adminPrimary,
                side: BorderSide(
                  color: date == null ? _adminLine : _adminPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Clear date',
            onPressed: onClear,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              foregroundColor: _adminInk,
              disabledForegroundColor: _adminMuted.withValues(alpha: 0.45),
              side: BorderSide(
                color: onClear == null
                    ? _adminLine.withValues(alpha: 0.6)
                    : _adminLine,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminFilterBar extends StatelessWidget {
  const _AdminFilterBar({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
            avatar: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : _adminInk,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: _adminPrimary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? _adminPrimary : _adminLine,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

class AdminOrderTile extends StatelessWidget {
  const AdminOrderTile({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _adminStatusColor(order.orderStatus);
    return _AdminCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminOrderDetailsScreen(orderId: order.orderId),
        ),
      ),
      child: Row(
        children: [
          _AdminIconBadge(icon: Icons.receipt_long, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.customerName} - ${_shortId(order.orderId)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat.yMMMd().add_jm().format(order.createdAt),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(status: order.orderStatus),
              const SizedBox(height: 7),
              Text(
                order.totalAmount.money,
                style: const TextStyle(
                  color: _adminInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: _adminMuted),
        ],
      ),
    );
  }
}

class AdminOrderDetailsScreen extends StatefulWidget {
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  final _cartItemsAmount = TextEditingController();
  final _photoListAmount = TextEditingController();
  final _manualListAmount = TextEditingController();
  final _subtotal = TextEditingController();
  final _delivery = TextEditingController();
  final _service = TextEditingController();
  final _adminNotes = TextEditingController(text: _defaultAdminNote);
  final _rejectionReason = TextEditingController();
  final _deliveryPerson = TextEditingController();
  final _deliveryPhone = TextEditingController();
  String _status = 'Pending';
  String _paymentStatus = 'pending';
  String? _selectedDeliveryBoyId;
  String? _loadedOrderId;
  var _isSavingBill = false;
  var _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _cartItemsAmount.addListener(_updateSubtotalPreview);
    _photoListAmount.addListener(_updateSubtotalPreview);
    _manualListAmount.addListener(_updateSubtotalPreview);
  }

  @override
  void dispose() {
    _cartItemsAmount.removeListener(_updateSubtotalPreview);
    _photoListAmount.removeListener(_updateSubtotalPreview);
    _manualListAmount.removeListener(_updateSubtotalPreview);
    _cartItemsAmount.dispose();
    _photoListAmount.dispose();
    _manualListAmount.dispose();
    _subtotal.dispose();
    _delivery.dispose();
    _service.dispose();
    _adminNotes.dispose();
    _rejectionReason.dispose();
    _deliveryPerson.dispose();
    _deliveryPhone.dispose();
    super.dispose();
  }

  void _syncControllers(OrderModel order) {
    if (_loadedOrderId == order.orderId) {
      return;
    }
    _loadedOrderId = order.orderId;
    _cartItemsAmount.text = order.cartItemsAmount.toStringAsFixed(2);
    _photoListAmount.text = order.photoListAmount.toStringAsFixed(2);
    _manualListAmount.text = order.manualListAmount.toStringAsFixed(2);
    _subtotal.text = order.subtotal.toStringAsFixed(2);
    _delivery.text = order.deliveryCharge.toStringAsFixed(2);
    _service.text = order.serviceCharge.toStringAsFixed(2);
    _adminNotes.text =
        order.adminNotes.trim().isEmpty ? _defaultAdminNote : order.adminNotes;
    _rejectionReason.text = order.rejectionReason;
    _deliveryPerson.text = order.assignedDeliveryPerson;
    _deliveryPhone.text = order.assignedDeliveryPhone;
    _selectedDeliveryBoyId = order.assignedDeliveryBoyId.isEmpty
        ? null
        : order.assignedDeliveryBoyId;
    _status = order.orderStatus;
    _paymentStatus = order.paymentStatus;
  }

  void _updateSubtotalPreview() {
    final subtotal = _previewAmount(_cartItemsAmount) +
        _previewAmount(_photoListAmount) +
        _previewAmount(_manualListAmount);
    final text = subtotal.toStringAsFixed(2);
    if (_subtotal.text != text) {
      _subtotal.text = text;
    }
  }

  double _previewAmount(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return 0;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final paymentSettings = appState.paymentSettings;
    return _AdminScaffold(
      title: 'Order details',
      body: _AdminPage(
        child: StreamBuilder<OrderModel?>(
          stream: appState.firestoreService.watchOrder(widget.orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RefreshableCenteredContent(
                child: LoadingView(),
              );
            }
            final order = snapshot.data;
            if (order == null) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.receipt_long,
                  title: 'Order not found',
                  message: 'This order is no longer available.',
                ),
              );
            }
            _syncControllers(order);
            final customerNotes = order.customerNotes;
            final manualListLines = order.manualListLines;
            return ListView(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
              children: [
                _AdminReveal(
                  child: _AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _AdminIconBadge(
                              icon: Icons.person_outline,
                              color: _adminPrimary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                order.customerName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _adminInk,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            StatusChip(status: order.orderStatus),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _OrderInfoRow(
                          'Order number',
                          '#${_shortId(order.orderId)}',
                        ),
                        _OrderInfoRow('Full order ID', order.orderId),
                        _OrderInfoRow(
                          'Placed',
                          DateFormat.yMMMd().add_jm().format(order.createdAt),
                        ),
                        _OrderInfoRow('Phone', order.customerPhone),
                        _OrderInfoRow('Address', order.customerAddress),
                        if (customerNotes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _AdminPill(
                              label: 'Notes: $customerNotes',
                              color: _adminWarning,
                              icon: Icons.sticky_note_2_outlined,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _launchPhone(order.customerPhone),
                                icon: const Icon(Icons.call),
                                label: const Text('Call'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _launchWhatsapp(order.customerPhone),
                                icon: const Icon(Icons.chat),
                                label: const Text('WhatsApp'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminOrderSheetScreen(order: order),
                                ),
                              );
                            },
                            icon: const Icon(Icons.assignment_outlined),
                            label: const Text('View preparation sheet'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _AdminSectionHeader(
                  title: 'Payment',
                  icon: Icons.payments_outlined,
                ),
                _AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrderInfoRow('Method', order.paymentMethod),
                      _OrderInfoRow('Payment status', order.paymentStatus),
                      _OrderInfoRow('Order total', order.totalAmount.money),
                      if (order.paymentMethod ==
                          AppConstants.paymentMethodBankTransfer) ...[
                        const Divider(height: 22),
                        _OrderInfoRow(
                          'Account name',
                          paymentSettings.bankAccountName,
                        ),
                        _OrderInfoRow('Bank', paymentSettings.bankName),
                        _OrderInfoRow(
                          'Branch',
                          paymentSettings.bankBranch,
                        ),
                        _OrderInfoRow(
                          'Account number',
                          paymentSettings.bankAccountNumber,
                        ),
                        const SizedBox(height: 12),
                        if (order.hasPaymentReceipt) ...[
                          const Text(
                            'Transfer receipt',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () =>
                                _showZoomImage(order.paymentReceiptImageUrl),
                            child: AspectRatio(
                              aspectRatio: 1.35,
                              child: ProductImage(
                                url: order.paymentReceiptImageUrl,
                              ),
                            ),
                          ),
                        ] else
                          const Text(
                            'No transfer receipt uploaded.',
                            style: TextStyle(color: Color(0xFFC83A2B)),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (order.items.isNotEmpty) ...[
                  const _AdminSectionHeader(
                    title: 'Items',
                    icon: Icons.shopping_basket_outlined,
                  ),
                  for (var index = 0; index < order.items.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == order.items.length - 1 ? 0 : 8,
                      ),
                      child: _AdminCard(
                        child: CheckboxListTile(
                          enabled: true,
                          value: order.items[index].isAvailable,
                          onChanged: null,
                          title: Text(
                            order.items[index].name,
                            style: const TextStyle(
                              color: Color(0xFF17201B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${order.items[index].quantity} x ${order.items[index].price.money} / ${order.items[index].unit}',
                            style: const TextStyle(
                              color: Color(0xFF4B5A51),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          secondary: Text(
                            order.items[index].lineTotal.money,
                            style: const TextStyle(
                              color: Color(0xFF4B5A51),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                if (manualListLines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _AdminSectionHeader(
                    title: 'Manual grocery list',
                    icon: Icons.edit_note,
                  ),
                  for (var index = 0; index < manualListLines.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == manualListLines.length - 1 ? 0 : 8,
                      ),
                      child: _AdminCard(
                        child: CheckboxListTile(
                          enabled: true,
                          value: true,
                          onChanged: null,
                          title: SelectableText(
                            manualListLines[index],
                            style: const TextStyle(
                              color: _adminInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: const Text(
                            'Manual list item',
                            style: TextStyle(
                              color: _adminMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          secondary: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: _adminMuted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                if (order.hasUpload) ...[
                  const SizedBox(height: 12),
                  const _AdminSectionHeader(
                    title: 'Uploaded bill/list image',
                    icon: Icons.image_outlined,
                  ),
                  _AdminCard(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => _showZoomImage(order.uploadedImageUrl),
                      child: AspectRatio(
                        aspectRatio: 1.35,
                        child: ProductImage(url: order.uploadedImageUrl),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _AdminCard(
                  child: Column(
                    children: [
                      const _AdminSectionHeader(
                        title: 'Bill amount',
                        icon: Icons.request_quote_outlined,
                      ),
                      TextField(
                        controller: _cartItemsAmount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cart items amount',
                          prefixIcon: Icon(Icons.shopping_basket_outlined),
                        ),
                      ),
                      if (order.hasUpload) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _photoListAmount,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Photo list amount',
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                        ),
                      ],
                      if (order.hasManualList) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _manualListAmount,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Manual list amount',
                            prefixIcon: Icon(Icons.edit_note),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: _subtotal,
                        readOnly: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Order subtotal',
                          prefixIcon: Icon(Icons.calculate_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _delivery,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Delivery charge',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _service,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Service charge',
                          prefixIcon: Icon(Icons.receipt_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: [
                          'pending',
                          'receipt uploaded',
                          'collected',
                        ].contains(_paymentStatus)
                            ? _paymentStatus
                            : 'pending',
                        decoration:
                            const InputDecoration(labelText: 'Payment status'),
                        items: const [
                          DropdownMenuItem(
                              value: 'pending', child: Text('pending')),
                          DropdownMenuItem(
                            value: 'receipt uploaded',
                            child: Text('receipt uploaded'),
                          ),
                          DropdownMenuItem(
                              value: 'collected', child: Text('collected')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _paymentStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      PrimaryActionButton(
                        label: 'Save bill amount',
                        icon: Icons.save,
                        isLoading: _isSavingBill,
                        onPressed: () => _saveBill(order),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _AdminCard(
                  child: Column(
                    children: [
                      const _AdminSectionHeader(
                        title: 'Fulfillment',
                        icon: Icons.route_outlined,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue:
                            AppConstants.selectableOrderStatuses.contains(
                          _status,
                        )
                                ? _status
                                : null,
                        decoration:
                            const InputDecoration(labelText: 'Order status'),
                        items: AppConstants.selectableOrderStatuses
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                      if (_status == 'Rejected') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _rejectionReason,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Rejection reason',
                            prefixIcon: Icon(Icons.report_problem_outlined),
                          ),
                        ),
                      ],
                      if (_status == 'Out for Delivery') ...[
                        const SizedBox(height: 10),
                        StreamBuilder<List<UserProfile>>(
                          stream: appState.firestoreService.watchDeliveryBoys(
                            activeOnly: true,
                          ),
                          builder: (context, snapshot) {
                            final deliveryBoys =
                                snapshot.data ?? const <UserProfile>[];
                            final selectedId = deliveryBoys.any(
                              (deliveryBoy) =>
                                  deliveryBoy.uid == _selectedDeliveryBoyId,
                            )
                                ? _selectedDeliveryBoyId
                                : null;
                            return DropdownButtonFormField<String>(
                              initialValue: selectedId,
                              decoration: const InputDecoration(
                                labelText: 'Assign delivery boy',
                                prefixIcon: Icon(Icons.delivery_dining),
                              ),
                              hint: Text(
                                deliveryBoys.isEmpty
                                    ? 'No active delivery boys'
                                    : 'Select delivery boy',
                              ),
                              items: deliveryBoys
                                  .map(
                                    (deliveryBoy) => DropdownMenuItem(
                                      value: deliveryBoy.uid,
                                      child: Text(
                                        deliveryBoy.fullName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: deliveryBoys.isEmpty
                                  ? null
                                  : (value) {
                                      UserProfile? selected;
                                      for (final deliveryBoy in deliveryBoys) {
                                        if (deliveryBoy.uid == value) {
                                          selected = deliveryBoy;
                                          break;
                                        }
                                      }
                                      if (selected == null) {
                                        return;
                                      }
                                      final selectedDeliveryBoy = selected;
                                      setState(() {
                                        _selectedDeliveryBoyId =
                                            selectedDeliveryBoy.uid;
                                        _deliveryPerson.text =
                                            selectedDeliveryBoy.fullName;
                                        _deliveryPhone.text =
                                            selectedDeliveryBoy.phone;
                                      });
                                    },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _deliveryPerson,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Delivery boy name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _deliveryPhone,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Delivery boy phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ] else if (order.hasAssignedDeliveryContact) ...[
                        const SizedBox(height: 10),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: _adminBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _adminLine),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _AdminSectionHeader(
                                  title: 'Assigned delivery boy',
                                  icon: Icons.delivery_dining,
                                ),
                                _OrderInfoRow(
                                  'Name',
                                  order.assignedDeliveryPerson,
                                ),
                                _OrderInfoRow(
                                  'Phone',
                                  order.assignedDeliveryPhone,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextField(
                        controller: _adminNotes,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Admin notes',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryActionButton(
                        label: 'Update status',
                        icon: Icons.update,
                        isLoading: _isUpdatingStatus,
                        onPressed: () => _updateStatus(order),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveBill(OrderModel order) async {
    final cartItemsAmount =
        _readNonNegativeAmount(_cartItemsAmount, 'cart items amount');
    final photoListAmount =
        _readNonNegativeAmount(_photoListAmount, 'photo list amount');
    final manualListAmount =
        _readNonNegativeAmount(_manualListAmount, 'manual list amount');
    final delivery = _readNonNegativeAmount(_delivery, 'delivery charge');
    final service = _readNonNegativeAmount(_service, 'service charge');
    if (cartItemsAmount == null ||
        photoListAmount == null ||
        manualListAmount == null ||
        delivery == null ||
        service == null) {
      return;
    }

    setState(() => _isSavingBill = true);
    try {
      await context.read<AppState>().firestoreService.updateOrderFinancials(
            order: order,
            cartItemsAmount: cartItemsAmount,
            photoListAmount: photoListAmount,
            manualListAmount: manualListAmount,
            deliveryCharge: delivery,
            serviceCharge: service,
            paymentStatus: _paymentStatus,
          );
      if (mounted) {
        showSnack(context, 'Bill updated.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBill = false);
      }
    }
  }

  double? _readNonNegativeAmount(
    TextEditingController controller,
    String label,
  ) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      showSnack(context, 'Enter a valid $label.');
      return null;
    }
    return value;
  }

  Future<void> _updateStatus(OrderModel order) async {
    final deliveryPhoneText = _deliveryPhone.text.trim();
    final deliveryPhoneError =
        deliveryPhoneText.isEmpty ? null : Validators.phone(deliveryPhoneText);
    if (deliveryPhoneError != null) {
      showSnack(context, deliveryPhoneError);
      return;
    }
    final rejectionReason = _rejectionReason.text.trim();
    if (_status == 'Rejected' && rejectionReason.isEmpty) {
      showSnack(context, 'Enter the rejection reason before rejecting.');
      return;
    }
    if (_status == 'Out for Delivery' &&
        (_selectedDeliveryBoyId == null || _selectedDeliveryBoyId!.isEmpty)) {
      showSnack(context, 'Select a delivery boy before sending delivery.');
      return;
    }
    final deliveryPhone = deliveryPhoneText.isEmpty
        ? ''
        : PhoneUtils.normalizeSriLankanPhone(deliveryPhoneText);
    setState(() => _isUpdatingStatus = true);
    try {
      await context.read<AppState>().firestoreService.updateOrderStatus(
            order: order,
            status: _status,
            adminNotes: _adminNotes.text.trim(),
            rejectionReason: _status == 'Rejected' ? rejectionReason : '',
            assignedDeliveryBoyId:
                _status == 'Out for Delivery' ? _selectedDeliveryBoyId : null,
            assignedDeliveryPerson: _deliveryPerson.text.trim(),
            assignedDeliveryPhone: deliveryPhone,
          );
      if (mounted) {
        showSnack(context, 'Status updated and notification recorded.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _launchWhatsapp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse('https://wa.me/$digits'));
  }

  void _showZoomImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 280,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66736B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAccountsManagementScreen extends StatefulWidget {
  const AdminAccountsManagementScreen({super.key});

  @override
  State<AdminAccountsManagementScreen> createState() =>
      _AdminAccountsManagementScreenState();
}

class _AdminAccountsManagementScreenState
    extends State<AdminAccountsManagementScreen> {
  static const _filters = ['All', 'Today', 'This month', 'Custom'];

  var _filter = 'This month';
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Accounts',
      body: _AdminPage(
        child: Column(
          children: [
            _AdminFilterBar(
              filters: _filters,
              selected: _filter,
              onSelected: _selectFilter,
            ),
            if (_filter == 'Custom')
              _AccountDateControls(
                startDate: _customStart,
                endDate: _customEnd,
                onStartTap: () => _pickCustomDate(isStart: true),
                onEndTap: () => _pickCustomDate(isStart: false),
                onClear: () => setState(() {
                  _customStart = null;
                  _customEnd = null;
                }),
              ),
            Expanded(
              child: StreamBuilder<List<AccountSaleRecord>>(
                stream: appState.firestoreService.watchAccountSales(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const RefreshableCenteredContent(
                      child: LoadingView(),
                    );
                  }

                  final records = snapshot.data ?? const <AccountSaleRecord>[];
                  if (records.isEmpty) {
                    return const RefreshableCenteredContent(
                      child: EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No account records',
                        message:
                            'Delivered order sales will appear here automatically.',
                      ),
                    );
                  }

                  final filteredRecords = _filteredRecords(records);
                  final manualRecords = filteredRecords
                      .where(
                        (record) =>
                            record.hasShoppingList ||
                            record.hasManualSales ||
                            record.needsManualSalesAmount,
                      )
                      .toList();
                  final filteredSummary = _AccountsSummary(filteredRecords);

                  return ListView(
                    physics: appRefreshScrollPhysics,
                    padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
                    children: [
                      _AdminReveal(
                        child: _AccountSummaryPanel(
                          summary: filteredSummary,
                          rangeLabel: _rangeLabel,
                          visibleCount: filteredRecords.length,
                          totalCount: records.length,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AccountKpiGrid(summary: filteredSummary),
                      const SizedBox(height: 18),
                      _AdminReveal(
                        child: _AccountReportCard(
                          summary: filteredSummary,
                          rangeLabel: _rangeLabel,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _AdminSectionHeader(
                        title: 'List sales entries',
                        icon: Icons.edit_note,
                      ),
                      if (manualRecords.isEmpty)
                        const _AdminCard(
                          child: Text(
                            'No list sales entries in this date range.',
                            style: TextStyle(
                              color: _adminMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        for (var index = 0;
                            index < manualRecords.length;
                            index++) ...[
                          _AdminReveal(
                            index: index,
                            child: _AccountSaleTile(
                              record: manualRecords[index],
                              onTap: () =>
                                  _showAccountEntryDialog(manualRecords[index]),
                            ),
                          ),
                          if (index != manualRecords.length - 1)
                            const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 18),
                      const _AdminSectionHeader(
                        title: 'Sales history',
                        icon: Icons.history,
                      ),
                      if (filteredRecords.isEmpty)
                        const EmptyState(
                          icon: Icons.history,
                          title: 'No sales in this range',
                          message: 'Try a different date range.',
                        )
                      else
                        for (var index = 0;
                            index < filteredRecords.length;
                            index++) ...[
                          _AdminReveal(
                            index: index,
                            child: _AccountSaleTile(
                              record: filteredRecords[index],
                              onTap: () => _showAccountEntryDialog(
                                filteredRecords[index],
                              ),
                            ),
                          ),
                          if (index != filteredRecords.length - 1)
                            const SizedBox(height: 10),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectFilter(String filter) {
    setState(() {
      _filter = filter;
      if (filter == 'Custom' && _customStart == null && _customEnd == null) {
        final today = _dateOnly(DateTime.now());
        _customStart = today;
        _customEnd = today;
      }
    });
  }

  List<AccountSaleRecord> _filteredRecords(List<AccountSaleRecord> records) {
    switch (_filter) {
      case 'Today':
        return _recordsForToday(records);
      case 'This month':
        return _recordsForThisMonth(records);
      case 'Custom':
        final start = _customStart == null ? null : _dateOnly(_customStart!);
        final end = _customEnd == null ? null : _endOfDay(_customEnd!);
        return records.where((record) {
          final deliveredAt = record.deliveredAt;
          final isAfterStart = start == null || !deliveredAt.isBefore(start);
          final isBeforeEnd = end == null || !deliveredAt.isAfter(end);
          return isAfterStart && isBeforeEnd;
        }).toList();
      default:
        return records;
    }
  }

  List<AccountSaleRecord> _recordsForToday(List<AccountSaleRecord> records) {
    final now = DateTime.now();
    return records
        .where((record) => _isSameDate(record.deliveredAt, now))
        .toList();
  }

  List<AccountSaleRecord> _recordsForThisMonth(
    List<AccountSaleRecord> records,
  ) {
    final now = DateTime.now();
    return records
        .where(
          (record) =>
              record.deliveredAt.year == now.year &&
              record.deliveredAt.month == now.month,
        )
        .toList();
  }

  String get _rangeLabel {
    if (_filter != 'Custom') {
      return _filter;
    }
    final formatter = DateFormat.yMMMd();
    final start =
        _customStart == null ? 'Start' : formatter.format(_customStart!);
    final end = _customEnd == null ? 'End' : formatter.format(_customEnd!);
    return '$start to $end';
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? (_customStart ?? now) : (_customEnd ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _customStart = _dateOnly(selected);
        if (_customEnd != null && _customEnd!.isBefore(_customStart!)) {
          _customEnd = _customStart;
        }
      } else {
        _customEnd = _dateOnly(selected);
        if (_customStart != null && _customStart!.isAfter(_customEnd!)) {
          _customStart = _customEnd;
        }
      }
    });
  }

  Future<void> _showAccountEntryDialog(AccountSaleRecord record) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AccountSaleEditorDialog(record: record),
    );
    if (mounted && saved == true) {
      showSnack(context, 'Account entry updated.');
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _AccountDateControls extends StatelessWidget {
  const _AccountDateControls({
    required this.startDate,
    required this.endDate,
    required this.onStartTap,
    required this.onEndTap,
    required this.onClear,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMd();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final controls = [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStartTap,
                icon: const Icon(Icons.event),
                label: Text(
                  startDate == null
                      ? 'Start date'
                      : formatter.format(startDate!),
                ),
              ),
            ),
            const SizedBox(width: 10, height: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEndTap,
                icon: const Icon(Icons.event_available),
                label: Text(
                  endDate == null ? 'End date' : formatter.format(endDate!),
                ),
              ),
            ),
            const SizedBox(width: 10, height: 10),
            IconButton.filledTonal(
              tooltip: 'Clear dates',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ];

          if (compact) {
            return Column(
              children: [
                Row(children: controls.take(3).toList()),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: controls.last,
                ),
              ],
            );
          }

          return Row(children: controls);
        },
      ),
    );
  }
}

class _AccountSummaryPanel extends StatelessWidget {
  const _AccountSummaryPanel({
    required this.summary,
    required this.rangeLabel,
    required this.visibleCount,
    required this.totalCount,
  });

  final _AccountsSummary summary;
  final String rangeLabel;
  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final profitColor =
        summary.profitOrLoss < 0 ? const Color(0xFFC83A2B) : _adminPrimary;
    return _AdminCard(
      padding: EdgeInsets.zero,
      borderColor: const Color(0xFFCFE1D5),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF2F8F4),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final headline = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _AdminIconBadge(
                      icon: Icons.account_balance_wallet_outlined,
                      color: _adminPrimary,
                      size: 42,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rangeLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _adminInk,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  summary.totalSales.money,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Delivered revenue',
                  style: TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AdminPill(
                      label: '$visibleCount of $totalCount records',
                      color: _adminBlue,
                      icon: Icons.filter_alt_outlined,
                    ),
                    _AdminPill(
                      label: '${summary.pendingManualCount} pending list',
                      color: summary.pendingManualCount > 0
                          ? _adminWarning
                          : _adminPrimary,
                      icon: summary.pendingManualCount > 0
                          ? Icons.edit_note
                          : Icons.check_circle_outline,
                    ),
                  ],
                ),
              ],
            );

            final finance = Column(
              children: [
                _AccountMiniMetric(
                  label: 'Photo list',
                  value: summary.photoListSales.money,
                  color: _adminWarning,
                ),
                const SizedBox(height: 10),
                _AccountMiniMetric(
                  label: 'Manual list',
                  value: summary.manualListSales.money,
                  color: _adminViolet,
                ),
                const SizedBox(height: 10),
                _AccountMiniMetric(
                  label: 'Profit / loss',
                  value: summary.profitOrLoss.money,
                  color: profitColor,
                ),
                const SizedBox(height: 10),
                _AccountMiniMetric(
                  label: 'Costs/expenses',
                  value: summary.costs.money,
                  color: _adminMuted,
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headline,
                  const SizedBox(height: 16),
                  finance,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: headline),
                const SizedBox(width: 20),
                SizedBox(width: 260, child: finance),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccountMiniMetric extends StatelessWidget {
  const _AccountMiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _adminMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountKpiGrid extends StatelessWidget {
  const _AccountKpiGrid({required this.summary});

  final _AccountsSummary summary;

  @override
  Widget build(BuildContext context) {
    final profitColor =
        summary.profitOrLoss < 0 ? const Color(0xFFC83A2B) : _adminPrimary;
    final metrics = [
      _AccountKpiTile(
        label: 'Orders',
        value: summary.orderCount.toString(),
        icon: Icons.verified_outlined,
        color: _adminBlue,
      ),
      _AccountKpiTile(
        label: 'Cart sales',
        value: summary.cartSales.money,
        icon: Icons.shopping_cart_checkout,
        color: _adminPrimary,
      ),
      _AccountKpiTile(
        label: 'Photo list',
        value: summary.photoListSales.money,
        icon: Icons.image_outlined,
        color: _adminWarning,
      ),
      _AccountKpiTile(
        label: 'Manual list',
        value: summary.manualListSales.money,
        icon: Icons.edit_note,
        color: _adminViolet,
      ),
      _AccountKpiTile(
        label: 'Delivery/service',
        value: summary.charges.money,
        icon: Icons.local_shipping_outlined,
        color: _adminBlue,
      ),
      _AccountKpiTile(
        label: 'Costs',
        value: summary.costs.money,
        icon: Icons.receipt_long_outlined,
        color: _adminMuted,
      ),
      _AccountKpiTile(
        label: 'Profit / loss',
        value: summary.profitOrLoss.money,
        icon:
            summary.profitOrLoss < 0 ? Icons.trending_down : Icons.trending_up,
        color: profitColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 900
            ? 6
            : constraints.maxWidth >= 680
                ? 3
                : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: count == 2 ? 1.55 : 1.75,
          children: metrics,
        );
      },
    );
  }
}

class _AccountKpiTile extends StatelessWidget {
  const _AccountKpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminIconBadge(icon: icon, color: color, size: 34),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _adminInk,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _adminMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsSummary {
  const _AccountsSummary(this.records);

  final List<AccountSaleRecord> records;

  int get orderCount => records.length;
  int get manualEntryCount => records
      .where(
        (record) =>
            record.hasShoppingList ||
            record.hasManualSales ||
            record.needsManualSalesAmount,
      )
      .length;
  int get pendingManualCount =>
      records.where((record) => record.needsManualSalesAmount).length;
  double get cartSales => records.fold<double>(
        0,
        (sum, record) => sum + record.cartSalesAmount,
      );
  double get manualSales => records.fold<double>(
        0,
        (sum, record) => sum + record.manualSalesAmount,
      );
  double get photoListSales => records.fold<double>(
        0,
        (sum, record) => sum + record.photoListSalesAmount,
      );
  double get manualListSales => records.fold<double>(
        0,
        (sum, record) => sum + record.manualListSalesAmount,
      );
  double get charges => records.fold<double>(
        0,
        (sum, record) => sum + record.chargeAmount,
      );
  double get totalSales => records.fold<double>(
        0,
        (sum, record) => sum + record.totalSalesAmount,
      );
  double get costs => records.fold<double>(
        0,
        (sum, record) => sum + record.totalCostAmount,
      );
  double get profitOrLoss => records.fold<double>(
        0,
        (sum, record) => sum + record.profitOrLoss,
      );
}

class _AccountReportCard extends StatelessWidget {
  const _AccountReportCard({
    required this.summary,
    required this.rangeLabel,
  });

  final _AccountsSummary summary;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final profitColor =
        summary.profitOrLoss < 0 ? const Color(0xFFC83A2B) : _adminPrimary;
    return _AdminCard(
      child: Column(
        children: [
          const _AdminSectionHeader(
            title: 'Date-wise report',
            icon: Icons.summarize_outlined,
          ),
          _AccountReportRow(label: 'Range', value: rangeLabel),
          _AccountReportRow(
            label: 'Delivered orders',
            value: summary.orderCount.toString(),
          ),
          _AccountReportRow(
            label: 'Cart item sales',
            value: summary.cartSales.money,
          ),
          _AccountReportRow(
            label: 'Photo list sales',
            value: summary.photoListSales.money,
          ),
          _AccountReportRow(
            label: 'Manual list sales',
            value: summary.manualListSales.money,
          ),
          _AccountReportRow(
            label: 'Delivery/service',
            value: summary.charges.money,
          ),
          _AccountReportRow(
            label: 'Costs/expenses',
            value: summary.costs.money,
          ),
          _AccountReportRow(
            label: 'Pending list',
            value: summary.pendingManualCount.toString(),
          ),
          const Divider(height: 22),
          _AccountReportRow(
            label: 'Profit / loss',
            value: summary.profitOrLoss.money,
            valueColor: profitColor,
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

class _AccountReportRow extends StatelessWidget {
  const _AccountReportRow({
    required this.label,
    required this.value,
    this.valueColor = _adminInk,
    this.isStrong = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _adminMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontWeight: isStrong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSaleTile extends StatelessWidget {
  const _AccountSaleTile({
    required this.record,
    required this.onTap,
  });

  final AccountSaleRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        record.needsManualSalesAmount ? _adminWarning : _adminPrimary;
    final profitColor =
        record.profitOrLoss < 0 ? const Color(0xFFC83A2B) : _adminPrimary;
    return _AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: record.needsManualSalesAmount
          ? _adminWarning.withValues(alpha: 0.45)
          : _adminLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminIconBadge(
                icon: record.needsManualSalesAmount
                    ? Icons.edit_note
                    : Icons.receipt_long,
                color: statusColor,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_shortId(record.orderId)} - ${DateFormat.MMMd().add_jm().format(record.deliveredAt)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.totalSalesAmount.money,
                    style: const TextStyle(
                      color: _adminInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'P/L ${record.profitOrLoss.money}',
                    style: TextStyle(
                      color: profitColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: _adminMuted, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _AdminPill(
                label: record.orderMethod,
                color: _adminBlue,
                icon: Icons.shopping_cart_checkout,
              ),
              _AdminPill(
                label: 'Cart ${record.cartSalesAmount.money}',
                color: _adminPrimary,
                icon: Icons.shopping_basket_outlined,
              ),
              if (record.needsManualSalesAmount)
                const _AdminPill(
                  label: 'List pending',
                  color: _adminWarning,
                  icon: Icons.edit_note,
                )
              else if (record.hasPhotoList || record.photoListSalesAmount > 0)
                _AdminPill(
                  label: 'Photo ${record.photoListSalesAmount.money}',
                  color: _adminWarning,
                  icon: Icons.image_outlined,
                ),
              if (!record.needsManualSalesAmount &&
                  (record.hasManualList || record.manualListSalesAmount > 0))
                _AdminPill(
                  label: 'Manual ${record.manualListSalesAmount.money}',
                  color: _adminViolet,
                  icon: Icons.edit_note,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountSaleEditorDialog extends StatefulWidget {
  const _AccountSaleEditorDialog({required this.record});

  final AccountSaleRecord record;

  @override
  State<_AccountSaleEditorDialog> createState() =>
      _AccountSaleEditorDialogState();
}

class _AccountSaleEditorDialogState extends State<_AccountSaleEditorDialog> {
  late final TextEditingController _photoListSales;
  late final TextEditingController _manualListSales;
  late final TextEditingController _cost;
  late final TextEditingController _expense;
  late final TextEditingController _notes;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _photoListSales = TextEditingController(
      text: widget.record.photoListSalesAmount.toStringAsFixed(2),
    );
    _manualListSales = TextEditingController(
      text: widget.record.manualListSalesAmount.toStringAsFixed(2),
    );
    _cost = TextEditingController(
      text: widget.record.costAmount.toStringAsFixed(2),
    );
    _expense = TextEditingController(
      text: widget.record.expenseAmount.toStringAsFixed(2),
    );
    _notes = TextEditingController(text: widget.record.accountNotes);
  }

  @override
  void dispose() {
    _photoListSales.dispose();
    _manualListSales.dispose();
    _cost.dispose();
    _expense.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectedPhotoList = _amountFrom(_photoListSales.text);
    final projectedManualList = _amountFrom(_manualListSales.text);
    final projectedCost = _amountFrom(_cost.text);
    final projectedExpense = _amountFrom(_expense.text);
    final projectedSales = widget.record.cartSalesAmount +
        projectedPhotoList +
        projectedManualList +
        widget.record.deliveryCharge +
        widget.record.serviceCharge;
    final projectedProfit = projectedSales - projectedCost - projectedExpense;

    return AlertDialog(
      backgroundColor: _adminSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          const _AdminIconBadge(
            icon: Icons.account_balance_wallet_outlined,
            color: _adminPrimary,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Account ${_shortId(widget.record.orderId)}')),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OrderInfoRow('Customer', widget.record.customerName),
              _OrderInfoRow('Method', widget.record.orderMethod),
              _OrderInfoRow('Cart sales', widget.record.cartSalesAmount.money),
              _OrderInfoRow(
                  'Delivery/service', widget.record.chargeAmount.money),
              const Divider(height: 22),
              TextField(
                controller: _photoListSales,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Photo list sales',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _manualListSales,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Manual list sales',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost amount',
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _expense,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Other expenses',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Accounts notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 12),
              _AdminCard(
                padding: const EdgeInsets.all(12),
                borderColor: _adminLine,
                child: Column(
                  children: [
                    _AccountReportRow(
                      label: 'Projected sales',
                      value: projectedSales.money,
                    ),
                    _AccountReportRow(
                      label: 'Projected P/L',
                      value: projectedProfit.money,
                      valueColor: projectedProfit < 0
                          ? const Color(0xFFC83A2B)
                          : _adminPrimary,
                      isStrong: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Saving' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().firestoreService.updateAccountSaleManuals(
            record: widget.record,
            photoListSalesAmount: _amountFrom(_photoListSales.text),
            manualListSalesAmount: _amountFrom(_manualListSales.text),
            costAmount: _amountFrom(_cost.text),
            expenseAmount: _amountFrom(_expense.text),
            accountNotes: _notes.text,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
        setState(() => _isSaving = false);
      }
    }
  }

  double _amountFrom(String raw) {
    return double.tryParse(raw.trim()) ?? 0;
  }
}

String _shortId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return value.substring(0, 8);
}

String _normalizeOrderSearchInput(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\border\b'), '')
      .replaceAll(RegExp(r'\bid\b'), '')
      .replaceAll(RegExp(r'[^a-z0-9-]'), '');
}

List<OrderModel> _matchingOrderSearchResults(
  List<OrderModel> orders,
  String query,
) {
  if (query.length < _minimumOrderSearchLength) {
    return const <OrderModel>[];
  }
  final compactQuery = query.replaceAll('-', '');
  final exactMatches = <OrderModel>[];
  final prefixMatches = <OrderModel>[];

  for (final order in orders) {
    final orderId = order.orderId.toLowerCase();
    final compactOrderId = orderId.replaceAll('-', '');
    final isExact = orderId == query || compactOrderId == compactQuery;
    final isPrefix =
        orderId.startsWith(query) || compactOrderId.startsWith(compactQuery);
    if (isExact) {
      exactMatches.add(order);
    } else if (isPrefix) {
      prefixMatches.add(order);
    }
  }

  return <OrderModel>[...exactMatches, ...prefixMatches];
}

class AdminOfferManagementScreen extends StatelessWidget {
  const AdminOfferManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Manage offers',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _adminInk,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminOfferFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Offer'),
      ),
      body: _AdminPage(
        child: StreamBuilder<List<Offer>>(
          stream: appState.firestoreService.watchOffers(activeOnly: false),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load offers',
                  message: appFriendlyErrorMessage(snapshot.error),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RefreshableCenteredContent(
                child: LoadingView(),
              );
            }
            final offers = snapshot.data ?? const <Offer>[];
            if (offers.isEmpty) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'No offers',
                  message: 'Create home page banners for current promotions.',
                ),
              );
            }
            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final offer = offers[index];
                return _AdminReveal(
                  index: index,
                  child: _AdminOfferTile(
                    offer: offer,
                    onActiveChanged: (value) => appState.firestoreService
                        .toggleOffer(offer.offerId, value),
                    onDelete: () => _confirmDeleteOffer(context, offer),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminOfferFormScreen(offer: offer),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOffer(
    BuildContext context,
    Offer offer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove offer?'),
          content: Text(
            'This will permanently remove "${offer.title}" from the home page offers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC83A2B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await context.read<AppState>().firestoreService.deleteOffer(
            offer.offerId,
          );
      if (context.mounted) {
        showSnack(context, 'Offer removed.');
      }
    } catch (error) {
      if (context.mounted) {
        showSnack(context, error.toString());
      }
    }
  }
}

class _AdminOfferTile extends StatelessWidget {
  const _AdminOfferTile({
    required this.offer,
    required this.onTap,
    required this.onActiveChanged,
    required this.onDelete,
  });

  final Offer offer;
  final VoidCallback onTap;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isLive = offer.isCurrentlyActive(DateTime.now());
    final statusColor = isLive
        ? _adminPrimary
        : offer.isActive
            ? _adminWarning
            : _adminMuted;
    final dateLabel = _offerDateLabel(offer);
    return _AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 64,
            child: ProductImage(url: offer.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (offer.tamilTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    offer.tamilTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _adminMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  offer.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _AdminPill(
                      label: isLive
                          ? 'Live'
                          : offer.isActive
                              ? 'Scheduled'
                              : 'Hidden',
                      color: statusColor,
                      icon: Icons.circle,
                    ),
                    if (dateLabel != null)
                      _AdminPill(
                        label: dateLabel,
                        color: _adminBlue,
                        icon: Icons.event_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Switch(
                value: offer.isActive,
                onChanged: onActiveChanged,
              ),
              Text(
                offer.isActive ? 'Active' : 'Hidden',
                style: TextStyle(
                  color: offer.isActive ? _adminPrimary : _adminMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              IconButton(
                tooltip: 'Remove offer',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFC83A2B),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: _adminMuted),
        ],
      ),
    );
  }
}

class AdminOfferFormScreen extends StatefulWidget {
  const AdminOfferFormScreen({super.key, this.offer});

  final Offer? offer;

  @override
  State<AdminOfferFormScreen> createState() => _AdminOfferFormScreenState();
}

class _AdminOfferFormScreenState extends State<AdminOfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _tamilTitle = TextEditingController();
  final _caption = TextEditingController();
  final _tamilCaption = TextEditingController();
  String? _imagePath;
  DateTime? _startDate;
  DateTime? _endDate;
  var _isActive = true;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final offer = widget.offer;
    if (offer != null) {
      _title.text = offer.title;
      _tamilTitle.text = offer.tamilTitle;
      _caption.text = offer.caption;
      _tamilCaption.text = offer.tamilCaption;
      _startDate = offer.startDate;
      _endDate = offer.endDate;
      _isActive = offer.isActive;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _tamilTitle.dispose();
    _caption.dispose();
    _tamilCaption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminScaffold(
      title: widget.offer == null ? 'Add offer' : 'Edit offer',
      actions: widget.offer == null
          ? null
          : [
              _AdminAppBarButton(
                tooltip: 'Remove offer',
                icon: Icons.delete_outline,
                onPressed: _isSaving ? () {} : _confirmDeleteOffer,
              ),
            ],
      body: _AdminPage(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: appRefreshScrollPhysics,
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
            children: [
              _AdminReveal(
                child: _AdminCard(
                  child: Column(
                    children: [
                      const _AdminSectionHeader(
                        title: 'Offer details',
                        icon: Icons.local_offer_outlined,
                      ),
                      AppTextField(
                        controller: _title,
                        label: 'Offer title',
                        validator: (value) => Validators.requiredText(
                          value,
                          'Offer title',
                        ),
                        prefixIcon: Icons.title,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _tamilTitle,
                        label: 'Tamil offer title',
                        prefixIcon: Icons.translate,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _caption,
                        label: 'Caption',
                        validator: (value) => Validators.requiredText(
                          value,
                          'Caption',
                        ),
                        maxLines: 3,
                        prefixIcon: Icons.notes,
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _tamilCaption,
                        label: 'Tamil caption',
                        maxLines: 3,
                        prefixIcon: Icons.translate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AdminReveal(
                index: 1,
                child: _AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _AdminSectionHeader(
                        title: 'Schedule',
                        icon: Icons.event_outlined,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isActive,
                        onChanged: _isSaving
                            ? null
                            : (value) => setState(() => _isActive = value),
                        title: const Text(
                          'Show offer',
                          style: TextStyle(
                            color: _adminInk,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: const Text(
                          'Only active offers appear on the customer home page.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _pickStartDate,
                              icon: const Icon(Icons.today_outlined),
                              label: Text(_scheduleLabel(
                                label: 'Start',
                                date: _startDate,
                              )),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _pickEndDate,
                              icon: const Icon(Icons.event_available_outlined),
                              label: Text(_scheduleLabel(
                                label: 'End',
                                date: _endDate,
                              )),
                            ),
                          ),
                        ],
                      ),
                      if (_startDate != null || _endDate != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _isSaving ? null : _clearSchedule,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear dates'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AdminReveal(
                index: 2,
                child: _AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _AdminSectionHeader(
                        title: 'Offer image',
                        icon: Icons.image_outlined,
                      ),
                      SizedBox(
                        height: 172,
                        child: _buildImagePreview(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _pickOfferImage(fromCamera: false),
                              icon: const Icon(Icons.image),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _pickOfferImage(fromCamera: true),
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                      if (_imagePath != null) ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: _AdminPill(
                            label: 'Offer image selected',
                            color: _adminPrimary,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Save offer',
                icon: Icons.save,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveOffer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final imagePath = _imagePath;
    final currentImageUrl = widget.offer?.imageUrl ?? '';
    Widget image;
    if (imagePath != null) {
      image = Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (currentImageUrl.isNotEmpty) {
      image = ProductImage(url: currentImageUrl, radius: 0);
    } else {
      image = const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF6EF),
              Color(0xFFFFF8F3),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.local_offer_outlined,
            color: _adminPrimary,
            size: 46,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }

  Future<void> _saveOffer() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_imagePath == null && (widget.offer?.imageUrl ?? '').isEmpty) {
      showSnack(context, 'Offer image is required.');
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      showSnack(context, 'End date must be after the start date.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      final offerId = widget.offer?.offerId ?? const Uuid().v4();
      var imageUrl = widget.offer?.imageUrl ?? '';
      var imagePublicId = widget.offer?.imagePublicId ?? '';
      if (_imagePath != null) {
        final uploadedImage = await ImageUploadService.uploadCatalogImage(
          imageFile: File(_imagePath!),
          collection: 'offers',
          entityId: offerId,
        );
        imageUrl = uploadedImage.secureUrl;
        imagePublicId = uploadedImage.publicId;
      }
      final offer = Offer(
        offerId: offerId,
        title: _title.text.trim(),
        tamilTitle: _tamilTitle.text.trim(),
        caption: _caption.text.trim(),
        tamilCaption: _tamilCaption.text.trim(),
        imageUrl: imageUrl,
        imagePublicId: imagePublicId,
        createdAt: widget.offer?.createdAt ?? DateTime.now(),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
      );
      await appState.firestoreService.saveOffer(offer);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteOffer() async {
    if (_isSaving) {
      return;
    }
    final offer = widget.offer;
    if (offer == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove offer?'),
          content: Text(
            'This will permanently remove "${offer.title}" from the home page offers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC83A2B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().firestoreService.deleteOffer(
            offer.offerId,
          );
      if (mounted) {
        showSnack(context, 'Offer removed.');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickOfferImage({required bool fromCamera}) async {
    final imageFile =
        fromCamera ? await takePhotoFromCamera() : await pickImageFromGallery();
    if (!mounted || imageFile == null) {
      return;
    }
    setState(() => _imagePath = imageFile.path);
  }

  Future<void> _pickStartDate() async {
    final selected = await _pickDate(
      initialDate: _startDate ?? DateTime.now(),
    );
    if (!mounted || selected == null) {
      return;
    }
    final nextStart = _dateOnly(selected);
    setState(() {
      _startDate = nextStart;
      if (_endDate != null && _endDate!.isBefore(nextStart)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final selected = await _pickDate(
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() => _endDate = _endOfDay(selected));
  }

  Future<DateTime?> _pickDate({required DateTime initialDate}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
  }

  void _clearSchedule() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  String _scheduleLabel({
    required String label,
    required DateTime? date,
  }) {
    if (date == null) {
      return '$label date';
    }
    return '$label ${DateFormat.yMMMd().format(date)}';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }
}

String? _offerDateLabel(Offer offer) {
  final startDate = offer.startDate;
  final endDate = offer.endDate;
  final formatter = DateFormat.MMMd();
  if (startDate == null && endDate == null) {
    return null;
  }
  if (startDate != null && endDate != null) {
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }
  if (startDate != null) {
    return 'From ${formatter.format(startDate)}';
  }
  return 'Until ${formatter.format(endDate!)}';
}

class AdminProductManagementScreen extends StatelessWidget {
  const AdminProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Manage products',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _adminInk,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
      body: _AdminPage(
        child: StreamBuilder<List<Product>>(
          stream: appState.firestoreService.watchProducts(activeOnly: false),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load products',
                  message: appFriendlyErrorMessage(snapshot.error),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RefreshableCenteredContent(
                child: LoadingView(),
              );
            }
            final products = snapshot.data ?? const <Product>[];
            if (products.isEmpty) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products',
                  message: 'Add catalog products for customers to order.',
                ),
              );
            }
            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                return _AdminReveal(
                  index: index,
                  child: _AdminProductTile(
                    product: product,
                    onActiveChanged: (value) => appState.firestoreService
                        .disableProduct(product.productId, value),
                    onDelete: () => _confirmDeleteProduct(context, product),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminProductFormScreen(
                          product: product,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove product?'),
          content: Text(
            'This will permanently remove "${product.name}" from the product catalog.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC83A2B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await context.read<AppState>().firestoreService.deleteProduct(
            product.productId,
          );
      if (context.mounted) {
        showSnack(context, 'Product removed.');
      }
    } catch (error) {
      if (context.mounted) {
        showSnack(context, error.toString());
      }
    }
  }
}

class _AdminProductTile extends StatelessWidget {
  const _AdminProductTile({
    required this.product,
    required this.onTap,
    required this.onActiveChanged,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onTap;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = product.isAvailable ? _adminPrimary : _adminWarning;
    return _AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ProductImage(url: product.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (product.nameTamil.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    product.nameTamil,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _adminMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  product.shopName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _AdminPill(
                      label: '${product.price.money} / ${product.unit}',
                      color: _adminBlue,
                      icon: Icons.payments_outlined,
                    ),
                    _AdminPill(
                      label: product.stockStatus,
                      color: statusColor,
                      icon: Icons.circle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Switch(
                value: product.isActive,
                onChanged: onActiveChanged,
              ),
              Text(
                product.isActive ? 'Active' : 'Hidden',
                style: TextStyle(
                  color: product.isActive ? _adminPrimary : _adminMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              IconButton(
                tooltip: 'Remove product',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: const Color(0xFFC83A2B),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: _adminMuted),
        ],
      ),
    );
  }
}

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameTamil = TextEditingController();
  final _description = TextEditingController();
  final _descriptionTamil = TextEditingController();
  final _price = TextEditingController();
  final _customUnit = TextEditingController();
  String _unit = AppConstants.productUnits.first;
  String _stockStatus = 'available';
  String? _selectedShopId;
  String? _imagePath;
  var _isPickingImage = false;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _nameTamil.text = product.nameTamil;
      _description.text = product.description;
      _descriptionTamil.text = product.descriptionTamil;
      _price.text = product.price.toStringAsFixed(2);
      if (_isPresetUnit(product.unit)) {
        _unit = product.unit;
      } else {
        _unit = AppConstants.productUnitOther;
        _customUnit.text = product.unit;
      }
      _stockStatus = product.stockStatus;
      _selectedShopId = product.shopId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nameTamil.dispose();
    _description.dispose();
    _descriptionTamil.dispose();
    _price.dispose();
    _customUnit.dispose();
    super.dispose();
  }

  bool get _isCustomUnit => _unit == AppConstants.productUnitOther;

  bool _isPresetUnit(String unit) {
    return unit != AppConstants.productUnitOther &&
        AppConstants.productUnits.contains(unit);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: widget.product == null ? 'Add product' : 'Edit product',
      actions: widget.product == null
          ? null
          : [
              _AdminAppBarButton(
                tooltip: 'Remove product',
                icon: Icons.delete_outline,
                onPressed: _isSaving || _isPickingImage
                    ? () {}
                    : _confirmDeleteProduct,
              ),
            ],
      body: _AdminPage(
        maxWidth: 760,
        child: StreamBuilder<List<Shop>>(
          stream: appState.firestoreService.watchShops(activeOnly: true),
          builder: (context, snapshot) {
            final shops = _uniqueShops(snapshot.data ?? const <Shop>[]);
            if (_selectedShopId != null &&
                _shopForId(shops, _selectedShopId) == null) {
              _selectedShopId = null;
            }
            _selectedShopId ??= shops.isEmpty ? null : shops.first.shopId;
            return Form(
              key: _formKey,
              child: ListView(
                physics: appRefreshScrollPhysics,
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
                children: [
                  if (shops.isEmpty)
                    const EmptyState(
                      icon: Icons.category_outlined,
                      title: 'Add a category first',
                      message: 'Products must be linked to a category.',
                    ),
                  _AdminReveal(
                    child: _AdminCard(
                      child: Column(
                        children: [
                          const _AdminSectionHeader(
                            title: 'Product details',
                            icon: Icons.inventory_2_outlined,
                          ),
                          AppTextField(
                            controller: _name,
                            label: 'Product name',
                            validator: (value) => Validators.requiredText(
                              value,
                              'Product name',
                            ),
                            prefixIcon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: _nameTamil,
                            label: 'Tamil product name',
                            validator: (value) => Validators.requiredText(
                              value,
                              'Tamil product name',
                            ),
                            prefixIcon: Icons.translate,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedShopId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: shops
                                .map(
                                  (shop) => DropdownMenuItem(
                                    value: shop.shopId,
                                    child: Text(shop.shopName),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedShopId = value);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: _description,
                            label: 'Description',
                            maxLines: 3,
                            prefixIcon: Icons.notes,
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: _descriptionTamil,
                            label: 'Tamil description',
                            validator: (value) => Validators.requiredText(
                              value,
                              'Tamil description',
                            ),
                            maxLines: 3,
                            prefixIcon: Icons.translate,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AdminReveal(
                    index: 1,
                    child: _AdminCard(
                      child: Column(
                        children: [
                          const _AdminSectionHeader(
                            title: 'Pricing and stock',
                            icon: Icons.tune,
                          ),
                          AppTextField(
                            controller: _price,
                            label: 'Price',
                            validator: (value) {
                              if ((double.tryParse(value ?? '') ?? 0) <= 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.payments,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _unit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              prefixIcon: Icon(Icons.scale_outlined),
                            ),
                            items: AppConstants.productUnits
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _unit = value);
                              }
                            },
                          ),
                          if (_isCustomUnit) ...[
                            const SizedBox(height: 10),
                            AppTextField(
                              controller: _customUnit,
                              label: 'Custom unit',
                              validator: (value) => Validators.requiredText(
                                value,
                                'Custom unit',
                              ),
                              prefixIcon: Icons.edit_outlined,
                            ),
                          ],
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _stockStatus,
                            decoration: const InputDecoration(
                              labelText: 'Stock status',
                              prefixIcon: Icon(Icons.fact_check_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'available',
                                child: Text('available'),
                              ),
                              DropdownMenuItem(
                                value: 'unavailable',
                                child: Text('unavailable'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _stockStatus = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AdminReveal(
                    index: 2,
                    child: _AdminCard(
                      child: Column(
                        children: [
                          const _AdminSectionHeader(
                            title: 'Product image',
                            icon: Icons.image_outlined,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving || _isPickingImage
                                      ? null
                                      : () => _pickProductImage(
                                            fromCamera: false,
                                          ),
                                  icon: const Icon(Icons.image),
                                  label: const Text('Gallery'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving || _isPickingImage
                                      ? null
                                      : () => _pickProductImage(
                                            fromCamera: true,
                                          ),
                                  icon: const Icon(Icons.photo_camera),
                                  label: const Text('Camera'),
                                ),
                              ),
                            ],
                          ),
                          if (_isPickingImage) ...[
                            const SizedBox(height: 10),
                            const _AdminProgressPill(
                              label: 'Preparing image cropper',
                              color: _adminPrimary,
                            ),
                          ] else if (_imagePath != null) ...[
                            const SizedBox(height: 10),
                            const _AdminPill(
                              label: 'Product image selected',
                              color: _adminPrimary,
                              icon: Icons.check_circle_outline,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(
                    label: 'Save product',
                    icon: Icons.save,
                    isLoading: _isSaving,
                    onPressed: shops.isEmpty || _isSaving || _isPickingImage
                        ? null
                        : () => _saveProduct(shops),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveProduct(List<Shop> shops) async {
    if (_isSaving || _isPickingImage) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final selectedShop = _shopForId(shops, _selectedShopId);
    if (selectedShop == null) {
      showSnack(context, 'Select a category.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      final productId = widget.product?.productId ?? const Uuid().v4();
      var imageUrl = widget.product?.imageUrl ?? '';
      var imagePublicId = widget.product?.imagePublicId ?? '';
      if (_imagePath != null) {
        final uploadedImage = await ImageUploadService.uploadCatalogImage(
          imageFile: File(_imagePath!),
          collection: 'products',
          entityId: productId,
        );
        imageUrl = uploadedImage.secureUrl;
        imagePublicId = uploadedImage.publicId;
      }
      final now = DateTime.now();
      final productUnit = _isCustomUnit ? _customUnit.text.trim() : _unit;
      final product = Product(
        productId: productId,
        shopId: selectedShop.shopId,
        shopName: selectedShop.shopName,
        name: _name.text.trim(),
        nameTamil: _nameTamil.text.trim(),
        category: widget.product?.category ?? 'Other',
        description: _description.text.trim(),
        descriptionTamil: _descriptionTamil.text.trim(),
        price: double.parse(_price.text.trim()),
        imageUrl: imageUrl,
        imagePublicId: imagePublicId,
        unit: productUnit,
        stockStatus: _stockStatus,
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      await appState.firestoreService.saveProduct(product);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteProduct() async {
    if (_isSaving || _isPickingImage) {
      return;
    }
    final product = widget.product;
    if (product == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove product?'),
          content: Text(
            'This will permanently remove "${product.name}" from the product catalog.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC83A2B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().firestoreService.deleteProduct(
            product.productId,
          );
      if (mounted) {
        showSnack(context, 'Product removed.');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickProductImage({required bool fromCamera}) async {
    if (_isSaving || _isPickingImage) {
      return;
    }
    setState(() => _isPickingImage = true);
    try {
      final imageFile = fromCamera
          ? await takeProductPhotoForCrop()
          : await pickProductImageFromGalleryForCrop();
      if (!mounted || imageFile == null) {
        return;
      }
      final croppedImage = await cropProductImageFile(
        context: context,
        imageFile: imageFile,
      );
      if (!mounted || croppedImage == null) {
        return;
      }
      setState(() => _imagePath = croppedImage.path);
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  List<Shop> _uniqueShops(List<Shop> shops) {
    final seenIds = <String>{};
    return [
      for (final shop in shops)
        if (seenIds.add(shop.shopId)) shop,
    ];
  }

  Shop? _shopForId(List<Shop> shops, String? shopId) {
    if (shopId == null) {
      return null;
    }
    for (final shop in shops) {
      if (shop.shopId == shopId) {
        return shop;
      }
    }
    return null;
  }
}

class AdminShopManagementScreen extends StatelessWidget {
  const AdminShopManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Manage categories',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _adminInk,
        foregroundColor: Colors.white,
        onPressed: () => _showShopDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Category'),
      ),
      body: _AdminPage(
        child: StreamBuilder<List<Shop>>(
          stream: appState.firestoreService.watchShops(activeOnly: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RefreshableCenteredContent(
                child: LoadingView(),
              );
            }
            final shops = snapshot.data ?? const <Shop>[];
            if (shops.isEmpty) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories',
                  message: 'Add categories before adding products.',
                ),
              );
            }
            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 96),
              itemCount: shops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final shop = shops[index];
                return _AdminReveal(
                  index: index,
                  child: _AdminShopTile(
                    shop: shop,
                    onActiveChanged: (value) => appState.firestoreService
                        .toggleShop(shop.shopId, value),
                    onTap: () => _showShopDialog(context, shop: shop),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showShopDialog(BuildContext context, {Shop? shop}) {
    final name = TextEditingController(text: shop?.shopName ?? '');
    final address = TextEditingController(text: shop?.address ?? '');
    final phone = TextEditingController(
      text: PhoneUtils.localSriLankanDigits(shop?.phone ?? ''),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _adminSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              _AdminIconBadge(
                icon: Icons.category_outlined,
                color: shop == null ? _adminPrimary : _adminBlue,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(shop == null ? 'Add category' : 'Edit category'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                AppPhoneField(
                  controller: phone,
                  label: 'Contact phone',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  return;
                }
                final phoneError = Validators.phone(phone.text);
                if (phoneError != null) {
                  showSnack(context, phoneError);
                  return;
                }
                final appState = context.read<AppState>();
                final saved = Shop(
                  shopId: shop?.shopId ?? const Uuid().v4(),
                  shopName: name.text.trim(),
                  address: address.text.trim(),
                  phone: PhoneUtils.normalizeSriLankanPhone(phone.text),
                  isActive: shop?.isActive ?? true,
                  createdAt: shop?.createdAt ?? DateTime.now(),
                );
                await appState.firestoreService.saveShop(saved);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _AdminShopTile extends StatelessWidget {
  const _AdminShopTile({
    required this.shop,
    required this.onTap,
    required this.onActiveChanged,
  });

  final Shop shop;
  final VoidCallback onTap;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          _AdminIconBadge(
            icon: Icons.category_outlined,
            color: shop.isActive ? _adminPrimary : _adminMuted,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.shopName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  shop.phone,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (shop.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    shop.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _adminMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Switch(
                value: shop.isActive,
                onChanged: onActiveChanged,
              ),
              Text(
                shop.isActive ? 'Active' : 'Hidden',
                style: TextStyle(
                  color: shop.isActive ? _adminPrimary : _adminMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: _adminMuted),
        ],
      ),
    );
  }
}

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Support tickets',
      actions: [
        _AdminAppBarButton(
          tooltip: 'Find order',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminOrdersScreen.find(),
            ),
          ),
          icon: Icons.manage_search,
        ),
      ],
      body: _AdminPage(
        child: StreamBuilder<List<SupportTicket>>(
          stream: appState.firestoreService.watchTickets(allTickets: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RefreshableCenteredContent(
                child: LoadingView(),
              );
            }
            final tickets = snapshot.data ?? const <SupportTicket>[];
            if (tickets.isEmpty) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.support_agent,
                  title: 'No support tickets',
                  message: 'Customer messages will appear here.',
                ),
              );
            }
            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _AdminReveal(
                  index: index,
                  child: _AdminSupportTile(
                    ticket: ticket,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupportThreadScreen(ticket: ticket),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AdminSupportTile extends StatelessWidget {
  const _AdminSupportTile({
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _adminStatusColor(ticket.status);
    return _AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          _AdminIconBadge(
            icon: Icons.support_agent,
            color: statusColor,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ticket.customerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AdminPill(
            label: ticket.status,
            color: statusColor,
            icon: Icons.circle,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: _adminMuted),
        ],
      ),
    );
  }
}

class AdminCustomerManagementScreen extends StatelessWidget {
  const AdminCustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Customers',
      body: _AdminPage(
        child: StreamBuilder<List<UserProfile>>(
          stream: appState.firestoreService.watchUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RefreshableCenteredContent(
                child: LoadingView(),
              );
            }
            final users = (snapshot.data ?? const <UserProfile>[])
                .where((user) => !user.isDeliveryBoy)
                .toList();
            if (users.isEmpty) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: 'No customers',
                  message: 'Registered users will appear here.',
                ),
              );
            }
            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return _AdminReveal(
                  index: index,
                  child: _AdminCustomerTile(
                    user: user,
                    canToggle: user.uid != appState.profile?.uid,
                    onActiveChanged: (value) =>
                        appState.firestoreService.blockUser(
                      user.uid,
                      !value,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AdminDeliveryBoyManagementScreen extends StatefulWidget {
  const AdminDeliveryBoyManagementScreen({super.key});

  @override
  State<AdminDeliveryBoyManagementScreen> createState() =>
      _AdminDeliveryBoyManagementScreenState();
}

class _AdminDeliveryBoyManagementScreenState
    extends State<AdminDeliveryBoyManagementScreen> {
  final Set<String> _initializedRewardProfiles = <String>{};
  String? _payingDeliveryBoyId;
  String? _addingStarsDeliveryBoyId;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Delivery boys',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeliveryBoyDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add delivery boy'),
      ),
      body: _AdminPage(
        child: StreamBuilder<List<UserProfile>>(
          stream: appState.firestoreService.watchDeliveryBoys(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load delivery boys',
                  message:
                      'The delivery staff list could not be loaded. Please try again.',
                  action: FilledButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const RefreshableCenteredContent(child: LoadingView());
            }
            final deliveryBoys = snapshot.data ?? const <UserProfile>[];
            _initializeRewardProfiles(deliveryBoys, appState);
            if (deliveryBoys.isEmpty) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.delivery_dining,
                  title: 'No delivery boys',
                  message: 'Create accounts for delivery staff here.',
                ),
              );
            }
            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 90),
              itemCount: deliveryBoys.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final deliveryBoy = deliveryBoys[index];
                return _AdminReveal(
                  index: index,
                  child: _DeliveryBoyTile(
                    deliveryBoy: deliveryBoy,
                    onEdit: () => _showDeliveryBoyDialog(
                      context,
                      deliveryBoy: deliveryBoy,
                    ),
                    isPaying: _payingDeliveryBoyId == deliveryBoy.uid,
                    isAddingStars: _addingStarsDeliveryBoyId == deliveryBoy.uid,
                    onPayReward: () => _payReward(deliveryBoy),
                    onAddStars: () => _addRewardStars(deliveryBoy),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _initializeRewardProfiles(
    List<UserProfile> deliveryBoys,
    AppState appState,
  ) {
    for (final deliveryBoy in deliveryBoys) {
      if (deliveryBoy.deliveryRewardStarsInitialized ||
          !_initializedRewardProfiles.add(deliveryBoy.uid)) {
        continue;
      }
      unawaited(
        appState.authService
            .initializeDeliveryRewardStars(uid: deliveryBoy.uid)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _payReward(UserProfile deliveryBoy) async {
    final amountLkr = await showDialog<int>(
      context: context,
      builder: (_) => _DeliveryRewardPaymentDialog(
        deliveryBoy: deliveryBoy,
      ),
    );
    if (amountLkr == null || !mounted) {
      return;
    }

    setState(() => _payingDeliveryBoyId = deliveryBoy.uid);
    try {
      await context.read<AppState>().authService.payDeliveryStarReward(
            uid: deliveryBoy.uid,
            amountLkr: amountLkr,
          );
      if (mounted) {
        showSnack(
          context,
          'Successfully paid LKR $amountLkr from stars. '
          '${deliveryBoy.deliveryRewardStars - amountLkr} stars remain.',
        );
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _payingDeliveryBoyId = null);
      }
    }
  }

  Future<void> _addRewardStars(UserProfile deliveryBoy) async {
    final starsToAdd = await showDialog<int>(
      context: context,
      builder: (_) => _DeliveryRewardAddStarsDialog(
        deliveryBoy: deliveryBoy,
      ),
    );
    if (starsToAdd == null || !mounted) {
      return;
    }

    setState(() => _addingStarsDeliveryBoyId = deliveryBoy.uid);
    try {
      await context.read<AppState>().authService.addDeliveryRewardStars(
            uid: deliveryBoy.uid,
            stars: starsToAdd,
          );
      if (mounted) {
        showSnack(
          context,
          'Successfully added $starsToAdd stars to '
          '${deliveryBoy.fullName}. '
          '${deliveryBoy.deliveryRewardStars + starsToAdd} stars total.',
        );
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _addingStarsDeliveryBoyId = null);
      }
    }
  }

  Future<void> _showDeliveryBoyDialog(
    BuildContext context, {
    UserProfile? deliveryBoy,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _DeliveryBoyEditorDialog(deliveryBoy: deliveryBoy),
    );
    if (context.mounted && saved == true) {
      showSnack(
        context,
        deliveryBoy == null
            ? 'Delivery boy account created.'
            : 'Delivery boy account updated.',
      );
    }
  }
}

class _DeliveryRewardPaymentDialog extends StatefulWidget {
  const _DeliveryRewardPaymentDialog({required this.deliveryBoy});

  final UserProfile deliveryBoy;

  @override
  State<_DeliveryRewardPaymentDialog> createState() =>
      _DeliveryRewardPaymentDialogState();
}

class _DeliveryRewardPaymentDialogState
    extends State<_DeliveryRewardPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.deliveryBoy.deliveryRewardStars.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryBoy = widget.deliveryBoy;
    return AlertDialog(
      title: const Text('Pay from reward stars'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${deliveryBoy.fullName} has '
                '${deliveryBoy.deliveryRewardStars} stars. '
                'One star equals LKR 1.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Payment amount (LKR)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  helperText: 'The same number of stars will be deducted.',
                ),
                validator: (value) {
                  final amount = int.tryParse(value?.trim() ?? '');
                  if (amount == null || amount < 1) {
                    return 'Enter an amount of at least LKR 1.';
                  }
                  if (amount > deliveryBoy.deliveryRewardStars) {
                    return 'Only ${deliveryBoy.deliveryRewardStars} stars are available.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Confirm payment'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(int.parse(_amountController.text.trim()));
  }
}

class _DeliveryRewardAddStarsDialog extends StatefulWidget {
  const _DeliveryRewardAddStarsDialog({required this.deliveryBoy});

  final UserProfile deliveryBoy;

  @override
  State<_DeliveryRewardAddStarsDialog> createState() =>
      _DeliveryRewardAddStarsDialogState();
}

class _DeliveryRewardAddStarsDialogState
    extends State<_DeliveryRewardAddStarsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _starsController = TextEditingController();

  @override
  void dispose() {
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryBoy = widget.deliveryBoy;
    return AlertDialog(
      title: const Text('Add reward stars'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${deliveryBoy.fullName} currently has '
                '${deliveryBoy.deliveryRewardStars} stars.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _starsController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Stars to add',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  helperText:
                      'These stars will be added to the current balance.',
                ),
                validator: (value) {
                  final stars = int.tryParse(value?.trim() ?? '');
                  if (stars == null || stars < 1) {
                    return 'Enter at least 1 star.';
                  }
                  if (stars > 100000) {
                    return 'You can add up to 100,000 stars at once.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add stars'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(int.parse(_starsController.text.trim()));
  }
}

class _DeliveryBoyTile extends StatelessWidget {
  const _DeliveryBoyTile({
    required this.deliveryBoy,
    required this.onEdit,
    required this.onPayReward,
    required this.onAddStars,
    required this.isPaying,
    required this.isAddingStars,
  });

  static const _rewardTarget = 1000;
  final UserProfile deliveryBoy;
  final VoidCallback onEdit;
  final VoidCallback onPayReward;
  final VoidCallback onAddStars;
  final bool isPaying;
  final bool isAddingStars;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        deliveryBoy.isBlocked ? const Color(0xFFC83A2B) : _adminPrimary;
    final rewardStars = deliveryBoy.deliveryRewardStars;
    final canPayReward = rewardStars > 0;
    final rewardProgress =
        (rewardStars / _rewardTarget).clamp(0.0, 1.0).toDouble();
    return _AdminCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminIconBadge(
                icon: Icons.delivery_dining,
                color: statusColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryBoy.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      deliveryBoy.phone,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AdminPill(
                label: deliveryBoy.isBlocked ? 'Inactive' : 'Active',
                color: statusColor,
                icon: deliveryBoy.isBlocked ? Icons.block : Icons.check_circle,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, color: _adminMuted),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _adminLine),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 21,
                color: _adminWarning,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Reward stars: $rewardStars / $_rewardTarget',
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (deliveryBoy.deliveryRewardCount > 0)
                Text(
                  '${deliveryBoy.deliveryRewardCount} paid',
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rewardProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF2E8D9),
              valueColor: const AlwaysStoppedAnimation<Color>(_adminWarning),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final message = Text(
                canPayReward
                    ? 'Available to pay: LKR $rewardStars'
                    : 'No reward stars available yet.',
                style: const TextStyle(
                  color: _adminMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              );
              final payButton = FilledButton.icon(
                onPressed: canPayReward && !isPaying && !isAddingStars
                    ? onPayReward
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _adminWarning,
                  foregroundColor: Colors.white,
                ),
                icon: isPaying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(isPaying ? 'Recording...' : 'Pay from stars'),
              );
              final addButton = OutlinedButton.icon(
                onPressed: isAddingStars || isPaying ? null : onAddStars,
                icon: isAddingStars
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(isAddingStars ? 'Adding...' : 'Add stars'),
              );
              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    message,
                    const SizedBox(height: 10),
                    addButton,
                    const SizedBox(height: 8),
                    payButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: message),
                  const SizedBox(width: 12),
                  addButton,
                  const SizedBox(width: 8),
                  payButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeliveryBoyEditorDialog extends StatefulWidget {
  const _DeliveryBoyEditorDialog({this.deliveryBoy});

  final UserProfile? deliveryBoy;

  @override
  State<_DeliveryBoyEditorDialog> createState() =>
      _DeliveryBoyEditorDialogState();
}

class _DeliveryBoyEditorDialogState extends State<_DeliveryBoyEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  var _isActive = true;
  var _isSaving = false;

  bool get _isEditing => widget.deliveryBoy != null;

  @override
  void initState() {
    super.initState();
    final deliveryBoy = widget.deliveryBoy;
    _name = TextEditingController(text: deliveryBoy?.fullName ?? '');
    _phone = TextEditingController(text: deliveryBoy?.phone ?? '');
    _password = TextEditingController();
    _isActive = !(deliveryBoy?.isBlocked ?? false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit delivery boy' : 'Add delivery boy'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      Validators.requiredText(value, 'Full name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        _isEditing ? 'New password (optional)' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (_isEditing && (value == null || value.isEmpty)) {
                      return null;
                    }
                    return Validators.password(value);
                  },
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active account'),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      if (_isEditing) {
        await appState.authService.updateDeliveryBoy(
          uid: widget.deliveryBoy!.uid,
          fullName: _name.text,
          phone: _phone.text,
          password: _password.text.trim().isEmpty ? null : _password.text,
          isBlocked: !_isActive,
        );
      } else {
        await appState.authService.createDeliveryBoy(
          fullName: _name.text,
          phone: _phone.text,
          password: _password.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class AdminAccountDeletionScreen extends StatefulWidget {
  const AdminAccountDeletionScreen({super.key});

  @override
  State<AdminAccountDeletionScreen> createState() =>
      _AdminAccountDeletionScreenState();
}

class _AdminAccountDeletionScreenState
    extends State<AdminAccountDeletionScreen> {
  String? _busyRequestId;
  String? _busyCustomerId;
  final _searchController = TextEditingController();
  String _query = '';

  static const _terminalStatuses = <String>{
    'Delivered',
    'Cancelled',
    'Rejected',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final service = appState.firestoreService;
    return _AdminScaffold(
      title: 'Account deletion',
      body: _AdminPage(
        child: StreamBuilder<List<UserProfile>>(
          stream: service.watchUsers(),
          builder: (context, usersSnapshot) {
            return StreamBuilder<List<OrderModel>>(
              stream: service.watchAllOrders(),
              builder: (context, ordersSnapshot) {
                return StreamBuilder<List<AccountDeletionRequest>>(
                  stream: service.watchAccountDeletionRequests(),
                  builder: (context, requestsSnapshot) {
                    if ((!usersSnapshot.hasData ||
                            !ordersSnapshot.hasData ||
                            !requestsSnapshot.hasData) &&
                        (usersSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            ordersSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            requestsSnapshot.connectionState ==
                                ConnectionState.waiting)) {
                      return const RefreshableCenteredContent(
                        child: LoadingView(),
                      );
                    }
                    final error = usersSnapshot.error ??
                        ordersSnapshot.error ??
                        requestsSnapshot.error;
                    if (error != null) {
                      return RefreshableCenteredContent(
                        child: EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Could not load account deletion',
                          message: 'Customer accounts could not be loaded.',
                          action: FilledButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ),
                      );
                    }

                    final orders = ordersSnapshot.data ?? const <OrderModel>[];
                    final requests = requestsSnapshot.data ??
                        const <AccountDeletionRequest>[];
                    final pendingRequests =
                        requests.where((request) => request.isPending).toList();
                    final customers =
                        (usersSnapshot.data ?? const <UserProfile>[])
                            .where((user) => user.role == 'user')
                            .where(_matchesSearch)
                            .toList();

                    return ListView(
                      physics: appRefreshScrollPhysics,
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
                      children: [
                        const _AdminCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AdminIconBadge(
                                icon: Icons.admin_panel_settings_outlined,
                                color: _adminAccent,
                                size: 48,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Delete registered customer accounts here. '
                                  'Accounts with active orders must be completed '
                                  'or cancelled first.',
                                  style: TextStyle(
                                    color: _adminMuted,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pendingRequests.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _AdminSectionHeader(
                            title: 'Public deletion requests '
                                '(${pendingRequests.length} waiting)',
                          ),
                          const SizedBox(height: 10),
                          ...pendingRequests.asMap().entries.map((entry) {
                            final request = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AdminReveal(
                                index: entry.key,
                                child: _AdminAccountDeletionTile(
                                  request: request,
                                  isBusy: _busyRequestId == request.requestId,
                                  onDelete: () =>
                                      _process(request, deleteAccount: true),
                                  onReject: () =>
                                      _process(request, deleteAccount: false),
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 18),
                        _AdminSectionHeader(
                          title: 'Registered customers (${customers.length})',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _query = value.trim().toLowerCase());
                          },
                          decoration: InputDecoration(
                            hintText: 'Search name, phone, or address',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (customers.isEmpty)
                          const _AdminCard(
                            child: EmptyState(
                              icon: Icons.person_search_outlined,
                              title: 'No matching customers',
                              message: 'Try a different search.',
                            ),
                          )
                        else
                          ...customers.asMap().entries.map((entry) {
                            final customer = entry.value;
                            final customerOrders = orders
                                .where(
                                  (order) => order.userId == customer.uid,
                                )
                                .toList();
                            final activeOrders = customerOrders
                                .where(
                                  (order) => !_terminalStatuses
                                      .contains(order.orderStatus),
                                )
                                .length;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AdminReveal(
                                index: entry.key,
                                child: _AdminCustomerDeletionTile(
                                  customer: customer,
                                  totalOrders: customerOrders.length,
                                  activeOrders: activeOrders,
                                  isBusy: _busyCustomerId == customer.uid,
                                  onDelete: activeOrders == 0
                                      ? () => _deleteCustomer(customer)
                                      : null,
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _matchesSearch(UserProfile customer) {
    if (_query.isEmpty) {
      return true;
    }
    return customer.fullName.toLowerCase().contains(_query) ||
        customer.phone.toLowerCase().contains(_query) ||
        customer.address.toLowerCase().contains(_query);
  }

  Future<void> _deleteCustomer(UserProfile customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently delete customer?'),
        content: Text(
          '${customer.fullName} (${customer.phone}) will lose access '
          'immediately. Personal data will be removed and completed order '
          'records will be anonymized. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _adminDanger),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busyCustomerId = customer.uid);
    try {
      await context
          .read<AppState>()
          .authService
          .deleteCustomerAccountAsAdmin(customer.uid);
      if (mounted) {
        showSnack(context, 'Customer account deleted.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busyCustomerId = null);
      }
    }
  }

  Future<void> _process(
    AccountDeletionRequest request, {
    required bool deleteAccount,
  }) async {
    if (deleteAccount) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Identity verified?'),
          content: Text(
            'Only continue after confirming that ${request.phone} controls '
            'this customer account. This permanently deletes the account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _adminAccent),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Verified - delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _busyRequestId = request.requestId);
    try {
      await context.read<AppState>().authService.processAccountDeletionRequest(
            requestId: request.requestId,
            deleteAccount: deleteAccount,
          );
      if (mounted) {
        showSnack(
          context,
          deleteAccount ? 'Account deleted.' : 'Request rejected.',
        );
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _busyRequestId = null);
      }
    }
  }
}

class _AdminAccountDeletionTile extends StatelessWidget {
  const _AdminAccountDeletionTile({
    required this.request,
    required this.isBusy,
    required this.onDelete,
    required this.onReject,
  });

  final AccountDeletionRequest request;
  final bool isBusy;
  final VoidCallback? onDelete;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = _adminStatusColor(request.status);
    final requestedAt = DateFormat.yMMMd().add_jm().format(request.createdAt);
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminIconBadge(
                icon: Icons.person_remove_outlined,
                color: statusColor,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.customerName.isEmpty
                          ? request.phone
                          : request.customerName,
                      style: const TextStyle(
                        color: _adminInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${request.phone} - $requestedAt',
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _AdminPill(
                label: request.status,
                color: statusColor,
                icon: Icons.circle,
              ),
            ],
          ),
          if (request.details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              request.details,
              style: const TextStyle(color: _adminMuted),
            ),
          ],
          if (request.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.delete_forever),
                    label: Text(isBusy ? 'Working' : 'Verify & delete'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminCustomerDeletionTile extends StatelessWidget {
  const _AdminCustomerDeletionTile({
    required this.customer,
    required this.totalOrders,
    required this.activeOrders,
    required this.isBusy,
    required this.onDelete,
  });

  final UserProfile customer;
  final int totalOrders;
  final int activeOrders;
  final bool isBusy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final blocked = activeOrders > 0;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminIconBadge(
                icon: Icons.person_outline,
                color: blocked ? _adminWarning : _adminAccent,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName.isEmpty
                          ? 'Unnamed customer'
                          : customer.fullName,
                      style: const TextStyle(
                        color: _adminInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (customer.address.trim().isNotEmpty)
                      Text(
                        customer.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _adminMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _AdminPill(
                label: customer.isBlocked ? 'Blocked' : 'Active',
                color: customer.isBlocked ? _adminDanger : _adminSuccess,
                icon: Icons.circle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AdminPill(
                label: '$totalOrders total orders',
                color: _adminMuted,
                icon: Icons.receipt_long_outlined,
              ),
              _AdminPill(
                label: '$activeOrders active',
                color: blocked ? _adminWarning : _adminSuccess,
                icon: blocked ? Icons.pending_actions : Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _adminDanger,
              ),
              onPressed: isBusy ? null : onDelete,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever),
              label: Text(
                isBusy
                    ? 'Deleting account'
                    : blocked
                        ? 'Complete active orders first'
                        : 'Delete customer account',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLoginPasswordResetScreen extends StatefulWidget {
  const AdminLoginPasswordResetScreen({super.key});

  @override
  State<AdminLoginPasswordResetScreen> createState() =>
      _AdminLoginPasswordResetScreenState();
}

class _AdminLoginPasswordResetScreenState
    extends State<AdminLoginPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _isSaving = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    return _AdminScaffold(
      title: 'Admin login reset',
      body: _AdminPage(
        maxWidth: 680,
        child: ListView(
          physics: appRefreshScrollPhysics,
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
          children: [
            _AdminReveal(
              child: _AdminCard(
                child: Row(
                  children: [
                    const _AdminIconBadge(
                      icon: Icons.admin_panel_settings_outlined,
                      color: _adminPrimary,
                      size: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.fullName.isNotEmpty == true
                                ? profile!.fullName
                                : 'Admin account',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _adminInk,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            profile?.phone.isNotEmpty == true
                                ? profile!.phone
                                : 'Current login',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _adminMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _AdminPill(
                      label: 'Admin',
                      color: _adminPrimary,
                      icon: Icons.verified_user_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _AdminReveal(
              index: 1,
              child: _AdminNotice(
                icon: Icons.info_outline,
                color: _adminBlue,
                message:
                    'Enter the current admin password before saving a new login password.',
              ),
            ),
            const SizedBox(height: 12),
            _AdminReveal(
              index: 2,
              child: _AdminCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _currentPassword,
                        label: 'Current password',
                        obscureText: true,
                        validator: Validators.password,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _newPassword,
                        label: 'New password',
                        obscureText: true,
                        validator: Validators.password,
                        prefixIcon: Icons.lock_reset,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _confirmPassword,
                        label: 'Confirm new password',
                        obscureText: true,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _newPassword.text,
                        ),
                        prefixIcon: Icons.lock,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _savePassword,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Updating password' : 'Update password',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_currentPassword.text == _newPassword.text) {
      showSnack(context, 'New password must be different.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().authService.updateCurrentUserPassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
          );
      if (!mounted) {
        return;
      }
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      showSnack(context, 'Admin login password updated.');
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class AdminPasswordResetScreen extends StatefulWidget {
  const AdminPasswordResetScreen({super.key});

  @override
  State<AdminPasswordResetScreen> createState() =>
      _AdminPasswordResetScreenState();
}

class _AdminPasswordResetScreenState extends State<AdminPasswordResetScreen> {
  String? _busyRequestId;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Password resets',
      body: _AdminPage(
        child: StreamBuilder<List<PasswordResetRequest>>(
          stream: appState.firestoreService.watchPasswordResetRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RefreshableCenteredContent(
                child: LoadingView(),
              );
            }
            final requests = snapshot.data ?? const <PasswordResetRequest>[];
            if (requests.isEmpty) {
              return const RefreshableCenteredContent(
                child: EmptyState(
                  icon: Icons.lock_reset,
                  title: 'No reset requests',
                  message: 'Customer password reset requests will appear here.',
                ),
              );
            }
            return ListView.separated(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _AdminReveal(
                  index: index,
                  child: _AdminPasswordResetTile(
                    request: request,
                    isBusy: _busyRequestId == request.requestId,
                    onApprove: request.isPending
                        ? () => _setRequestStatus(request, approve: true)
                        : null,
                    onReject: request.isPending
                        ? () => _setRequestStatus(request, approve: false)
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _setRequestStatus(
    PasswordResetRequest request, {
    required bool approve,
  }) async {
    setState(() => _busyRequestId = request.requestId);
    try {
      final authService = context.read<AppState>().authService;
      if (approve) {
        await authService.approvePasswordReset(request.requestId);
      } else {
        await authService.rejectPasswordReset(request.requestId);
      }
      if (mounted) {
        showSnack(context, approve ? 'Reset approved.' : 'Reset rejected.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busyRequestId = null);
      }
    }
  }
}

class _AdminPasswordResetTile extends StatelessWidget {
  const _AdminPasswordResetTile({
    required this.request,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final PasswordResetRequest request;
  final bool isBusy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = _adminStatusColor(request.status);
    final requestedAt = DateFormat.yMMMd().add_jm().format(request.createdAt);
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminIconBadge(
                icon: Icons.lock_reset,
                color: statusColor,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.customerName.isEmpty
                          ? request.phone
                          : request.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${request.phone} - $requestedAt',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AdminPill(
                label: request.status,
                color: statusColor,
                icon: Icons.circle,
              ),
            ],
          ),
          if (request.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onApprove,
                    icon: const Icon(Icons.check),
                    label: Text(isBusy ? 'Saving' : 'Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminCustomerTile extends StatelessWidget {
  const _AdminCustomerTile({
    required this.user,
    required this.canToggle,
    required this.onActiveChanged,
  });

  final UserProfile user;
  final bool canToggle;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.isEmpty ? '?' : user.fullName[0];
    final statusColor =
        user.isBlocked ? const Color(0xFFC83A2B) : _adminPrimary;
    return _AdminCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: statusColor.withValues(alpha: 0.13),
            foregroundColor: statusColor,
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user.phone,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                _AdminPill(
                  label: user.role,
                  color: user.isAdmin ? _adminBlue : _adminMuted,
                  icon: user.isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Switch(
                value: !user.isBlocked,
                onChanged: canToggle ? onActiveChanged : null,
              ),
              Text(
                user.isBlocked ? 'Blocked' : 'Active',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
