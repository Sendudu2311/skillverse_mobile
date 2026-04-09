import 'package:flutter/material.dart';

/// Trend banner showing learning trend with colored background and icon.
/// improving = green + Trophy
/// stable = amber + TrendingUp
/// declining = red + AlertCircle
class TrendBannerWidget extends StatelessWidget {
  final String? learningTrend;
  final bool isDark;

  const TrendBannerWidget({
    super.key,
    required this.learningTrend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final trend = (learningTrend ?? 'stable').toLowerCase();

    final (icon, color, bgColor, label) = switch (trend) {
      'improving' => (
          Icons.emoji_events,
          const Color(0xFF22C55E),
          const Color(0xFF22C55E).withValues(alpha: 0.12),
          'Xu hướng: Đang tiến bộ tuyệt vời!',
        ),
      'stable' => (
          Icons.trending_up,
          const Color(0xFFFBBF24),
          const Color(0xFFFBBF24).withValues(alpha: 0.12),
          'Xu hướng: Ổn định và đều đặn',
        ),
      'declining' => (
          Icons.warning_amber_rounded,
          const Color(0xFFEF4444),
          const Color(0xFFEF4444).withValues(alpha: 0.12),
          'Xu hướng: Cần tập trung hơn',
        ),
      _ => (
          Icons.trending_flat,
          const Color(0xFFFBBF24),
          const Color(0xFFFBBF24).withValues(alpha: 0.12),
          'Xu hướng: Ổn định',
        ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - anim)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
