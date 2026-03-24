import 'package:flutter/material.dart';

/// Staggered slide-up + fade-in animation for list items.
///
/// Usage:
/// ```dart
/// AnimatedListItem(
///   index: index,
///   child: MyCard(...),
/// )
/// ```
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final int baseDurationMs;
  final int staggerMs;
  final int maxStaggerMs;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDurationMs = 300,
    this.staggerMs = 60,
    this.maxStaggerMs = 300,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('animated_item_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds:
            baseDurationMs + (index * staggerMs).clamp(0, maxStaggerMs),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}
