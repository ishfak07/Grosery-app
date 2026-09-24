import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const _authSheet = Color(0xFFFFFDF8);
const _authSand = Color(0xFFF6F1E7);
const _authSandLine = Color(0xFFE9E0CF);
const _authNight = Color(0xFF12261D);
const _authLime = Color(0xFFB5E36A);

class _AuthHero {
  const _AuthHero({required this.title, required this.message});

  final String title;
  final String message;
}

/// Colours for the lagoon scene; each auth screen gets its own time of day.
class _AuthScenePalette {
  const _AuthScenePalette({
    required this.sky,
    required this.sun,
    required this.hills,
    required this.water,
    required this.palm,
  });

  final List<Color> sky;
  final Color sun;
  final Color hills;
  final List<Color> water;
  final Color palm;

  static const dawn = _AuthScenePalette(
    sky: [Color(0xFFFFD9BE), Color(0xFFFFF1E2)],
    sun: Color(0xFFFF8A5B),
    hills: Color(0xFFE8C4A6),
    water: [Color(0xFFA3D7D1), Color(0xFF5FB2A9), Color(0xFF2F7F77)],
    palm: Color(0xFF1F3B33),
  );

  static const day = _AuthScenePalette(
    sky: [Color(0xFFCDEEEB), Color(0xFFF1FAF5)],
    sun: Color(0xFFFFC34D),
    hills: Color(0xFFB7DAC5),
    water: [Color(0xFFA7DDD6), Color(0xFF5DB6AB), Color(0xFF2A8076)],
    palm: Color(0xFF1C3E30),
  );

