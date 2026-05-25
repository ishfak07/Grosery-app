import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../services/cloudinary_service.dart';
import '../../../services/image_picker_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../customer/customer_screens.dart';

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

Color _adminStatusColor(String status) {
  switch (status) {
    case 'Delivered':
    case 'available':
    case 'Active':
    case 'open':
      return _adminPrimary;
    case 'Cancelled':
    case 'Rejected':
    case 'Item Unavailable':
    case 'unavailable':
    case 'Blocked':
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
        backgroundColor: _adminBackground.withOpacity(0.96),
        foregroundColor: _adminInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _adminLine)),
      ),
      floatingActionButton: floatingActionButton,
      body: _AdminBackdrop(child: body),
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
            color: const Color(0xFF163526).withOpacity(0.07),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
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
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
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
                  'Manage orders, products, shops, customers, and support.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.82),
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
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Icon(
                Icons.admin_panel_settings_outlined,
                color: Colors.white.withOpacity(0.9),
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
    final profile = appState.profile!;
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
                  subtitle: 'Review and update',
                  accent: _adminPrimary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminOrdersScreen(),
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
                  icon: Icons.storefront,
                  title: 'Shops',
                  subtitle: 'Partner shops',
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
                final activeOrders = allOrders
                    .where(
                      (order) =>
                          order.orderStatus != 'Delivered' &&
                          order.orderStatus != 'Cancelled',
                    )
                    .length;
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
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  var _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final filters = [
      'All',
      'Pending',
      'Accepted',
      'Out for Delivery',
      'Delivered'
    ];
    return _AdminScaffold(
      title: 'Orders',
      body: _AdminPage(
        child: Column(
          children: [
            _AdminFilterBar(
              filters: filters,
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                stream: appState.firestoreService.watchAllOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView();
                  }
                  final orders = (snapshot.data ?? const <OrderModel>[])
                      .where(
                        (order) =>
                            _filter == 'All' || order.orderStatus == _filter,
                      )
                      .toList();
                  if (orders.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long,
                      title: 'No orders',
                      message: 'Orders matching this filter will appear here.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _AdminReveal(
                        index: index,
                        child: AdminOrderTile(order: orders[index]),
                      );
                    },
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
                  '${order.customerName} - ${order.orderId.substring(0, 8)}',
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
  final _subtotal = TextEditingController();
  final _delivery = TextEditingController();
  final _service = TextEditingController();
  final _adminNotes = TextEditingController();
  final _deliveryPerson = TextEditingController();
  String _status = 'Pending';
  String _paymentStatus = 'pending';
  String? _loadedOrderId;
  var _isSavingBill = false;
  var _isUpdatingStatus = false;

  @override
  void dispose() {
    _subtotal.dispose();
    _delivery.dispose();
    _service.dispose();
    _adminNotes.dispose();
    _deliveryPerson.dispose();
    super.dispose();
  }

  void _syncControllers(OrderModel order) {
    if (_loadedOrderId == order.orderId) {
      return;
    }
    _loadedOrderId = order.orderId;
    _subtotal.text = order.subtotal.toStringAsFixed(2);
    _delivery.text = order.deliveryCharge.toStringAsFixed(2);
    _service.text = order.serviceCharge.toStringAsFixed(2);
    _adminNotes.text = order.adminNotes;
    _deliveryPerson.text = order.assignedDeliveryPerson;
    _status = order.orderStatus;
    _paymentStatus = order.paymentStatus;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: 'Order details',
      body: _AdminPage(
        child: StreamBuilder<OrderModel?>(
          stream: appState.firestoreService.watchOrder(widget.orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final order = snapshot.data;
            if (order == null) {
              return const EmptyState(
                icon: Icons.receipt_long,
                title: 'Order not found',
                message: 'This order is no longer available.',
              );
            }
            _syncControllers(order);
            return ListView(
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
                        _OrderInfoRow('Phone', order.customerPhone),
                        _OrderInfoRow('Address', order.customerAddress),
                        if (order.orderNotes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _AdminPill(
                              label: 'Notes: ${order.orderNotes}',
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
                        const _OrderInfoRow(
                          'Account name',
                          AppConstants.bankAccountName,
                        ),
                        const _OrderInfoRow('Bank', AppConstants.bankName),
                        const _OrderInfoRow(
                          'Branch',
                          AppConstants.bankBranch,
                        ),
                        const _OrderInfoRow(
                          'Account number',
                          AppConstants.bankAccountNumber,
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
                        controller: _subtotal,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Final subtotal',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
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
                        value: [
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
                        value: AppConstants.orderStatuses.contains(_status)
                            ? _status
                            : 'Pending',
                        decoration:
                            const InputDecoration(labelText: 'Order status'),
                        items: AppConstants.orderStatuses
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
                      const SizedBox(height: 10),
                      TextField(
                        controller: _deliveryPerson,
                        decoration: const InputDecoration(
                          labelText: 'Assigned delivery person',
                          prefixIcon: Icon(Icons.delivery_dining),
                        ),
                      ),
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
    setState(() => _isSavingBill = true);
    try {
      final subtotal = double.tryParse(_subtotal.text.trim()) ?? order.subtotal;
      final delivery =
          double.tryParse(_delivery.text.trim()) ?? order.deliveryCharge;
      final service =
          double.tryParse(_service.text.trim()) ?? order.serviceCharge;
      await context.read<AppState>().firestoreService.updateOrderFinancials(
            order: order,
            subtotal: subtotal,
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

  Future<void> _updateStatus(OrderModel order) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await context.read<AppState>().firestoreService.updateOrderStatus(
            order: order,
            status: _status,
            adminNotes: _adminNotes.text,
            assignedDeliveryPerson: _deliveryPerson.text,
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
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load products',
                message: snapshot.error.toString(),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final products = snapshot.data ?? const <Product>[];
            if (products.isEmpty) {
              return const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No products',
                message: 'Add catalog products for customers to order.',
              );
            }
            return ListView.separated(
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
}

class _AdminProductTile extends StatelessWidget {
  const _AdminProductTile({
    required this.product,
    required this.onTap,
    required this.onActiveChanged,
  });

  final Product product;
  final VoidCallback onTap;
  final ValueChanged<bool> onActiveChanged;

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
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _category = AppConstants.productCategories.first;
  String _unit = AppConstants.productUnits.first;
  String _stockStatus = 'available';
  String? _selectedShopId;
  String? _imagePath;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _description.text = product.description;
      _price.text = product.price.toStringAsFixed(2);
      _category = product.category;
      _unit = product.unit;
      _stockStatus = product.stockStatus;
      _selectedShopId = product.shopId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _AdminScaffold(
      title: widget.product == null ? 'Add product' : 'Edit product',
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
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
                children: [
                  if (shops.isEmpty)
                    const EmptyState(
                      icon: Icons.storefront,
                      title: 'Add a shop first',
                      message: 'Products must be linked to a partner shop.',
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
                          DropdownButtonFormField<String>(
                            value: _selectedShopId,
                            decoration: const InputDecoration(
                              labelText: 'Shop',
                              prefixIcon: Icon(Icons.storefront),
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
                          DropdownButtonFormField<String>(
                            value: AppConstants.productCategories
                                    .contains(_category)
                                ? _category
                                : AppConstants.productCategories.first,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: AppConstants.productCategories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
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
                            value: _unit,
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
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _stockStatus,
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
                                  onPressed: _isSaving
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
                                  onPressed: _isSaving
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
                          if (_imagePath != null) ...[
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
                    onPressed: shops.isEmpty || _isSaving
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
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final selectedShop = _shopForId(shops, _selectedShopId);
    if (selectedShop == null) {
      showSnack(context, 'Select a shop.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      final productId = widget.product?.productId ?? const Uuid().v4();
      var imageUrl = widget.product?.imageUrl ?? '';
      if (_imagePath != null) {
        imageUrl = await CloudinaryService.uploadImage(File(_imagePath!));
      }
      final now = DateTime.now();
      final product = Product(
        productId: productId,
        shopId: selectedShop.shopId,
        shopName: selectedShop.shopName,
        name: _name.text.trim(),
        category: _category,
        description: _description.text.trim(),
        price: double.parse(_price.text.trim()),
        imageUrl: imageUrl,
        unit: _unit,
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

  Future<void> _pickProductImage({required bool fromCamera}) async {
    final imageFile =
        fromCamera ? await takePhotoFromCamera() : await pickImageFromGallery();
    if (!mounted || imageFile == null) {
      return;
    }
    setState(() => _imagePath = imageFile.path);
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
      title: 'Manage shops',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _adminInk,
        foregroundColor: Colors.white,
        onPressed: () => _showShopDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Shop'),
      ),
      body: _AdminPage(
        child: StreamBuilder<List<Shop>>(
          stream: appState.firestoreService.watchShops(activeOnly: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final shops = snapshot.data ?? const <Shop>[];
            if (shops.isEmpty) {
              return const EmptyState(
                icon: Icons.storefront,
                title: 'No shops',
                message: 'Add partner shops before adding products.',
              );
            }
            return ListView.separated(
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
                icon: Icons.storefront,
                color: shop == null ? _adminPrimary : _adminBlue,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(shop == null ? 'Add shop' : 'Edit shop')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Shop name',
                    prefixIcon: Icon(Icons.storefront),
                  ),
                ),
                const SizedBox(height: 8),
                AppPhoneField(
                  controller: phone,
                  label: 'Phone',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
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
            icon: Icons.storefront,
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
      body: _AdminPage(
        child: StreamBuilder<List<SupportTicket>>(
          stream: appState.firestoreService.watchTickets(allTickets: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final tickets = snapshot.data ?? const <SupportTicket>[];
            if (tickets.isEmpty) {
              return const EmptyState(
                icon: Icons.support_agent,
                title: 'No support tickets',
                message: 'Customer messages will appear here.',
              );
            }
            return ListView.separated(
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
              return const LoadingView();
            }
            final users = snapshot.data ?? const <UserProfile>[];
            if (users.isEmpty) {
              return const EmptyState(
                icon: Icons.people_outline,
                title: 'No customers',
                message: 'Registered users will appear here.',
              );
            }
            return ListView.separated(
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
            backgroundColor: statusColor.withOpacity(0.13),
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
