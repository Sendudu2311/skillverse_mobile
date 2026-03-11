import 'dart:ui';
import 'package:flutter/material.dart';

/// Glass morphism card with backdrop blur effect
/// Provides frosted glass appearance matching web design
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool showBorder;
  final double elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
    this.onTap,
    this.showBorder = true,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark
        ? const Color(0xDD1E293B) // Matching darkCardBackground
        : const Color(0xDDFFFFFF); // Matching lightCardBackground

    final defaultBorderColor = isDark
        ? const Color(0x2694A3B8)
        : const Color(0x3394A3B8);

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: borderColor ?? defaultBorderColor,
                width: 1,
              )
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    // Wrap with ClipRRect for backdrop filter
    cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: cardContent,
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      ),
    );
  }
}

/// Gradient glass card with animated gradient background
class GradientGlassCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool animate;

  const GradientGlassCard({
    super.key,
    required this.child,
    required this.gradientColors,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.onTap,
    this.animate = false,
  });

  @override
  State<GradientGlassCard> createState() => _GradientGlassCardState();
}

class _GradientGlassCardState extends State<GradientGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat(reverse: true);

      _animation = Tween<double>(begin: -0.5, end: 1.5).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: widget.child,
    );

    if (widget.animate) {
      cardContent = AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
                stops: [
                  (_animation.value - 0.3).clamp(0.0, 1.0),
                  (_animation.value).clamp(0.0, 1.0),
                  (_animation.value + 0.3).clamp(0.0, 1.0),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: child,
          );
        },
        child: cardContent,
      );
    } else {
      cardContent = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors,
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: cardContent,
      );
    }

    // Add backdrop blur
    cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: cardContent,
      ),
    );

    if (widget.onTap != null) {
      return Container(
        margin: widget.margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: widget.margin,
      child: cardContent,
    );
  }
}