  static const dusk = _AuthScenePalette(
    sky: [Color(0xFFDCCFEF), Color(0xFFFCEBE0)],
    sun: Color(0xFFF2876A),
    hills: Color(0xFFD2BCD6),
    water: [Color(0xFFB9C7E8), Color(0xFF7F9BCD), Color(0xFF4C6BA5)],
    palm: Color(0xFF282C45),
  );
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.children,
    this.scene = _AuthScenePalette.dawn,
    this.appBarTitle,
    this.hero,
  });

  final String title;
  final String? appBarTitle;
  final _AuthHero? hero;
  final _AuthScenePalette scene;
  final List<Widget> children;

  static const _sheetOverlap = 30.0;

  @override
  Widget build(BuildContext context) {
    final hero = this.hero;
    return Scaffold(
      backgroundColor: _authSheet,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: AppRefreshIndicator(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sceneHeight =
                  (constraints.maxHeight * 0.36).clamp(230.0, 340.0);
              final horizontal = constraints.maxWidth >= 720 ? 32.0 : 22.0;
              return ListView(
                physics: appRefreshScrollPhysics,
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: sceneHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _AuthScene(palette: scene),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: appBarTitle == null
                                  ? const _AuthBrandMark()
                                  : _AuthBackBar(title: appBarTitle!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -_sheetOverlap),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          constraints.maxHeight - sceneHeight + _sheetOverlap,
                        ),
                      ),
                      decoration: const BoxDecoration(
                        color: _authSheet,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(34)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A0F2A2E),
                            blurRadius: 30,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            14,
                            horizontal,
                            28,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 44,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: _authSandLine,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (hero != null)
                                    _AuthStagger(
                                      index: 0,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: _authAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                context.t(hero.title),
                                                style: const TextStyle(
                                                  color: _authAccent,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  _AuthTitleReveal(text: context.t(title)),
                                  if (hero != null)
                                    _AuthStagger(
                                      index: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          context.t(hero.message),
                                          style: const TextStyle(
                                            color: _authMuted,
                                            fontSize: 14.5,
                                            height: 1.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 22),
                                  _AuthFormTheme(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (var i = 0;
                                            i < children.length;
                                            i++)
                                          _AuthStagger(
                                            index: i + 2,
                                            child: children[i],
                                          ),
                                      ],
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthBackBar extends StatelessWidget {
  const _AuthBackBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          elevation: 0,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: _authInk),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              context.t(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _authInk,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimal underlined inputs and pill buttons for the auth forms only.
class _AuthFormTheme extends StatelessWidget {
  const _AuthFormTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    UnderlineInputBorder line(Color color, [double width = 1.2]) {
      return UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
      );
    }

    const error = Color(0xFFC83A2B);
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: false,
          contentPadding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
          border: line(_authSandLine),
          enabledBorder: line(_authSandLine),
          focusedBorder: line(_authNight, 2.2),
          errorBorder: line(error),
          focusedErrorBorder: line(error, 2.2),
          floatingLabelStyle: WidgetStateTextStyle.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.error) ? error : _authNight,
              fontWeight: FontWeight.w700,
            ),
          ),
          prefixIconColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? _authNight
                : const Color(0xFF9AA59E),
          ),
          suffixIconColor: const Color(0xFF9AA59E),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: _authNight,
            side: const BorderSide(color: _authSandLine, width: 1.4),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _authNight,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: const WidgetStatePropertyAll(StadiumBorder()),
            side: const WidgetStatePropertyAll(
              BorderSide(color: _authSandLine, width: 1.4),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected) ? _authNight : null,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : _authNight,
            ),
            iconColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? _authLime
                  : _authNight,
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Fades and lifts a block into place, later for higher [index].
class _AuthStagger extends StatelessWidget {
  const _AuthStagger({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = 90 * index.clamp(0, 8);
    final total = 520 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Headline that rises out of a mask, like a title card.
class _AuthTitleReveal extends StatelessWidget {
  const _AuthTitleReveal({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 750),
        curve: const Interval(0.1, 1, curve: Curves.easeOutQuart),
        builder: (context, value, child) => FractionalTranslation(
          translation: Offset(0, 1 - value),
          child: child,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: _authNight,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

class _AuthScene extends StatefulWidget {
  const _AuthScene({required this.palette});

  final _AuthScenePalette palette;

  @override
  State<_AuthScene> createState() => _AuthSceneState();
}

class _AuthSceneState extends _LoopingArtState<_AuthScene> {
  @override
  Duration get loopDuration => const Duration(seconds: 24);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AuthScenePainter(palette: widget.palette, animation: loop),
      ),
    );
  }
}

/// Puttalam lagoon at a chosen time of day: sun, coconut palms, layered
/// water, a passing oruwa and the Puttalam Drop pin. Every motion uses a
/// whole number of cycles per loop so the scene repeats without a seam.
class _AuthScenePainter extends CustomPainter {
  _AuthScenePainter({required this.palette, required this.animation})
      : super(repaint: animation);

  final _AuthScenePalette palette;
  final Animation<double> animation;

  static const _tau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final w = size.width;
    final h = size.height;
    final waterTop = h * 0.67;

    // Sky.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.sky,
        ).createShader(Offset.zero & size),
    );

    // Sun with a slow breathing glow.
    final sunRadius = (math.min(w, h) * 0.11).clamp(24.0, 44.0);
    final sun = Offset(w * 0.74, h * 0.4 + math.sin(t * _tau) * 4);
    final glow = sunRadius * (2.6 + 0.2 * math.sin(t * _tau * 2));
    canvas.drawCircle(
      sun,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.sun.withValues(alpha: 0.38),
            palette.sun.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: glow)),
    );
    canvas.drawCircle(sun, sunRadius, Paint()..color = palette.sun);

    // Far shore.
    final hills = Path()
      ..moveTo(0, h * 0.66)
      ..cubicTo(w * 0.18, h * 0.54, w * 0.34, h * 0.6, w * 0.5, h * 0.6)
      ..cubicTo(w * 0.68, h * 0.6, w * 0.82, h * 0.52, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hills, Paint()..color = palette.hills);

    // Drop pin standing on the shore, with its shadow.
    final pinBob = (math.sin(t * _tau * 4) + 1) / 2 * 8;
    final pinTip = Offset(w * 0.36, h * 0.6 - pinBob);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.36, h * 0.605),
        width: 24 * (1 - pinBob / 18),
        height: 6,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    final pinHead = pinTip.translate(0, -24);
    final pinPaint = Paint()..color = _authPrimary;
    canvas.drawPath(
      Path()
        ..moveTo(pinHead.dx - 13, pinHead.dy + 8)
        ..lineTo(pinTip.dx, pinTip.dy)
        ..lineTo(pinHead.dx + 13, pinHead.dy + 8)
        ..close(),
      pinPaint,
    );
    canvas.drawCircle(pinHead, 16, pinPaint);
    canvas.drawCircle(pinHead, 6.5, Paint()..color = Colors.white);

    // Coconut palms swaying out of step with each other.
    _palm(canvas, Offset(w * 0.09, h * 0.7), h * 0.36, 0.35,
        math.sin(t * _tau * 3) * 0.05);
    _palm(canvas, Offset(w * 0.19, h * 0.71), h * 0.25, 0.15,
        math.sin(t * _tau * 3 + 1.4) * 0.05);
    _palm(canvas, Offset(w * 0.93, h * 0.7), h * 0.3, -0.3,
        math.sin(t * _tau * 3 + 2.6) * 0.05);

    // Lagoon: three wave bands drifting at different speeds.
    for (var i = 0; i < 3; i++) {
      final y = waterTop + i * h * 0.08;
      final amplitude = 3.0 + i * 1.5;
      final wavelength = w / (1.3 + i * 0.4);
      final direction = i.isEven ? 1 : -1;
      final phase = t * _tau * (i + 1) * direction;
      final wave = Path()..moveTo(0, y);
      for (var x = 0.0; x <= w + 6; x += 6) {
        wave.lineTo(
          x,
          y + math.sin(x / wavelength * _tau + phase) * amplitude,
        );
      }
      wave
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(wave, Paint()..color = palette.water[i]);

      if (i == 0) {
        // Sun glitter on the first band.
        final glitter = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var j = 0; j < 4; j++) {
          final half =
              (20 - j * 4) * (0.75 + 0.25 * math.sin(t * _tau * 6 + j));
          final gy = y + 10 + j * 7;
          canvas.drawLine(
            Offset(sun.dx - half, gy),
            Offset(sun.dx + half, gy),
            glitter,
          );
        }
      }

      if (i == 1) {
        // An oruwa sailing across between the wave bands.
        final bx = -40 + (w + 80) * t;
        final by = y - 2 + math.sin(t * _tau * 8) * 1.5;
        final boat = Paint()..color = palette.palm;
        canvas.drawPath(
          Path()
            ..moveTo(bx - 18, by)
            ..lineTo(bx + 18, by)
            ..lineTo(bx + 12, by + 6)
            ..lineTo(bx - 12, by + 6)
            ..close(),
          boat,
        );
        canvas.drawLine(
          Offset(bx - 4, by + 9),
          Offset(bx + 18, by + 9),
          boat..strokeWidth = 1.6,
        );
        canvas.drawPath(
          Path()
            ..moveTo(bx - 2, by - 1)
            ..lineTo(bx - 2, by - 30)
            ..quadraticBezierTo(bx + 14, by - 16, bx + 13, by - 2)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: 0.92),
        );
      }
    }
  }

  void _palm(
    Canvas canvas,
    Offset base,
    double height,
    double lean,
    double sway,
  ) {
    final paint = Paint()..color = palette.palm;
    final top = base + Offset(lean * height * 0.45, -height);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx + lean * height * 0.05,
          base.dy - height * 0.55,
          top.dx,
          top.dy,
        ),
      Paint()
        ..color = palette.palm
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(3, height * 0.05)
        ..strokeCap = StrokeCap.round,
    );

    final length = height * 0.44;
    const angles = [-2.9, -2.4, -1.95, -1.2, -0.75, -0.25];
    for (final base in angles) {
      final angle = base + sway;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final normal = Offset(-direction.dy, direction.dx);
      final end = top + direction * length + Offset(0, length * 0.38);
      final control = top + direction * length * 0.6 + Offset(0, -length * 0.1);
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            control.dx + normal.dx * length * 0.12,
            control.dy + normal.dy * length * 0.12,
            end.dx,
            end.dy,
          )
          ..quadraticBezierTo(
            control.dx - normal.dx * length * 0.08,
            control.dy - normal.dy * length * 0.08,
            top.dx,
            top.dy,
          )
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuthScenePainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.animation != animation;
}

