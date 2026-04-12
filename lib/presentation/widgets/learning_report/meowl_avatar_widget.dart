import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// Meowl avatar widget with floating animation, animated glow ring,
/// and speech bubble fade-in — matching the Web Prototype's premium feel.
class MeowlAvatarWidget extends StatefulWidget {
  final String? speech;
  final bool animate;
  final double size;
  final bool showSpeechBubble;

  const MeowlAvatarWidget({
    super.key,
    this.speech,
    this.animate = true,
    this.size = 80,
    this.showSpeechBubble = true,
  });

  @override
  State<MeowlAvatarWidget> createState() => _MeowlAvatarWidgetState();
}

class _MeowlAvatarWidgetState extends State<MeowlAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;


  @override
  void initState() {
    super.initState();

    // Floating up/down
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Glow ring that pulses around the avatar
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _floatController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MeowlAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    } else if (!widget.animate && _floatController.isAnimating) {
      _floatController.stop();
      _floatController.value = 0;
      _glowController.stop();
      _glowController.value = 0;
    }
    // Speech change is handled by TweenAnimationBuilder key in build()
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar with glow ring ──
        AnimatedBuilder(
          animation: Listenable.merge([_floatAnimation, _glowAnimation]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, widget.animate ? _floatAnimation.value : 0),
              child: CustomPaint(
                painter: _GlowRingPainter(
                  glowOpacity: widget.animate ? _glowAnimation.value : 0.2,
                  color: AppTheme.accentCyan,
                  radius: widget.size / 2 + 6,
                ),
                child: child,
              ),
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/meowl_bg_clear.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.pets,
                    size: widget.size * 0.5,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Speech bubble with animated entrance ──
        if (widget.showSpeechBubble &&
            widget.speech != null &&
            widget.speech!.isNotEmpty) ...[
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            key: ValueKey(widget.speech),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppTheme.galaxyMid.withValues(alpha: 0.95),
                            AppTheme.galaxyMid.withValues(alpha: 0.8),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.98),
                            Colors.white.withValues(alpha: 0.9),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.accentCyan.withValues(alpha: 0.25)
                        : AppTheme.primaryBlue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlueDark.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.speech!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter that draws a soft glow ring around the avatar.
class _GlowRingPainter extends CustomPainter {
  final double glowOpacity;
  final Color color;
  final double radius;

  _GlowRingPainter({
    required this.glowOpacity,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: glowOpacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowRingPainter oldDelegate) =>
      oldDelegate.glowOpacity != glowOpacity;
}
