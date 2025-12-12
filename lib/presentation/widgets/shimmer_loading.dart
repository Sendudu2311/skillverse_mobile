import 'package:flutter/material.dart';

/// Shimmer loading effect for skeleton screens
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final highlightColor = widget.highlightColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer placeholder for loading skeletons
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Course card skeleton for loading state
class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            const ShimmerBox(
              width: double.infinity,
              height: 160,
              borderRadius: 16,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  const ShimmerBox(
                    width: double.infinity,
                    height: 20,
                    margin: EdgeInsets.only(bottom: 8),
                  ),

                  // Subtitle placeholder
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 18,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),

                  const SizedBox(height: 8),

                  // Author row
                  Row(
                    children: [
                      const ShimmerBox(
                        width: 24,
                        height: 24,
                        borderRadius: 12,
                        margin: EdgeInsets.only(right: 8),
                      ),
                      Expanded(
                        child: ShimmerBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: 14,
                        margin: const EdgeInsets.only(right: 16),
                      ),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: 14,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerBox(
                        width: 100,
                        height: 36,
                        borderRadius: 8,
                      ),
                      ShimmerBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: 40,
                        borderRadius: 8,
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
