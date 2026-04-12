import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// Step indicator for AI report generation process with pulse glow
/// on the active step — matches the Prototype's animated step pipeline.
class GeneratingStepsWidget extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  const GeneratingStepsWidget({
    super.key,
    required this.currentStep,
    required this.isDark,
  });

  static const _steps = [
    ('Thu thập dữ liệu', Icons.cloud_download_outlined),
    ('Phân tích AI', Icons.psychology_outlined),
    ('Tạo báo cáo', Icons.description_outlined),
    ('Hoàn thiện', Icons.auto_awesome),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // ── Connector line ──
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return _AnimatedConnector(
              isCompleted: isCompleted,
              isDark: isDark,
            );
          }

          // ── Step circle ──
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;
          final (label, icon) = _steps[stepIndex];

          return _StepIndicator(
            label: label,
            icon: icon,
            isCompleted: isCompleted,
            isActive: isActive,
            isDark: isDark,
          );
        }),
      ),
    );
  }
}

/// Connector line that animates its fill when completed.
class _AnimatedConnector extends StatelessWidget {
  final bool isCompleted;
  final bool isDark;

  const _AnimatedConnector({
    required this.isCompleted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted
                ? [AppTheme.successColor, const Color(0xFF34D399)]
                : [
                    isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final bool isDark;

  const _StepIndicator({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppTheme.accentCyan;
    final Color doneColor = AppTheme.successColor;
    final Color pendingColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.15);

    final Color color =
        isCompleted ? doneColor : (isActive ? activeColor : pendingColor);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle with optional pulse glow
        isActive
            ? _PulseGlowCircle(color: color, icon: icon)
            : Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border:
                      Border.all(color: color, width: isCompleted ? 2 : 1.5),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check_rounded, color: color, size: 20)
                      : Icon(icon, color: color, size: 18),
                ),
              ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? color
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Animated pulsing glow circle for the currently active generation step.
class _PulseGlowCircle extends StatefulWidget {
  final Color color;
  final IconData icon;

  const _PulseGlowCircle({required this.color, required this.icon});

  @override
  State<_PulseGlowCircle> createState() => _PulseGlowCircleState();
}

class _PulseGlowCircleState extends State<_PulseGlowCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
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
        final pulse = _controller.value;
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.12 + pulse * 0.1),
            border:
                Border.all(color: widget.color, width: 2.0 + pulse * 0.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2 + pulse * 0.2),
                blurRadius: 8 + pulse * 8,
                spreadRadius: pulse * 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
        );
      },
    );
  }
}
