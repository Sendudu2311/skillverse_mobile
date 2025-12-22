import 'package:flutter/material.dart';

/// Common loading indicator widget
/// Provides consistent loading UI across the app
class CommonLoading extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const CommonLoading({super.key, this.message, this.size = 40, this.color});

  /// Full-screen loading overlay
  static Widget fullScreen({String? message, Color? backgroundColor}) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: Center(child: CommonLoading(message: message)),
    );
  }

  /// Center loading with optional message
  static Widget center({String? message}) {
    return Center(child: CommonLoading(message: message));
  }

  /// Small inline loading
  static Widget small({Color? color}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  /// Loading button content
  static Widget button({Color? color}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 3, color: loadingColor),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Loading overlay that can be shown on top of content
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: CommonLoading.fullScreen(
              message: loadingMessage,
              backgroundColor: backgroundColor,
            ),
          ),
      ],
    );
  }
}

/// Adaptive loading indicator
/// Shows platform-specific loading indicator
class AdaptiveLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const AdaptiveLoading({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final loadingColor = color ?? Theme.of(context).colorScheme.primary;

    if (platform == TargetPlatform.iOS) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(loadingColor),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 3, color: loadingColor),
    );
  }
}

/// Linear progress indicator for processes
class LinearLoadingBar extends StatelessWidget {
  final double? value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;

  const LinearLoadingBar({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LinearProgressIndicator(
        value: value,
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer,
        valueColor: AlwaysStoppedAnimation(
          valueColor ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Loading state for lists and grids
class ListLoadingState extends StatelessWidget {
  final String? message;
  final IconData? icon;

  const ListLoadingState({super.key, this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
            ],
            CommonLoading(message: message ?? 'Đang tải dữ liệu...'),
          ],
        ),
      ),
    );
  }
}

/// Pulsing loading indicator (alternative to circular)
class PulsingLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const PulsingLoading({super.key, this.size = 40, this.color});

  @override
  State<PulsingLoading> createState() => _PulsingLoadingState();
}

class _PulsingLoadingState extends State<PulsingLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadingColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: loadingColor,
            ),
          ),
        );
      },
    );
  }
}
