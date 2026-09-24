import 'dart:math' as math;
import 'dart:ui' show PathMetric;

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
                        'Local shopping, lists, pickup, and COD delivery.',
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

  static const _items = [
    _OnboardingItem(
      art: _OnboardingArt.catalog,
      title: 'Everything you need in one place',
      message:
          'Browse our carefully selected products and enjoy a simple shopping experience.',
      colors: [Color(0xFF0B3B27), Color(0xFF136B43), Color(0xFF2F9E62)],
      glow: Color(0xFF6EE7A0),
    ),
    _OnboardingItem(
      art: _OnboardingArt.list,
      title: 'Upload a shopping list',
      message:
          'Send a handwritten or printed list photo when catalog items are not enough.',
      colors: [Color(0xFF0C2F3F), Color(0xFF155E6E), Color(0xFF1F8A7C)],
      glow: Color(0xFF67E8D5),
    ),
    _OnboardingItem(
      art: _OnboardingArt.delivery,
      title: 'Cash on delivery',
      message:
          'Admin reviews the bill, buys items, delivers, and collects cash.',
      colors: [Color(0xFF1F3A2A), Color(0xFF8C4A22), Color(0xFFE8774F)],
      glow: Color(0xFFFFB38A),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _pagePosition {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return _controller.page ?? _page.toDouble();
    }
    return _page.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final current = _items[_page];
    return Scaffold(
      backgroundColor: _authBackground,
      body: _AuthBackdrop(
        child: Stack(
          children: [
            // Soft page-tinted light that blends between pages while swiping.
            Positioned(
              top: -140,
              right: -120,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final position =
                      _pagePosition.clamp(0.0, _items.length - 1.0);
                  final from = position.floor();
                  final to = math.min(from + 1, _items.length - 1);
                  final color = Color.lerp(
                    _items[from].glow,
                    _items[to].glow,
                    position - from,
                  )!;
                  return _OnboardingGlow(
                    size: 360,
                    color: color,
                    opacity: 0.28,
                  );
                },
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  FirebaseSetupBanner(appState: appState),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        const Expanded(child: _AuthBrandMark()),
                        _OnboardingStepPill(
                          step: _page + 1,
                          total: _items.length,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemCount: _items.length,
                      itemBuilder: (context, index) => _OnboardingPage(
                        item: _items[index],
                        index: index,
                        controller: _controller,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _items.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                width: _page == index ? 30 : 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _page == index
                                      ? current.colors[1]
                                      : _authLine,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          PrimaryActionButton(
                            label: _page == _items.length - 1
                                ? 'Get started'
                                : 'Next',
                            icon: Icons.arrow_forward,
                            onPressed: () async {
                              if (_page == _items.length - 1) {
                                await context
                                    .read<AppState>()
                                    .markOnboardingComplete();
                                return;
                              }
                              await _controller.nextPage(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

class _OnboardingStepPill extends StatelessWidget {
  const _OnboardingStepPill({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _authSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _authLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              step.toString().padLeft(2, '0'),
              key: ValueKey(step),
              style: const TextStyle(
                color: _authInk,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            ' / ${total.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: _authMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.item,
    required this.index,
    required this.controller,
  });

  final _OnboardingItem item;
  final int index;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageHeight = (constraints.maxHeight * 0.56).clamp(220.0, 400.0);
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            var delta = 0.0;
            if (controller.hasClients && controller.position.haveDimensions) {
              delta = ((controller.page ?? index.toDouble()) - index)
                  .clamp(-1.0, 1.0);
            }
            final textOpacity = (1 - delta.abs() * 1.4).clamp(0.0, 1.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: SizedBox(
                        height: stageHeight,
                        width: double.infinity,
                        child: _OnboardingStage(item: item, delta: delta),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: textOpacity,
                      child: Transform.translate(
                        offset: Offset(delta * -60, 0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            children: [
                              Text(
                                context.t(item.title),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _authInk,
                                  fontSize: 26,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.t(item.message),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _authMuted,
                                  fontSize: 15,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 22),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OnboardingStage extends StatelessWidget {
  const _OnboardingStage({required this.item, required this.delta});

  final _OnboardingItem item;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final art = switch (item.art) {
      _OnboardingArt.catalog => _CatalogArt(accent: item.colors[1]),
      _OnboardingArt.list => _ShoppingListArt(accent: item.colors[2]),
      _OnboardingArt.delivery => _DeliveryArt(accent: item.colors[2]),
    };
    return Transform.scale(
      scale: 1 - delta.abs() * 0.06,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: item.colors.last.withValues(alpha: 0.28),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _DotGridPainter()),
            Positioned(
              top: -70,
              right: -50,
              child: _OnboardingGlow(
                size: 220,
                color: item.glow,
                opacity: 0.4,
              ),
            ),
            const Positioned(
              bottom: -90,
              left: -70,
              child: _OnboardingGlow(
                size: 240,
                color: Colors.white,
                opacity: 0.14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              // The art drifts against the swipe for a layered, parallax feel.
              child: Transform.translate(
                offset: Offset(delta * 120, 0),
                child: FittedBox(
                  child: SizedBox(width: 300, height: 260, child: art),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingGlow extends StatelessWidget {
  const _OnboardingGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    const spacing = 18.0;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}

/// Runs one art piece's own endless loop, independent of the other pages,
/// and holds a still frame when the system asks to reduce motion.
abstract class _LoopingArtState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  Duration get loopDuration;

  late final AnimationController loop = AnimationController(
    vsync: this,
    duration: loopDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      loop
        ..stop()
        ..value = 0.6;
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

Widget _artBubble({
  required IconData icon,
  required Color color,
  double size = 46,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Icon(icon, color: color, size: size * 0.48),
  );
}

class _CatalogArt extends StatefulWidget {
  const _CatalogArt({required this.accent});

  final Color accent;

  @override
  State<_CatalogArt> createState() => _CatalogArtState();
}

class _CatalogArtState extends _LoopingArtState<_CatalogArt> {
  static const _center = Offset(150, 130);
  static const _radius = 96.0;
  static const _satellites = [
    (Icons.eco_rounded, Color(0xFF16A34A)),
    (Icons.local_drink_rounded, Color(0xFF2563EB)),
    (Icons.bakery_dining_rounded, Color(0xFFD97706)),
    (Icons.egg_rounded, Color(0xFFE86F4A)),
  ];

  @override
  Duration get loopDuration => const Duration(seconds: 14);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final t = loop.value;
        final breathe = 1 + 0.035 * math.sin(t * math.pi * 2 * 7);
        final placed = [
          for (var i = 0; i < _satellites.length; i++)
            (i, t * math.pi * 2 + i * math.pi / 2),
        ]..sort((a, b) => math.sin(a.$2).compareTo(math.sin(b.$2)));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _OrbitPainter(
                  center: _center,
                  radius: _radius,
                  rotation: t * math.pi * 2 * 2,
                ),
              ),
            ),
            Positioned(
              left: _center.dx - 60,
              top: _center.dy - 60,
              child: Transform.scale(
                scale: breathe,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 40,
                      color: widget.accent,
                    ),
                  ),
                ),
              ),
            ),
            for (final (index, angle) in placed)
              Builder(
                builder: (context) {
                  final depth = (math.sin(angle) + 1) / 2;
                  final position = _center +
                      Offset(
                        math.cos(angle) * _radius,
                        math.sin(angle) * _radius * 0.9,
                      );
                  final (icon, color) = _satellites[index];
                  return Positioned(
                    left: position.dx - 23,
                    top: position.dy - 23,
                    child: Opacity(
                      opacity: 0.75 + 0.25 * depth,
                      child: Transform.scale(
                        scale: 0.82 + 0.2 * depth,
                        child: _artBubble(icon: icon, color: color),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.center,
    required this.radius,
    required this.rotation,
  });

  final Offset center;
  final double radius;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 1.8,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawOval(
      rect.inflate(24),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawArc(
      rect,
      rotation,
      1.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class _ShoppingListArt extends StatefulWidget {
  const _ShoppingListArt({required this.accent});

  final Color accent;

  @override
  State<_ShoppingListArt> createState() => _ShoppingListArtState();
}

class _ShoppingListArtState extends _LoopingArtState<_ShoppingListArt> {
  static const _lineWidths = [88.0, 64.0, 96.0, 56.0, 78.0];

  @override
  Duration get loopDuration => const Duration(milliseconds: 4200);

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF5EEAD4);
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final t = loop.value;
        final checked = (t * 7).floor().clamp(0, _lineWidths.length);
        final scan = (t * 2) % 1;
        final pulse = (t * 3) % 1;
        final bob = math.sin(t * math.pi * 2) * 5;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Photo card peeking out behind the list.
            Positioned(
              left: 96,
              top: 16,
              child: Transform.rotate(
                angle: 0.13,
                child: Container(
                  width: 150,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 66,
              top: 24,
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  width: 160,
                  height: 212,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: widget.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 70,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F2937),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            for (var i = 0; i < _lineWidths.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 260),
                                      curve: Curves.easeOutBack,
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: i < checked
                                            ? widget.accent
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: i < checked
                                              ? widget.accent
                                              : const Color(0xFFCBD5E1),
                                          width: 1.6,
                                        ),
                                      ),
                                      child: i < checked
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 260),
                                      width: _lineWidths[i],
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: i < checked
                                            ? const Color(0xFFCBD5E1)
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Scanner sweep reading the list.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -30 + scan * 250,
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                mint.withValues(alpha: 0),
                                mint.withValues(alpha: 0.35),
                              ],
                            ),
                            border: const Border(
                              bottom: BorderSide(color: mint, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Camera badge with a steady capture pulse.
            Positioned(
              left: 196,
              top: 6,
              child: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 52 + 30 * pulse,
                      height: 52 + 30 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.5 * (1 - pulse),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                    _artBubble(
                      icon: Icons.photo_camera_rounded,
                      color: widget.accent,
                      size: 52,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 170 + bob,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DeliveryArt extends StatefulWidget {
  const _DeliveryArt({required this.accent});

  final Color accent;

  @override
  State<_DeliveryArt> createState() => _DeliveryArtState();
}

class _DeliveryArtState extends _LoopingArtState<_DeliveryArt> {
  static const _start = Offset(52, 204);
  static const _end = Offset(248, 56);

  static final Path _route = Path()
    ..moveTo(_start.dx, _start.dy)
    ..cubicTo(120, 206, 84, 104, 158, 116)
    ..cubicTo(230, 128, 210, 60, _end.dx, _end.dy);
  static final PathMetric _metric = _route.computeMetrics().first;

  @override
  Duration get loopDuration => const Duration(milliseconds: 4600);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final t = loop.value;
        final progress =
            Curves.easeInOutCubic.transform((t / 0.78).clamp(0.0, 1.0));
        final rider =
            _metric.getTangentForOffset(_metric.length * progress)!.position;
        final riderOpacity = t < 0.06
            ? t / 0.06
            : t > 0.92
                ? (1 - t) / 0.08
                : 1.0;
        final arrived = t > 0.78 ? (t - 0.78) / 0.22 : 0.0;
        final bob = math.sin(t * math.pi * 4) * 4;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePainter(
                  route: _route,
                  metric: _metric,
                  progress: progress,
                ),
              ),
            ),
            Positioned(
              left: _start.dx - 24,
              top: _start.dy - 24,
              child: _artBubble(
                icon: Icons.storefront_rounded,
                color: const Color(0xFF136B43),
                size: 48,
              ),
            ),
            Positioned(
              left: _end.dx - 34,
              top: _end.dy - 34,
              child: SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50 + 36 * arrived,
                      height: 50 + 36 * arrived,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: arrived > 0 ? 0.3 * (1 - arrived) : 0,
                        ),
                      ),
                    ),
                    _artBubble(
                      icon: Icons.home_rounded,
                      color: widget.accent,
                      size: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: rider.dx - 25,
              top: rider.dy - 31,
              child: Opacity(
                opacity: riderOpacity.clamp(0.0, 1.0),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(widget.accent, Colors.white, 0.2)!,
                        widget.accent,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            // Cash card floating in the corner.
            Positioned(
              left: 188,
              top: 176 + bob,
              child: Transform.rotate(
                angle: -0.06,
                child: Container(
                  width: 92,
                  height: 58,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            FractionallySizedBox(
                              widthFactor: 0.6,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(4),
                                ),
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
          ],
        );
      },
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.route,
    required this.metric,
    required this.progress,
  });

  final Path route;
  final PathMetric metric;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.3);
    for (var distance = 0.0; distance < metric.length; distance += 14) {
      canvas.drawPath(
        metric.extractPath(distance, math.min(distance + 7, metric.length)),
        dash,
      );
    }

    final travelled = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      travelled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      travelled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
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

enum _OnboardingArt { catalog, list, delivery }

class _OnboardingItem {
  const _OnboardingItem({
    required this.art,
    required this.title,
    required this.message,
    required this.colors,
    required this.glow,
  });

  final _OnboardingArt art;
  final String title;
  final String message;
  final List<Color> colors;
  final Color glow;
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
          title: 'Your next order is waiting',
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
        if (appState.passwordResetTracker != null) ...[
          const SizedBox(height: 12),
          _PasswordResetTrackerCard(
            status: appState.passwordResetTracker!,
            isRefreshing: appState.isCheckingPasswordResetTracker,
            onRefresh: () => appState.refreshPasswordResetTracker(),
            onContinue: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  phone: appState.passwordResetTracker!.phone,
                  requestId: appState.passwordResetTracker!.requestId,
                ),
              ),
            ),
            onSubmitNew: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ForgotPasswordPhoneScreen(),
              ),
            ),
          ),
        ],
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

/// The Login-page "Password Reset Request" tracker (see AppState.
/// passwordResetTracker). Only rendered when there is an active/recent
/// request to show — the customer never has to leave the Login page to
/// check on a submitted request.
class _PasswordResetTrackerCard extends StatelessWidget {
  const _PasswordResetTrackerCard({
    required this.status,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onContinue,
    required this.onSubmitNew,
  });

  final PasswordResetStatusResult status;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onContinue;
  final VoidCallback onSubmitNew;

  @override
  Widget build(BuildContext context) {
    final visuals = _resetTrackerVisuals(status);
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visuals.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(visuals.icon, color: visuals.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t('Password Reset Request'),
                  style: const TextStyle(
                    color: _authInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${context.t('Status')}: ${context.t(visuals.statusLabel)}',
            style: TextStyle(
              color: visuals.color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.t(visuals.message),
            style: const TextStyle(
              color: _authMuted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (status.isApproved)
            PrimaryActionButton(
              label: 'Continue password reset',
              icon: Icons.arrow_forward,
              isLoading: false,
              onPressed: onContinue,
            )
          else if (status.isRejected || status.isExpired)
            OutlinedButton.icon(
              onPressed: onSubmitNew,
              icon: const Icon(Icons.refresh),
              label: Text(context.t('Submit new request')),
            )
          else if (!status.isCompleted)
            OutlinedButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                context.t(isRefreshing ? 'Checking' : 'Refresh status'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResetTrackerVisuals {
  const _ResetTrackerVisuals({
    required this.icon,
    required this.color,
    required this.background,
    required this.statusLabel,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String statusLabel;
  final String message;
}

_ResetTrackerVisuals _resetTrackerVisuals(PasswordResetStatusResult status) {
  if (status.isApproved) {
    return const _ResetTrackerVisuals(
      icon: Icons.check_circle,
      color: _authPrimary,
      background: _authPrimaryLight,
      statusLabel: 'Approved',
      message:
          'Your password reset request has been approved. You can now create a new password.',
    );
  }
  if (status.isRejected) {
    return const _ResetTrackerVisuals(
      icon: Icons.error_outline,
      color: Color(0xFFC83A2B),
      background: Color(0xFFFBEAE8),
      statusLabel: 'Rejected',
      message:
          'Your password reset request was not approved. Please submit a new request if needed.',
    );
  }
  if (status.isExpired) {
    return const _ResetTrackerVisuals(
      icon: Icons.timer_off_outlined,
      color: Color(0xFF6B7280),
      background: Color(0xFFF1F2F4),
      statusLabel: 'Expired',
      message:
          'This password reset approval has expired. Please submit a new request.',
    );
  }
  if (status.isCompleted) {
    return const _ResetTrackerVisuals(
      icon: Icons.check_circle_outline,
      color: _authPrimary,
      background: _authPrimaryLight,
      statusLabel: 'Completed',
      message:
          'Password updated successfully. Please sign in with your new password.',
    );
  }
  return const _ResetTrackerVisuals(
    icon: Icons.hourglass_top,
    color: _authAccent,
    background: Color(0xFFFFF5E5),
    statusLabel: 'Pending',
    message: 'Your request has been sent and is waiting for admin approval.',
  );
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
      final appState = context.read<AppState>();
      final status = await appState.authService.requestPasswordReset(phone);
      await appState.trackPasswordResetRequest(status);
      if (!mounted) {
        return;
      }
      showSnack(context, status.message);
      // Back to the Login page: the Password Reset Request tracker there
      // (driven by AppState.passwordResetTracker) picks this request up
      // automatically, so the customer never has to return to this screen
      // to check on it.
      Navigator.of(context).popUntil((route) => route.isFirst);
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
          title: 'Your shopping profile',
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
  const ResetPasswordScreen({
    super.key,
    required this.phone,
    required this.requestId,
  });

  final String phone;

  /// The exact approved reset request this screen completes. Completion is
  /// always bound to this id - never re-derived from [phone] - so it can
  /// only ever finish the specific request the customer's own tracker
  /// pointed them at.
  final String requestId;

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
        requestId: widget.requestId,
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
