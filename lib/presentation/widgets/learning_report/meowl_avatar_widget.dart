import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// Meowl avatar widget with optional floating animation and speech bubble.
///
/// Adapts the web Meowl mascot pattern for mobile.
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MeowlAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, widget.animate ? _floatAnimation.value : 0),
              child: child,
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
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
        if (widget.showSpeechBubble && widget.speech != null && widget.speech!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.galaxyMid.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
                      : AppTheme.primaryBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
        ],
      ],
    );
  }
}
