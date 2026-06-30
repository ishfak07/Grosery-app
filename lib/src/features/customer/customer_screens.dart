import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/image_upload_service.dart';
import '../../../services/image_picker_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/language_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

const _customerBackground = Color(0xFFF7FAF5);
const _customerSurface = Color(0xFFFFFFFF);
const _customerInk = Color(0xFF10231A);
const _customerMuted = Color(0xFF66736B);
const _customerLine = Color(0xFFDDE8DF);
const _customerPrimary = Color(0xFF176B45);
const _customerPrimaryLight = Color(0xFFE9F7EF);
const _customerAccent = Color(0xFFE86F4A);
const _customerGold = Color(0xFFF6B84B);
const _customerBlue = Color(0xFF2E6F9E);
const _customerDanger = Color(0xFFC83A2B);
const _customerWarning = Color(0xFFB66D00);

class _CustomerBackdrop extends StatelessWidget {
  const _CustomerBackdrop({required this.child});

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

class _CustomerScaffold extends StatelessWidget {
  const _CustomerScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _customerBackground,
      appBar: AppBar(
        title: Text(context.t(title)),
        actions: actions,
        backgroundColor: _customerBackground.withValues(alpha: 0.96),
        foregroundColor: _customerInk,
        shape: const Border(bottom: BorderSide(color: _customerLine)),
      ),
      body: _CustomerBackdrop(
        child: AppRefreshIndicator(child: body),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _CustomerLogoutTransition extends StatelessWidget {
  const _CustomerLogoutTransition();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _customerBackground,
      body: _CustomerBackdrop(
        child: LoadingView(message: 'Logging out...'),
      ),
    );
  }
}

class _CustomerScrollView extends StatelessWidget {
  const _CustomerScrollView({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
    this.safeAreaTop = false,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool safeAreaTop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: safeAreaTop,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 720 ? 24.0 : 16.0;
          return ListView(
            physics: appRefreshScrollPhysics,
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final content = Material(
      color: _customerSurface,
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

    return _Pressable(
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: _customerLine),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF163526).withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp:
          widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel:
          widget.enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.985 : 1,
        child: widget.child,
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
  });

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: 360 + index.clamp(0, 5) * 45);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _CustomerIconButton extends StatelessWidget {
  const _CustomerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, color: _customerInk);
    if (badgeCount > 0) {
      child = Badge.count(count: badgeCount, child: child);
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton.filledTonal(
        tooltip: context.t(tooltip),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _customerInk,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: _customerLine),
        ),
        icon: child,
      ),
    );
  }
}

