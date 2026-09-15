import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Backdrop for the customer home screen.
///
/// A flat near-white page left the top of the screen looking empty, so this
/// gives it a hero: a rich brand-green field fills the upper third and curves
/// into the light page below, with wide rings and a soft bloom inside it. The
/// field is deliberately lighter than the dark green header card so that card
/// still reads as a distinct layer on top of it.
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The hero is dark enough that the default dark status bar icons would
    // disappear into it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: HomeBackdropPainter.pageColor),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(painter: HomeBackdropPainter()),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class HomeBackdropPainter extends CustomPainter {
  /// The light page below the hero.
  static const pageColor = Color(0xFFF4FAF6);

  static const _heroTop = Color(0xFF3D9E6C);
  static const _heroBottom = Color(0xFF7FC9A0);
  static const _accent = Color(0xFFE86F4A);
  static const _gold = Color(0xFFF6B84B);

  /// Where the hero ends at the screen edges, and how far its curve bulges
  /// below that in the middle, both as fractions of the height.
  static const _heroEdge = 0.30;
  static const _heroBulge = 0.37;

  @override
  void paint(Canvas canvas, Size size) {
    _paintHero(canvas, size);
    _paintBottomArc(canvas, size);
    _paintDots(canvas, size);
  }

  void _paintHero(Canvas canvas, Size size) {
    final edgeY = size.height * _heroEdge;
    final bulgeY = size.height * _heroBulge;
    // Quadratic control point is twice as far from the ends as the curve
    // actually travels, so the apex lands on bulgeY.
    final hero = Path()
      ..lineTo(0, edgeY)
      ..quadraticBezierTo(
        size.width / 2,
        edgeY + (bulgeY - edgeY) * 2,
        size.width,
        edgeY,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(
      hero,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_heroTop, _heroBottom],
        ).createShader(Rect.fromLTWH(0, 0, size.width, bulgeY)),
    );

    // Decoration is clipped to the hero so it stops cleanly at the curve
    // rather than trailing over the cards below.
    canvas.save();
    canvas.clipPath(hero);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.16);
    final ringCenter = Offset(size.width * 0.88, size.height * 0.02);
    for (final radiusFactor in const [0.24, 0.40, 0.58, 0.78]) {
      canvas.drawCircle(ringCenter, radiusFactor * size.width, ring);
    }

    final bloomCenter = Offset(size.width * 0.08, edgeY * 0.85);
    final bloomRadius = size.width * 0.42;
    canvas.drawCircle(
      bloomCenter,
      bloomRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: bloomCenter, radius: bloomRadius),
        ),
    );

    canvas.restore();
  }

  /// A warm arc lifting the bottom of the page, so the area below the last
  /// card is not dead space.
  void _paintBottomArc(Canvas canvas, Size size) {
    final startY = size.height * 0.90;
    final arc = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, startY)
      ..quadraticBezierTo(
        size.width * 0.5,
        startY - size.height * 0.10,
        size.width,
        startY,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      arc,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withValues(alpha: 0.14),
            _gold.withValues(alpha: 0.24),
          ],
        ).createShader(
          Rect.fromLTWH(
            0,
            startY - size.height * 0.10,
            size.width,
            size.height * 0.20,
          ),
        ),
    );
  }

  /// Faint dot texture over the open area between the hero and the bottom
  /// arc, in one drawPoints call rather than hundreds of drawCircle calls.
  void _paintDots(Canvas canvas, Size size) {
    const spacing = 24.0;
    final from = size.height * _heroBulge + 12;
    final to = size.height * 0.90;
    final dots = <Offset>[
      for (var y = from; y < to; y += spacing)
        for (var x = spacing / 2; x < size.width; x += spacing) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      dots,
      Paint()
        ..color = const Color(0xFF176B45).withValues(alpha: 0.10)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(HomeBackdropPainter oldDelegate) => false;
}