/// Dark pill button with a lime action dot whose icon nudges forward.
class _AuthPrimaryButton extends StatefulWidget {
  const _AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<_AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends _LoopingArtState<_AuthPrimaryButton> {
  @override
  Duration get loopDuration => const Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return Material(
      color: enabled || widget.isLoading ? _authNight : const Color(0xFFC9D0CB),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? widget.onPressed : null,
        splashColor: _authLime.withValues(alpha: 0.18),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 26),
              Expanded(
                child: Text(
                  context.t(widget.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(7),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: enabled || widget.isLoading
                        ? _authLime
                        : Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: widget.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: _authNight,
                          ),
                        )
                      : AnimatedBuilder(
                          animation: loop,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              enabled
                                  ? math.sin(loop.value * math.pi * 2) * 2.5
                                  : 0,
                              0,
                            ),
                            child: child,
                          ),
                          child: Icon(
                            widget.icon ?? Icons.arrow_forward_rounded,
                            color: _authNight,
                            size: 22,
                          ),
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.flat = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Sits straight on the sheet with no panel behind it.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    if (flat) {
      return child;
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _authSand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _authSandLine),
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
        AppLogoMark(size: 52),
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
                      child: const AppLogoMark(size: 96),
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
      hero: const _AuthHero(
        title: 'Your next order is waiting',
        message:
            'Login with your phone and password to reorder, track deliveries, and send shopping lists.',
      ),
      children: [
        FirebaseSetupBanner(appState: appState),
        _AuthCard(
          flat: true,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPhoneField(
                  controller: _phone,
                ),
                const SizedBox(height: 6),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  obscureText: true,
                  validator: Validators.password,
                  prefixIcon: Icons.lock,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: appState.firebaseAvailable
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ForgotPasswordPhoneScreen(),
                              ),
                            )
                        : null,
                    child: Text(context.t('Forgot password?')),
                  ),
                ),
                const SizedBox(height: 10),
                _AuthPrimaryButton(
                  label: 'Login',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: appState.firebaseAvailable ? _login : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: appState.firebaseAvailable
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterDetailsScreen(),
                    ),
                  )
              : null,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(context.t('Create account')),
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
            _AuthPrimaryButton(
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
      scene: _AuthScenePalette.dusk,
      hero: const _AuthHero(
        title: 'Admin-approved reset',
        message:
            'Request approval first. Once approved, you can set a new password here.',
      ),
      children: [
        _AuthCard(
          flat: true,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppPhoneField(
                  controller: _phone,
                ),
                const SizedBox(height: 18),
                _AuthPrimaryButton(
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
      scene: _AuthScenePalette.day,
      hero: const _AuthHero(
        title: 'Your shopping profile',
        message:
            'Add your delivery details once and checkout faster on every order.',
      ),
      children: [
        _AuthCard(
          flat: true,
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
                _AuthPrimaryButton(
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
      scene: _AuthScenePalette.dusk,
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
          flat: true,
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
                  _AuthPrimaryButton(
                    label: 'Update password',
                    icon: Icons.save,
                    isLoading: _isLoading,
                    onPressed: _reset,
                  ),
                ] else ...[
                  _AuthPrimaryButton(
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
