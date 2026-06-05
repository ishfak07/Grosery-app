import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../services/cloudinary_service.dart';
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
        backgroundColor: _customerBackground.withOpacity(0.96),
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
              color: const Color(0xFF163526).withOpacity(0.08),
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
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(context.t(actionLabel!)),
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
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
            safeAreaTop: true,
            children: [
              FirebaseSetupBanner(appState: appState),
              _HomeHeader(
                profile: profile,
                cartCount: appState.cartCount,
              ),
              const SizedBox(height: 16),
              _HomeSearchCallout(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                ),
              ),
              const SizedBox(height: 14),
              const _HomeOffersCarousel(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 22),
              _CustomerSectionHeader(
                title: 'Fresh picks',
                subtitle: 'Recently added to the catalog',
                actionLabel: 'View all',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogoMark(size: 44, padding: 2),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: _customerMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.t('Hi {name}', values: {'name': firstName}),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _customerInk,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: _customerAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            profile.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _customerMuted,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _CustomerIconButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_outlined,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        _CustomerIconButton(
          tooltip: 'Cart',
          icon: Icons.shopping_bag_outlined,
          badgeCount: cartCount,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ],
    );
  }
}

class _HomeSearchCallout extends StatelessWidget {
  const _HomeSearchCallout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.search, color: _customerPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.t('Search groceries and shops'),
              style: const TextStyle(
                color: _customerMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.tune, color: _customerMuted, size: 20),
        ],
      ),
    );
  }
}

