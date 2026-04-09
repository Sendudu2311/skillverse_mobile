import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// Step indicator for AI report generation process.
/// Shows 4 steps: Thu thập dữ liệu → Phân tích AI → Tạo báo cáo → Hoàn thiện
class GeneratingStepsWidget extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  const GeneratingStepsWidget({
    super.key,
    required this.currentStep,
    required this.isDark,
  });

  static const _steps = [
    ('Thu thập dữ liệu', Icons.check_circle_outline),
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
            // Connector
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return SizedBox(
              width: 24,
              height: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [AppTheme.successColor, AppTheme.successColor]
                        : [
                            isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                            isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                          ],
                  ),
                ),
              ),
            );
          }

          // Step indicator
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
    final Color pendingColor =
        isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2);

    final Color color = isCompleted
        ? doneColor
        : (isActive ? activeColor : pendingColor);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: isActive ? 2.5 : 1.5),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: color, size: 20)
                : (isActive
                    ? _AnimatedIcon(icon: icon, color: color)
                    : Icon(icon, color: color, size: 18)),
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

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIcon({required this.icon, required this.color});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.refresh, color: widget.color, size: 18),
    );
  }
}