class _CustomerSectionHeader extends StatelessWidget {
  const _CustomerSectionHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(title),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    context.t(subtitle!),
                    style: const TextStyle(
                      color: _customerMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    this.width,
    this.height,
    this.radius = 8,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final x = (_controller.value * 2) - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(x - 1, -0.8),
              end: Alignment(x + 1, 0.8),
              colors: const [
                Color(0xFFE8F0EA),
                Color(0xFFF8FBF8),
                Color(0xFFE8F0EA),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: 0.66,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            return const _CustomerCard(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ShimmerBox(width: double.infinity)),
                  SizedBox(height: 10),
                  _ShimmerBox(width: 110, height: 13),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 80, height: 12),
                  SizedBox(height: 12),
                  _ShimmerBox(width: double.infinity, height: 42),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: appRefreshScrollPhysics,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return const _CustomerCard(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              _ShimmerBox(width: 58, height: 58),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 160, height: 13),
                    SizedBox(height: 10),
                    _ShimmerBox(width: double.infinity, height: 12),
                    SizedBox(height: 8),
                    _ShimmerBox(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _statusAccent(String status) {
  switch (status) {
    case 'Delivered':
    case 'Available':
    case 'open':
      return _customerPrimary;
    case 'Cancelled':
    case 'Rejected':
    case 'Item Unavailable':
    case 'Unavailable':
    case 'closed':
      return _customerDanger;
    case 'Pending':
    case 'Need Clarification':
    case 'Bill Updated':
    case 'pending':
    case 'receipt uploaded':
      return _customerWarning;
    case 'Accepted':
    case 'Shopping Started':
    case 'Out for Delivery':
    case 'replied':
      return _customerBlue;
    default:
      return _customerMuted;
  }
}

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    if (profile == null) {
      return const _CustomerLogoutTransition();
    }
    return Scaffold(
      backgroundColor: _customerBackground,
      body: _CustomerBackdrop(
        child: AppRefreshIndicator(
          child: _CustomerScrollView(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 28),
            safeAreaTop: true,
            children: [
              FirebaseSetupBanner(appState: appState),
              _HomeHeader(
                profile: profile,
                cartCount: appState.cartCount,
              ),
              const SizedBox(height: 14),
              _HomeSearchCallout(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              const _HomeOffersCarousel(),
              const SizedBox(height: 18),
              _HomeActionGrid(
                actions: [
                  _HomeActionSpec(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Items',
                    subtitle: 'Pick the items you need.',
                    accent: _customerPrimary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopListScreen()),
                    ),
                  ),
                  _HomeActionSpec(
                    icon: Icons.document_scanner_outlined,
                    title: 'Photo list',
                    subtitle: 'Send list photo',
                    accent: _customerBlue,
                    featured: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UploadBillScreen(),
                      ),
                    ),
                  ),
                  _HomeActionSpec(
                    icon: Icons.edit_note,
                    title: 'Manual list',
                    subtitle: 'Type your grocery list',
                    accent: _customerAccent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _HomeFreshPicksHeader(
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                ),
              ),
              const _RecentProductsGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _CustomerBottomNavigation(selectedIndex: 0),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.profile,
    required this.cartCount,
  });

  final UserProfile profile;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.fullName.trim().isEmpty
        ? context.t('there')
        : profile.fullName.trim().split(' ').first;
    final radius = BorderRadius.circular(8);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: _customerPrimary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D4C33),
                Color(0xFF176B45),
                Color(0xFF2E8758),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                bottom: -46,
                child: Icon(
                  Icons.shopping_basket_outlined,
                  size: 168,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                left: -44,
                top: 72,
                child: Transform.rotate(
                  angle: -0.34,
                  child: Container(
                    width: 210,
                    height: 42,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Image.asset(
                            AppConstants.appLogoAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                context.t(
                                  'Hi {name}',
                                  values: {'name': firstName},
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 17,
                                    color: Colors.white.withValues(alpha: 0.86),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      profile.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                        height: 1.24,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HomeHeaderActionButton(
                          tooltip: 'Notifications',
                          icon: Icons.notifications_outlined,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HomeHeaderActionButton(
                          tooltip: 'Cart',
                          icon: Icons.shopping_bag_outlined,
                          badgeCount: cartCount,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HomeHeaderPill(
                          icon: Icons.eco_outlined,
                          label: 'Fresh',
                        ),
                        _HomeHeaderPill(
                          icon: Icons.flash_on_outlined,
                          label: 'Fast',
                        ),
                        _HomeHeaderPill(
                          icon: Icons.verified_user_outlined,
                          label: 'Trusted',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeaderActionButton extends StatelessWidget {
  const _HomeHeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, color: _customerInk, size: 21);
    if (badgeCount > 0) {
      child = Badge.count(count: badgeCount, child: child);
    }
    return Tooltip(
      message: context.t(tooltip),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _HomeHeaderPill extends StatelessWidget {
  const _HomeHeaderPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              context.t(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchCallout extends StatelessWidget {
  const _HomeSearchCallout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return _Pressable(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10231A).withValues(alpha: 0.09),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _customerPrimaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: _customerPrimary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t('Search groceries '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _customerInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _customerLine),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: _customerMuted,
                      size: 18,
                    ),
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

class _HomePromoBanner extends StatelessWidget {
  const _HomePromoBanner();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: _customerPrimary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF123E2C),
                Color(0xFF176B45),
                Color(0xFFE86F4A),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -38,
                bottom: -46,
                child: Icon(
                  Icons.delivery_dining,
                  size: 172,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _customerGold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              context.t('Fast local delivery'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _customerInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.t(
                              'Fresh groceries, photo lists, and COD in one smooth order.',
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.t(
                              'We shop from trusted partners and keep you updated.',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 78,
                      height: 98,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_outlined,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeOffersCarousel extends StatefulWidget {
  const _HomeOffersCarousel();

  @override
  State<_HomeOffersCarousel> createState() => _HomeOffersCarouselState();
}

class _HomeOffersCarouselState extends State<_HomeOffersCarousel> {
  static const _autoPlayInterval = Duration(seconds: 4);
  static const _pageAnimationDuration = Duration(milliseconds: 260);
  static const _swipeDistanceThreshold = 36.0;
  static const _swipeVelocityThreshold = 220.0;

  Timer? _autoPlayTimer;
  var _page = 0;
  var _offerCount = 0;
  var _dragDistance = 0.0;
  var _isForward = true;

  @override
  void dispose() {
    _stopAutoPlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return StreamBuilder<List<Offer>>(
      stream: appState.firestoreService.watchOffers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _OfferCarouselSkeleton();
        }
        if (snapshot.hasError) {
          _syncOfferCount(0);
          return const _HomePromoBanner();
        }
        final offers = snapshot.data ?? const <Offer>[];
        if (offers.isEmpty) {
          _syncOfferCount(0);
          return const _HomePromoBanner();
        }
        _syncOfferCount(offers.length);
        final activePage = _page < 0
            ? 0
            : _page >= offers.length
                ? offers.length - 1
                : _page;
        final activeOffer = offers[activePage];
        return LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxWidth < 380 ? 190.0 : 214.0;
            return Column(
              children: [
                SizedBox(
                  height: height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: offers.length > 1
                        ? (_) {
                            _stopAutoPlay();
                            _dragDistance = 0;
                          }
                        : null,
                    onHorizontalDragUpdate: offers.length > 1
                        ? (details) {
                            _dragDistance += details.primaryDelta ?? 0;
                          }
                        : null,
                    onHorizontalDragEnd:
                        offers.length > 1 ? _handleOfferDragEnd : null,
                    onHorizontalDragCancel:
                        offers.length > 1 ? _handleOfferDragCancel : null,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: _pageAnimationDuration,
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) {
                              final offset = _isForward ? 0.08 : -0.08;
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(offset, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _HomeOfferBanner(
                              key: ValueKey(activeOffer.offerId),
                              offer: activeOffer,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OfferDetailsScreen(offer: activeOffer),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (offers.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < offers.length; index++)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showOfferAt(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: activePage == index ? 18 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: activePage == index
                                  ? _customerPrimary
                                  : _customerLine,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  void _syncOfferCount(int offerCount) {
    if (_offerCount == offerCount) {
      return;
    }
    _offerCount = offerCount;
    if (offerCount <= 1) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
    if (_page < offerCount || offerCount == 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _page = 0);
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(
      _autoPlayInterval,
      (_) => _showNextOffer(),
    );
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _handleOfferDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_swipeVelocityThreshold ||
        _dragDistance <= -_swipeDistanceThreshold) {
      _showNextOffer();
    } else if (velocity >= _swipeVelocityThreshold ||
        _dragDistance >= _swipeDistanceThreshold) {
      _showPreviousOffer();
    }
    _dragDistance = 0;
    if (_offerCount > 1) {
      _startAutoPlay();
    }
  }

  void _handleOfferDragCancel() {
    _dragDistance = 0;
    if (_offerCount > 1) {
      _startAutoPlay();
    }
  }

  void _showNextOffer() {
    if (!mounted || _offerCount <= 1) {
      return;
    }
    _showOfferAt((_page + 1) % _offerCount);
  }

  void _showPreviousOffer() {
    if (!mounted || _offerCount <= 1) {
      return;
    }
    _showOfferAt((_page - 1 + _offerCount) % _offerCount);
  }

  void _showOfferAt(int page) {
    if (!mounted || _offerCount == 0 || page == _page) {
      return;
    }
    final boundedPage = page < 0
        ? 0
        : page >= _offerCount
            ? _offerCount - 1
            : page;
    setState(() {
      _isForward =
          boundedPage > _page || (_page == _offerCount - 1 && boundedPage == 0);
      _page = boundedPage;
    });
  }
}

class _HomeOfferBanner extends StatelessWidget {
  const _HomeOfferBanner({
    super.key,
    required this.offer,
    required this.onTap,
  });

  final Offer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final languageCode = appState.effectiveLanguageCode;
    final title = offer.localizedTitle(languageCode);
    final caption = offer.localizedCaption(languageCode);
    final dateLabel = _offerDateLabel(offer);
    final radius = BorderRadius.circular(8);
    return _Pressable(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10231A).withValues(alpha: 0.20),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(url: offer.imageUrl, radius: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.34),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 240),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _customerGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.t('New offer'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _customerInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              height: 1.06,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          height: 1.24,
                        ),
                      ),
                      if (dateLabel != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 230),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event_available_outlined,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  dateLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

class _OfferCarouselSkeleton extends StatelessWidget {
  const _OfferCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 214,
      child: _ShimmerBox(width: double.infinity, radius: 8),
    );
  }
}

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({super.key, required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final languageCode = appState.effectiveLanguageCode;
    final title = offer.localizedTitle(languageCode);
    final caption = offer.localizedCaption(languageCode);
    final dateLabel = _offerDateLabel(offer);
    return _CustomerScaffold(
      title: 'Offer details',
      body: _CustomerScrollView(
        children: [
          SizedBox(
            height: 260,
            child: ProductImage(url: offer.imageUrl),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _customerInk,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1.12,
                ),
          ),
          if (dateLabel != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: _customerPrimary,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      color: _customerMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            caption,
            style: const TextStyle(
              color: _customerInk,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
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

class _CustomerBottomNavigation extends StatelessWidget {
  const _CustomerBottomNavigation({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _customerLine)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10231A).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index == selectedIndex && index == 0) {
              return;
            }
            final routes = [
              null,
              const OrderHistoryScreen(),
              const SupportScreen(),
              const ProfileScreen(),
            ];
            final route = routes[index];
            if (route != null) {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => route));
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.t('Home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: context.t('Orders'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.support_agent_outlined),
              selectedIcon: const Icon(Icons.support_agent),
              label: context.t('Support'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: context.t('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFreshPicksHeader extends StatelessWidget {
  const _HomeFreshPicksHeader({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _customerPrimaryLight,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: _customerPrimary.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: _customerPrimary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('Fresh picks'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.t('Recently added to the catalog'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _customerMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(
                context.t('View all'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: _customerPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentProductsGrid extends StatefulWidget {
  const _RecentProductsGrid();

  @override
  State<_RecentProductsGrid> createState() => _RecentProductsGridState();
}

class _RecentProductsGridState extends State<_RecentProductsGrid> {
  late final Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = context.read<AppState>().firestoreService.watchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DataErrorState(
            message: _friendlyDataError(snapshot.error),
          );
        }
        final products = (snapshot.data ?? const <Product>[]).take(6).toList();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProductGridSkeleton();
        }
        if (products.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            message: 'Admin can add products from the admin dashboard.',
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                childAspectRatio: 0.66,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return _FadeSlideIn(
                  index: index,
                  child: ProductCard(product: products[index]),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeActionSpec {
  const _HomeActionSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.featured = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool featured;
}

class _HomeActionGrid extends StatelessWidget {
  const _HomeActionGrid({required this.actions});

  final List<_HomeActionSpec> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final spacing = constraints.maxWidth < 360
            ? 7.0
            : compact
                ? 8.0
                : 12.0;
        final featured = actions.where((action) => action.featured).toList();
        final secondary = actions.where((action) => !action.featured).toList();

        if (featured.isNotEmpty && secondary.isNotEmpty) {
          return Column(
            children: [
              for (var i = 0; i < featured.length; i++) ...[
                _HomeActionTile(
                  icon: featured[i].icon,
                  title: featured[i].title,
                  subtitle: featured[i].subtitle,
                  accent: featured[i].accent,
                  onTap: featured[i].onTap,
                  compact: compact,
                  featured: true,
                ),
                if (i != featured.length - 1) SizedBox(height: spacing),
              ],
              SizedBox(height: spacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < secondary.length; i++) ...[
                    Expanded(
                      child: _HomeActionTile(
                        icon: secondary[i].icon,
                        title: secondary[i].title,
                        subtitle: secondary[i].subtitle,
                        accent: secondary[i].accent,
                        onTap: secondary[i].onTap,
                        compact: compact,
                      ),
                    ),
                    if (i != secondary.length - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(
                child: _HomeActionTile(
                  icon: actions[i].icon,
                  title: actions[i].title,
                  subtitle: actions[i].subtitle,
                  accent: actions[i].accent,
                  onTap: actions[i].onTap,
                  compact: compact,
                  featured: actions[i].featured,
                ),
              ),
              if (i != actions.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.compact = false,
    this.featured = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final tileHeight = featured
        ? compact
            ? 126.0
            : 136.0
        : compact
            ? 116.0
            : 132.0;
    final contentPadding = featured
        ? compact
            ? const EdgeInsets.fromLTRB(15, 14, 14, 14)
            : const EdgeInsets.fromLTRB(18, 17, 18, 17)
        : compact
            ? const EdgeInsets.fromLTRB(10, 12, 9, 12)
            : const EdgeInsets.fromLTRB(15, 15, 14, 14);
    final badgeSize = featured
        ? compact
            ? 50.0
            : 56.0
        : compact
            ? 40.0
            : 48.0;
    final arrowSize = featured
        ? compact
            ? 34.0
            : 38.0
        : compact
            ? 26.0
            : 30.0;
    final backgroundIconSize = featured
        ? compact
            ? 118.0
            : 138.0
        : compact
            ? 82.0
            : 96.0;
    final titleColor = featured ? Colors.white : _customerInk;
    final subtitleColor =
        featured ? Colors.white.withValues(alpha: 0.84) : _customerMuted;
    final arrowBackground = featured
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.86);

    return _Pressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: tileHeight,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: featured
                ? Colors.white.withValues(alpha: 0.16)
                : accent.withValues(alpha: 0.20),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: featured
                ? [
                    Color.lerp(accent, Colors.white, 0.05)!,
                    accent,
                    Color.lerp(accent, Colors.black, 0.22)!,
                  ]
                : [
                    Colors.white,
                    Color.lerp(Colors.white, accent, 0.065)!,
                    Color.lerp(Colors.white, accent, 0.11)!,
                  ],
            stops: const [0.0, 0.62, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: featured ? 0.24 : 0.13),
              blurRadius: featured ? 28 : 24,
              offset: Offset(0, featured ? 14 : 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.black, 0.18)!,
                        ],
                      ),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: const SizedBox(width: 5),
                  ),
                ),
                if (featured)
                  Positioned(
                    left: -22,
                    top: -42,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white.withValues(alpha: 0.055),
                      size: 118,
                    ),
                  ),
                Positioned(
                  right: featured ? -10 : -16,
                  bottom: featured ? -26 : -18,
                  child: Icon(
                    icon,
                    color: featured
                        ? Colors.white.withValues(alpha: 0.12)
                        : accent.withValues(alpha: 0.065),
                    size: backgroundIconSize,
                  ),
                ),
                Padding(
                  padding: contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _HomeActionIconBadge(
                            icon: icon,
                            accent: accent,
                            size: badgeSize,
                            featured: featured,
                          ),
                          const Spacer(),
                          Container(
                            width: arrowSize,
                            height: arrowSize,
                            decoration: BoxDecoration(
                              color: arrowBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: featured
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : accent.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: accent,
                              size: featured
                                  ? compact
                                      ? 19
                                      : 21
                                  : compact
                                      ? 15
                                      : 16,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        context.t(title),
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: titleColor,
                                  fontSize: featured
                                      ? compact
                                          ? 22
                                          : 24
                                      : compact
                                          ? 13
                                          : null,
                                  height: featured
                                      ? 1.0
                                      : compact
                                          ? 1.05
                                          : null,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t(subtitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: featured
                              ? compact
                                  ? 13
                                  : 14
                              : compact
                                  ? 10.8
                                  : 12,
                          fontWeight: FontWeight.w700,
                          height: compact ? 1.18 : 1.22,
                        ),
                      ),
                    ],
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

class _HomeActionIconBadge extends StatelessWidget {
  const _HomeActionIconBadge({
    required this.icon,
    required this.accent,
    this.size = 46,
    this.featured = false,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: featured
            ? Colors.white.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.88),
        border: Border.all(
          color: featured
              ? Colors.white.withValues(alpha: 0.22)
              : accent.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: featured ? 0.22 : 0.12),
            blurRadius: featured ? 16 : 12,
            offset: Offset(0, featured ? 8 : 6),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: size <= 40 ? 22 : 25),
    );
  }
}

class ShopListScreen extends StatelessWidget {
  const ShopListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppState>().firestoreService;
    return _CustomerScaffold(
      title: 'Items',
      body: StreamBuilder<List<Shop>>(
        stream: store.watchShops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton();
          }
          final shops = snapshot.data ?? const <Shop>[];
          if (shops.isEmpty) {
            return RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.store_mall_directory_outlined,
                title: 'No active shops',
                message: 'Products can still be browsed from the full catalog.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProductListScreen()),
                  ),
                  icon: const Icon(Icons.search),
                  label: Text(context.t('Browse catalog')),
                ),
              ),
            );
          }
          return _CustomerScrollView(
            children: [
              const _CustomerSectionHeader(
                title: 'Choose your Items',
                subtitle: 'Browse needed items near you',
              ),
              for (var index = 0; index < shops.length; index++) ...[
                _FadeSlideIn(
                  index: index,
                  child: _ShopCard(
                    shop: shops[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(shop: shops[index]),
                      ),
                    ),
                  ),
                ),
                if (index != shops.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.onTap,
  });

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _customerPrimaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront, color: _customerPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  shop.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _customerMuted,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _customerLine),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: _customerPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.shop});

  final Shop? shop;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  late final Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = context.read<AppState>().firestoreService.watchProducts(
          shopId: widget.shop?.shopId,
        );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final title = widget.shop?.shopName ?? 'Products';
    return _CustomerScaffold(
      title: title,
      actions: [
        _CustomerIconButton(
          tooltip: 'Cart',
          icon: Icons.shopping_bag_outlined,
          badgeCount: appState.cartCount,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ],
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.t('Search products'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? const Icon(Icons.tune)
                        : IconButton(
                            tooltip: context.t('Clear search'),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return RefreshableCenteredContent(
                    child: _DataErrorState(
                      message: _friendlyDataError(snapshot.error),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const RefreshableCenteredContent(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: _ProductGridSkeleton(),
                    ),
                  );
                }
                final query = _search.text.trim().toLowerCase();
                final languageCode = appState.effectiveLanguageCode;
                final products = (snapshot.data ?? const <Product>[]).where(
                  (product) {
                    final displayName =
                        product.localizedName(languageCode).toLowerCase();
                    return query.isEmpty ||
                        displayName.contains(query) ||
                        product.name.toLowerCase().contains(query) ||
                        product.nameTamil.toLowerCase().contains(query) ||
                        product.shopName.toLowerCase().contains(query);
                  },
                ).toList();
                if (products.isEmpty) {
                  return const RefreshableCenteredContent(
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No products found',
                      message: 'Try a different product name or shop.',
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final count = constraints.maxWidth >= 720 ? 3 : 2;
                    return GridView.builder(
                      physics: appRefreshScrollPhysics,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      itemCount: products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        childAspectRatio: 0.66,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        return _FadeSlideIn(
                          index: index,
                          child: ProductCard(product: products[index]),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DataErrorState extends StatelessWidget {
  const _DataErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Could not load products',
      message: message,
    );
  }
}

String _friendlyDataError(Object? error) {
  return appFriendlyErrorMessage(error);
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final languageCode = appState.effectiveLanguageCode;
    final productName = product.localizedName(languageCode);
    return _CustomerCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(url: product.imageUrl, radius: 0),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: product.isAvailable
                          ? _customerPrimary
                          : _customerDanger,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      product.isAvailable ? Icons.check : Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _customerMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.price.money,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _customerPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '/ ${context.t(product.unit)}',
                      style: const TextStyle(
                        color: _customerMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: product.isAvailable
                        ? () async {
                            await appState.addToCart(product);
                            if (context.mounted) {
                              showSnack(context, 'Added to cart.');
                            }
                          }
                        : null,
                    icon: Icon(
                      product.isAvailable
                          ? Icons.add_shopping_cart
                          : Icons.block,
                      size: 17,
                    ),
                    label: Text(
                      context.t(product.isAvailable ? 'Add' : 'Unavailable'),
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
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.radius = 8});

  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    const placeholder = DecoratedBox(
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
          Icons.local_grocery_store_outlined,
          color: _customerPrimary,
          size: 42,
        ),
      ),
    );
    const brokenImage = DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFEAF0EA)),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: _customerMuted,
          size: 42,
        ),
      ),
    );

    if (url.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: placeholder,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Stack(
            fit: StackFit.expand,
            children: [
              _ShimmerBox(radius: 0),
              Center(
                child: Icon(
                  Icons.local_grocery_store_outlined,
                  color: _customerPrimary,
                  size: 36,
                ),
              ),
            ],
          );
        },
        errorBuilder: (_, __, ___) => brokenImage,
      ),
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppState>().effectiveLanguageCode;
    final productName = product.localizedName(languageCode);
    final productDescription = product.localizedDescription(languageCode);
    return _CustomerScaffold(
      title: productName,
      body: _CustomerScrollView(
        children: [
          _CustomerCard(
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.05,
                  child: ProductImage(url: product.imageUrl, radius: 8),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: StatusChip(
                    status: product.isAvailable ? 'Available' : 'Unavailable',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 18,
                      color: _customerMuted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        product.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _customerMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _customerLine),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.price.money,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: _customerPrimary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ),
                      Text(
                        context.t(
                          'per {unit}',
                          values: {'unit': context.t(product.unit)},
                        ),
                        style: const TextStyle(
                          color: _customerMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('About this item'),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  productDescription.isEmpty
                      ? context.t(
                          'No description added yet. You can still add it to your cart and confirm details at checkout.',
                        )
                      : productDescription,
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: PrimaryActionButton(
          label: product.isAvailable ? 'Add to cart' : 'Unavailable',
          icon: product.isAvailable ? Icons.add_shopping_cart : Icons.block,
          onPressed: product.isAvailable
              ? () async {
                  await context.read<AppState>().addToCart(product);
                  if (context.mounted) {
                    showSnack(context, 'Added to cart.');
                  }
                }
              : null,
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = appState.cartItems;
    final hasCheckoutDraft =
        items.isNotEmpty || appState.hasBillImage || appState.hasManualList;
    return _CustomerScaffold(
      title: 'Cart',
      body: !hasCheckoutDraft
          ? RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Your cart is empty',
                message:
                    'Add catalog products, upload a list photo, or type a manual list.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProductListScreen()),
                  ),
                  icon: const Icon(Icons.search),
                  label: Text(context.t('Browse products')),
                ),
              ),
            )
          : _CustomerScrollView(
              children: [
                _CartSummaryPanel(
                  itemCount: appState.cartCount,
                  subtotal: appState.cartSubtotal,
                  hasBillImage: appState.hasBillImage,
                  hasManualList: appState.hasManualList,
                ),
                const SizedBox(height: 16),
                if (items.isNotEmpty)
                  const _CustomerSectionHeader(
                    title: 'Items in cart',
                    subtitle: 'Adjust quantities before checkout',
                  ),
                for (var index = 0; index < items.length; index++) ...[
                  _FadeSlideIn(
                    index: index,
                    child: _CartItemTile(item: items[index]),
                  ),
                  if (index != items.length - 1) const SizedBox(height: 10),
                ],
                if (appState.hasBillImage) ...[
                  if (items.isNotEmpty) const SizedBox(height: 16),
                  const _CustomerSectionHeader(
                    title: 'Attached list',
                    subtitle: 'Admin will review this with your order',
                  ),
                  _BillImagePreview(path: appState.billImagePath!),
                  const SizedBox(height: 10),
                  const _AttachedListPriceNotice(),
                ],
                if (appState.hasManualList) ...[
                  if (items.isNotEmpty || appState.hasBillImage)
                    const SizedBox(height: 16),
                  const _CustomerSectionHeader(
                    title: 'Manual list',
                    subtitle: 'Admin will review this with your order',
                  ),
                  _ManualListPreview(
                    text: appState.manualListText,
                    onRemove: () => appState.setManualListText(''),
                  ),
                  const SizedBox(height: 10),
                  if (!appState.hasBillImage) const _AttachedListPriceNotice(),
                ],
                const SizedBox(height: 88),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: hasCheckoutDraft
                  ? () => _confirmClearCheckoutDraft(context)
                  : null,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(context.t('Clear cart')),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UploadBillScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: Text(appState.hasBillImage
                        ? context.t('Change photo')
                        : context.t('Upload photo')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualListScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note),
                    label: Text(appState.hasManualList
                        ? context.t('Edit list')
                        : context.t('Type list')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryActionButton(
              label: 'Checkout',
              icon: Icons.payments,
              onPressed: hasCheckoutDraft
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CheckoutScreen()),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCheckoutDraft(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(context.t('Clear cart')),
              content: Text(
                context.t(
                  'Remove all cart items, attached photo, and manual list?',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.t('Cancel')),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(context.t('Clear')),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }
    await context.read<AppState>().clearCheckoutDraft();
    if (context.mounted) {
      showSnack(context, 'Cart cleared.');
    }
  }
}

class _CartSummaryPanel extends StatelessWidget {
  const _CartSummaryPanel({
    required this.itemCount,
    required this.subtotal,
    required this.hasBillImage,
    required this.hasManualList,
  });

  final int itemCount;
  final double subtotal;
  final bool hasBillImage;
  final bool hasManualList;

  @override
  Widget build(BuildContext context) {
    final hasAttachedList = hasBillImage || hasManualList;
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
            Color(0xFF2E6F9E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _customerPrimary.withValues(alpha: 0.2),
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
                  itemCount == 0 && hasAttachedList
                      ? context.t('Shopping list attached')
                      : itemCount == 1
                          ? context.t('1 catalog item')
                          : context.t(
                              '{count} catalog items',
                              values: {'count': itemCount},
                            ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtotal.money,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasAttachedList
                      ? context.t('Attached list for admin pricing')
                      : context.t('Catalog subtotal before delivery'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final itemName = item.localizedName(appState.effectiveLanguageCode);
    return _CustomerCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: ProductImage(url: item.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.money} / ${context.t(item.unit)}',
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.lineTotal.money,
                  style: const TextStyle(
                    color: _customerPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _customerLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: context.t('Decrease'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => appState.updateCartQuantity(
                    item.productId,
                    item.quantity - 1,
                  ),
                  icon: const Icon(Icons.remove, size: 18),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _customerInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.t('Increase'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => appState.updateCartQuantity(
                    item.productId,
                    item.quantity + 1,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadHeaderScene extends StatefulWidget {
  const _UploadHeaderScene({required this.hasImage});

  final bool hasImage;

  @override
  State<_UploadHeaderScene> createState() => _UploadHeaderSceneState();
}

class _UploadHeaderSceneState extends State<_UploadHeaderScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final sweep = -0.85 + (_controller.value * 1.7);
          final float = math.sin(_controller.value * math.pi * 2) * 5;
          return Container(
            height: 216,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0E5435),
                  Color(0xFF19744B),
                  Color(0xFF2E6F9E),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _customerPrimary.withValues(alpha: 0.24),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -18,
                  top: -34,
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white.withValues(alpha: 0.08),
                    size: 178,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: -2 + float,
                  child: _UploadFloatingPaper(scanAlignment: sweep),
                ),
                Positioned(
                  left: 0,
                  right: 116,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.hasImage
                                  ? Icons.check_circle
                                  : Icons.flash_on,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.t(
                                widget.hasImage
                                    ? 'Photo attached'
                                    : 'Fast list upload',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.t('Send your grocery list photo'),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1.02,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t(
                          'We will read your list, price the items, and update your bill.',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UploadFloatingPaper extends StatelessWidget {
  const _UploadFloatingPaper({required this.scanAlignment});

  final double scanAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _customerBlue.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 13),
                for (var i = 0; i < 5; i++) ...[
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _customerPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3ECE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (i != 4) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment(0, scanAlignment),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: _customerPrimary.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _customerPrimary.withValues(alpha: 0.28),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPhotoStage extends StatelessWidget {
  const _UploadPhotoStage({
    required this.hasImage,
    required this.path,
    required this.onPick,
  });

  final bool hasImage;
  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: hasImage && path != null
          ? _FadeSlideIn(
              key: ValueKey(path),
              child: _BillImagePreview(path: path!),
            )
          : _AnimatedUploadPlaceholder(
              key: const ValueKey('empty-upload-placeholder'),
              onPick: onPick,
            ),
    );
  }
}

class _AnimatedUploadPlaceholder extends StatefulWidget {
  const _AnimatedUploadPlaceholder({super.key, required this.onPick});

  final VoidCallback onPick;

  @override
  State<_AnimatedUploadPlaceholder> createState() =>
      _AnimatedUploadPlaceholderState();
}

class _AnimatedUploadPlaceholderState extends State<_AnimatedUploadPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scanY = -0.85 + (_controller.value * 1.7);
          final pulse =
              0.94 + (math.sin(_controller.value * math.pi * 2) * 0.04);
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPick,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 318),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _customerLine),
                  boxShadow: [
                    BoxShadow(
                      color: _customerPrimary.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFF5FBF8),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: RadialGradient(
                            center: const Alignment(0.2, -0.25),
                            radius: 0.86,
                            colors: [
                              _customerPrimaryLight.withValues(alpha: 0.72),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment(0, scanY),
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: _customerPrimary.withValues(alpha: 0.34),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: _customerPrimary.withValues(alpha: 0.20),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _UploadCornerMark(
                        alignment: Alignment.topLeft,
                        color: _customerPrimary.withValues(alpha: 0.34),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _UploadCornerMark(
                        alignment: Alignment.topRight,
                        color: _customerPrimary.withValues(alpha: 0.34),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _UploadCornerMark(
                        alignment: Alignment.bottomLeft,
                        color: _customerPrimary.withValues(alpha: 0.34),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _UploadCornerMark(
                        alignment: Alignment.bottomRight,
                        color: _customerPrimary.withValues(alpha: 0.34),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              color: _customerPrimaryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _customerPrimary.withValues(alpha: 0.10),
                              ),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: _customerPrimary,
                              size: 46,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          context.t('Place your list photo here'),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: _customerInk,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          context.t(
                            'Handwritten, printed, or shop list photos are accepted.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _customerMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UploadCornerMark extends StatelessWidget {
  const _UploadCornerMark({
    required this.alignment,
    required this.color,
  });

  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final left = alignment.x < 0;
    final top = alignment.y < 0;
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: left ? 0 : null,
            right: left ? null : 0,
            top: top ? 0 : null,
            bottom: top ? null : 0,
            child: Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: left ? 0 : null,
            right: left ? null : 0,
            top: top ? 0 : null,
            bottom: top ? null : 0,
            child: Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadInfoPanel extends StatelessWidget {
  const _UploadInfoPanel({required this.hasImage});

  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasImage ? _customerPrimaryLight : const Color(0xFFEAF3F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasImage ? Icons.verified_outlined : Icons.tips_and_updates,
              color: hasImage ? _customerPrimary : _customerBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(
                    hasImage ? 'Ready for checkout' : 'For best results',
                  ),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(
                    hasImage
                        ? 'Continue when your list is clear and readable.'
                        : 'Use bright light and keep the full list inside the frame.',
                  ),
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
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

class _UploadActionBar extends StatelessWidget {
  const _UploadActionBar({
    required this.hasImage,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
    required this.onCheckout,
  });

  final bool hasImage;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          border: const Border(top: BorderSide(color: _customerLine)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF163526).withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: PrimaryActionButton(
                    label: hasImage ? 'Change photo' : 'Choose photo',
                    icon: Icons.photo_library,
                    onPressed: onGallery,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 118,
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera, size: 19),
                    label: Text(context.t(hasImage ? 'Retake' : 'Camera')),
                  ),
                ),
              ],
            ),
            if (hasImage) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 118,
                    child: OutlinedButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 19),
                      label: Text(context.t('Remove')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryActionButton(
                      label: 'Continue to checkout',
                      icon: Icons.payments,
                      onPressed: onCheckout,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadStepStrip extends StatelessWidget {
  const _UploadStepStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _UploadStepChip(
            icon: Icons.photo_camera_outlined,
            label: 'Capture',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _UploadStepChip(
            icon: Icons.fact_check_outlined,
            label: 'Review',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _UploadStepChip(
            icon: Icons.payments_outlined,
            label: 'Bill',
          ),
        ),
      ],
    );
  }
}

class _UploadStepChip extends StatelessWidget {
  const _UploadStepChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _customerLine),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _customerPrimary, size: 21),
          const SizedBox(height: 6),
          Text(
            context.t(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _customerInk,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class UploadBillScreen extends StatelessWidget {
  const UploadBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    Future<void> choosePhoto() async {
      final imageFile = await pickImageFromGallery();
      if (imageFile == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      await appState.setBillImagePath(imageFile.path);
    }

    Future<void> takePhoto() async {
      final imageFile = await takePhotoFromCamera();
      if (imageFile == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      await appState.setBillImagePath(imageFile.path);
    }

    return _CustomerScaffold(
      title: 'Upload list',
      body: _CustomerScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        children: [
          _UploadHeaderScene(
            hasImage: appState.hasBillImage,
          ),
          const SizedBox(height: 16),
          _UploadPhotoStage(
            hasImage: appState.hasBillImage,
            path: appState.billImagePath,
            onPick: choosePhoto,
          ),
          const SizedBox(height: 16),
          const _FadeSlideIn(
            index: 2,
            child: _UploadStepStrip(),
          ),
          const SizedBox(height: 12),
          _FadeSlideIn(
            index: 3,
            child: _UploadInfoPanel(hasImage: appState.hasBillImage),
          ),
          SizedBox(height: appState.hasBillImage ? 126 : 74),
        ],
      ),
      bottomNavigationBar: _UploadActionBar(
        hasImage: appState.hasBillImage,
        onGallery: choosePhoto,
        onCamera: takePhoto,
        onRemove: () => appState.setBillImagePath(null),
        onCheckout: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CheckoutScreen(),
          ),
        ),
      ),
    );
  }
}

class ManualListScreen extends StatefulWidget {
  const ManualListScreen({super.key});

  @override
  State<ManualListScreen> createState() => _ManualListScreenState();
}

class _ManualListScreenState extends State<ManualListScreen> {
  static const _draftSaveDelay = Duration(milliseconds: 450);

  late final TextEditingController _list;
  late final AppState _appState;
  Timer? _saveDebounce;
  String _lastSavedText = '';

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    final initialText = _appState.manualListText;
    _list = TextEditingController(text: initialText);
    _lastSavedText = initialText;
    _list.addListener(_handleListChanged);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (_list.text != _lastSavedText) {
      unawaited(_appState.setManualListText(_list.text));
    }
    _list.removeListener(_handleListChanged);
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasList = _list.text.trim().isNotEmpty;
    return _CustomerScaffold(
      title: 'Manual list',
      body: _CustomerScrollView(
        children: [
          _CustomerCard(
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _customerPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: _customerPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t(
                      'Type your grocery items with quantities. Admin will review the list and update your final bill.',
                    ),
                    style: const TextStyle(
                      color: _customerMuted,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CustomerCard(
            child: TextFormField(
              controller: _list,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 9,
              maxLines: 14,
              decoration: InputDecoration(
                labelText: context.t('Grocery list'),
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.playlist_add),
                hintText: context.t(
                  'Example:\n2 kg rice\n1 packet baking powder\n6 eggs',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _AttachedListPriceNotice(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasList ? _clearList : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.t('Clear list')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveNow,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.t('Save draft')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            label: 'Continue to checkout',
            icon: Icons.payments,
            onPressed: hasList ? _continueToCheckout : null,
          ),
        ],
      ),
    );
  }

  void _handleListChanged() {
    if (mounted) {
      setState(() {});
    }
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_draftSaveDelay, () {
      unawaited(_persistList());
    });
  }

  Future<void> _persistList() async {
    final text = _list.text;
    if (text == _lastSavedText) {
      return;
    }
    _lastSavedText = text;
    await _appState.setManualListText(text);
  }

  Future<void> _saveNow() async {
    _saveDebounce?.cancel();
    await _persistList();
    if (mounted) {
      showSnack(context, 'Manual list saved.');
    }
  }

  Future<void> _clearList() async {
    _saveDebounce?.cancel();
    _list.clear();
    _lastSavedText = '';
    await _appState.setManualListText('');
    if (mounted) {
      showSnack(context, 'Manual list cleared.');
    }
  }

  Future<void> _continueToCheckout() async {
    if (_list.text.trim().isEmpty) {
      showSnack(context, 'Type at least one grocery item.');
      return;
    }
    _saveDebounce?.cancel();
    await _persistList();
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }
}

class _BillImagePreview extends StatelessWidget {
  const _BillImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFEAF0EA),
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _customerPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: _customerPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('Shopping list image ready for upload.'),
                    style: const TextStyle(
                      color: _customerInk,
                      fontWeight: FontWeight.w800,
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
}

class _ManualListPreview extends StatelessWidget {
  const _ManualListPreview({
    required this.text,
    this.onRemove,
  });

  final String text;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _customerPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: _customerPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('Typed grocery list'),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: context.t('Remove list'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _customerLine),
            ),
            child: Text(
              text.trim(),
              style: const TextStyle(
                color: _customerInk,
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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  final _notes = TextEditingController();
  String _paymentMethod = AppConstants.paymentMethodCod;
  String? _receiptImagePath;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile!;
    _name = TextEditingController(text: profile.fullName);
    _phone = TextEditingController(
      text: PhoneUtils.localSriLankanDigits(profile.phone),
    );
    _address = TextEditingController(text: profile.address);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final paymentSettings = context.watch<AppState>().paymentSettings;
    final availablePaymentMethod =
        paymentSettings.availablePaymentMethodOrNull(_paymentMethod);
    if (availablePaymentMethod != null &&
        availablePaymentMethod != _paymentMethod) {
      _paymentMethod = availablePaymentMethod;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final paymentSettings = appState.paymentSettings;
    final selectedPaymentMethod =
        paymentSettings.availablePaymentMethodOrNull(_paymentMethod);
    final hasPaymentMethods = selectedPaymentMethod != null;
    final isBankTransfer =
        selectedPaymentMethod == AppConstants.paymentMethodBankTransfer;
    final charges = appState.checkoutChargeSettings;
    final total = charges.totalFor(appState.cartSubtotal);
    return _CustomerScaffold(
      title: 'Checkout',
      body: Form(
        key: _formKey,
        child: _CustomerScrollView(
          children: [
            _CheckoutSummary(total: total),
            const SizedBox(height: 14),
            _CheckoutOrderReview(
              items: appState.cartItems,
              billImagePath: appState.billImagePath,
              manualListText: appState.manualListText,
              onEditItems: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              onEditPhotoList: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UploadBillScreen()),
              ),
              onEditManualList: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManualListScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _CustomerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('Payment method'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: AppConstants.paymentMethodCod,
                    groupValue: selectedPaymentMethod,
                    onChanged: paymentSettings.codEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() => _paymentMethod = value);
                            }
                          }
                        : null,
                    title: Text(context.t('Cash on Delivery')),
                    subtitle: Text(
                      context.t(
                        paymentSettings.codEnabled
                            ? 'Pay by cash when your order is delivered.'
                            : 'Temporarily unavailable.',
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: AppConstants.paymentMethodBankTransfer,
                    groupValue: selectedPaymentMethod,
                    onChanged: paymentSettings.bankTransferEnabled
                        ? (value) {
                            if (value != null) {
                              setState(() => _paymentMethod = value);
                            }
                          }
                        : null,
                    title: Text(context.t('Bank transfer')),
                    subtitle: Text(
                      context.t(
                        paymentSettings.bankTransferEnabled
                            ? 'Transfer to the store account and upload your receipt.'
                            : 'Temporarily unavailable.',
                      ),
                    ),
                  ),
                  if (!hasPaymentMethods) ...[
                    const SizedBox(height: 8),
                    const _CheckoutPaymentUnavailableNotice(),
                  ],
                  if (isBankTransfer) ...[
                    const SizedBox(height: 8),
                    _BankTransferDetails(settings: paymentSettings),
                    const SizedBox(height: 12),
                    _ReceiptUploadSection(
                      imagePath: _receiptImagePath,
                      onGallery: _pickReceiptFromGallery,
                      onCamera: _takeReceiptPhoto,
                      onRemove: () => setState(() => _receiptImagePath = null),
                    ),
                  ],
                  const Divider(height: 24),
                  _AmountRow('Subtotal', appState.cartSubtotal.money),
                  if (charges.deliveryCharge > 0)
                    _AmountRow('Delivery charge', charges.deliveryCharge.money),
                  if (charges.serviceCharge > 0)
                    _AmountRow('Service charge', charges.serviceCharge.money),
                  if (appState.hasBillImage || appState.hasManualList) ...[
                    const SizedBox(height: 10),
                    const _AttachedListPriceNotice(),
                  ],
                  const Divider(height: 24),
                  _AmountRow('Estimated total', total.money, isStrong: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _name,
              label: 'Customer name',
              validator: (value) =>
                  Validators.requiredText(value, 'Customer name'),
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
              controller: _notes,
              label: 'Order notes',
              maxLines: 3,
              prefixIcon: Icons.notes,
            ),
            const SizedBox(height: 18),
            PrimaryActionButton(
              label: !hasPaymentMethods
                  ? 'Payment unavailable'
                  : isBankTransfer
                      ? 'Place bank transfer order'
                      : 'Place COD order',
              icon: !hasPaymentMethods
                  ? Icons.block
                  : isBankTransfer
                      ? Icons.account_balance
                      : Icons.check_circle,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting || !hasPaymentMethods ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final appState = context.read<AppState>();
    final paymentMethod =
        appState.paymentSettings.availablePaymentMethodOrNull(_paymentMethod);
    if (paymentMethod == null) {
      showSnack(context, 'Payment methods are temporarily unavailable.');
      return;
    }
    if (paymentMethod != _paymentMethod) {
      setState(() => _paymentMethod = paymentMethod);
    }
    if (paymentMethod == AppConstants.paymentMethodBankTransfer &&
        (_receiptImagePath == null || _receiptImagePath!.isEmpty)) {
      showSnack(context, 'Upload the bank transfer receipt before checkout.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final order = await appState.createOrder(
        customerName: _name.text,
        customerPhone: PhoneUtils.normalizeSriLankanPhone(_phone.text),
        customerAddress: _address.text,
        orderNotes: _notes.text,
        paymentMethod: paymentMethod,
        paymentReceiptImagePath: _receiptImagePath,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickReceiptFromGallery() async {
    final imageFile = await pickImageFromGallery();
    if (imageFile == null || !mounted) {
      return;
    }
    setState(() => _receiptImagePath = imageFile.path);
  }

  Future<void> _takeReceiptPhoto() async {
    final imageFile = await takePhotoFromCamera();
    if (imageFile == null || !mounted) {
      return;
    }
    setState(() => _receiptImagePath = imageFile.path);
  }
}

class _CheckoutOrderReview extends StatelessWidget {
  const _CheckoutOrderReview({
    required this.items,
    required this.billImagePath,
    required this.manualListText,
    required this.onEditItems,
    required this.onEditPhotoList,
    required this.onEditManualList,
  });

  final List<CartItem> items;
  final String? billImagePath;
  final String manualListText;
  final VoidCallback onEditItems;
  final VoidCallback onEditPhotoList;
  final VoidCallback onEditManualList;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppState>().effectiveLanguageCode;
    final hasPhotoList = billImagePath != null && billImagePath!.isNotEmpty;
    final hasManualList = manualListText.trim().isNotEmpty;
    return _CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _customerPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: _customerPrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('Order review'),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isNotEmpty) ...[
            _CheckoutReviewHeader(
              title: items.length == 1 ? 'Catalog item' : 'Catalog items',
              trailing: items.length == 1
                  ? '1 item'
                  : context.t(
                      '{count} items',
                      values: {'count': items.length},
                    ),
              onEdit: onEditItems,
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < items.length; index++) ...[
              _CheckoutItemRow(
                item: items[index],
                languageCode: languageCode,
              ),
              if (index != items.length - 1) const Divider(height: 14),
            ],
          ],
          if (hasPhotoList) ...[
            if (items.isNotEmpty) const Divider(height: 22),
            _CheckoutPhotoListReview(
              imagePath: billImagePath!,
              onEdit: onEditPhotoList,
            ),
          ],
          if (hasManualList) ...[
            if (items.isNotEmpty || hasPhotoList) const Divider(height: 22),
            _CheckoutManualListReview(
              text: manualListText,
              onEdit: onEditManualList,
            ),
          ],
          if (items.isEmpty && !hasPhotoList && !hasManualList)
            Text(
              context.t('No checkout items selected.'),
              style: const TextStyle(
                color: _customerMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckoutReviewHeader extends StatelessWidget {
  const _CheckoutReviewHeader({
    required this.title,
    required this.trailing,
    required this.onEdit,
  });

  final String title;
  final String trailing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t(title),
            style: const TextStyle(
              color: _customerInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: _customerMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(context.t('Edit')),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }
}

class _CheckoutItemRow extends StatelessWidget {
  const _CheckoutItemRow({
    required this.item,
    required this.languageCode,
  });

  final CartItem item;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: ProductImage(url: item.imageUrl),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.localizedName(languageCode),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _customerInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} x ${item.price.money} / ${context.t(item.unit)}',
                style: const TextStyle(
                  color: _customerMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.lineTotal.money,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: _customerPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CheckoutPhotoListReview extends StatelessWidget {
  const _CheckoutPhotoListReview({
    required this.imagePath,
    required this.onEdit,
  });

  final String imagePath;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFEAF0EA),
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('Photo list attached'),
                style: const TextStyle(
                  color: _customerInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('Admin will review this photo with your order.'),
                style: const TextStyle(
                  color: _customerMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(context.t('Edit')),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }
}

class _CheckoutManualListReview extends StatelessWidget {
  const _CheckoutManualListReview({
    required this.text,
    required this.onEdit,
  });

  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.t('Manual list'),
                style: const TextStyle(
                  color: _customerInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(context.t('Edit')),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _customerLine),
          ),
          child: Text(
            text.trim(),
            style: const TextStyle(
              color: _customerInk,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({required this.total});

  final double total;

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
            Color(0xFF176B45),
            Color(0xFF2E6F9E),
            Color(0xFFE86F4A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _customerPrimary.withValues(alpha: 0.2),
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
                  context.t('Estimated total'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total.money,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('Review payment and delivery details'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.value, {this.isStrong = false});

  final String label;
  final String value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isStrong ? FontWeight.w900 : FontWeight.w500,
      fontSize: isStrong ? 16 : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(context.t(label), style: style)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachedListPriceNotice extends StatelessWidget {
  const _AttachedListPriceNotice();

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFC83A2B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0B1A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                'The prices of attached list items are not calculated in this estimate. Admin will review the photo or typed list and update the final bill.',
              ),
              style: const TextStyle(
                color: danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutPaymentUnavailableNotice extends StatelessWidget {
  const _CheckoutPaymentUnavailableNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD89A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pause_circle_outline, color: _customerWarning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(
                'Payment methods are temporarily unavailable. Please try again later.',
              ),
              style: const TextStyle(
                color: _customerInk,
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

class _BankTransferDetails extends StatelessWidget {
  const _BankTransferDetails({required this.settings});

  final PaymentSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('Transfer account'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _BankDetailRow('Name', settings.bankAccountName),
          _BankDetailRow('Bank', settings.bankName),
          _BankDetailRow('Branch', settings.bankBranch),
          _BankDetailRow('Account number', settings.bankAccountNumber),
        ],
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  const _BankDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              context.t(label),
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

class _ReceiptUploadSection extends StatelessWidget {
  const _ReceiptUploadSection({
    required this.imagePath,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('Payment receipt'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFEAF0EA),
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDE5DD)),
            ),
            child: Text(
              context.t(
                'Upload the bank slip or transfer screenshot before placing the order.',
              ),
              style: const TextStyle(color: Color(0xFF66736B)),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(context.t(hasImage ? 'Change' : 'Gallery')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera),
                label: Text(context.t(hasImage ? 'Retake' : 'Camera')),
              ),
            ),
          ],
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            label: Text(context.t('Remove receipt')),
          ),
        ],
      ],
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final isBankTransfer =
        order.paymentMethod == AppConstants.paymentMethodBankTransfer;
    return _CustomerScaffold(
      title: 'Order placed',
      body: _CustomerScrollView(
        children: [
          _CustomerCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.78, end: 1),
                  duration: const Duration(milliseconds: 460),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: _customerPrimaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: _customerPrimary,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.t('Order received'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBankTransfer
                      ? context.t(
                          'Your bank transfer order is pending admin receipt review.',
                        )
                      : context.t('Your COD order is pending admin review.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CustomerCard(
            child: Column(
              children: [
                _AmountRow('Order', '#${order.orderId.substring(0, 8)}'),
                _AmountRow('Total', order.totalAmount.money, isStrong: true),
                _AmountRow('Payment', context.t(order.paymentMethod)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: order.orderId),
              ),
            ),
            icon: const Icon(Icons.track_changes),
            label: Text(context.t('Track order')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(context.t('Back home')),
          ),
        ],
      ),
    );
  }
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  var _selectedFilter = _OrderHistoryFilters.all;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return _CustomerScaffold(
      title: 'Order history',
      body: StreamBuilder<List<OrderModel>>(
        stream:
            appState.firestoreService.watchOrdersForUser(appState.profile!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton();
          }
          final orders = snapshot.data ?? const <OrderModel>[];
          if (orders.isEmpty) {
            return const RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.history,
                title: 'No orders yet',
                message: 'Your order history will appear here.',
              ),
            );
          }
          return _CustomerScrollView(
            children: [
              _OrderHistoryHeading(
                filter: _selectedFilter,
                shownCount: _selectedFilter.countIn(orders),
                totalCount: orders.length,
              ),
              _OrderHistoryFilterBar(
                selected: _selectedFilter,
                orders: orders,
                onSelected: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
              const SizedBox(height: 14),
              ..._buildOrderList(_selectedFilter.apply(orders)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return [
        EmptyState(
          icon: _selectedFilter.emptyIcon,
          title: _selectedFilter.emptyTitle,
          message: _selectedFilter.emptyMessage,
        ),
      ];
    }

    return [
      for (var index = 0; index < orders.length; index++) ...[
        _FadeSlideIn(
          index: index,
          child: OrderTile(order: orders[index]),
        ),
        if (index != orders.length - 1) const SizedBox(height: 12),
      ],
    ];
  }
}

class _OrderHistoryFilter {
  const _OrderHistoryFilter({
    required this.id,
    required this.label,
    required this.icon,
    required this.heading,
    required this.subtitle,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.statuses,
  });

  final String id;
  final String label;
  final IconData icon;
  final String heading;
  final String subtitle;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final Set<String>? statuses;

  bool matches(OrderModel order) {
    final filterStatuses = statuses;
    return filterStatuses == null || filterStatuses.contains(order.orderStatus);
  }

  int countIn(List<OrderModel> orders) {
    return orders.where(matches).length;
  }

  List<OrderModel> apply(List<OrderModel> orders) {
    return orders.where(matches).toList();
  }
}

class _OrderHistoryFilters {
  const _OrderHistoryFilters._();

  static const all = _OrderHistoryFilter(
    id: 'all',
    label: 'All',
    icon: Icons.receipt_long_outlined,
    heading: 'Recent orders',
    subtitle: 'Track progress and review previous baskets',
    emptyIcon: Icons.history,
    emptyTitle: 'No orders yet',
    emptyMessage: 'Your order history will appear here.',
  );

  static const active = _OrderHistoryFilter(
    id: 'active',
    label: 'Active',
    icon: Icons.local_shipping_outlined,
    heading: 'Active orders',
    subtitle: 'Orders being prepared, shopped, or delivered.',
    emptyIcon: Icons.local_shipping_outlined,
    emptyTitle: 'No active orders',
    emptyMessage: 'Orders in progress will appear here.',
    statuses: {
      'Pending',
      'Accepted',
      'Shopping Started',
      'Out for Delivery',
    },
  );

  static const attention = _OrderHistoryFilter(
    id: 'attention',
    label: 'Needs attention',
    icon: Icons.priority_high_rounded,
    heading: 'Needs attention',
    subtitle: 'Orders with questions, item changes, or updated bills.',
    emptyIcon: Icons.mark_chat_read_outlined,
    emptyTitle: 'Nothing needs attention',
    emptyMessage: 'Orders that need your review will appear here.',
    statuses: {
      'Need Clarification',
      'Item Unavailable',
      'Bill Updated',
    },
  );

  static const delivered = _OrderHistoryFilter(
    id: 'delivered',
    label: 'Delivered',
    icon: Icons.check_circle_outline,
    heading: 'Delivered orders',
    subtitle: 'Completed baskets are saved for quick review.',
    emptyIcon: Icons.check_circle_outline,
    emptyTitle: 'No delivered orders',
    emptyMessage: 'Completed orders will appear here.',
    statuses: {'Delivered'},
  );

  static const rejected = _OrderHistoryFilter(
    id: 'rejected',
    label: 'Rejected',
    icon: Icons.cancel_outlined,
    heading: 'Rejected orders',
    subtitle: 'Orders that could not be completed.',
    emptyIcon: Icons.cancel_outlined,
    emptyTitle: 'No rejected orders',
    emptyMessage: 'Rejected or cancelled orders will appear here.',
    statuses: {'Rejected', 'Cancelled'},
  );

  static const values = [
    all,
    active,
    attention,
    delivered,
    rejected,
  ];
}

class _OrderHistoryHeading extends StatelessWidget {
  const _OrderHistoryHeading({
    required this.filter,
    required this.shownCount,
    required this.totalCount,
  });

  final _OrderHistoryFilter filter;
  final int shownCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final isShowingAll = filter.id == _OrderHistoryFilters.all.id;
    final countLabel = isShowingAll
        ? context.t('{count} orders', values: {'count': totalCount})
        : context.t(
            '{count} of {total} orders',
            values: {'count': shownCount, 'total': totalCount},
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(filter.heading),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.t(filter.subtitle),
                  style: const TextStyle(
                    color: _customerMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _customerPrimaryLight,
              border: Border.all(color: _customerLine),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              countLabel,
              style: const TextStyle(
                color: _customerPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryFilterBar extends StatelessWidget {
  const _OrderHistoryFilterBar({
    required this.selected,
    required this.orders,
    required this.onSelected,
  });

  final _OrderHistoryFilter selected;
  final List<OrderModel> orders;
  final ValueChanged<_OrderHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _OrderHistoryFilters.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _OrderHistoryFilters.values[index];
          final isSelected = selected.id == filter.id;
          final accent = isSelected ? _customerPrimary : _customerMuted;
          return ChoiceChip(
            avatar: Icon(
              isSelected ? Icons.check : filter.icon,
              size: 17,
              color: isSelected ? Colors.white : accent,
            ),
            label: Text(
              '${context.t(filter.label)} (${filter.countIn(orders)})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : _customerInk,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: _customerPrimary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? _customerPrimary : _customerLine,
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

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final color = _statusAccent(order.orderStatus);
    return _CustomerCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.orderId),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(
                    'Order {id}',
                    values: {'id': order.orderId.substring(0, 8)},
                  ),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat.yMMMd().add_jm().format(order.createdAt),
                  style: const TextStyle(
                    color: _customerMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.totalAmount.money,
                  style: const TextStyle(
                    color: _customerPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (order.hasDeliveryReview) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star, color: _customerGold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${order.deliveryRating}/5 delivery rating',
                        style: const TextStyle(
                          color: _customerMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          StatusChip(status: order.orderStatus),
        ],
      ),
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return StreamBuilder<OrderModel?>(
      stream: appState.firestoreService.watchOrder(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CustomerScaffold(
            title: 'Order tracking',
            body: _ListSkeleton(itemCount: 3),
          );
        }
        final order = snapshot.data;
        if (order == null) {
          return const _CustomerScaffold(
            title: 'Order tracking',
            body: RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.receipt_long,
                title: 'Order not found',
                message: 'This order may have been removed.',
              ),
            ),
          );
        }
        if (order.orderStatus == 'Delivered') {
          return _CustomerScaffold(
            title: 'Order delivered',
            body: _DeliveredOrderCompletionView(order: order),
          );
        }
        if (order.orderStatus == 'Rejected') {
          return _CustomerScaffold(
            title: 'Order rejected',
            body: _RejectedOrderCompletionView(order: order),
          );
        }
        return _CustomerScaffold(
          title: 'Order tracking',
          body: _ActiveOrderTrackingView(order: order),
        );
      },
    );
  }
}

class _ActiveOrderTrackingView extends StatelessWidget {
  const _ActiveOrderTrackingView({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerScrollView(
      children: [
        _CustomerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t(
                        'Order {id}',
                        values: {
                          'id': order.orderId.substring(0, 8),
                        },
                      ),
                      style: const TextStyle(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  StatusChip(status: order.orderStatus),
                ],
              ),
              const SizedBox(height: 14),
              _AmountRow('Total', order.totalAmount.money, isStrong: true),
              _AmountRow(
                'Payment',
                '${context.t(order.paymentMethod)} (${context.t(order.paymentStatus)})',
              ),
              if (order.hasAssignedDeliveryContact) ...[
                const Divider(height: 24),
                _DeliveryContactSummary(order: order),
              ],
              if (order.adminNotes.isNotEmpty) ...[
                const Divider(height: 24),
                _AdminNoteSummary(order: order),
              ],
            ],
          ),
        ),
        if (_shouldShowFinalBillBreakdown(order)) ...[
          const SizedBox(height: 16),
          const _CustomerSectionHeader(title: 'Bill details'),
          _OrderBillBreakdown(order: order),
        ],
        const SizedBox(height: 16),
        _TrackingSteps(status: order.orderStatus),
        const SizedBox(height: 16),
        _OrderContentSections(
          order: order,
          showAttachedListPriceNotice: true,
        ),
        const SizedBox(height: 18),
        _OrderSupportButton(order: order),
      ],
    );
  }
}

class _DeliveredOrderCompletionView extends StatelessWidget {
  const _DeliveredOrderCompletionView({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerScrollView(
      children: [
        _OrderTerminalHero(
          icon: Icons.check_circle_outline,
          color: _customerPrimary,
          status: order.orderStatus,
          title: 'Thank you for your order!',
          message:
              'Your groceries have been delivered successfully. We hope everything reached you safely.',
        ),
        const SizedBox(height: 16),
        const _CustomerSectionHeader(
          title: 'Amount details',
          subtitle: 'Final bill summary',
        ),
        _OrderBillBreakdown(order: order),
        const SizedBox(height: 12),
        _OrderSummaryCard(order: order),
        if (order.hasAssignedDeliveryContact) ...[
          const SizedBox(height: 12),
          _CustomerCard(child: _DeliveryContactSummary(order: order)),
        ],
        if (order.assignedDeliveryBoyId.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DeliveryReviewCard(order: order),
        ],
        if (order.adminNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CustomerCard(child: _AdminNoteSummary(order: order)),
        ],
        const SizedBox(height: 16),
        _OrderContentSections(order: order),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.home_outlined),
          label: Text(context.t('Back home')),
        ),
        const SizedBox(height: 8),
        _OrderSupportButton(order: order),
      ],
    );
  }
}

class _DeliveryReviewCard extends StatelessWidget {
  const _DeliveryReviewCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final hasReview = order.hasDeliveryReview;
    final deliveryName = order.assignedDeliveryPerson.trim().isEmpty
        ? context.t('your delivery person')
        : order.assignedDeliveryPerson.trim();
    return _CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _customerGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: _customerWarning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t(
                        hasReview
                            ? 'Your delivery review'
                            : 'Rate your delivery',
                      ),
                      style: const TextStyle(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasReview
                          ? context.t('Thank you for sharing your experience.')
                          : context.t(
                              'How was your delivery with {name}?',
                              values: {'name': deliveryName},
                            ),
                      style: const TextStyle(
                        color: _customerMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasReview) ...[
            const SizedBox(height: 14),
            _DeliveryRatingStars(
              rating: order.deliveryRating,
              iconSize: 26,
            ),
            if (order.deliveryReview.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _customerBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _customerLine),
                ),
                child: Text(
                  order.deliveryReview.trim(),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDeliveryReviewDialog(context, order),
              icon: Icon(hasReview ? Icons.edit_outlined : Icons.star_outline),
              label: Text(
                context.t(hasReview ? 'Edit review' : 'Rate delivery'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryRatingStars extends StatelessWidget {
  const _DeliveryRatingStars({
    required this.rating,
    this.iconSize = 32,
    this.onSelected,
  });

  final int rating;
  final double iconSize;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final canSelect = onSelected != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var value = 1; value <= 5; value++) ...[
          Semantics(
            button: canSelect,
            selected: value <= rating,
            label: context.tNow('{rating} stars', values: {'rating': value}),
            child: InkResponse(
              onTap: canSelect ? () => onSelected!(value) : null,
              radius: iconSize * 0.7,
              containedInkWell: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Icon(
                  value <= rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: value <= rating ? _customerGold : _customerMuted,
                  size: iconSize,
                ),
              ),
            ),
          ),
          if (value < 5) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

Future<void> _showDeliveryReviewDialog(
  BuildContext context,
  OrderModel order,
) async {
  final pageContext = context;
  final appState = context.read<AppState>();

  final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DeliveryReviewDialog(
          order: order,
          title: pageContext.tNow(
            order.hasDeliveryReview
                ? 'Edit delivery review'
                : 'Rate your delivery',
          ),
          helperText: pageContext.tNow(
            'Your feedback helps us improve every delivery.',
          ),
          reviewLabel: pageContext.tNow('Review (optional)'),
          reviewHint: pageContext.tNow(
            'Tell us what went well or what can improve.',
          ),
          requiredRatingMessage: pageContext.tNow(
            'Choose a star rating before submitting.',
          ),
          cancelLabel: pageContext.tNow('Cancel'),
          submitLabel: pageContext.tNow('Submit review'),
          savingLabel: pageContext.tNow('Saving'),
          submitReview: ({
            required orderId,
            required rating,
            required review,
          }) {
            return appState.authService.submitDeliveryReview(
              orderId: orderId,
              rating: rating,
              review: review,
            );
          },
        ),
      ) ??
      false;

  if (saved && pageContext.mounted) {
    showSnack(pageContext, 'Delivery review saved. Thank you!');
  }
}

class _DeliveryReviewDialog extends StatefulWidget {
  const _DeliveryReviewDialog({
    required this.order,
    required this.title,
    required this.helperText,
    required this.reviewLabel,
    required this.reviewHint,
    required this.requiredRatingMessage,
    required this.cancelLabel,
    required this.submitLabel,
    required this.savingLabel,
    required this.submitReview,
  });

  final OrderModel order;
  final String title;
  final String helperText;
  final String reviewLabel;
  final String reviewHint;
  final String requiredRatingMessage;
  final String cancelLabel;
  final String submitLabel;
  final String savingLabel;
  final Future<void> Function({
    required String orderId,
    required int rating,
    required String review,
  }) submitReview;

  @override
  State<_DeliveryReviewDialog> createState() => _DeliveryReviewDialogState();
}

class _DeliveryReviewDialogState extends State<_DeliveryReviewDialog> {
  late int _selectedRating;
  late final TextEditingController _reviewController;
  var _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.order.deliveryRating;
    _reviewController =
        TextEditingController(text: widget.order.deliveryReview);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedRating == 0) {
      setState(() => _errorMessage = widget.requiredRatingMessage);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.submitReview(
        orderId: widget.order.orderId,
        rating: _selectedRating,
        review: _reviewController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = context.tNow(appFriendlyErrorMessage(error));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.helperText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _customerMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _DeliveryRatingStars(
              rating: _selectedRating,
              iconSize: 36,
              onSelected: _isSaving
                  ? null
                  : (rating) {
                      setState(() {
                        _selectedRating = rating;
                        _errorMessage = null;
                      });
                    },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _customerDanger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _reviewController,
              enabled: !_isSaving,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: widget.reviewLabel,
                hintText: widget.reviewHint,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(_isSaving ? widget.savingLabel : widget.submitLabel),
        ),
      ],
    );
  }
}

class _RejectedOrderCompletionView extends StatelessWidget {
  const _RejectedOrderCompletionView({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final reason = order.rejectionReason.trim();
    return _CustomerScrollView(
      children: [
        _OrderTerminalHero(
          icon: Icons.cancel_outlined,
          color: _customerDanger,
          status: order.orderStatus,
          title: 'Sorry, your order was rejected',
          message:
              'We could not complete this order. Please review the admin reason below.',
        ),
        const SizedBox(height: 16),
        const _CustomerSectionHeader(title: 'Rejection reason'),
        _CustomerCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.report_problem_outlined,
                color: _customerDanger,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reason.isEmpty
                      ? context.t('Admin did not add a rejection reason.')
                      : reason,
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _OrderSummaryCard(order: order),
        if (order.adminNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CustomerCard(child: _AdminNoteSummary(order: order)),
        ],
        const SizedBox(height: 16),
        _OrderContentSections(order: order),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.home_outlined),
          label: Text(context.t('Back home')),
        ),
        const SizedBox(height: 8),
        _OrderSupportButton(order: order),
      ],
    );
  }
}

class _OrderTerminalHero extends StatelessWidget {
  const _OrderTerminalHero({
    required this.icon,
    required this.color,
    required this.status,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String status;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            context.t(title),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _customerInk,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t(message),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _customerMuted,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          StatusChip(status: status),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      child: Column(
        children: [
          _AmountRow('Order', '#${order.orderId.substring(0, 8)}'),
          _AmountRow('Status', context.t(order.orderStatus)),
          _AmountRow(
            'Payment',
            '${context.t(order.paymentMethod)} (${context.t(order.paymentStatus)})',
          ),
          _AmountRow('Total', order.totalAmount.money, isStrong: true),
        ],
      ),
    );
  }
}

class _AdminNoteSummary extends StatelessWidget {
  const _AdminNoteSummary({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.sticky_note_2_outlined,
          color: _customerAccent,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            order.adminNotes,
            style: const TextStyle(
              color: _customerMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderContentSections extends StatelessWidget {
  const _OrderContentSections({
    required this.order,
    this.showAttachedListPriceNotice = false,
  });

  final OrderModel order;
  final bool showAttachedListPriceNotice;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    void addSectionGap() {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 12));
      }
    }

    if (order.items.isNotEmpty) {
      addSectionGap();
      children.add(const _CustomerSectionHeader(title: 'Items'));
      for (var index = 0; index < order.items.length; index++) {
        children.add(_OrderItemRow(item: order.items[index]));
        if (index != order.items.length - 1) {
          children.add(const SizedBox(height: 8));
        }
      }
    }

    if (order.hasManualList) {
      addSectionGap();
      children.add(const _CustomerSectionHeader(title: 'Manual list'));
      children.add(_ManualListPreview(text: order.effectiveManualListText));
    }

    if (order.hasUpload) {
      addSectionGap();
      children.add(const _CustomerSectionHeader(title: 'Uploaded list'));
      if (showAttachedListPriceNotice) {
        children.add(const _AttachedListPriceNotice());
        children.add(const SizedBox(height: 10));
      }
      children.add(
        _CustomerCard(
          padding: EdgeInsets.zero,
          child: AspectRatio(
            aspectRatio: 1.4,
            child: ProductImage(url: order.uploadedImageUrl, radius: 8),
          ),
        ),
      );
    }

    if (order.hasPaymentReceipt) {
      addSectionGap();
      children.add(const _CustomerSectionHeader(title: 'Payment receipt'));
      children.add(
        _CustomerCard(
          padding: EdgeInsets.zero,
          child: AspectRatio(
            aspectRatio: 1.4,
            child: ProductImage(
              url: order.paymentReceiptImageUrl,
              radius: 8,
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _OrderSupportButton extends StatelessWidget {
  const _OrderSupportButton({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupportScreen(
            initialSubject: 'Order ${order.orderId.substring(0, 8)}',
          ),
        ),
      ),
      icon: const Icon(Icons.support_agent),
      label: Text(context.t('Contact admin')),
    );
  }
}

class _DeliveryContactSummary extends StatelessWidget {
  const _DeliveryContactSummary({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final name = order.assignedDeliveryPerson.trim();
    final phone = order.assignedDeliveryPhone.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.delivery_dining,
          color: _customerAccent,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('Delivery boy details'),
                style: const TextStyle(
                  color: _customerInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (name.isNotEmpty)
                _DeliveryContactLine(
                  label: 'Name',
                  value: name,
                ),
              if (phone.isNotEmpty)
                _DeliveryContactLine(
                  label: 'Phone number',
                  value: phone,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryContactLine extends StatelessWidget {
  const _DeliveryContactLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              context.t(label),
              style: const TextStyle(
                color: _customerMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: _customerInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _shouldShowFinalBillBreakdown(OrderModel order) {
  const finalBillStatuses = <String>{
    'Bill Updated',
    'Out for Delivery',
    'Delivered',
  };
  return finalBillStatuses.contains(order.orderStatus) ||
      (order.hasShoppingList && order.listAmountsReviewed);
}

class _OrderBillBreakdown extends StatelessWidget {
  const _OrderBillBreakdown({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      child: Column(
        children: [
          _AmountRow('Cart items', order.cartItemsAmount.money),
          _AmountRow('Photo list items', order.photoListAmount.money),
          _AmountRow('Manual list items', order.manualListAmount.money),
          const Divider(height: 20),
          _AmountRow('Order subtotal', order.subtotal.money),
          _AmountRow('Delivery charge', order.deliveryCharge.money),
          _AmountRow('Service charge', order.serviceCharge.money),
          const Divider(height: 20),
          _AmountRow(
            'Grand total',
            order.totalAmount.money,
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppState>().effectiveLanguageCode;
    return _CustomerCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isAvailable
                  ? _customerPrimaryLight
                  : _customerDanger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.isAvailable ? Icons.shopping_basket_outlined : Icons.block,
              color: item.isAvailable ? _customerPrimary : _customerDanger,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.localizedName(languageCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} x ${item.price.money} / ${context.t(item.unit)}',
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.lineTotal.money,
            style: const TextStyle(
              color: _customerPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingSteps extends StatelessWidget {
  const _TrackingSteps({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const statuses = AppConstants.customerTrackingStatuses;
    final currentIndex = statuses.indexOf(status);
    final effectiveIndex = currentIndex < 0 ? 0 : currentIndex;
    final isTerminalStatus = status == 'Cancelled' || status == 'Rejected';
    final primaryColor = Theme.of(context).colorScheme.primary;
    return _CustomerCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < statuses.length; i++)
              Builder(
                builder: (context) {
                  final isCurrent = i == effectiveIndex && currentIndex >= 0;
                  final isComplete = isTerminalStatus
                      ? i == 0 || isCurrent
                      : i <= effectiveIndex;
                  final stepColor = isCurrent
                      ? _currentStepColor(status, primaryColor)
                      : primaryColor;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == statuses.length - 1 ? 0 : 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(
                              isComplete
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isComplete
                                  ? stepColor
                                  : const Color(0xFFB8C2BB),
                            ),
                            if (i != statuses.length - 1)
                              Container(
                                height: 30,
                                width: 2,
                                color: !isTerminalStatus && i < effectiveIndex
                                    ? primaryColor
                                    : const Color(0xFFDDE5DD),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              context.t(statuses[i]),
                              style: TextStyle(
                                color:
                                    isCurrent ? _customerInk : _customerMuted,
                                fontWeight: isCurrent
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _currentStepColor(String status, Color fallback) {
    switch (status) {
      case 'Cancelled':
      case 'Rejected':
      case 'Item Unavailable':
        return const Color(0xFFC83A2B);
      case 'Need Clarification':
      case 'Bill Updated':
        return const Color(0xFFB66D00);
      default:
        return fallback;
    }
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final profile = appState.profile!;
    return _CustomerScaffold(
      title: 'Notifications',
      body: StreamBuilder<List<AppNotification>>(
        stream: appState.firestoreService.watchNotifications(
          userId: profile.uid,
          role: profile.role,
          accountCreatedAt: profile.createdAt,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Notifications unavailable',
                message: appFriendlyErrorMessage(snapshot.error),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton();
          }
          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications',
                message: 'Order and support updates will appear here.',
              ),
            );
          }
          return _CustomerScrollView(
            children: [
              const _CustomerSectionHeader(
                title: 'Updates',
                subtitle: 'Order and support activity',
              ),
              for (var index = 0; index < notifications.length; index++) ...[
                _FadeSlideIn(
                  index: index,
                  child: _CustomerCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _customerPrimaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: _customerPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.serverT(notifications[index].title),
                                style: const TextStyle(
                                  color: _customerInk,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                context.serverT(notifications[index].body),
                                style: const TextStyle(
                                  color: _customerMuted,
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
                ),
                if (index != notifications.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  var _isCreating = false;

  @override
  void initState() {
    super.initState();
    _subject.text = widget.initialSubject ?? '';
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final profile = appState.profile!;
    return _CustomerScaffold(
      title: 'Support',
      body: _CustomerScrollView(
        children: [
          _CustomerCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _subject,
                  label: 'Subject',
                  prefixIcon: Icons.subject,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _message,
                  label: 'Message',
                  maxLines: 3,
                  prefixIcon: Icons.message,
                ),
                const SizedBox(height: 12),
                PrimaryActionButton(
                  label: 'Create ticket',
                  icon: Icons.add_comment,
                  isLoading: _isCreating,
                  onPressed: _createTicket,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _CustomerSectionHeader(
            title: 'Your tickets',
            subtitle: 'Continue a previous conversation',
          ),
          StreamBuilder<List<SupportTicket>>(
            stream: appState.firestoreService.watchTickets(userId: profile.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    _ShimmerBox(width: double.infinity, height: 86),
                    SizedBox(height: 12),
                    _ShimmerBox(width: double.infinity, height: 86),
                  ],
                );
              }
              final tickets = snapshot.data ?? const <SupportTicket>[];
              if (tickets.isEmpty) {
                return const EmptyState(
                  icon: Icons.support_agent,
                  title: 'No support tickets',
                  message: 'Create a ticket when you need help with an order.',
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < tickets.length; index++) ...[
                    _FadeSlideIn(
                      index: index,
                      child: _CustomerCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SupportThreadScreen(ticket: tickets[index]),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _statusAccent(tickets[index].status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.support_agent,
                                color: _statusAccent(tickets[index].status),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tickets[index].subject,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _customerInk,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.t(tickets[index].status),
                                    style: const TextStyle(
                                      color: _customerMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: _customerMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index != tickets.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createTicket() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      showSnack(context, 'Subject and message are required.');
      return;
    }
    setState(() => _isCreating = true);
    try {
      final appState = context.read<AppState>();
      await appState.firestoreService.createSupportTicket(
        user: appState.profile!,
        subject: _subject.text,
        message: _message.text,
      );
      _subject.clear();
      _message.clear();
      if (mounted) {
        showSnack(context, 'Support ticket created.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

class SupportThreadScreen extends StatefulWidget {
  const SupportThreadScreen({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  State<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends State<SupportThreadScreen> {
  final _message = TextEditingController();
  String? _imagePath;
  var _isSending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final profile = appState.profile!;
    final isClosed = widget.ticket.status == 'closed';
    return Scaffold(
      backgroundColor: _customerBackground,
      appBar: AppBar(
        title: Text(widget.ticket.subject),
        actions: [
          if (profile.isAdmin && !isClosed)
            _CustomerIconButton(
              tooltip: 'Close ticket',
              icon: Icons.check_circle_outline,
              onPressed: () async {
                await appState.firestoreService
                    .closeTicket(widget.ticket.ticketId);
                if (context.mounted) {
                  showSnack(context, 'Ticket closed.');
                }
              },
            ),
        ],
        backgroundColor: _customerBackground.withValues(alpha: 0.96),
        foregroundColor: _customerInk,
        shape: const Border(bottom: BorderSide(color: _customerLine)),
      ),
      body: Container(
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
        child: Stack(
          children: [
            Positioned.fill(
              bottom: isClosed ? 70 : 92,
              child: SafeArea(
                top: false,
                bottom: false,
                child: _buildMessageList(appState, profile),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: isClosed ? _buildClosedNotice() : _buildComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(AppState appState, UserProfile profile) {
    return AppRefreshIndicator(
      onRefresh: () => appState.firestoreService.refreshSupportMessages(
        widget.ticket.ticketId,
      ),
      child: StreamBuilder<List<SupportMessage>>(
        stream: appState.firestoreService.watchSupportMessages(
          widget.ticket.ticketId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton(itemCount: 3);
          }
          if (snapshot.hasError) {
            return const RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.sms_failed_outlined,
                title: 'Messages unavailable',
                message: 'Please go back and open this ticket again.',
              ),
            );
          }
          final messages = snapshot.data ?? const <SupportMessage>[];
          if (messages.isEmpty) {
            return const RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.forum_outlined,
                title: 'No messages yet',
                message: 'Send a message to continue this support ticket.',
              ),
            );
          }
          return ListView.builder(
            physics: appRefreshScrollPhysics,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMine = message.senderId == profile.uid;
              return _FadeSlideIn(
                index: index,
                child: Align(
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 310),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMine ? _customerPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMine ? _customerPrimary : _customerLine,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF163526).withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.serverT(message.message),
                          style: TextStyle(
                            color: isMine ? Colors.white : _customerInk,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        if (message.imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 140,
                            child: ProductImage(url: message.imageUrl),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildClosedNotice() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      color: _customerPrimaryLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: _customerPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            context.t('Ticket closed.'),
            style: const TextStyle(
              color: _customerInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 88 + bottomInset,
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
      color: _customerPrimaryLight,
      child: Row(
        children: [
          IconButton(
            tooltip: context.t('Attach image'),
            onPressed: _isSending ? null : _chooseSupportImage,
            icon: Icon(
              _imagePath == null ? Icons.image_outlined : Icons.image,
              color: _customerInk,
            ),
          ),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _customerLine),
              ),
              child: Center(
                child: TextField(
                  controller: _message,
                  maxLines: 1,
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: context.t('Type a message'),
                    hintStyle: const TextStyle(color: _customerMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    filled: false,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54,
            height: 52,
            child: FilledButton(
              onPressed: _isSending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: _customerPrimary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }
    if (_message.text.trim().isEmpty && _imagePath == null) {
      return;
    }
    setState(() => _isSending = true);
    try {
      final appState = context.read<AppState>();
      var imageUrl = '';
      if (_imagePath != null) {
        imageUrl = await ImageUploadService.uploadUserImage(
          imageFile: File(_imagePath!),
          ownerUid: appState.profile!.uid,
          folder: 'support/${widget.ticket.ticketId}',
          fileName: 'message-${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      await appState.firestoreService.sendSupportMessage(
        ticket: widget.ticket,
        sender: appState.profile!,
        message:
            _message.text.trim().isEmpty ? 'Image attached' : _message.text,
        imageUrl: imageUrl,
      );
      if (mounted) {
        _message.clear();
        setState(() => _imagePath = null);
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _chooseSupportImage() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.t('Gallery')),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(context.t('Camera')),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );
    if (fromCamera == null) {
      return;
    }

    final imageFile =
        fromCamera ? await takePhotoFromCamera() : await pickImageFromGallery();
    if (!mounted || imageFile == null) {
      return;
    }
    setState(() => _imagePath = imageFile.path);
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  var _isSaving = false;
  var _isChangingLanguage = false;
  var _isLoggingOut = false;
  var _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile!;
    _name = TextEditingController(text: profile.fullName);
    _address = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    if (_isLoggingOut || _isDeletingAccount || profile == null) {
      return const _CustomerLogoutTransition();
    }
    return _CustomerScaffold(
      title: 'Profile',
      body: Form(
        key: _formKey,
        child: _CustomerScrollView(
          children: [
            _ProfileHeader(profile: profile),
            const SizedBox(height: 16),
            _LanguageSettingsCard(
              languageCode: appState.effectiveLanguageCode,
              isSaving: _isChangingLanguage,
              onToggle: _toggleLanguage,
            ),
            const SizedBox(height: 16),
            _CustomerCard(
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
                  AppTextField(
                    controller: _address,
                    label: 'Delivery address',
                    validator: (value) =>
                        Validators.requiredText(value, 'Delivery address'),
                    maxLines: 3,
                    prefixIcon: Icons.home,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryActionButton(
              label: 'Save profile',
              icon: Icons.save,
              isLoading: _isSaving,
              onPressed: _save,
            ),
            const SizedBox(height: 16),
            _CustomerCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: _customerPrimary,
                    ),
                    title: const Text('Privacy policy'),
                    subtitle: const Text(
                      'See how account, order, and image data is handled.',
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_forever_outlined,
                      color: _customerDanger,
                    ),
                    title: const Text(
                      'Delete account',
                      style: TextStyle(color: _customerDanger),
                    ),
                    subtitle: const Text(
                      'Permanently remove your account and personal data.',
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(context.t('Logout')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _isLoggingOut = true);
    try {
      await context.read<AppState>().logout();
    } finally {
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _openUrl(String value) async {
    final launched = await launchUrl(
      Uri.parse(value),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      showSnack(context, 'Unable to open this page.');
    }
  }

  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (password == null || !mounted) {
      return;
    }

    final navigator = Navigator.of(context);
    setState(() => _isDeletingAccount = true);
    try {
      await context.read<AppState>().deleteCustomerAccount(
            password: password,
          );
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        showSnack(context, error);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().updateProfile(
            fullName: _name.text,
            address: _address.text,
          );
      if (mounted) {
        showSnack(context, 'Profile updated.');
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

  Future<void> _toggleLanguage() async {
    if (_isChangingLanguage) {
      return;
    }
    final appState = context.read<AppState>();
    final nextLanguage =
        appState.effectiveLanguageCode == AppLanguageCodes.tamil
            ? AppLanguageCodes.english
            : AppLanguageCodes.tamil;
    setState(() => _isChangingLanguage = true);
    try {
      await appState.updatePreferredLanguage(nextLanguage);
      if (mounted) {
        showSnack(context, 'Language updated.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingLanguage = false);
      }
    }
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  var _confirmed = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Permanently delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your profile, support messages, notifications, and uploaded '
              'personal images will be removed. Closed order records are '
              'anonymized for accounting. Active orders must be completed or '
              'cancelled first.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: _obscurePassword,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            CheckboxListTile(
              value: _confirmed,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I understand this cannot be undone.'),
              onChanged: (value) {
                setState(() => _confirmed = value ?? false);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep account'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _customerDanger),
          onPressed: !_confirmed || _password.text.isEmpty
              ? null
              : () => Navigator.of(context).pop(_password.text),
          child: const Text('Delete permanently'),
        ),
      ],
    );
  }
}

class _LanguageSettingsCard extends StatelessWidget {
  const _LanguageSettingsCard({
    required this.languageCode,
    required this.isSaving,
    required this.onToggle,
  });

  final String languageCode;
  final bool isSaving;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final normalized = AppLanguageCodes.normalize(languageCode);
    final isTamil = normalized == AppLanguageCodes.tamil;
    return _CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _customerPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.translate, color: _customerPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('Language / Translate'),
                      style: const TextStyle(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.t('Current language')}: ${AppLanguageCodes.nativeName(normalized)}',
                      style: const TextStyle(
                        color: _customerMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isSaving ? null : onToggle,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.swap_horiz),
            label: Text(
              context.t(isTamil ? 'Switch to English' : 'Switch to Tamil'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile.fullName.trim().isEmpty
        ? 'IG'
        : profile.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.substring(0, 1).toUpperCase())
            .join();
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
            color: _customerPrimary.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.phone,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t(profile.role),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
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