class _HomePromoBanner extends StatelessWidget {
  const _HomePromoBanner();

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
            Color(0xFF145C3B),
            Color(0xFF1E8E5A),
            Color(0xFFE86F4A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _customerPrimary.withOpacity(0.22),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Text(
                    context.t('Fast local delivery'),
                    style: const TextStyle(
                      color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t(
                    'We shop from trusted partners and keep you updated.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
              ),
              const Icon(
                Icons.shopping_basket_outlined,
                size: 52,
                color: Colors.white,
              ),
              Positioned(
                right: 4,
                bottom: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _customerGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 17,
                    color: _customerInk,
                  ),
                ),
              ),
            ],
          ),
        ],
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
            final height = constraints.maxWidth < 380 ? 178.0 : 204.0;
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
                  const SizedBox(height: 8),
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
    return _Pressable(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(url: offer.imageUrl, radius: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.72),
                    ],
                  ),
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
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (dateLabel != null) ...[
                      const SizedBox(height: 9),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_available_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              dateLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _OfferCarouselSkeleton extends StatelessWidget {
  const _OfferCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 204,
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
            color: const Color(0xFF10231A).withOpacity(0.07),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
}

class _HomeActionGrid extends StatelessWidget {
  const _HomeActionGrid({required this.actions});

  final List<_HomeActionSpec> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useThreeColumns = constraints.maxWidth >= 640;
        final spacing = useThreeColumns ? 12.0 : 10.0;
        final compactTileWidth = (constraints.maxWidth - spacing) / 2;
        final wideTileWidth = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < actions.length; i++)
              SizedBox(
                width: useThreeColumns
                    ? wideTileWidth
                    : i == actions.length - 1
                        ? constraints.maxWidth
                        : compactTileWidth,
                child: _HomeActionTile(
                  icon: actions[i].icon,
                  title: actions[i].title,
                  subtitle: actions[i].subtitle,
                  accent: actions[i].accent,
                  onTap: actions[i].onTap,
                ),
              ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return _Pressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 144,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: const Color(0xFFDCE8DF)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color.lerp(Colors.white, accent, 0.055)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF163526).withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
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
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: const SizedBox(width: 5),
                  ),
                ),
                Positioned(
                  right: -16,
                  bottom: -18,
                  child: Icon(
                    icon,
                    color: accent.withOpacity(0.065),
                    size: 92,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 13, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _HomeActionIconBadge(icon: icon, accent: accent),
                          const Spacer(),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.72),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accent.withOpacity(0.18),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: accent,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        context.t(title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _customerInk,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t(subtitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _customerMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
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
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Icon(icon, color: accent, size: 25),
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
            color: _customerPrimary.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.82),
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
                    color: Colors.white.withOpacity(0.8),
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
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
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

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: _customerPrimaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: _customerPrimary,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.t('No list photo selected'),
            style: const TextStyle(
              color: _customerInk,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('Use gallery or camera to attach your list.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _customerMuted,
              fontWeight: FontWeight.w600,
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
    return _CustomerScaffold(
      title: 'Upload list',
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
                    Icons.receipt_long,
                    color: _customerPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t(
                      'Upload a clear handwritten, printed, or shop list photo. Admin will review it and update your final bill.',
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
          if (appState.hasBillImage)
            _BillImagePreview(path: appState.billImagePath!)
          else
            const _UploadPlaceholder(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PrimaryActionButton(
                  label: appState.hasBillImage ? 'Gallery' : 'Choose photo',
                  icon: Icons.photo_library,
                  onPressed: () async {
                    final imageFile = await pickImageFromGallery();
                    if (imageFile == null) {
                      return;
                    }
                    if (!context.mounted) {
                      return;
                    }
                    await appState.setBillImagePath(imageFile.path);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final imageFile = await takePhotoFromCamera();
                    if (imageFile == null) {
                      return;
                    }
                    if (!context.mounted) {
                      return;
                    }
                    await appState.setBillImagePath(imageFile.path);
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: Text(
                    context.t(appState.hasBillImage ? 'Retake' : 'Camera'),
                  ),
                ),
              ),
            ],
          ),
          if (appState.hasBillImage) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => appState.setBillImagePath(null),
              icon: const Icon(Icons.delete_outline),
              label: Text(context.t('Remove photo')),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
              icon: const Icon(Icons.payments),
              label: Text(context.t('Continue to checkout')),
            ),
          ],
        ],
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
            color: _customerPrimary.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.82),
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
                    color: Colors.white.withOpacity(0.8),
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
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
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
          Text(value, style: style),
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

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

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
              const _CustomerSectionHeader(
                title: 'Recent orders',
                subtitle: 'Track progress and review previous baskets',
              ),
              for (var index = 0; index < orders.length; index++) ...[
                _FadeSlideIn(
                  index: index,
                  child: OrderTile(order: orders[index]),
                ),
                if (index != orders.length - 1) const SizedBox(height: 12),
              ],
            ],
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
              color: color.withOpacity(0.1),
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
    return _CustomerScaffold(
      title: 'Order tracking',
      body: StreamBuilder<OrderModel?>(
        stream: appState.firestoreService.watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton(itemCount: 3);
          }
          final order = snapshot.data;
          if (order == null) {
            return const RefreshableCenteredContent(
              child: EmptyState(
                icon: Icons.receipt_long,
                title: 'Order not found',
                message: 'This order may have been removed.',
              ),
            );
          }
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
                    _AmountRow('Total', order.totalAmount.money,
                        isStrong: true),
                    _AmountRow(
                      'Payment',
                      '${context.t(order.paymentMethod)} (${context.t(order.paymentStatus)})',
                    ),
                    if (order.adminNotes.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
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
                      ),
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
              if (order.items.isNotEmpty) ...[
                const _CustomerSectionHeader(title: 'Items'),
                for (final item in order.items) _OrderItemRow(item: item),
              ],
              if (order.hasManualList) ...[
                if (order.items.isNotEmpty) const SizedBox(height: 12),
                const _CustomerSectionHeader(title: 'Manual list'),
                _ManualListPreview(text: order.effectiveManualListText),
              ],
              if (order.hasUpload) ...[
                const SizedBox(height: 12),
                const _CustomerSectionHeader(title: 'Uploaded list'),
                const _AttachedListPriceNotice(),
                const SizedBox(height: 10),
                _CustomerCard(
                  padding: EdgeInsets.zero,
                  child: AspectRatio(
                    aspectRatio: 1.4,
                    child: ProductImage(url: order.uploadedImageUrl, radius: 8),
                  ),
                ),
              ],
              if (order.hasPaymentReceipt) ...[
                const SizedBox(height: 12),
                const _CustomerSectionHeader(title: 'Payment receipt'),
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
              ],
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SupportScreen(
                      initialSubject: 'Order ${order.orderId.substring(0, 8)}',
                    ),
                  ),
                ),
                icon: const Icon(Icons.support_agent),
                label: Text(context.t('Contact admin')),
              ),
            ],
          );
        },
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
                  : _customerDanger.withOpacity(0.1),
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
                                    .withOpacity(0.1),
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
        backgroundColor: _customerBackground.withOpacity(0.96),
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
                          color: const Color(0xFF163526).withOpacity(0.06),
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
        imageUrl = await CloudinaryService.uploadImage(File(_imagePath!));
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
    if (profile == null) {
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
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.popUntil((route) => route.isFirst);
                await appState.logout();
              },
              icon: const Icon(Icons.logout),
              label: Text(context.t('Logout')),
            ),
          ],
        ),
      ),
    );
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
            color: _customerPrimary.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
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
                    color: Colors.white.withOpacity(0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t(profile.role),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
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
