import 'dart:math';
import 'package:flutter/material.dart';

/// Galaxy background widget with animated starfield and nebula effects
/// Matching web version's galaxy theme
class GalaxyBackground extends StatefulWidget {
  final Widget child;
  final bool enableAnimation;

  const GalaxyBackground({
    super.key,
    required this.child,
    this.enableAnimation = true,
  });

  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  late List<NebulaCloud> _nebulaClouds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    if (widget.enableAnimation) {
      _controller.repeat();
    }

    // Generate stars
    _stars = List.generate(100, (index) => Star.random());

    // Generate nebula clouds (matching web's 3 nebula gradients)
    _nebulaClouds = [
      NebulaCloud(
        center: const Offset(0.7, 0.3),
        radius: 300,
        color: const Color(0x594C1D95), // rgba(76, 29, 149, 0.35)
      ),
      NebulaCloud(
        center: const Offset(0.3, 0.7),
        radius: 250,
        color: const Color(0x3306B6D4), // rgba(6, 182, 212, 0.2)
      ),
      NebulaCloud(
        center: const Offset(0.5, 0.5),
        radius: 350,
        color: const Color(0x406366F1), // rgba(99, 102, 241, 0.25)
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.6, -0.6),
              radius: 1.2,
              colors: [
                Color(0xE6141423), // rgba(20, 20, 35, 0.9)
                Color(0xF20A0A14), // rgba(10, 10, 20, 0.95)
                Color(0xFF050510), // #050510
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),

        // Animated starfield and nebula
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: GalaxyPainter(
                stars: _stars,
                nebulaClouds: _nebulaClouds,
                animationValue: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class GalaxyPainter extends CustomPainter {
  final List<Star> stars;
  final List<NebulaCloud> nebulaClouds;
  final double animationValue;

  GalaxyPainter({
    required this.stars,
    required this.nebulaClouds,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw nebula clouds first (background layer)
    _drawNebulaClouds(canvas, size);

    // Draw stars
    _drawStars(canvas, size);
  }

  void _drawNebulaClouds(Canvas canvas, Size size) {
    for (var cloud in nebulaClouds) {
      final center = Offset(
        size.width * cloud.center.dx,
        size.height * cloud.center.dy,
      );

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            cloud.color,
            cloud.color.withAlpha(0),
          ],
          stops: const [0.0, 0.6],
        ).createShader(Rect.fromCircle(
          center: center,
          radius: cloud.radius,
        ))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

      canvas.drawCircle(center, cloud.radius, paint);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    for (var star in stars) {
      final position = Offset(
        size.width * star.x,
        size.height * star.y,
      );

      // Twinkling effect (opacity oscillates)
      final twinkle = (sin(animationValue * 2 * pi + star.phase) + 1) / 2;
      final opacity = star.opacity * (0.6 + 0.4 * twinkle);

      final paint = Paint()
        ..color = Colors.white.withAlpha((255 * opacity).toInt())
        ..style = PaintingStyle.fill;

      // Draw star as small circle
      canvas.drawCircle(position, star.size, paint);

      // Add star glow for larger stars
      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withAlpha((50 * opacity).toInt())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size);
        canvas.drawCircle(position, star.size * 1.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GalaxyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class Star {
  final double x; // Position 0.0 to 1.0
  final double y; // Position 0.0 to 1.0
  final double size; // Radius in pixels
  final double opacity; // Base opacity 0.0 to 1.0
  final double phase; // Phase offset for twinkling

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.phase,
  });

  factory Star.random() {
    final random = Random();
    return Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 2.0 + 0.5, // 0.5 to 2.5px
      opacity: random.nextDouble() * 0.5 + 0.4, // 0.4 to 0.9
      phase: random.nextDouble() * 2 * pi,
    );
  }
}

class NebulaCloud {
  final Offset center; // Normalized position 0.0 to 1.0
  final double radius; // Radius in pixels
  final Color color;

  NebulaCloud({
    required this.center,
    required this.radius,
    required this.color,
  });
}
