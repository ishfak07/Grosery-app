import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/image_upload_service.dart';
import '../../../services/image_picker_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/language_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/home_backdrop.dart';
import '../../core/utils/bilingual_text.dart';
import '../../core/utils/category_grouping.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/order_cancellation_service.dart';
import '../../services/order_receipt_pdf_service.dart';
import '../../state/app_state.dart';
import '../order_cancellation/order_cancellation_countdown.dart';

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

class _CustomerPageRoute<T> extends PageRouteBuilder<T> {
  _CustomerPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final transition = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.94, end: 1).animate(transition),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.035, 0),
                  end: Offset.zero,
                ).animate(transition),
                child: child,
              ),
            );
          },
        );
}

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
    final pageBody = _CustomerBackdrop(
      child: AppRefreshIndicator(child: body),
    );

    return Scaffold(
      backgroundColor: _customerBackground,
      appBar: AppBar(
        title: Text(context.t(title)),
        actions: actions,
        backgroundColor: _customerBackground.withValues(alpha: 0.96),
        foregroundColor: _customerInk,
        shape: const Border(bottom: BorderSide(color: _customerLine)),
      ),
      body: bottomNavigationBar == null
          ? pageBody
          : Column(
              children: [
                Expanded(child: pageBody),
                bottomNavigationBar!,
              ],
            ),
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
    this.pulse = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;

  /// Keeps beating while there is something waiting behind the button (see
  /// [_CartPulse]) — used by the cart button so a half-finished order is
  /// hard to forget.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, color: _customerInk);
    if (badgeCount > 0) {
      child = Badge.count(count: badgeCount, child: child);
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _CartPulse(
        active: pulse,
        bump: badgeCount,
        child: IconButton.filledTonal(
          tooltip: context.t(tooltip),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _customerInk,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: const BorderSide(color: _customerLine),
          ),
          icon: child,
        ),
      ),
    );
  }
}

/// A repeating "your cart still has something in it" nudge. While [active]
/// is true the child beats twice, rests, then beats again, with a soft ring
/// blooming out of it — a reminder that keeps coming back rather than one
/// that fires once and is missed. [bump] restarts the beat immediately
/// whenever it changes, so a freshly added item, photo list or manual list
/// announces itself right away.
class _CartPulse extends StatefulWidget {
  const _CartPulse({
    required this.child,
    required this.active,
    this.bump = 0,
    this.ringColor = _customerAccent,
    this.ringRadius = 12,
    this.swell = 0.12,
  });

  final Widget child;
  final bool active;
  final int bump;
  final Color ringColor;
  final double ringRadius;

  /// How far past its own size the child swells at the peak of a beat.
  final double swell;

  @override
  State<_CartPulse> createState() => _CartPulseState();
}

