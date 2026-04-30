import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Reusable animated success overlay — scale+fade checkmark with CTA buttons.
///
/// Can be used:
/// 1. As an inline widget (inside a bottom sheet that transitions from form → success)
/// 2. As a fullscreen dialog via [AnimatedSuccessOverlay.show()]
class AnimatedSuccessOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryAction;
  final String closeButtonText;
  final VoidCallback? onClose;

  /// If true, shows drag handle at top (for bottom sheet usage)
  final bool showDragHandle;

  const AnimatedSuccessOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.primaryButtonText,
    this.onPrimaryAction,
    this.closeButtonText = 'Đóng',
    this.onClose,
    this.showDragHandle = true,
  });

  /// Show as a dialog overlay (fullscreen modal)
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? primaryButtonText,
    VoidCallback? onPrimaryAction,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(dialogContext).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedSuccessOverlay(
            title: title,
            subtitle: subtitle,
            primaryButtonText: primaryButtonText,
            onPrimaryAction: onPrimaryAction,
            showDragHandle: false,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    );
  }

  @override
  State<AnimatedSuccessOverlay> createState() => _AnimatedSuccessOverlayState();
}

class _AnimatedSuccessOverlayState extends State<AnimatedSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle (for bottom sheet usage)
            if (widget.showDragHandle) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],

            // Animated checkmark
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.themeGreenStart.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Fade-in content
            Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // CTA buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              widget.onClose ??
                              () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(widget.closeButtonText),
                        ),
                      ),
                      if (widget.primaryButtonText != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Close first, then run action
                              if (widget.onClose != null) {
                                widget.onClose!();
                              } else {
                                Navigator.of(context).pop();
                              }
                              widget.onPrimaryAction?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.themeBlueStart,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.primaryButtonText!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