class _CartPulseState extends State<_CartPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _CartPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _sync();
    } else if (widget.active && widget.bump != oldWidget.bump) {
      // Something just landed in the cart: start the cycle over so the beat
      // lands with the change instead of waiting out the current rest.
      _controller
        ..stop()
        ..repeat();
    }
  }

  void _sync() {
    if (widget.active) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Two quick beats at the top of each cycle and then a rest — a heartbeat
  /// rather than a constant throb, which reads as a reminder without nagging.
  static double _beat(double t) {
    double curve(double x) => math.sin(x * math.pi);
    if (t < 0.13) {
      return curve(t / 0.13);
    }
    if (t >= 0.17 && t < 0.30) {
      return curve((t - 0.17) / 0.13) * 0.7;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.active || reduceMotion) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final beat = _beat(_controller.value);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (beat > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 1 + beat * 0.55,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.ringRadius + 6),
                        border: Border.all(
                          color: widget.ringColor
                              .withValues(alpha: (1 - beat) * 0.55),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Transform.scale(
              scale: 1 + beat * widget.swell,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// The floating "your cart has items" reminder that rides above the page
/// once the header cart button has scrolled out of sight. Hidden entirely
/// while the cart is empty, so an empty cart leaves the screen as it was.
class _CartReminderBar extends StatelessWidget {
  const _CartReminderBar({
    required this.visible,
    this.bottomInset = 0,
  });

  final bool visible;
  final double bottomInset;

  /// What the reminder says is waiting — products first, then the photo and
  /// manual drafts, which count as a cart even with no products in it.
  static String _summary(BuildContext context, AppState appState) {
    final items = appState.cartCount;
    if (items > 0) {
      return items == 1
          ? context.t('1 item in your cart')
          : context.t('{count} items in your cart', values: {'count': items});
    }
    if (appState.hasBillImage) {
      return context.t('Photo list ready in your cart');
    }
    return context.t('Manual list ready in your cart');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final show = visible && appState.hasCartDraft;
    return IgnorePointer(
      ignoring: !show,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: show ? Offset.zero : const Offset(0, 0.6),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: show ? 1 : 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _CartPulse(
                  active: show,
                  bump: appState.cartBadgeCount,
                  ringRadius: 14,
                  swell: 0.03,
                  child: Material(
                    color: _customerPrimary,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    elevation: 10,
                    shadowColor:
                        const Color(0xFF10231A).withValues(alpha: 0.38),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        _CustomerPageRoute(builder: (_) => const CartScreen()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Badge.count(
                              count: appState.cartBadgeCount,
                              backgroundColor: _customerAccent,
                              child: const Icon(
                                Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _summary(context, appState),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.t('Tap to review and order'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.82),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 22,
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

/// A small category heading shown above a group of items belonging to the
/// same admin-created category (shop), used wherever cart/checkout items are
/// grouped by category. [shopName] is admin-entered data, not a translatable
/// UI string, so it is rendered as-is (matching how shop names are shown
/// elsewhere in this file, e.g. [_ShopCard]).
class _CategorySectionLabel extends StatelessWidget {
  const _CategorySectionLabel(
      {required this.shopName, required this.itemCount});

  final String shopName;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _customerPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              shopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _customerInk,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '$itemCount ${context.t(itemCount == 1 ? 'item' : 'items')}',
            style: const TextStyle(
              color: _customerMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "Category: X" caption shown under the Photo List / Manual List
/// preview when that submission was tagged with a category (see
/// [AppState.photoListShopName]/[AppState.manualListShopName]).
class _CategoryCaption extends StatelessWidget {
  const _CategoryCaption({required this.shopName});

  final String shopName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '${context.t('Category')}: $shopName',
        style: const TextStyle(
          color: _customerMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
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

const _homeMethodIcons = <String, IconData>{
  OrderCategoryMethod.methodItems: Icons.shopping_bag_outlined,
  OrderCategoryMethod.methodPhoto: Icons.document_scanner_outlined,
  OrderCategoryMethod.methodManual: Icons.edit_note,
};

const _homeMethodTitles = <String, String>{
  OrderCategoryMethod.methodItems: 'Items',
  OrderCategoryMethod.methodPhoto: 'Photo list',
  OrderCategoryMethod.methodManual: 'Manual list',
};

const _homeMethodSubtitles = <String, String>{
  OrderCategoryMethod.methodItems: 'Pick the items you need.',
  OrderCategoryMethod.methodPhoto: 'Send list photo',
  OrderCategoryMethod.methodManual: 'Type your shopping list',
};

const _homeMethodAccents = <String, Color>{
  OrderCategoryMethod.methodItems: _customerPrimary,
  OrderCategoryMethod.methodPhoto: _customerBlue,
  OrderCategoryMethod.methodManual: _customerAccent,
};

/// How long the home page takes to settle when the selected category changes
/// which sections apply.
const Duration _homeSectionMotion = Duration(milliseconds: 280);

/// Collapses a home section to nothing instead of ripping it out of the tree.
/// The section slides up under a clip while it fades, so switching from a
/// full-service category to a photo-only one (a pharmacy) reads as one smooth
/// movement rather than the page snapping to a new height.
///
/// The child stays built for the length of the animation and is dropped once
/// the section is fully closed, so hidden sections cost nothing.
class _HomeCollapsible extends StatelessWidget {
  const _HomeCollapsible({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visible ? 1 : 0),
      duration: _homeSectionMotion,
      curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
      child: child,
      builder: (context, t, child) {
        if (t == 0) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t,
            child: Opacity(
              // Fade a little ahead of the collapse so the content is gone
              // before the last sliver of height closes.
              opacity: Curves.easeOut.transform(t),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  /// True once the header — and with it the header's cart button — has
  /// scrolled away, which is when the floating reminder takes over.
  var _headerGone = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final gone = notification.metrics.pixels > 150;
    if (gone != _headerGone) {
      setState(() => _headerGone = gone);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    if (profile == null) {
      return const _CustomerLogoutTransition();
    }
    final selectedCategory = appState.liveSelectedHomeCategory;
    // A category the admin limited (a pharmacy set to photo/manual only, say)
    // must not surface the methods it disallows anywhere on Home, not just on
    // the method-selection screen.
    final allowedMethods =
        selectedCategory?.allowedMethods ?? Shop.allShoppingMethods;
    final allowsItems =
        allowedMethods.contains(OrderCategoryMethod.methodItems);
    final categoryHours =
        selectedCategory?.effectiveHours(appState.shopHoursSettings) ??
            appState.shopHoursSettings;
    final categoryClosed = !categoryHours.isOpenAt(DateTime.now());
    return Scaffold(
      backgroundColor: _customerBackground,
      body: HomeBackdrop(
        child: Stack(
          children: [
            Positioned.fill(
              child: AppRefreshIndicator(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: _CustomerScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 128),
                    safeAreaTop: true,
                    children: [
                      FirebaseSetupBanner(appState: appState),
                      _HomeHeader(
                        profile: profile,
                        cartCount: appState.cartBadgeCount,
                        cartPulse: appState.hasCartDraft,
                      ),
                      // Switching to a photo-only category (a pharmacy, say) removes
                      // the search bar and the fresh picks. Collapsing them instead of
                      // dropping them keeps the page from jumping under the finger.
                      _HomeCollapsible(
                        visible: allowsItems,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 14),
                            _HomeSearchCallout(
                              categoryName: selectedCategory?.shopName,
                              onTap: () {
                                _openShoppingMethod(
                                  context,
                                  passedShop: selectedCategory,
                                  method: OrderCategoryMethod.methodItems,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _HomeOffersCarousel(),
                      const SizedBox(height: 18),
                      const _HomeCategorySelector(),
                      _HomeCollapsible(
                        visible: categoryClosed && selectedCategory != null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 14),
                            _CategoryClosedNotice(hours: categoryHours),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // The tile set changes with the category, so cross-fade the old
                      // layout into the new one and let the height glide between them.
                      AnimatedSize(
                        duration: _homeSectionMotion,
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: _homeSectionMotion,
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              for (final child in previous)
                                Positioned(
                                    left: 0, right: 0, top: 0, child: child),
                              if (current != null) current,
                            ],
                          ),
                          child: _HomeActionGrid(
                            key: ValueKey(allowedMethods.join('|')),
                            actions: [
                              for (final method in allowedMethods)
                                _HomeActionSpec(
                                  icon: _homeMethodIcons[method]!,
                                  title: _homeMethodTitles[method]!,
                                  subtitle: _homeMethodSubtitles[method]!,
                                  accent: _homeMethodAccents[method]!,
                                  featured:
                                      method == OrderCategoryMethod.methodPhoto,
                                  onTap: () => _openShoppingMethod(
                                    context,
                                    passedShop: selectedCategory,
                                    method: method,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      _HomeCollapsible(
                        visible: allowsItems,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            _HomeFreshPicksHeader(
                              onAction: () {
                                _openShoppingMethod(
                                  context,
                                  passedShop: selectedCategory,
                                  method: OrderCategoryMethod.methodItems,
                                );
                              },
                            ),
                            const _RecentProductsGrid(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Once the header's cart button is out of sight the reminder
            // follows the customer down the page, above the nav bar.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CartReminderBar(
                visible: _headerGone,
                bottomInset: 96,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.profile,
    required this.cartCount,
    this.cartPulse = false,
  });

  final UserProfile profile;
  final int cartCount;
  final bool cartPulse;

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
                            _CustomerPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HomeHeaderActionButton(
                          tooltip: 'Cart',
                          icon: Icons.shopping_bag_outlined,
                          badgeCount: cartCount,
                          pulse: cartPulse,
                          onPressed: () => Navigator.of(context).push(
                            _CustomerPageRoute(
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
    this.pulse = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  /// See [_CustomerIconButton.pulse].
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, color: _customerInk, size: 21);
    if (badgeCount > 0) {
      child = Badge.count(count: badgeCount, child: child);
    }
    return Tooltip(
      message: context.t(tooltip),
      child: _CartPulse(
        active: pulse,
        bump: badgeCount,
        ringColor: Colors.white,
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
  const _HomeSearchCallout({required this.onTap, this.categoryName});

  final VoidCallback onTap;
  final String? categoryName;

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
                      (categoryName == null || categoryName!.isEmpty)
                          ? context.t('Search products ')
                          : context.t(
                              'Search {category}',
                              values: {'category': categoryName!},
                            ),
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
                              'Everyday essentials, photo lists, and COD in one smooth order.',
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
                              'We source from trusted partners and keep you updated.',
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
  static const _pageAnimationDuration = Duration(milliseconds: 620);

  final _pageController = PageController();
  Timer? _autoPlayTimer;
  var _activeIndex = 0;
  var _offerCount = 0;
  late final Stream<List<Offer>> _offersStream;

  @override
  void initState() {
    super.initState();
    _offersStream = context.read<AppState>().firestoreService.watchOffers();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Offer>>(
      stream: _offersStream,
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
        final activeIndex = _activeIndex.clamp(0, offers.length - 1);
        return LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxWidth < 380 ? 190.0 : 214.0;
            return Column(
              children: [
                SizedBox(
                  height: height,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (offers.length <= 1) {
                        return false;
                      }
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        _stopAutoPlay();
                      } else if (notification is ScrollEndNotification) {
                        _startAutoPlay();
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: offers.length,
                      onPageChanged: (index) {
                        setState(() => _activeIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            var page = _activeIndex.toDouble();
                            if (_pageController.hasClients &&
                                _pageController.position.haveDimensions) {
                              page = _pageController.page ?? page;
                            }
                            final delta = (page - index).clamp(-1.0, 1.0);
                            final proximity = 1 - delta.abs();
                            final scale = 0.90 + (proximity * 0.10);
                            final opacity = 0.55 + (proximity * 0.45);
                            return Transform.scale(
                              scale: scale,
                              child: Opacity(opacity: opacity, child: child),
                            );
                          },
                          child: _HomeOfferBanner(
                            key: ValueKey(offers[index].offerId),
                            offer: offers[index],
                            onTap: () => Navigator.of(context).push(
                              _CustomerPageRoute(
                                builder: (_) =>
                                    OfferDetailsScreen(offer: offers[index]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (offers.length > 1) ...[
                  const SizedBox(height: 12),
                  _OfferProgressIndicator(
                    count: offers.length,
                    activeIndex: activeIndex,
                    interval: _autoPlayInterval,
                    onDotTap: _showOfferAt,
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
    if (_activeIndex < offerCount || offerCount == 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _activeIndex = 0);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_offerCount <= 1) {
      return;
    }
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || !_pageController.hasClients || _offerCount <= 1) {
        return;
      }
      final next = (_activeIndex + 1) % _offerCount;
      _pageController.animateToPage(
        next,
        duration: _pageAnimationDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _showOfferAt(int index) {
    if (!mounted || _offerCount == 0 || index == _activeIndex) {
      return;
    }
    final boundedIndex = index.clamp(0, _offerCount - 1);
    _stopAutoPlay();
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        boundedIndex,
        duration: _pageAnimationDuration,
        curve: Curves.easeInOutCubic,
      );
    }
    if (_offerCount > 1) {
      _startAutoPlay();
    }
  }
}

/// Instagram-Stories-style segmented progress bar: the active segment fills
/// smoothly over the autoplay interval, past segments stay full, and
/// upcoming ones stay empty — a much clearer, livelier read of carousel
/// progress than static dots.
class _OfferProgressIndicator extends StatefulWidget {
  const _OfferProgressIndicator({
    required this.count,
    required this.activeIndex,
    required this.interval,
    required this.onDotTap,
  });

  final int count;
  final int activeIndex;
  final Duration interval;
  final ValueChanged<int> onDotTap;

  @override
  State<_OfferProgressIndicator> createState() =>
      _OfferProgressIndicatorState();
}

class _OfferProgressIndicatorState extends State<_OfferProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.interval)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant _OfferProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _controller
        ..duration = widget.interval
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < widget.count; index++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onDotTap(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  width: 22,
                  height: 5,
                  color: _customerLine,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final value = index < widget.activeIndex
                          ? 1.0
                          : index > widget.activeIndex
                              ? 0.0
                              : _controller.value;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _customerPrimary.withValues(alpha: 0.85),
                                  _customerPrimary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeOfferBanner extends StatefulWidget {
  const _HomeOfferBanner({
    super.key,
    required this.offer,
    required this.onTap,
  });

  final Offer offer;
  final VoidCallback onTap;

  @override
  State<_HomeOfferBanner> createState() => _HomeOfferBannerState();
}

class _HomeOfferBannerState extends State<_HomeOfferBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurnsController;

  @override
  void initState() {
    super.initState();
    _kenBurnsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _kenBurnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final titleEnglish = offer.title.trim();
    final titleTamil = offer.tamilTitle.trim();
    final captionEnglish = offer.caption.trim();
    final captionTamil = offer.tamilCaption.trim();
    final hasTitle = titleEnglish.isNotEmpty || titleTamil.isNotEmpty;
    final hasCaption = captionEnglish.isNotEmpty || captionTamil.isNotEmpty;
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
            onTap: widget.onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _kenBurnsController,
                  builder: (context, child) => Transform.scale(
                    scale: 1 + (_kenBurnsController.value * 0.035),
                    child: child,
                  ),
                  child: ProductImage(url: offer.imageUrl, radius: 8),
                ),
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
                            offer.badgeTag.isNotEmpty
                                ? offer.badgeTag
                                : context.t('New offer'),
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
                      if (hasTitle)
                        BilingualLines(
                          english: titleEnglish,
                          tamil: titleTamil,
                          maxLinesEach: 1,
                          gap: 1,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                        height: 1.06,
                                      ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      if (hasTitle && hasCaption) const SizedBox(height: 4),
                      if (hasCaption)
                        BilingualLines(
                          english: captionEnglish,
                          tamil: captionTamil,
                          maxLinesEach: 1,
                          gap: 1,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.2,
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
    final titleEnglish = offer.title.trim();
    final titleTamil = offer.tamilTitle.trim();
    final captionEnglish = offer.caption.trim();
    final captionTamil = offer.tamilCaption.trim();
    final hasTitle = titleEnglish.isNotEmpty || titleTamil.isNotEmpty;
    final hasCaption = captionEnglish.isNotEmpty || captionTamil.isNotEmpty;
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
          if (hasTitle)
            BilingualLines(
              english: titleEnglish,
              tamil: titleTamil,
              maxLinesEach: 3,
              gap: 4,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1.12,
                      ) ??
                  const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
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
          if (hasCaption) ...[
            const SizedBox(height: 14),
            BilingualLines(
              english: captionEnglish,
              tamil: captionTamil,
              maxLinesEach: 20,
              overflow: TextOverflow.visible,
              gap: 6,
              style: const TextStyle(
                color: _customerInk,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
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

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  var _index = 0;

  static const _tabs = <Widget>[
    CustomerHomeScreen(),
    OrderHistoryScreen(),
    SupportScreen(),
    ProfileScreen(),
  ];

  void _onSelect(int index) {
    if (index == _index) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(index: _index, children: _tabs),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _CustomerNavBar(
            selectedIndex: _index,
            onSelected: _onSelect,
          ),
        ),
      ],
    );
  }
}

class _CustomerNavBar extends StatelessWidget {
  const _CustomerNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Translucent so the page shows faintly through the frosted bar. Also
  /// used for the ring around the selected item so it matches the bar where
  /// the two overlap.
  static const _barColor = Color(0xB0FFFFFF);

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItemSpec(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: context.t('Home'),
      ),
      _NavBarItemSpec(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: context.t('Orders'),
      ),
      _NavBarItemSpec(
        icon: Icons.support_agent_outlined,
        selectedIcon: Icons.support_agent_rounded,
        label: context.t('Support'),
      ),
      _NavBarItemSpec(
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        label: context.t('Profile'),
      ),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: SizedBox(
        height: 82,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 64,
              // The frosted pill is a separate layer behind the items rather
              // than their parent, because clipping it for the blur would
              // also cut off the selected item's circle where it lifts above
              // the bar.
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: _FrostedNavBarSurface()),
                  Row(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        Expanded(
                          child: _CustomerNavBarItem(
                            data: items[index],
                            selected: index == selectedIndex,
                            barColor: _barColor,
                            onTap: () => onSelected(index),
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
    );
  }
}

/// The translucent, blurred pill behind the nav bar items.
class _FrostedNavBarSurface extends StatelessWidget {
  const _FrostedNavBarSurface();

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(32);
    return DecoratedBox(
      // Shadow sits outside the clip; clipping it would erase it.
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10231A).withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF10231A).withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _CustomerNavBar._barColor,
              borderRadius: shape,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemSpec {
  const _NavBarItemSpec({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _CustomerNavBarItem extends StatelessWidget {
  const _CustomerNavBarItem({
    required this.data,
    required this.selected,
    required this.barColor,
    required this.onTap,
  });

  final _NavBarItemSpec data;
  final bool selected;
  final Color barColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  opacity: selected ? 0 : 1,
                  child: Icon(
                    data.icon,
                    color: _customerMuted,
                    size: 24,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: selected ? 1 : 0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    if (value <= 0.01) {
                      return const SizedBox.shrink();
                    }
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, -16 * value),
                        child: Transform.scale(
                          scale: 0.55 + (0.45 * value),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E8355), _customerPrimary],
                      ),
                      border: Border.all(color: barColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: _customerPrimary.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      data.selectedIcon,
                      color: Colors.white,
                      size: 22,
                    ),
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
                  context.t('New arrivals'),
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
  String? _streamShopId;
  late Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _streamShopId = appState.selectedHomeCategory?.shopId;
    _productsStream =
        appState.firestoreService.watchRecentProducts(shopId: _streamShopId);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentShopId = appState.selectedHomeCategory?.shopId;
    if (currentShopId != _streamShopId) {
      _streamShopId = currentShopId;
      _productsStream =
          appState.firestoreService.watchRecentProducts(shopId: currentShopId);
    }
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DataErrorState(
            message: _friendlyDataError(snapshot.error),
          );
        }
        final products = snapshot.data ?? const <Product>[];
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

const _homeCategoryPalette = <Color>[
  Color(0xFF176B45), // green
  Color(0xFFC0392B), // red
  Color(0xFF1B6FB5), // blue
  Color(0xFFE07A1F), // orange
  Color(0xFF7B3FA0), // purple
  Color(0xFF0F8A80), // teal
  Color(0xFF8A5A2B), // brown
  Color(0xFFC2185B), // pink
];

const _homeCategoryNamedAccents = <String, Color>{
  'grocer': Color(0xFF176B45),
  'meat': Color(0xFFC0392B),
  'fish': Color(0xFFC0392B),
  'pharmac': Color(0xFF1B6FB5),
  'medic': Color(0xFF1B6FB5),
  'vegetab': Color(0xFF4C8B2B),
  'fruit': Color(0xFFE07A1F),
  'bakery': Color(0xFF8A5A2B),
  'dairy': Color(0xFF3F51B5),
  'beverage': Color(0xFF7B3FA0),
  'drink': Color(0xFF7B3FA0),
  'household': Color(0xFF0F8A80),
};

/// Gives every home category chip its own accent colour so the selected chip
/// is easy to tell apart. Falls back to a stable palette slot when the shop
/// name is not one of the known categories.
Color _homeCategoryAccent(String shopName, int index) {
  final name = shopName.toLowerCase();
  for (final entry in _homeCategoryNamedAccents.entries) {
    if (name.contains(entry.key)) {
      return entry.value;
    }
  }
  return _homeCategoryPalette[index % _homeCategoryPalette.length];
}

/// The home category rail. Chips scroll sideways, and a fading edge plus a
/// tappable arrow on the right advertise that there is more to see; both
/// disappear once the rail is scrolled to the end. "View all" opens every
/// category in a sheet so a long list is never hidden behind a swipe.
class _HomeCategorySelector extends StatefulWidget {
  const _HomeCategorySelector();

  @override
  State<_HomeCategorySelector> createState() => _HomeCategorySelectorState();
}

class _HomeCategorySelectorState extends State<_HomeCategorySelector> {
  static const _railHeight = 40.0;
  static const _fadeWidth = 44.0;

  final ScrollController _controller = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  /// Set once the customer has swiped the rail or used either control. The
  /// attention animations exist only to make the hidden categories findable,
  /// so they stop for good the moment that has worked.
  bool _engaged = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEdges);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncEdges)
      ..dispose();
    super.dispose();
  }

  /// Recomputes which edge hints belong on screen. Called on every scroll and
  /// once after each build, so the hints also settle when the category list
  /// arrives from Firestore or the window is resized.
  void _syncEdges() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    const tolerance = 1.0;
    final back = position.pixels > position.minScrollExtent + tolerance;
    final forward = position.pixels < position.maxScrollExtent - tolerance;
    if (back != _canScrollBack || forward != _canScrollForward) {
      setState(() {
        _canScrollBack = back;
        _canScrollForward = forward;
      });
    }
  }

  void _markEngaged() {
    if (_engaged || !mounted) {
      return;
    }
    setState(() => _engaged = true);
  }

  void _scrollForward() {
    _markEngaged();
    if (!_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final target = (position.pixels + position.viewportDimension * 0.8)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openAllCategories(List<Shop> shops) async {
    _markEngaged();
    final appState = context.read<AppState>();
    final picked = await showModalBottomSheet<Shop>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _customerSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AllCategoriesSheet(
        shops: shops,
        selectedShopId: appState.selectedHomeCategory?.shopId,
        hoursSettings: appState.shopHoursSettings,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    appState.setSelectedHomeCategory(picked);
    final index = shops.indexWhere((shop) => shop.shopId == picked.shopId);
    if (index < 0) {
      return;
    }
    // Bring the category the customer just picked into view on the rail.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final position = _controller.position;
      final estimate = index * 110.0;
      _controller.animateTo(
        estimate.clamp(position.minScrollExtent, position.maxScrollExtent),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return StreamBuilder<List<Shop>>(
      stream: appState.firestoreService.watchShops(activeOnly: true),
      builder: (context, snapshot) {
        final shops = snapshot.data ?? const <Shop>[];
        if (shops.isEmpty) {
          return const SizedBox.shrink();
        }
        final selected = appState.selectedHomeCategory;
        if (selected == null) {
          final defaultShop = shops.firstWhere(
            (shop) => shop.shopName.toLowerCase().contains('grocer'),
            orElse: () => shops.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            if (appState.selectedHomeCategory == null) {
              appState.setSelectedHomeCategory(defaultShop);
            }
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdges());
        final overflows = _canScrollBack || _canScrollForward;
        final attract = overflows && !_engaged;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.t('Categories'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _customerInk,
                    ),
                  ),
                ),
                _ViewAllButton(
                  label: context.t('View All'),
                  // Pulses only while categories are still out of sight, and
                  // on its own 2.6s cycle so it never beats in time with the
                  // rail arrow.
                  animate: attract,
                  onTap: () => _openAllCategories(shops),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _railHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NotificationListener<UserScrollNotification>(
                      onNotification: (_) {
                        _markEngaged();
                        return false;
                      },
                      child: ShaderMask(
                        // Fades the chips themselves rather than painting a
                        // coloured veil, so the hint works over the home
                        // backdrop's pattern.
                        shaderCallback: _edgeFadeShader,
                        blendMode: BlendMode.dstIn,
                        child: ListView.separated(
                          controller: _controller,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: EdgeInsets.only(
                            right: _canScrollForward ? _fadeWidth : 0,
                          ),
                          itemCount: shops.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final shop = shops[index];
                            return _HomeCategoryChip(
                              shop: shop,
                              selected: selected?.shopId == shop.shopId,
                              accent: _homeCategoryAccent(shop.shopName, index),
                              closed: !shop
                                  .effectiveHours(appState.shopHoursSettings)
                                  .isOpenAt(DateTime.now()),
                              onTap: () =>
                                  appState.setSelectedHomeCategory(shop),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: !_canScrollForward,
                      child: AnimatedOpacity(
                        opacity: _canScrollForward ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Center(
                          child: _RailArrowButton(
                            icon: Icons.chevron_right,
                            tooltip: context.t('More categories'),
                            onTap: _scrollForward,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Transparent at whichever edge still has chips beyond it.
  Shader _edgeFadeShader(Rect bounds) {
    final width = bounds.width;
    if (width <= 0) {
      return const LinearGradient(colors: [Colors.white, Colors.white])
          .createShader(bounds);
    }
    final fade = (_fadeWidth / width).clamp(0.0, 0.4);
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _canScrollBack ? Colors.transparent : Colors.white,
        Colors.white,
        Colors.white,
        _canScrollForward ? Colors.transparent : Colors.white,
      ],
      stops: [0, fade * 0.6, 1 - fade, 1],
    ).createShader(bounds);
  }
}

/// The "View All" affordance in the category header. It is always a tinted
/// pill, so it reads as a button at rest. While categories are still off
/// screen a gloss band sweeps across it every 2.6s while the pill lifts,
/// deepens and its arrow slides -- a slow cycle deliberately out of step with
/// the rail arrow, so the two read as two separate invitations.
class _ViewAllButton extends StatefulWidget {
  const _ViewAllButton({
    required this.label,
    required this.animate,
    required this.onTap,
  });

  final String label;
  final bool animate;
  final VoidCallback onTap;

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// The sweep runs across the first 45% of the cycle; the rest is a rest
  /// beat, so the button invites rather than flickers.
  static const _sweepEnd = 0.45;

  /// Rises and falls with the sweep and drives the lift, the tint and the
  /// chevron.
  late final Animation<double> _emphasis = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 18,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 27,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(0), weight: 55),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _ViewAllButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      _syncAnimation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    // Customers who asked the platform for less motion get a plain button.
    final allowed = widget.animate &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (allowed) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else if (_controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final emphasis = _emphasis.value;
        // Where the highlight band sits, from just off the left edge to just
        // past the right one.
        final sweep = (_controller.value / _sweepEnd).clamp(0.0, 1.0);
        final showSweep =
            _controller.isAnimating && _controller.value < _sweepEnd;
        return Transform.scale(
          scale: 1 + 0.05 * emphasis,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: Color.lerp(
                _customerPrimary.withValues(alpha: 0.10),
                _customerPrimary.withValues(alpha: 0.20),
                emphasis,
              ),
              border: Border.all(
                color: _customerPrimary.withValues(
                  alpha: 0.22 + 0.38 * emphasis,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: _customerPrimary.withValues(alpha: 0.18 * emphasis),
                  blurRadius: 10 * emphasis,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  child!,
                  if (showSweep)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              // A narrow gloss band travelling left to right.
                              begin: Alignment(-2.2 + 3.6 * sweep, 0),
                              end: Alignment(-1.4 + 3.6 * sweep, 0),
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.75),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.5, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _customerPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 3),
                AnimatedBuilder(
                  animation: _emphasis,
                  builder: (context, icon) => Transform.translate(
                    offset: Offset(3 * _emphasis.value, 0),
                    child: icon,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: _customerPrimary,
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

/// The round chevron sitting on the faded edge of the category rail. It is
/// static: the rail only fades it in while there are chips left to the right,
/// and the "View All" pill carries the animated invitation.
class _RailArrowButton extends StatelessWidget {
  const _RailArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _customerSurface,
        shape: const CircleBorder(side: BorderSide(color: _customerLine)),
        elevation: 1,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, size: 18, color: _customerPrimary),
          ),
        ),
      ),
    );
  }
}

class _HomeCategoryChip extends StatelessWidget {
  const _HomeCategoryChip({
    required this.shop,
    required this.selected,
    required this.accent,
    required this.closed,
    required this.onTap,
  });

  final Shop shop;
  final bool selected;
  final Color accent;
  final bool closed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: closed
          ? Icon(
              Icons.access_time,
              size: 14,
              color: selected ? Colors.white : _customerDanger,
            )
          : null,
      label: Text(shop.shopName),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _customerInk,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      selectedColor: accent,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? accent : _customerLine,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

/// Every category in one scrollable sheet, so nothing depends on noticing the
/// rail can be swiped.
class _AllCategoriesSheet extends StatelessWidget {
  const _AllCategoriesSheet({
    required this.shops,
    required this.selectedShopId,
    required this.hoursSettings,
  });

  final List<Shop> shops;
  final String? selectedShopId;
  final ShopHoursSettings hoursSettings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _customerLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('All categories'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _customerInk,
                      ),
                    ),
                  ),
                  Text(
                    '${shops.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _customerMuted,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: shops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  final accent = _homeCategoryAccent(shop.shopName, index);
                  final isSelected = shop.shopId == selectedShopId;
                  final closed =
                      !shop.effectiveHours(hoursSettings).isOpenAt(now);
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? accent : Colors.transparent,
                      ),
                    ),
                    tileColor: isSelected
                        ? accent.withValues(alpha: 0.08)
                        : Colors.transparent,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: accent.withValues(alpha: 0.14),
                      child: Icon(
                        Icons.storefront_outlined,
                        size: 17,
                        color: accent,
                      ),
                    ),
                    title: Text(
                      shop.shopName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _customerInk,
                      ),
                    ),
                    subtitle: closed
                        ? Text(
                            context.t('Closed right now'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _customerDanger,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: accent, size: 20)
                        : const Icon(
                            Icons.chevron_right,
                            color: _customerMuted,
                            size: 20,
                          ),
                    onTap: () => Navigator.of(context).pop(shop),
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

class _HomeActionGrid extends StatelessWidget {
  const _HomeActionGrid({super.key, required this.actions});

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
            : 140.0
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
      title: 'Categories',
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
                icon: Icons.category_outlined,
                title: 'No active categories',
                message: 'Products can still be browsed from the full catalog.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    _CustomerPageRoute(
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
                title: 'Choose a category',
                subtitle: 'Browse by item type',
              ),
              for (var index = 0; index < shops.length; index++) ...[
                _FadeSlideIn(
                  index: index,
                  child: _ShopCard(
                    shop: shops[index],
                    onTap: () => Navigator.of(context).push(
                      _CustomerPageRoute(
                        builder: (_) =>
                            CategoryMethodSelectionScreen(shop: shops[index]),
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

class CategoryMethodSelectionScreen extends StatelessWidget {
  const CategoryMethodSelectionScreen({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedMethod = appState.selectedMethodForCategory(shop.shopId);
    final hours = shop.effectiveHours(appState.shopHoursSettings);
    final isOpen = hours.isOpenAt(DateTime.now());
    return _CustomerScaffold(
      title: shop.shopName,
      body: _CustomerScrollView(
        children: [
          _CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.shopName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('Select shopping method'),
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!isOpen) ...[
            const SizedBox(height: 14),
            _CategoryClosedNotice(hours: hours),
          ],
          for (final method in shop.allowedMethods) ...[
            const SizedBox(height: 10),
            _MethodOptionTile(
              icon: _methodIcons[method]!,
              title: _methodTitles[method]!,
              subtitle: _methodSubtitles[method]!,
              method: method,
              groupValue: selectedMethod,
              onTap: () => _openShoppingMethod(
                context,
                passedShop: shop,
                method: method,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _methodIcons = <String, IconData>{
  OrderCategoryMethod.methodItems: Icons.shopping_basket_outlined,
  OrderCategoryMethod.methodPhoto: Icons.document_scanner_outlined,
  OrderCategoryMethod.methodManual: Icons.edit_note,
};

const _methodTitles = <String, String>{
  OrderCategoryMethod.methodItems: 'Select Items',
  OrderCategoryMethod.methodPhoto: 'Photo List',
  OrderCategoryMethod.methodManual: 'Manual List',
};

const _methodSubtitles = <String, String>{
  OrderCategoryMethod.methodItems: 'Choose products from the catalog.',
  OrderCategoryMethod.methodPhoto: 'Upload one list photo for this category.',
  OrderCategoryMethod.methodManual:
      'Type the items and quantities for this category.',
};

/// Banner shown on a category that is closed by its own hours while the rest
/// of the shop is still taking orders.
class _CategoryClosedNotice extends StatelessWidget {
  const _CategoryClosedNotice({required this.hours});

  final ShopHoursSettings hours;

  @override
  Widget build(BuildContext context) {
    final message = hours.isTemporarilyClosed
        ? (hours.temporaryClosureReason.trim().isEmpty
            ? context.t('This category is not accepting orders right now.')
            : hours.temporaryClosureReason.trim())
        : context.t(
            'This category is closed. Please come back at {time}.',
            values: {'time': hours.openingTimeLabel},
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _customerDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _customerDanger.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time, color: _customerDanger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('Closed right now'),
                  style: const TextStyle(
                    color: _customerDanger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _MethodOptionTile extends StatelessWidget {
  const _MethodOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.method,
    required this.groupValue,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String method;
  final String? groupValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == method;
    return _CustomerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? _customerPrimary : _customerMuted,
          ),
          const SizedBox(width: 4),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected ? _customerPrimaryLight : const Color(0xFFF4F8F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? _customerPrimary : _customerLine,
              ),
            ),
            child: Icon(
              icon,
              color: selected ? _customerPrimary : _customerMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(title),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(subtitle),
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

/// The first category in the current draft (cart items, photo lists, manual
/// lists) that is closed right now, or null when everything is orderable.
Shop? _firstClosedDraftCategory(AppState appState) {
  final shopIds = <String>{
    for (final item in appState.cartItems) item.shopId.trim(),
    for (final entry in appState.photoLists) entry.shopId.trim(),
    for (final entry in appState.manualLists) entry.shopId.trim(),
  };
  for (final shopId in shopIds) {
    final category = appState.categoryById(shopId);
    if (category != null && !appState.isCategoryOpenNow(shopId)) {
      return category;
    }
  }
  return null;
}

Future<void> _openShoppingMethod(
  BuildContext context, {
  required Shop? passedShop,
  required String method,
}) async {
  if (passedShop == null) {
    await Navigator.of(context).push(
      _CustomerPageRoute(builder: (_) => const ShopListScreen()),
    );
    return;
  }
  final appState = context.read<AppState>();
  // Prefer the live category record over the caller's snapshot so an admin
  // edit made mid-session is honoured immediately.
  final shop = appState.categoryById(passedShop.shopId) ?? passedShop;
  if (!shop.allowsMethod(method)) {
    showSnack(
      context,
      context.tNow(
        '{category} does not accept {method} orders.',
        values: {
          'category': shop.displayName,
          'method': context.tNow(AppState.shoppingMethodLabel(method)),
        },
      ),
    );
    return;
  }
  final hours = shop.effectiveHours(appState.shopHoursSettings);
  if (!hours.isOpenAt(DateTime.now())) {
    await showShopClosedDialog(context, hours, categoryName: shop.displayName);
    return;
  }
  appState.setSelectedHomeCategory(shop);
  final currentMethod = appState.selectedMethodForCategory(shop.shopId);
  if (currentMethod != null && currentMethod != method) {
    final confirmed = await _confirmChangeShoppingMethod(
      context,
      categoryName: shop.shopName,
      currentMethod: currentMethod,
      newMethod: method,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await appState.changeCategoryMethod(shopId: shop.shopId, method: method);
  }
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    _CustomerPageRoute(
      builder: (_) {
        switch (method) {
          case OrderCategoryMethod.methodPhoto:
            return const UploadBillScreen();
          case OrderCategoryMethod.methodManual:
            return const ManualListScreen();
          default:
            return ProductListScreen(shop: shop);
        }
      },
    ),
  );
}

Future<bool> _confirmChangeShoppingMethod(
  BuildContext context, {
  required String categoryName,
  required String currentMethod,
  required String newMethod,
}) async {
  showSnack(
    context,
    '$categoryName category already uses ${AppState.shoppingMethodLabel(currentMethod)}. Change the shopping method to continue.',
  );
  return showAppConfirmDialog(
    context,
    title: context.tNow('Change shopping method?'),
    message: context.tNow(
      'Changing this category to {method} will remove its current data.',
      values: {'method': AppState.shoppingMethodLabel(newMethod)},
    ),
    confirmLabel: context.tNow('Change'),
    icon: Icons.swap_horiz_rounded,
    confirmIcon: Icons.swap_horiz,
  );
}

Future<bool> _addProductWithMethodGuard(
  BuildContext context,
  AppState appState,
  Product product,
) async {
  try {
    await appState.addToCart(product);
    return true;
  } on CategoryMethodNotAllowedException catch (error) {
    if (context.mounted) {
      showSnack(
        context,
        context.tNow(
          '{category} does not accept {method} orders.',
          values: {
            'category': error.categoryName,
            'method': context.tNow(error.methodLabel),
          },
        ),
      );
    }
    return false;
  } on CategoryMethodConflictException catch (error) {
    if (!context.mounted) {
      return false;
    }
    final confirmed = await _confirmChangeShoppingMethod(
      context,
      categoryName: error.categoryName,
      currentMethod: error.currentMethod,
      newMethod: error.requestedMethod,
    );
    if (!confirmed || !context.mounted) {
      return false;
    }
    await appState.changeCategoryMethod(
      shopId: product.shopId,
      method: OrderCategoryMethod.methodItems,
    );
    await appState.addToCart(product);
    return true;
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
    final hours =
        shop.effectiveHours(context.watch<AppState>().shopHoursSettings);
    final isClosed = !hours.isOpenAt(DateTime.now());
    return _CustomerCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isClosed
                  ? _customerDanger.withValues(alpha: 0.10)
                  : _customerPrimaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category_outlined,
              color: isClosed ? _customerDanger : _customerPrimary,
            ),
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
                if (isClosed) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: _customerDanger,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          hours.isTemporarilyClosed
                              ? context.t('Closed right now')
                              : context.t(
                                  'Opens at {time}',
                                  values: {'time': hours.openingTimeLabel},
                                ),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _customerDanger,
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

  /// True once the customer has scrolled into the grid, which is when the
  /// floating cart reminder joins them on the way down.
  var _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final scrolled = notification.metrics.pixels > 120;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
    return false;
  }

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
          badgeCount: appState.cartBadgeCount,
          pulse: appState.hasCartDraft,
          onPressed: () => Navigator.of(context).push(
            _CustomerPageRoute(builder: (_) => const CartScreen()),
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
                    hintText: widget.shop == null
                        ? context.t('Search products')
                        : context.t(
                            'Search {category}',
                            values: {'category': widget.shop!.shopName},
                          ),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const RefreshableCenteredContent(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: _ProductGridSkeleton(),
                            ),
                          );
                        }
                        final query = _search.text.trim().toLowerCase();
                        final products =
                            (snapshot.data ?? const <Product>[]).where(
                          (product) {
                            return query.isEmpty ||
                                product.name.toLowerCase().contains(query) ||
                                product.nameTamil
                                    .toLowerCase()
                                    .contains(query) ||
                                product.shopName.toLowerCase().contains(query);
                          },
                        ).toList();
                        if (products.isEmpty) {
                          return const RefreshableCenteredContent(
                            child: EmptyState(
                              icon: Icons.search_off,
                              title: 'No products found',
                              message:
                                  'Try a different product name or category.',
                            ),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final count = constraints.maxWidth >= 720 ? 3 : 2;
                            return GridView.builder(
                              physics: appRefreshScrollPhysics,
                              // Leave room under the last row for the floating cart
                              // reminder when one is riding above the grid.
                              padding: EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                appState.hasCartDraft ? 96 : 18,
                              ),
                              itemCount: products.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _CartReminderBar(visible: _scrolled),
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
    final nameEnglish = product.name.trim();
    final nameTamil = product.nameTamil.trim();
    return _CustomerCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        _CustomerPageRoute(
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
                if (!product.isAvailable)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _ProductAvailabilityBadge(
                      isAvailable: product.isAvailable,
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
                BilingualLines(
                  english: nameEnglish,
                  tamil: nameTamil,
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
                            final added = await _addProductWithMethodGuard(
                              context,
                              appState,
                              product,
                            );
                            if (context.mounted) {
                              if (added) {
                                showCartConfirmation(context);
                              }
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

class _ProductAvailabilityBadge extends StatelessWidget {
  const _ProductAvailabilityBadge({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final label = context.t(isAvailable ? 'Available' : 'Unavailable');
    final badge = isAvailable ? _availableBadge() : _unavailableBadge(label);
    return Semantics(
      label: label,
      container: true,
      child: Tooltip(
        message: label,
        child: badge,
      ),
    );
  }

  Widget _availableBadge() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: _customerPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.check,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _unavailableBadge(String label) {
    return Container(
      height: 28,
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 14,
            color: _customerWarning,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: _customerWarning,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
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
          Icons.shopping_bag_outlined,
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
                  Icons.shopping_bag_outlined,
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
    // Falls back to the [product] passed in via navigation immediately, but
    // switches to the live catalog doc as soon as it arrives — so a price
    // the admin changes while this screen is open still updates on screen.
    return StreamBuilder<Product?>(
      stream: context
          .read<AppState>()
          .firestoreService
          .watchProduct(product.productId),
      initialData: product,
      builder: (context, snapshot) {
        final liveProduct = snapshot.data ?? product;
        return _ProductDetailsView(product: liveProduct);
      },
    );
  }
}

class _ProductDetailsView extends StatelessWidget {
  const _ProductDetailsView({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final nameEnglish = product.name.trim();
    final nameTamil = product.nameTamil.trim();
    final descriptionEnglish = product.description.trim();
    final descriptionTamil = product.descriptionTamil.trim();
    return _CustomerScaffold(
      title: BilingualText.label(nameEnglish, nameTamil),
      body: _CustomerScrollView(
        children: [
          _CustomerCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductAvailabilityBanner(
                  isAvailable: product.isAvailable,
                ),
                AspectRatio(
                  aspectRatio: 1.05,
                  child: ProductImage(url: product.imageUrl, radius: 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CustomerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BilingualLines(
                  english: nameEnglish,
                  tamil: nameTamil,
                  maxLinesEach: 2,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: _customerInk,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ) ??
                      const TextStyle(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                      ),
                  gap: 4,
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
                if (descriptionEnglish.isEmpty && descriptionTamil.isEmpty)
                  Text(
                    context.t(
                      'No description added yet. You can still add it to your cart and confirm details at checkout.',
                    ),
                    style: const TextStyle(
                      color: _customerMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  )
                else
                  BilingualLines(
                    english: descriptionEnglish,
                    tamil: descriptionTamil,
                    maxLinesEach: 20,
                    overflow: TextOverflow.visible,
                    gap: 6,
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
                  final appState = context.read<AppState>();
                  final added = await _addProductWithMethodGuard(
                    context,
                    appState,
                    product,
                  );
                  if (context.mounted) {
                    if (added) {
                      showCartConfirmation(context);
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }
}

class _ProductAvailabilityBanner extends StatelessWidget {
  const _ProductAvailabilityBanner({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? _customerPrimary : _customerWarning;
    final label = context.t(isAvailable ? 'Available' : 'Unavailable');
    return Semantics(
      label: label,
      container: true,
      child: Tooltip(
        message: label,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                isAvailable ? _customerPrimaryLight : const Color(0xFFFFF4E0),
            border: Border(
              bottom: BorderSide(
                color: color.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAvailable
                      ? Icons.check_rounded
                      : Icons.inventory_2_outlined,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
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

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = appState.cartItems;
    final cartGroups = items.groupByShop();
    final hasCheckoutDraft =
        items.isNotEmpty || appState.hasBillImage || appState.hasManualList;
    final canCheckout = hasCheckoutDraft && appState.meetsMinimumOrderValue;
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
                    _CustomerPageRoute(
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
                if (!appState.meetsMinimumOrderValue) ...[
                  const SizedBox(height: 12),
                  _MinimumOrderWarningCard(
                    subtotal: appState.cartSubtotal,
                    remainingAmount: appState.minimumOrderRemainingAmount,
                  ),
                ],
                const SizedBox(height: 16),
                if (items.isNotEmpty) ...[
                  const _CustomerSectionHeader(
                    title: 'Items in cart',
                    subtitle: 'Adjust quantities before checkout',
                  ),
                  for (var g = 0; g < cartGroups.length; g++) ...[
                    _CategorySectionLabel(
                      shopName: cartGroups[g].shopName,
                      itemCount: cartGroups[g].items.length,
                    ),
                    for (var i = 0; i < cartGroups[g].items.length; i++) ...[
                      _FadeSlideIn(
                        index: cartGroups
                                .take(g)
                                .fold<int>(0, (n, gr) => n + gr.items.length) +
                            i,
                        child: _CartItemTile(item: cartGroups[g].items[i]),
                      ),
                      if (i != cartGroups[g].items.length - 1)
                        const SizedBox(height: 10),
                    ],
                    if (g != cartGroups.length - 1) const SizedBox(height: 14),
                  ],
                ],
                if (appState.hasBillImage) ...[
                  if (items.isNotEmpty) const SizedBox(height: 16),
                  const _CustomerSectionHeader(
                    title: 'Attached lists',
                    subtitle: 'Admin will review these with your order',
                  ),
                  for (final entry
                      in appState.photoLists.sortedByCategory()) ...[
                    if (entry.shopName.isNotEmpty)
                      _CategorySectionLabel(
                          shopName: entry.shopName, itemCount: 1),
                    _BillImagePreview(
                      path: entry.imagePath,
                      onEdit: () => _editDraftList(
                        context,
                        appState,
                        shopId: entry.shopId,
                        shopName: entry.shopName,
                        screen: const UploadBillScreen(),
                      ),
                      onRemove: () => appState.removePhotoList(entry.shopId),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const _AttachedListPriceNotice(),
                ],
                if (appState.hasManualList) ...[
                  if (items.isNotEmpty || appState.hasBillImage)
                    const SizedBox(height: 16),
                  const _CustomerSectionHeader(
                    title: 'Manual lists',
                    subtitle: 'Admin will review these with your order',
                  ),
                  for (final entry
                      in appState.manualLists.sortedByCategory()) ...[
                    if (entry.shopName.isNotEmpty)
                      _CategorySectionLabel(
                          shopName: entry.shopName, itemCount: 1),
                    _ManualListPreview(
                      text: entry.text,
                      onEdit: () => _editDraftList(
                        context,
                        appState,
                        shopId: entry.shopId,
                        shopName: entry.shopName,
                        screen: const ManualListScreen(),
                      ),
                      onRemove: () => appState.removeManualList(entry.shopId),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!appState.hasBillImage) const _AttachedListPriceNotice(),
                ],
                const SizedBox(height: 88),
              ],
            ),
      bottomNavigationBar: _CartActionBar(
        hasCheckoutDraft: hasCheckoutDraft,
        canCheckout: canCheckout,
        hasBillImage: appState.hasBillImage,
        hasManualList: appState.hasManualList,
        onClearCart: () => _confirmClearCheckoutDraft(context),
        onUploadPhoto: () => _openShoppingMethod(
          context,
          passedShop: appState.liveSelectedHomeCategory,
          method: OrderCategoryMethod.methodPhoto,
        ),
        onTypeList: () => _openShoppingMethod(
          context,
          passedShop: appState.liveSelectedHomeCategory,
          method: OrderCategoryMethod.methodManual,
        ),
        onCheckout: () async {
          final state = context.read<AppState>();
          final shopHours = state.shopHoursSettings;
          if (!shopHours.isOpenAt(DateTime.now())) {
            await showShopClosedDialog(context, shopHours);
            return;
          }
          final closedCategory = _firstClosedDraftCategory(state);
          if (closedCategory != null) {
            if (!context.mounted) {
              return;
            }
            await showShopClosedDialog(
              context,
              state.effectiveHoursForCategory(closedCategory.shopId),
              categoryName: closedCategory.displayName,
            );
            return;
          }
          if (!context.mounted) {
            return;
          }
          await Navigator.of(context).push(
            _CustomerPageRoute(builder: (_) => const CheckoutScreen()),
          );
        },
      ),
    );
  }

  Future<void> _confirmClearCheckoutDraft(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.tNow('Clear cart'),
      message: context.tNow(
        'Remove all cart items, attached photo, and manual list?',
      ),
      confirmLabel: context.tNow('Clear'),
      icon: Icons.delete_sweep_outlined,
      confirmIcon: Icons.delete_sweep_outlined,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await context.read<AppState>().clearCheckoutDraft();
    if (context.mounted) {
      showSnack(context, 'Cart cleared.');
    }
  }
}

/// Opens [screen] (Photo List or Manual List) scoped to a specific
/// category, by first selecting that category on Home so the target
/// screen's [AppState.currentPhotoList]/[AppState.currentManualList] reads
/// the right entry — reuses the same selection mechanism the Home category
/// selector already drives, instead of adding new routing.
Future<void> _editDraftList(
  BuildContext context,
  AppState appState, {
  required String shopId,
  required String shopName,
  required Widget screen,
}) {
  appState.setSelectedHomeCategory(
    shopId.isEmpty
        ? null
        : Shop(
            shopId: shopId,
            shopName: shopName,
            address: '',
            phone: '',
            isActive: true,
            createdAt: DateTime.now(),
          ),
  );
  return Navigator.of(context).push(
    _CustomerPageRoute(builder: (_) => screen),
  );
}

class _CartActionBar extends StatelessWidget {
  const _CartActionBar({
    required this.hasCheckoutDraft,
    required this.canCheckout,
    required this.hasBillImage,
    required this.hasManualList,
    required this.onClearCart,
    required this.onUploadPhoto,
    required this.onTypeList,
    required this.onCheckout,
  });

  final bool hasCheckoutDraft;
  final bool canCheckout;
  final bool hasBillImage;
  final bool hasManualList;
  final VoidCallback onClearCart;
  final VoidCallback onUploadPhoto;
  final VoidCallback onTypeList;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _customerSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: _customerLine)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163526).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _CartSecondaryButton(
                    icon: Icons.upload_file_outlined,
                    label: hasBillImage ? 'Change photo' : 'Upload photo',
                    onPressed: onUploadPhoto,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CartSecondaryButton(
                    icon: Icons.edit_note,
                    label: hasManualList ? 'Edit list' : 'Type list',
                    onPressed: onTypeList,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'Checkout',
              icon: Icons.payments,
              onPressed: canCheckout ? onCheckout : null,
            ),
            if (hasCheckoutDraft) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onClearCart,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC0392B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: Text(context.t('Clear cart')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartSecondaryButton extends StatelessWidget {
  const _CartSecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFEFF4EE),
        foregroundColor: _customerInk,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _customerLine),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        context.t(label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
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

class _MinimumOrderWarningCard extends StatelessWidget {
  const _MinimumOrderWarningCard({
    required this.subtotal,
    required this.remainingAmount,
  });

  final double subtotal;
  final double remainingAmount;

  @override
  Widget build(BuildContext context) {
    final progress =
        (subtotal / AppConstants.minimumOrderValue).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD89A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: _customerWarning,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('Minimum Order Value'),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.t(
              'Your order must be at least Rs. {amount} to continue.',
              values: {
                'amount': AppConstants.formatRupees(
                  AppConstants.minimumOrderValue,
                ),
              },
            ),
            style: const TextStyle(
              color: _customerInk,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t(
              'Add Rs. {amount} more to reach the minimum order value.',
              values: {'amount': AppConstants.formatRupees(remainingAmount)},
            ),
            style: const TextStyle(
              color: _customerWarning,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: const AlwaysStoppedAnimation(_customerWarning),
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
    final unitPrice = appState.livePriceFor(item);
    final lineTotal = appState.lineTotalFor(item);
    final isAvailable = appState.isCartItemAvailable(item);
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
                BilingualLines(
                  english: item.name,
                  tamil: item.nameTamil,
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!isAvailable) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.block,
                        size: 13,
                        color: _customerDanger,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.t('No longer available'),
                        style: const TextStyle(
                          color: _customerDanger,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${unitPrice.money} / ${context.t(item.unit)}',
                  style: const TextStyle(
                    color: _customerMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  lineTotal.money,
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
  const _UploadHeaderScene({required this.hasImage, this.categoryName});

  final bool hasImage;
  final String? categoryName;

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
            height: 236,
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
                        (widget.categoryName ?? '').isNotEmpty
                            ? context.t(
                                'Send your {category} list photo',
                                values: {'category': widget.categoryName},
                              )
                            : context.t('Send your list photo'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1.02,
                                  fontSize: 22,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t(
                          'We will read your list, price the items, and update your bill.',
                        ),
                        maxLines: 2,
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
                            'Handwritten, printed, or shopping-list photos are accepted.',
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

class _ImportantOrderNoticeCard extends StatelessWidget {
  const _ImportantOrderNoticeCard({required this.message});

  final String message;

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
          const Icon(Icons.info_outline, color: _customerWarning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('Important Order Notice'),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t(message),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w600,
                    height: 1.32,
                    fontSize: 12.5,
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
    final currentPhoto = appState.currentPhotoList;
    final hasImage = currentPhoto != null;
    final categoryName = appState.selectedHomeCategory?.shopName;

    Future<void> choosePhoto() async {
      final imageFile = await pickImageFromGallery();
      if (imageFile == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      try {
        await appState.setBillImagePath(imageFile.path);
      } on CategoryMethodConflictException catch (error) {
        if (context.mounted) {
          showSnack(context, error.toString());
        }
      }
    }

    Future<void> takePhoto() async {
      final imageFile = await takePhotoFromCamera();
      if (imageFile == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      try {
        await appState.setBillImagePath(imageFile.path);
      } on CategoryMethodConflictException catch (error) {
        if (context.mounted) {
          showSnack(context, error.toString());
        }
      }
    }

    return _CustomerScaffold(
      title: 'Upload list',
      body: _CustomerScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        children: [
          _UploadHeaderScene(
            hasImage: hasImage,
            categoryName: categoryName,
          ),
          if ((categoryName ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _CategoryCaption(shopName: categoryName!),
          ],
          const SizedBox(height: 16),
          _ImportantOrderNoticeCard(
            message: (categoryName ?? '').isNotEmpty
                ? 'Please include multiple $categoryName items in your photo list. Orders containing only one or very few items may be rejected by the admin.'
                : 'Please include multiple items in your photo list. Orders containing only one or very few items may be rejected by the admin.',
          ),
          const SizedBox(height: 16),
          _UploadPhotoStage(
            hasImage: hasImage,
            path: currentPhoto?.imagePath,
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
            child: _UploadInfoPanel(hasImage: hasImage),
          ),
          SizedBox(height: hasImage ? 126 : 74),
        ],
      ),
      bottomNavigationBar: _UploadActionBar(
        hasImage: hasImage,
        onGallery: choosePhoto,
        onCamera: takePhoto,
        onRemove: () => appState.setBillImagePath(null),
        onCheckout: () => Navigator.of(context).push(
          _CustomerPageRoute(
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
    final initialText = _appState.currentManualList?.text ?? '';
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
    final categoryName = _appState.selectedHomeCategory?.shopName;
    return _CustomerScaffold(
      title: 'Manual list',
      body: _CustomerScrollView(
        children: [
          if ((categoryName ?? '').isNotEmpty) ...[
            _CategoryCaption(shopName: categoryName!),
            const SizedBox(height: 8),
          ],
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
                    (categoryName ?? '').isNotEmpty
                        ? context.t(
                            'Type your {category} items with quantities. Admin will review the list and update your final bill.',
                            values: {'category': categoryName},
                          )
                        : context.t(
                            'Type your items with quantities. Admin will review the list and update your final bill.',
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
          const SizedBox(height: 12),
          _ImportantOrderNoticeCard(
            message: (categoryName ?? '').isNotEmpty
                ? 'Please include multiple $categoryName items in your manual list. Orders containing only one or very few items may be rejected by the admin.'
                : 'Please include multiple items in your manual list. Orders containing only one or very few items may be rejected by the admin.',
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
                labelText: (categoryName ?? '').isNotEmpty
                    ? context.t(
                        '{category} list',
                        values: {'category': categoryName},
                      )
                    : context.t('Shopping list'),
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.playlist_add),
                hintText: context.t(
                  'Example:\nItem name - 2 kg\nItem name - 1 packet\nItem name - 6 pieces',
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
      final categoryName = _appState.selectedHomeCategory?.shopName;
      showSnack(
        context,
        (categoryName ?? '').isNotEmpty
            ? 'Type at least one $categoryName item.'
            : 'Type at least one item.',
      );
      return;
    }
    _saveDebounce?.cancel();
    await _persistList();
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      _CustomerPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }
}

class _BillImagePreview extends StatelessWidget {
  const _BillImagePreview({required this.path, this.onEdit, this.onRemove});

  final String path;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

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
          if (onEdit != null || onRemove != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(context.t('Edit')),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  if (onRemove != null)
                    TextButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(context.t('Remove')),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: const Color(0xFFC83A2B),
                      ),
                    ),
                ],
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
    this.onEdit,
    this.onRemove,
  });

  final String text;
  final VoidCallback? onEdit;
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
                  context.t('Typed list'),
                  style: const TextStyle(
                    color: _customerInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: context.t('Edit list'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
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
            if (!appState.meetsMinimumOrderValue) ...[
              const SizedBox(height: 12),
              _MinimumOrderWarningCard(
                subtotal: appState.cartSubtotal,
                remainingAmount: appState.minimumOrderRemainingAmount,
              ),
            ],
            const SizedBox(height: 14),
            _CheckoutOrderReview(
              items: appState.cartItems,
              photoLists: appState.photoLists,
              manualLists: appState.manualLists,
              onEditItems: () => Navigator.of(context).push(
                _CustomerPageRoute(builder: (_) => const CartScreen()),
              ),
              onEditPhotoList: (entry) => _editDraftList(
                context,
                appState,
                shopId: entry.shopId,
                shopName: entry.shopName,
                screen: const UploadBillScreen(),
              ),
              onEditManualList: (entry) => _editDraftList(
                context,
                appState,
                shopId: entry.shopId,
                shopName: entry.shopName,
                screen: const ManualListScreen(),
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
                  RadioGroup<String>(
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paymentMethod = value);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: AppConstants.paymentMethodCod,
                          enabled: paymentSettings.codEnabled,
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
                          enabled: paymentSettings.bankTransferEnabled,
                          title: Text(context.t('Bank transfer')),
                          subtitle: Text(
                            context.t(
                              paymentSettings.bankTransferEnabled
                                  ? 'Place the order now, then upload your receipt after the final bill is updated.'
                                  : 'Temporarily unavailable.',
                            ),
                          ),
                        ),
                      ],
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
              onPressed: _isSubmitting ||
                      !hasPaymentMethods ||
                      !appState.meetsMinimumOrderValue
                  ? null
                  : _submit,
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
    final appState = context.read<AppState>();
    final shopHours = appState.shopHoursSettings;
    if (!shopHours.isOpenAt(DateTime.now())) {
      await _showShopClosedDialog(shopHours);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final paymentMethod =
        appState.paymentSettings.availablePaymentMethodOrNull(_paymentMethod);
    if (paymentMethod == null) {
      showSnack(context, 'Payment methods are temporarily unavailable.');
      return;
    }
    if (paymentMethod != _paymentMethod) {
      setState(() => _paymentMethod = paymentMethod);
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
        _CustomerPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) {
        if (error is CategoryClosedException) {
          await showShopClosedDialog(
            context,
            error.hours,
            categoryName: error.categoryName,
          );
        } else if (error is CategoryMethodNotAllowedException) {
          showSnack(
            context,
            context.tNow(
              '{category} does not accept {method} orders.',
              values: {
                'category': error.categoryName,
                'method': context.tNow(error.methodLabel),
              },
            ),
          );
        } else if (_isShopClosedError(error)) {
          await _showShopClosedDialog(
              context.read<AppState>().shopHoursSettings);
        } else if (error is MinimumOrderNotMetException) {
          showSnack(
            context,
            context.tNow(
              'Add Rs. {amount} more to reach the minimum order value.',
              values: {
                'amount': AppConstants.formatRupees(error.remainingAmount),
              },
            ),
          );
        } else if (error is CartItemsUnavailableException) {
          showSnack(
            context,
            error.unavailableItemNames.length == 1
                ? context.tNow(
                    '{name} is no longer available. Remove it from your '
                    'cart to continue.',
                    values: {'name': error.unavailableItemNames.single},
                  )
                : context.tNow(
                    'These items are no longer available: {names}. Remove '
                    'them from your cart to continue.',
                    values: {
                      'names': error.unavailableItemNames.join(', '),
                    },
                  ),
          );
        } else {
          showSnack(context, error.toString());
        }
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

  bool _isShopClosedError(Object error) {
    final message = error.toString();
    return message.contains('Shop is closed.') ||
        message.contains('Shop is temporarily closed.');
  }

  Future<void> _showShopClosedDialog(ShopHoursSettings settings) {
    return showShopClosedDialog(context, settings);
  }
}

/// Shows the shop-closed dialog (used for both normal daily-hours closure
/// and the admin's manual temporary-closure switch). Reused by the cart
/// screen (blocking the checkout tap) and the checkout screen (blocking
/// order placement).
Future<void> showShopClosedDialog(
  BuildContext context,
  ShopHoursSettings settings, {
  String? categoryName,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Ordering closed',
    barrierColor: Colors.black.withValues(alpha: 0.46),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ShopClosedDialog(
        settings: settings,
        categoryName: categoryName,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _ShopClosedDialog extends StatelessWidget {
  const _ShopClosedDialog({required this.settings, this.categoryName});

  final ShopHoursSettings settings;

  /// Set when only one category is closed (it runs on its own hours), so the
  /// copy names it instead of implying the whole shop is shut.
  final String? categoryName;

  bool get _isCategoryScoped => (categoryName ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF10231A).withValues(alpha: 0.22),
                          blurRadius: 32,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.85, end: 1),
                          duration: const Duration(milliseconds: 520),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF176B45),
                                  Color(0xFFE86F4A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _customerAccent.withValues(alpha: 0.28),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _isCategoryScoped
                              ? categoryName!.trim()
                              : settings.isTemporarilyClosed
                                  ? context.tNow('Shop Temporarily Closed')
                                  : context.tNow('Ordering closed'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _customerInk,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isCategoryScoped
                              ? (settings.isTemporarilyClosed
                                  ? context.tNow(
                                      'This category is not accepting orders right now.',
                                    )
                                  : context.tNow(
                                      'This category is closed. Please come back at {time}.',
                                      values: {
                                        'time': settings.openingTimeLabel,
                                      },
                                    ))
                              : settings.isTemporarilyClosed
                                  ? context.tNow(
                                      'We are currently unable to accept new orders.',
                                    )
                                  : settings.closedMessage.replaceFirst(
                                      'Shop is closed.',
                                      'Ordering is closed.',
                                    ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _customerMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: _customerPrimaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _customerLine),
                          ),
                          child: settings.isTemporarilyClosed
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: _customerPrimary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.tNow('Reason'),
                                          style: const TextStyle(
                                            color: _customerPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      settings.temporaryClosureReason,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _customerPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      context.tNow('Please try again later.'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _customerMuted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.schedule_outlined,
                                      color: _customerPrimary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        settings.rangeLabel,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _customerPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: _customerPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.check),
                            label: Text(
                              settings.isTemporarilyClosed
                                  ? context.tNow('OK')
                                  : context.tNow('Got it'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
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

class _CheckoutOrderReview extends StatelessWidget {
  const _CheckoutOrderReview({
    required this.items,
    required this.photoLists,
    required this.manualLists,
    required this.onEditItems,
    required this.onEditPhotoList,
    required this.onEditManualList,
  });

  final List<CartItem> items;
  final List<DraftPhotoList> photoLists;
  final List<DraftManualList> manualLists;
  final VoidCallback onEditItems;
  final ValueChanged<DraftPhotoList> onEditPhotoList;
  final ValueChanged<DraftManualList> onEditManualList;

  @override
  Widget build(BuildContext context) {
    final hasPhotoList = photoLists.isNotEmpty;
    final hasManualList = manualLists.isNotEmpty;
    final groups = items.groupByShop();
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
            for (var g = 0; g < groups.length; g++) ...[
              _CategorySectionLabel(
                shopName: groups[g].shopName,
                itemCount: groups[g].items.length,
              ),
              for (var i = 0; i < groups[g].items.length; i++) ...[
                _CheckoutItemRow(
                  item: groups[g].items[i],
                ),
                if (i != groups[g].items.length - 1) const Divider(height: 14),
              ],
              if (g != groups.length - 1) const SizedBox(height: 10),
            ],
          ],
          if (hasPhotoList) ...[
            if (items.isNotEmpty) const Divider(height: 22),
            for (final entry in photoLists.sortedByCategory()) ...[
              _CheckoutPhotoListReview(
                imagePath: entry.imagePath,
                onEdit: () => onEditPhotoList(entry),
                shopName: entry.shopName,
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (hasManualList) ...[
            if (items.isNotEmpty || hasPhotoList) const Divider(height: 22),
            for (final entry in manualLists.sortedByCategory()) ...[
              _CheckoutManualListReview(
                text: entry.text,
                onEdit: () => onEditManualList(entry),
                shopName: entry.shopName,
              ),
              const SizedBox(height: 10),
            ],
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
  });

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final unitPrice = appState.livePriceFor(item);
    final lineTotal = appState.lineTotalFor(item);
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
              BilingualLines(
                english: item.name,
                tamil: item.nameTamil,
                maxLinesEach: 2,
                style: const TextStyle(
                  color: _customerInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} x ${unitPrice.money} / ${context.t(item.unit)}',
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
          lineTotal.money,
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
    this.shopName,
  });

  final String imagePath;
  final VoidCallback onEdit;
  final String? shopName;

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
              if ((shopName ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                _CategoryCaption(shopName: shopName!),
              ],
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
    this.shopName,
  });

  final String text;
  final VoidCallback onEdit;
  final String? shopName;

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
        if ((shopName ?? '').isNotEmpty) _CategoryCaption(shopName: shopName!),
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
                'Optional now. You can upload the bank slip or transfer screenshot after the final bill is updated.',
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
                          'Your bank transfer order is pending admin review. Upload the receipt after the final bill is updated.',
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
              _CustomerPageRoute(
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

  // Created once so filter taps (setState) don't resubscribe the stream and
  // flash the loading skeleton over the whole screen.
  late final Stream<List<OrderModel>> _ordersStream;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _ordersStream =
        appState.firestoreService.watchOrdersForUser(appState.profile!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return _CustomerScaffold(
      title: 'Order history',
      body: StreamBuilder<List<OrderModel>>(
        stream: _ordersStream,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
            children: [
              _OrderHistorySummary(
                filter: _selectedFilter,
                orders: orders,
              ),
              const SizedBox(height: 14),
              _OrderHistoryFilterBar(
                selected: _selectedFilter,
                orders: orders,
                onSelected: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                reverseDuration: const Duration(milliseconds: 140),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  fit: StackFit.passthrough,
                  children: [...previous, if (current != null) current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, (1 - animation.value) * 18),
                      child: child,
                    ),
                  ),
                ),
                child: Column(
                  key: ValueKey(_selectedFilter.id),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildOrderList(_selectedFilter.apply(orders)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return [
        const SizedBox(height: 12),
        EmptyState(
          icon: _selectedFilter.emptyIcon,
          title: _selectedFilter.emptyTitle,
          message: _selectedFilter.emptyMessage,
        ),
      ];
    }

    final monthFormat = DateFormat.yMMMM();
    final widgets = <Widget>[];
    String? currentMonth;
    for (var index = 0; index < orders.length; index++) {
      final order = orders[index];
      final month = monthFormat.format(order.createdAt);
      if (month != currentMonth) {
        currentMonth = month;
        widgets.add(_OrderHistoryMonthLabel(label: month));
      } else {
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(RepaintBoundary(child: OrderTile(order: order)));
    }
    return widgets;
  }
}

class _OrderHistoryMonthLabel extends StatelessWidget {
  const _OrderHistoryMonthLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _customerMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(height: 1, thickness: 1, color: _customerLine),
          ),
        ],
      ),
    );
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
    subtitle: 'Orders being prepared, sourced, or delivered.',
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

class _OrderHistorySummary extends StatelessWidget {
  const _OrderHistorySummary({
    required this.filter,
    required this.orders,
  });

  final _OrderHistoryFilter filter;
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final activeCount = _OrderHistoryFilters.active.countIn(orders);
    final deliveredCount = _OrderHistoryFilters.delivered.countIn(orders);
    final spent = orders
        .where((order) => order.orderStatus == 'Delivered')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C8053), _customerPrimary, Color(0xFF0F5134)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _customerPrimary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    filter.icon,
                    key: ValueKey(filter.id),
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Column(
                    key: ValueKey(filter.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t(filter.heading),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t(filter.subtitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _OrderHistoryStat(
                    value: '${orders.length}',
                    label: context.t('Orders'),
                  ),
                  const _OrderHistoryStatDivider(),
                  _OrderHistoryStat(
                    value: '$activeCount',
                    label: context.t('Active'),
                  ),
                  const _OrderHistoryStatDivider(),
                  _OrderHistoryStat(
                    value: '$deliveredCount',
                    label: context.t('Delivered'),
                  ),
                  const _OrderHistoryStatDivider(),
                  _OrderHistoryStat(
                    value: spent.money,
                    label: context.t('Total spent'),
                    flex: 2,
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

class _OrderHistoryStat extends StatelessWidget {
  const _OrderHistoryStat({
    required this.value,
    required this.label,
    this.flex = 1,
  });

  final String value;
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHistoryStatDivider extends StatelessWidget {
  const _OrderHistoryStatDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: 4,
      endIndent: 4,
      color: Colors.white.withValues(alpha: 0.2),
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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _OrderHistoryFilters.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _OrderHistoryFilters.values[index];
          final isSelected = selected.id == filter.id;
          final count = filter.countIn(orders);
          final highlight = !isSelected &&
              filter.id == _OrderHistoryFilters.attention.id &&
              count > 0;
          final iconColor = isSelected
              ? Colors.white
              : highlight
                  ? _customerWarning
                  : _customerMuted;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(filter),
              borderRadius: BorderRadius.circular(21),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                decoration: BoxDecoration(
                  color: isSelected ? _customerInk : _customerSurface,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: isSelected
                        ? _customerInk
                        : highlight
                            ? _customerWarning.withValues(alpha: 0.45)
                            : _customerLine,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(filter.icon, size: 16, color: iconColor),
                    const SizedBox(width: 6),
                    Text(
                      context.t(filter.label),
                      maxLines: 1,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _customerInk,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.18)
                            : highlight
                                ? _customerWarning.withValues(alpha: 0.14)
                                : _customerBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final color = _statusAccent(order.orderStatus);
    final shortId = order.orderId.length <= 8
        ? order.orderId
        : order.orderId.substring(0, 8);
    final reason = _orderTileReason(context, order);

    return _CustomerCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        _CustomerPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: order.orderId),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _orderStatusIcon(order.orderStatus),
                        color: color,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t(
                              'Order {id}',
                              values: {'id': '#$shortId'},
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _customerInk,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: _customerMuted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  DateFormat.MMMd()
                                      .add_jm()
                                      .format(order.createdAt),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _customerMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: StatusChip(status: order.orderStatus),
                      ),
                    ),
                  ],
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: _customerLine,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_basket_outlined,
                      size: 16,
                      color: _customerMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _orderTileSummary(context, order),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _customerMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (order.hasDeliveryReview) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                for (var star = 1; star <= 5; star++)
                                  Icon(
                                    star <= order.deliveryRating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: _customerGold,
                                    size: 14,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.totalAmount.money,
                      maxLines: 1,
                      style: const TextStyle(
                        color: _customerInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _customerMuted,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _orderTileReason(BuildContext context, OrderModel order) {
  switch (order.orderStatus) {
    case 'Rejected':
      return order.rejectionReason.trim();
    case 'Cancelled':
      final code = order.cancellationReason.trim();
      return code.isEmpty ? '' : _cancellationReasonMessage(context, code);
    default:
      return '';
  }
}

String _orderTileSummary(BuildContext context, OrderModel order) {
  final parts = <String>[];
  final itemCount =
      order.items.fold<int>(0, (sum, item) => sum + item.quantity);
  if (itemCount == 1) {
    parts.add(context.t('1 item'));
  } else if (itemCount > 1) {
    parts.add(context.t('{count} items', values: {'count': itemCount}));
  }
  if (order.photoLists.isNotEmpty || order.uploadedImageUrl.isNotEmpty) {
    parts.add(context.t('Photo list'));
  }
  if (order.manualLists.isNotEmpty || order.manualListText.trim().isNotEmpty) {
    parts.add(context.t('Manual list'));
  }
  if (parts.isEmpty) {
    return context.t('Order details');
  }
  return parts.join(' · ');
}

IconData _orderStatusIcon(String status) {
  switch (status) {
    case 'Delivered':
      return Icons.check_circle_outline_rounded;
    case 'Cancelled':
    case 'Rejected':
      return Icons.cancel_outlined;
    case 'Item Unavailable':
      return Icons.remove_shopping_cart_outlined;
    case 'Need Clarification':
      return Icons.help_outline_rounded;
    case 'Bill Updated':
      return Icons.receipt_long_outlined;
    case 'Pending':
      return Icons.hourglass_top_rounded;
    case 'Accepted':
      return Icons.thumb_up_alt_outlined;
    case 'Shopping Started':
      return Icons.shopping_cart_outlined;
    case 'Out for Delivery':
      return Icons.local_shipping_outlined;
    default:
      return Icons.receipt_long_outlined;
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
        if (order.orderStatus == 'Cancelled') {
          return _CustomerScaffold(
            title: 'Order cancelled',
            body: _CancelledOrderCompletionView(order: order),
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
    final shortOrderId = order.orderId.substring(0, 8);
    return _CustomerScrollView(
      children: [
        _TrackingHeroCard(
          orderId: shortOrderId,
          status: order.orderStatus,
          total: order.totalAmount.money,
          payment:
              '${context.t(order.paymentMethod)} (${context.t(order.paymentStatus)})',
        ),
        _CustomerOrderCancellationSection(order: order),
        if (_shouldShowFinalBillBreakdown(order)) ...[
          const SizedBox(height: 16),
          const _CustomerSectionHeader(title: 'Bill details'),
          _OrderBillBreakdown(order: order),
        ],
        if (_shouldShowPaymentReceiptUpload(order)) ...[
          const SizedBox(height: 16),
          _CustomerPaymentReceiptUploadCard(order: order),
        ],
        const SizedBox(height: 16),
        _TrackingSteps(status: order.orderStatus),
        if (order.hasAssignedDeliveryContact) ...[
          const SizedBox(height: 16),
          _CustomerCard(child: _DeliveryContactSummary(order: order)),
        ],
        if (order.adminNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CustomerCard(child: _AdminNoteSummary(order: order)),
        ],
        const SizedBox(height: 16),
        _OrderContentSections(
          order: order,
          showAttachedListPriceNotice: _shouldShowAttachedListPriceNotice(
            order,
          ),
        ),
        const SizedBox(height: 18),
        _OrderSupportButton(order: order),
      ],
    );
  }
}

class _CustomerOrderCancellationSection extends StatefulWidget {
  const _CustomerOrderCancellationSection({required this.order});

  final OrderModel order;

  @override
  State<_CustomerOrderCancellationSection> createState() =>
      _CustomerOrderCancellationSectionState();
}

class _CustomerOrderCancellationSectionState
    extends State<_CustomerOrderCancellationSection> {
  var _isCancelling = false;
  String? _blockingMessage;

  @override
  void didUpdateWidget(covariant _CustomerOrderCancellationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderId != widget.order.orderId ||
        oldWidget.order.orderStatus != widget.order.orderStatus) {
      _blockingMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrderCancellationCountdown(
      order: widget.order,
      builder: (context, snapshot) {
        final blockingMessage = _blockingMessage;
        if (blockingMessage != null) {
          return _CustomerCancellationMessageCard(message: blockingMessage);
        }

        if (snapshot.isActive) {
          return _CustomerCancellationActionCard(
            remaining: snapshot.remaining,
            isCancelling: _isCancelling,
            onCancel: _confirmCancellation,
          );
        }

        final message = OrderCancellationPolicy.customerMessageFor(snapshot);
        if (message == null) {
          return const SizedBox.shrink();
        }
        return _CustomerCancellationMessageCard(message: message);
      },
    );
  }

  Future<void> _confirmCancellation() async {
    if (_isCancelling) {
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.tNow('Cancel order?'),
      message: context.tNow(
        'Are you sure you want to cancel this order? This action cannot be undone.',
      ),
      cancelLabel: context.tNow('Keep order'),
      confirmLabel: context.tNow('Cancel order'),
      icon: Icons.remove_shopping_cart_outlined,
      confirmIcon: Icons.close_rounded,
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final appState = context.read<AppState>();
    setState(() => _isCancelling = true);
    try {
      await appState.orderCancellationService.cancelOrder(widget.order.orderId);
      await appState.firestoreService.refreshOrder(widget.order.orderId);
      if (mounted) {
        showSnack(context, 'Your order has been cancelled successfully.');
      }
    } on OrderCancellationException catch (error) {
      await appState.firestoreService.refreshOrder(widget.order.orderId);
      if (mounted) {
        setState(() => _blockingMessage = error.message);
        showSnack(context, error.message);
      }
    } catch (error) {
      await appState.firestoreService.refreshOrder(widget.order.orderId);
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
}

class _CustomerCancellationActionCard extends StatelessWidget {
  const _CustomerCancellationActionCard({
    required this.remaining,
    required this.isCancelling,
    required this.onCancel,
  });

  final Duration remaining;
  final bool isCancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final formatted = OrderCancellationPolicy.formatRemaining(remaining);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _CustomerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _customerWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: _customerWarning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('Customer cancellation available for:'),
                        style: const TextStyle(
                          color: _customerInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatted,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: _customerWarning,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'Cancel order',
              icon: Icons.cancel_outlined,
              isLoading: isCancelling,
              onPressed: isCancelling ? null : onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCancellationMessageCard extends StatelessWidget {
  const _CustomerCancellationMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _CustomerCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _customerPrimaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: _customerPrimary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.t(message),
                style: const TextStyle(
                  color: _customerInk,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
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
        _DeliveredSuccessHero(order: order),
        const SizedBox(height: 16),
        _TrackingSteps(status: order.orderStatus),
        const SizedBox(height: 16),
        const _CustomerSectionHeader(
          title: 'Amount details',
          subtitle: 'Final bill summary',
        ),
        _DeliveredBillBreakdown(order: order),
        if (_shouldShowPaymentReceiptUpload(order)) ...[
          const SizedBox(height: 12),
          _CustomerPaymentReceiptUploadCard(order: order),
        ],
        const SizedBox(height: 12),
        _DeliveredOrderSnapshot(order: order),
        if (order.hasAssignedDeliveryContact) ...[
          const SizedBox(height: 12),
          _DeliveredInfoPanel(
            child: _DeliveryContactSummary(order: order),
          ),
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
        _OrderReceiptDownloadButton(order: order),
        const SizedBox(height: 10),
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

class _OrderReceiptDownloadButton extends StatefulWidget {
  const _OrderReceiptDownloadButton({required this.order});

  final OrderModel order;

  @override
  State<_OrderReceiptDownloadButton> createState() =>
      _OrderReceiptDownloadButtonState();
}

class _OrderReceiptDownloadButtonState
    extends State<_OrderReceiptDownloadButton> {
  Future<Uint8List>? _pdfFuture;
  var _isDownloading = false;

  Future<Uint8List> _pdfBytes() {
    return _pdfFuture ??= OrderReceiptPdfService.build(widget.order);
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _pdfBytes();
      await Printing.layoutPdf(
        name: OrderReceiptPdfService.fileName(widget.order),
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      _pdfFuture = null;
      if (mounted) {
        showSnack(context, 'Could not create the receipt. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isDownloading ? null : _download,
      icon: _isDownloading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.receipt_long_outlined),
      label: Text(context.t('Download receipt')),
    );
  }
}

class _DeliveredSuccessHero extends StatelessWidget {
  const _DeliveredSuccessHero({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2B21),
                Color(0xFF176B45),
                Color(0xFF2E6F9E),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            child: Column(
              children: [
                const _DeliveredCheckMark(),
                const SizedBox(height: 18),
                Text(
                  context.t('Thank you for your order!'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.t(
                    'Your order has been delivered successfully. We hope everything reached you safely.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w700,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _DeliveredHeroMetric(
                        icon: Icons.receipt_long_outlined,
                        label: 'Order',
                        value: '#${order.orderId.substring(0, 8)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DeliveredHeroMetric(
                        icon: Icons.payments_outlined,
                        label: 'Paid',
                        value: order.totalAmount.money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DeliveredStatusBanner(status: order.orderStatus),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveredCheckMark extends StatefulWidget {
  const _DeliveredCheckMark();

  @override
  State<_DeliveredCheckMark> createState() => _DeliveredCheckMarkState();
}

class _DeliveredCheckMarkState extends State<_DeliveredCheckMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
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
        final value = Curves.easeOutBack.transform(_controller.value);
        return Transform.scale(
          scale: 0.72 + value * 0.28,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _customerPrimary,
                  size: 40,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeliveredHeroMetric extends StatelessWidget {
  const _DeliveredHeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(label),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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

class _DeliveredStatusBanner extends StatelessWidget {
  const _DeliveredStatusBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: _customerGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _customerGold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveredBillBreakdown extends StatelessWidget {
  const _DeliveredBillBreakdown({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DeliveredMoneyRow(
            icon: Icons.shopping_basket_outlined,
            label: 'Cart items',
            value: order.cartItemsAmount.money,
          ),
          _DeliveredMoneyRow(
            icon: Icons.photo_camera_outlined,
            label: 'Photo list items',
            value: order.photoListAmount.money,
          ),
          _DeliveredMoneyRow(
            icon: Icons.edit_note_outlined,
            label: 'Manual list items',
            value: order.manualListAmount.money,
          ),
          const Divider(height: 24),
          _DeliveredMoneyRow(
            icon: Icons.receipt_outlined,
            label: 'Order subtotal',
            value: order.subtotal.money,
          ),
          _DeliveredMoneyRow(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery charge',
            value: order.deliveryCharge.money,
          ),
          _DeliveredMoneyRow(
            icon: Icons.design_services_outlined,
            label: 'Service charge',
            value: order.serviceCharge.money,
          ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _customerPrimaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _customerPrimary.withValues(alpha: 0.16),
              ),
            ),
            child: _DeliveredMoneyRow(
              icon: Icons.task_alt_rounded,
              label: 'Grand total',
              value: order.totalAmount.money,
              isStrong: true,
              bottomPadding: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveredMoneyRow extends StatelessWidget {
  const _DeliveredMoneyRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isStrong = false,
    this.bottomPadding = 10,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isStrong;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isStrong
                  ? _customerPrimary.withValues(alpha: 0.12)
                  : _customerBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _customerLine),
            ),
            child: Icon(
              icon,
              color: isStrong ? _customerPrimary : _customerMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.t(label),
              style: TextStyle(
                color: _customerInk,
                fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isStrong ? _customerPrimary : _customerInk,
              fontSize: isStrong ? 17 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveredOrderSnapshot extends StatelessWidget {
  const _DeliveredOrderSnapshot({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _customerBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _customerBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('Order summary'),
                      style: const TextStyle(
                        color: _customerInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${order.orderId.substring(0, 8)}',
                      style: const TextStyle(
                        color: _customerMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(status: order.orderStatus),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DeliveredSnapshotTile(
                  label: 'Payment',
                  value:
                      '${context.t(order.paymentMethod)} (${context.t(order.paymentStatus)})',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DeliveredSnapshotTile(
                  label: 'Total',
                  value: order.totalAmount.money,
                  isStrong: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveredSnapshotTile extends StatelessWidget {
  const _DeliveredSnapshotTile({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  final String label;
  final String value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStrong ? _customerPrimaryLight : _customerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _customerLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t(label),
            style: const TextStyle(
              color: _customerMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isStrong ? _customerPrimary : _customerInk,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveredInfoPanel extends StatelessWidget {
  const _DeliveredInfoPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _customerAccent.withValues(alpha: 0.55),
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: child,
        ),
      ),
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

/// Maps a stored `order.cancellationReason` code (an internal identifier,
/// never meant for display) to customer-facing text (F14 fix). Only
/// `'customer_cancelled_within_window'` is ever written today — everything
/// else (including a future admin-initiated reason, or any value this
/// screen doesn't recognize) safely falls back to a generic message rather
/// than leaking the raw internal code into the UI.
String _cancellationReasonMessage(BuildContext context, String reasonCode) {
  switch (reasonCode) {
    case 'customer_cancelled_within_window':
      return context.t('Cancelled by customer within the order window.');
    default:
      return context.t('This order was cancelled.');
  }
}

class _CancelledOrderCompletionView extends StatelessWidget {
  const _CancelledOrderCompletionView({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _CustomerScrollView(
      children: [
        _OrderTerminalHero(
          icon: Icons.cancel_outlined,
          color: _customerDanger,
          status: order.orderStatus,
          title: 'Your order has been cancelled',
          message: 'This order is no longer active.',
        ),
        const SizedBox(height: 12),
        _OrderSummaryCard(order: order),
        if (order.cancellationReason.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CustomerCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: _customerDanger,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _cancellationReasonMessage(
                        context, order.cancellationReason),
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
      final groups = order.items.groupByShop();
      for (var g = 0; g < groups.length; g++) {
        children.add(
          _CategorySectionLabel(
            shopName: groups[g].shopName,
            itemCount: groups[g].items.length,
          ),
        );
        for (var i = 0; i < groups[g].items.length; i++) {
          children.add(_OrderItemRow(item: groups[g].items[i]));
          if (i != groups[g].items.length - 1) {
            children.add(const SizedBox(height: 8));
          }
        }
        if (g != groups.length - 1) {
          children.add(const SizedBox(height: 10));
        }
      }
    }

    if (order.hasManualList) {
      addSectionGap();
      children.add(const _CustomerSectionHeader(title: 'Manual lists'));
      for (final list in order.manualLists.sortedByCategory()) {
        if (list.shopName.isNotEmpty) {
          children.add(
            _CategorySectionLabel(shopName: list.shopName, itemCount: 1),
          );
        }
        children.add(_ManualListPreview(text: list.text));
        children.add(const SizedBox(height: 10));
      }
    }

    if (order.hasUpload) {
      addSectionGap();
      children.add(const _CustomerSectionHeader(title: 'Uploaded lists'));
      if (showAttachedListPriceNotice) {
        children.add(const _AttachedListPriceNotice());
        children.add(const SizedBox(height: 10));
      }
      for (final list in order.photoLists.sortedByCategory()) {
        if (list.shopName.isNotEmpty) {
          children.add(
            _CategorySectionLabel(shopName: list.shopName, itemCount: 1),
          );
        }
        children.add(
          _CustomerCard(
            padding: EdgeInsets.zero,
            child: AspectRatio(
              aspectRatio: 1.4,
              child: ProductImage(url: list.imageUrl, radius: 8),
            ),
          ),
        );
        children.add(const SizedBox(height: 10));
      }
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

class _CustomerPaymentReceiptUploadCard extends StatefulWidget {
  const _CustomerPaymentReceiptUploadCard({required this.order});

  final OrderModel order;

  @override
  State<_CustomerPaymentReceiptUploadCard> createState() =>
      _CustomerPaymentReceiptUploadCardState();
}

class _CustomerPaymentReceiptUploadCardState
    extends State<_CustomerPaymentReceiptUploadCard> {
  String? _receiptImagePath;
  var _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return _CustomerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.receipt_long_outlined, color: _customerAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('Upload payment receipt'),
                      style: const TextStyle(
                        color: _customerInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t(
                        'Attach your bank slip or transfer screenshot for the final bill.',
                      ),
                      style: const TextStyle(
                        color: _customerMuted,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReceiptUploadSection(
            imagePath: _receiptImagePath,
            onGallery: _pickReceiptFromGallery,
            onCamera: _takeReceiptPhoto,
            onRemove: _isUploading
                ? () {}
                : () => setState(() => _receiptImagePath = null),
          ),
          const SizedBox(height: 12),
          PrimaryActionButton(
            label: 'Submit receipt',
            icon: Icons.cloud_upload_outlined,
            isLoading: _isUploading,
            onPressed: _isUploading || _receiptImagePath == null
                ? null
                : _submitReceipt,
          ),
        ],
      ),
    );
  }

  Future<void> _pickReceiptFromGallery() async {
    if (_isUploading) {
      return;
    }
    final imageFile = await pickImageFromGallery();
    if (imageFile == null || !mounted) {
      return;
    }
    setState(() => _receiptImagePath = imageFile.path);
  }

  Future<void> _takeReceiptPhoto() async {
    if (_isUploading) {
      return;
    }
    final imageFile = await takePhotoFromCamera();
    if (imageFile == null || !mounted) {
      return;
    }
    setState(() => _receiptImagePath = imageFile.path);
  }

  Future<void> _submitReceipt() async {
    if (_isUploading) {
      return;
    }
    final imagePath = _receiptImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      showSnack(context, 'Select the bank transfer receipt first.');
      return;
    }
    setState(() => _isUploading = true);
    try {
      await context.read<AppState>().uploadOrderPaymentReceipt(
            order: widget.order,
            imagePath: imagePath,
          );
      if (mounted) {
        setState(() => _receiptImagePath = null);
        showSnack(context, 'Payment receipt uploaded.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _OrderSupportButton extends StatelessWidget {
  const _OrderSupportButton({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        _CustomerPageRoute(
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

bool _shouldShowPaymentReceiptUpload(OrderModel order) {
  const receiptUploadStatuses = <String>{
    'Bill Updated',
    'Out for Delivery',
    'Delivered',
  };
  return order.paymentMethod == AppConstants.paymentMethodBankTransfer &&
      !order.hasPaymentReceipt &&
      receiptUploadStatuses.contains(order.orderStatus);
}

bool _shouldShowAttachedListPriceNotice(OrderModel order) {
  return order.hasShoppingList && !_shouldShowFinalBillBreakdown(order);
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
                BilingualLines(
                  english: item.name,
                  tamil: item.nameTamil,
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
                if (item.hasPriceChanged) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.t(
                      '{original} → {current} · Price updated',
                      values: {
                        'original': item.originalPrice.money,
                        'current': item.price.money,
                      },
                    ),
                    style: const TextStyle(
                      color: _customerWarning,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
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

class _TrackingHeroCard extends StatelessWidget {
  const _TrackingHeroCard({
    required this.orderId,
    required this.status,
    required this.total,
    required this.payment,
  });

  final String orderId;
  final String status;
  final String total;
  final String payment;

  @override
  Widget build(BuildContext context) {
    final accent = _trackingStatusColor(status);
    const statuses = AppConstants.customerTrackingStatuses;
    final currentIndex = statuses.indexOf(status);
    final effectiveIndex = currentIndex < 0 ? 0 : currentIndex;
    final progress = statuses.length <= 1
        ? 1.0
        : (effectiveIndex / (statuses.length - 1)).clamp(0.0, 1.0);

    return _CustomerCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF123326),
                _customerPrimary,
                accent.withValues(alpha: 0.92),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context
                                    .t('Order {id}', values: {'id': orderId}),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.t('Live order progress'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _TrackingStatusPill(status: status, color: accent),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.22),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _customerGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(value * 100).round()}% ${context.t('complete')}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _TrackingMetric(
                            icon: Icons.payments_outlined,
                            label: 'Total',
                            value: total,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TrackingMetric(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Payment',
                            value: payment,
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
      ),
    );
  }
}

class _TrackingStatusPill extends StatelessWidget {
  const _TrackingStatusPill({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 156),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color == _customerWarning ? _customerGold : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              context.t(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  const _TrackingMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 9),
          Text(
            context.t(label),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.2,
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
    final progress = statuses.length <= 1
        ? 1.0
        : (effectiveIndex / (statuses.length - 1)).clamp(0.0, 1.0);
    return _CustomerCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _trackingStatusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _trackingStatusIcon(status),
                    color: _trackingStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('Tracking status'),
                        style: const TextStyle(
                          color: _customerInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.t(status),
                        style: TextStyle(
                          color: _trackingStatusColor(status),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < statuses.length; i++)
              Builder(
                builder: (context) {
                  final isCurrent = i == effectiveIndex && currentIndex >= 0;
                  final isComplete = isTerminalStatus
                      ? i == 0 || isCurrent
                      : i <= effectiveIndex;
                  return _TrackingStepTile(
                    title: statuses[i],
                    index: i,
                    isLast: i == statuses.length - 1,
                    isCurrent: isCurrent,
                    isComplete: isComplete,
                  );
                },
              ),
          ],
        ),
        builder: (context, value, child) {
          return Stack(
            children: [
              Positioned(
                left: 20,
                top: 76,
                bottom: 33,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _customerLine,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 76,
                bottom: 33,
                child: FractionallySizedBox(
                  heightFactor: value,
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_customerPrimary, _customerGold],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
      ),
    );
  }
}

class _TrackingStepTile extends StatelessWidget {
  const _TrackingStepTile({
    required this.title,
    required this.index,
    required this.isLast,
    required this.isCurrent,
    required this.isComplete,
  });

  final String title;
  final int index;
  final bool isLast;
  final bool isCurrent;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? _trackingStatusColor(title)
        : isComplete
            ? _customerPrimary
            : _customerMuted;
    return _FadeSlideIn(
      index: index,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isComplete
                    ? color.withValues(alpha: 0.13)
                    : _customerBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isComplete
                      ? color.withValues(alpha: 0.28)
                      : _customerLine,
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isComplete
                    ? _trackingStatusIcon(title)
                    : Icons.radio_button_unchecked,
                color: color,
                size: isCurrent ? 23 : 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? color.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent
                        ? color.withValues(alpha: 0.18)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t(title),
                        style: TextStyle(
                          color: isCurrent ? _customerInk : color,
                          fontWeight:
                              isCurrent ? FontWeight.w900 : FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      _TrackingPulseDot(color: color),
                    ] else if (isComplete) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.done, color: color, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingPulseDot extends StatefulWidget {
  const _TrackingPulseDot({required this.color});

  final Color color;

  @override
  State<_TrackingPulseDot> createState() => _TrackingPulseDotState();
}

class _TrackingPulseDotState extends State<_TrackingPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
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
        final value = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 10 + value * 4,
          height: 10 + value * 4,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.28 + value * 0.26),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _trackingStatusColor(String status) {
  switch (status) {
    case 'Cancelled':
    case 'Rejected':
    case 'Item Unavailable':
      return _customerDanger;
    case 'Pending':
    case 'Need Clarification':
    case 'Bill Updated':
      return _customerWarning;
    case 'Accepted':
    case 'Shopping Started':
    case 'Out for Delivery':
      return _customerBlue;
    case 'Delivered':
      return _customerPrimary;
    default:
      return _customerMuted;
  }
}

IconData _trackingStatusIcon(String status) {
  switch (status) {
    case 'Pending':
      return Icons.schedule_rounded;
    case 'Accepted':
      return Icons.verified_outlined;
    case 'Need Clarification':
      return Icons.contact_support_outlined;
    case 'Shopping Started':
      return Icons.shopping_cart_checkout_rounded;
    case 'Bill Updated':
      return Icons.receipt_long_outlined;
    case 'Out for Delivery':
      return Icons.delivery_dining_rounded;
    case 'Delivered':
      return Icons.check_circle_outline_rounded;
    case 'Rejected':
    case 'Cancelled':
    case 'Item Unavailable':
      return Icons.cancel_outlined;
    default:
      return Icons.radio_button_checked;
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
      actions: appState.isAdmin
          ? const [
              _NotificationsDeleteAllAction(),
            ]
          : null,
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

class _NotificationsDeleteAllAction extends StatelessWidget {
  const _NotificationsDeleteAllAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: () => _confirmDeleteAllNotifications(context),
        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
        label: Text(context.t('Delete All')),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _customerDanger,
          side: const BorderSide(color: _customerLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteAllNotifications(BuildContext context) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: context.tNow('Delete all notifications?'),
    message: context.tNow(
      'This permanently deletes every saved notification from the '
      'database. This action cannot be undone.',
    ),
    confirmLabel: context.tNow('Delete all'),
    icon: Icons.delete_forever_rounded,
    confirmIcon: Icons.delete_forever,
    isDestructive: true,
  );
  if (!confirmed || !context.mounted) {
    return;
  }

  try {
    await context.read<AppState>().authService.clearAdminSectionData(
          section: 'notifications',
        );
    if (!context.mounted) {
      return;
    }
    await context.read<AppState>().refreshVisibleData();
    if (context.mounted) {
      showSnack(context, 'All notifications deleted.');
    }
  } catch (error) {
    if (context.mounted) {
      showSnack(context, error);
    }
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
  late final Stream<List<SupportTicket>> _ticketsStream;

  @override
  void initState() {
    super.initState();
    _subject.text = widget.initialSubject ?? '';
    final appState = context.read<AppState>();
    _ticketsStream =
        appState.firestoreService.watchTickets(userId: appState.profile!.uid);
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CustomerScaffold(
      title: 'Support',
      body: StreamBuilder<List<SupportTicket>>(
        stream: _ticketsStream,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final tickets = snapshot.data ?? const <SupportTicket>[];
          final openCount =
              tickets.where((ticket) => ticket.status != 'closed').length;
          return _CustomerScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
            children: [
              _SupportHero(
                openCount: openCount,
                totalCount: tickets.length,
              ),
              const SizedBox(height: 16),
              _CustomerCard(
                padding: const EdgeInsets.all(16),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: _customerPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.t('New ticket'),
                            style: const TextStyle(
                              color: _customerInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.t('Pick a topic or write your own subject.'),
                      style: const TextStyle(
                        color: _customerMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListenableBuilder(
                      listenable: _subject,
                      builder: (context, _) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final topic in _supportTopics)
                            _SupportTopicChip(
                              topic: topic,
                              isSelected:
                                  _subject.text == context.t(topic.label),
                              onTap: () =>
                                  _subject.text = context.t(topic.label),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _subject,
                      label: 'Subject',
                      prefixIcon: Icons.subject,
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _message,
                      label: 'Message',
                      maxLines: 4,
                      prefixIcon: Icons.chat_bubble_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    PrimaryActionButton(
                      label: 'Create ticket',
                      icon: Icons.send_rounded,
                      isLoading: _isCreating,
                      onPressed: _createTicket,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: _CustomerSectionHeader(
                      title: 'Your tickets',
                      subtitle: 'Continue a previous conversation',
                    ),
                  ),
                  if (tickets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _customerPrimaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${tickets.length}',
                          style: const TextStyle(
                            color: _customerPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isLoading) ...const [
                _ShimmerBox(width: double.infinity, height: 96),
                SizedBox(height: 12),
                _ShimmerBox(width: double.infinity, height: 96),
              ] else if (tickets.isEmpty)
                const EmptyState(
                  icon: Icons.support_agent,
                  title: 'No support tickets',
                  message: 'Create a ticket when you need help with an order.',
                )
              else
                for (var index = 0; index < tickets.length; index++) ...[
                  _FadeSlideIn(
                    index: index,
                    child: _SupportTicketTile(ticket: tickets[index]),
                  ),
                  if (index != tickets.length - 1) const SizedBox(height: 12),
                ],
            ],
          );
        },
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

class _SupportTopic {
  const _SupportTopic(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _supportTopics = <_SupportTopic>[
  _SupportTopic('Order issue', Icons.receipt_long_outlined),
  _SupportTopic('Delivery', Icons.local_shipping_outlined),
  _SupportTopic('Payment', Icons.payments_outlined),
  _SupportTopic('Account', Icons.person_outline_rounded),
];

class _SupportHero extends StatelessWidget {
  const _SupportHero({required this.openCount, required this.totalCount});

  final int openCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C8053), _customerPrimary, Color(0xFF0F5134)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _customerPrimary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: Icon(
              Icons.support_agent_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.t('How can we help?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t(
                  'Send us a message and our team will reply right here.',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              if (totalCount > 0) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SupportHeroPill(
                      icon: Icons.mark_chat_unread_outlined,
                      label: context.t(
                        '{count} open',
                        values: {'count': openCount},
                      ),
                    ),
                    _SupportHeroPill(
                      icon: Icons.forum_outlined,
                      label: context.t(
                        '{count} total',
                        values: {'count': totalCount},
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportHeroPill extends StatelessWidget {
  const _SupportHeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTopicChip extends StatelessWidget {
  const _SupportTopicChip({
    required this.topic,
    required this.isSelected,
    required this.onTap,
  });

  final _SupportTopic topic;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _customerPrimary : _customerBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _customerPrimary : _customerLine,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                topic.icon,
                size: 15,
                color: isSelected ? Colors.white : _customerPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                context.t(topic.label),
                style: TextStyle(
                  color: isSelected ? Colors.white : _customerInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _supportStatusColor(String status) {
  switch (status) {
    case 'open':
      return _customerWarning;
    case 'replied':
      return _customerBlue;
    default:
      return _customerMuted;
  }
}

IconData _supportStatusIcon(String status) {
  switch (status) {
    case 'open':
      return Icons.hourglass_top_rounded;
    case 'replied':
      return Icons.mark_chat_unread_outlined;
    default:
      return Icons.check_circle_outline_rounded;
  }
}

class _SupportTicketTile extends StatelessWidget {
  const _SupportTicketTile({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final color = _supportStatusColor(ticket.status);
    final isClosed = ticket.status == 'closed';
    final preview = ticket.message.trim().replaceAll(RegExp(r'\s+'), ' ');

    return _CustomerCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        _CustomerPageRoute(
          builder: (_) => SupportThreadScreen(ticket: ticket),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _supportStatusIcon(ticket.status),
                        color: color,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ticket.subject,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isClosed
                                        ? _customerMuted
                                        : _customerInk,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      context.t(ticket.status),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (preview.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _customerMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: _customerMuted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  context.t(
                                    'Updated {date}',
                                    values: {
                                      'date': DateFormat.MMMd()
                                          .add_jm()
                                          .format(ticket.updatedAt),
                                    },
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _customerMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _customerMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      var imagePublicId = '';
      if (_imagePath != null) {
        final uploadedImage = await ImageUploadService.uploadUserImage(
          imageFile: File(_imagePath!),
          ownerUid: appState.profile!.uid,
          folder: 'support/${widget.ticket.ticketId}',
          fileName: 'message-${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrl = uploadedImage.secureUrl;
        imagePublicId = uploadedImage.publicId;
      }
      await appState.firestoreService.sendSupportMessage(
        ticket: widget.ticket,
        sender: appState.profile!,
        message:
            _message.text.trim().isEmpty ? 'Image attached' : _message.text,
        imageUrl: imageUrl,
        imagePublicId: imagePublicId,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('Follow us'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.chat_rounded,
                      color: Color(0xFF25D366),
                    ),
                    title: Text(context.t('Join our WhatsApp channel')),
                    subtitle: Text(
                      context.t('Get offers and updates on WhatsApp.'),
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openUrl(AppConstants.whatsappChannelUrl),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.facebook,
                      color: Color(0xFF1877F2),
                    ),
                    title: Text(context.t('Like our Facebook page')),
                    subtitle: Text(
                      context.t('Follow us on Facebook for the latest news.'),
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openUrl(AppConstants.facebookPageUrl),
                  ),
                ],
              ),
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
                    title: Text(context.t('Privacy policy')),
                    subtitle: Text(
                      context.t(
                        'See how account, order, and image data is handled.',
                      ),
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
                    title: Text(
                      context.t('Delete account'),
                      style: const TextStyle(color: _customerDanger),
                    ),
                    subtitle: Text(
                      context.t(
                        'Permanently remove your account and personal data.',
                      ),
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
      title: Text(context.t('Permanently delete account?')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t(
                'Your profile, support messages, notifications, and '
                'uploaded personal images will be removed. Closed order '
                'records are anonymized for accounting. Active orders must '
                'be completed or cancelled first.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: _obscurePassword,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.t('Password'),
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
              title: Text(context.t('I understand this cannot be undone.')),
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
          child: Text(context.t('Keep account')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _customerDanger),
          onPressed: !_confirmed || _password.text.isEmpty
              ? null
              : () => Navigator.of(context).pop(_password.text),
          child: Text(context.t('Delete permanently')),
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
