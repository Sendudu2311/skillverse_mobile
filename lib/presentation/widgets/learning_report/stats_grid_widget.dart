import 'package:flutter/material.dart';
import '../../../data/models/learning_report_model.dart';
import '../../../data/services/streak_service.dart';
import '../../themes/app_theme.dart';
import '../glass_card.dart';

/// 2×2 stats grid with animated entrance, gradient accent bars,
/// and animated progress indicator — matches Web Prototype's premium stats.
class StatsGridWidget extends StatelessWidget {
  final StudentMetrics? metrics;
  final StreakInfo? streakInfo;
  final int overallProgress;
  final ({int value, String emoji, String description}) streakDisplay;
  final bool isDark;

  const StatsGridWidget({
    super.key,
    this.metrics,
    this.streakInfo,
    required this.overallProgress,
    required this.streakDisplay,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final studyHours = metrics?.studyHours ?? 0;
    final tasksCompleted = metrics?.tasksCompleted ?? 0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.accentCyan, AppTheme.primaryBlueDark],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TỔNG QUAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentCyan,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.speed,
                    iconColor: AppTheme.primaryBlueDark,
                    gradientColors: [
                      AppTheme.primaryBlueDark,
                      AppTheme.accentCyan,
                    ],
                    value: '$overallProgress%',
                    label: 'Tiến độ',
                    isPrimary: true,
                    progress: overallProgress,
                    isDark: isDark,
                    delay: 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.schedule,
                    iconColor: AppTheme.accentCyan,
                    gradientColors: [
                      AppTheme.accentCyan,
                      const Color(0xFF06B6D4),
                    ],
                    value: '${studyHours}h',
                    label: 'Giờ học',
                    isDark: isDark,
                    delay: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    gradientColors: [Colors.orange, Colors.deepOrange],
                    value: '${streakDisplay.emoji} ${streakDisplay.value}',
                    label: streakDisplay.description,
                    isDark: isDark,
                    delay: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.task_alt,
                    iconColor: AppTheme.successColor,
                    gradientColors: [
                      AppTheme.successColor,
                      const Color(0xFF059669),
                    ],
                    value: '$tasksCompleted',
                    label: 'Tasks hoàn thành',
                    isDark: isDark,
                    delay: 3,
                  ),
                ),
              ],
            ),
            // Additional mini stats row
            if (metrics?.averageSessionDuration != null ||
                metrics?.totalStudySessions != null ||
                (streakInfo?.longestStreak ?? 0) > 0) ...[
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (metrics?.averageSessionDuration != null)
                    _MiniStat(
                      label: 'Phiên TB',
                      value: _formatDuration(metrics!.averageSessionDuration!),
                      isDark: isDark,
                    ),
                  if (metrics?.totalStudySessions != null)
                    _MiniStat(
                      label: 'Tổng phiên',
                      value: '${metrics!.totalStudySessions}',
                      isDark: isDark,
                    ),
                  if ((streakInfo?.longestStreak ?? 0) > 0)
                    _MiniStat(
                      label: 'Streak dài nhất',
                      value: '${streakInfo!.longestStreak} ngày',
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final String value;
  final String label;
  final bool isPrimary;
  final int? progress;
  final bool isDark;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.value,
    required this.label,
    this.isPrimary = false,
    this.progress,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay * 120),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - anim)),
            child: Transform.scale(
              scale: 0.95 + 0.05 * anim,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary
              ? iconColor.withValues(alpha: 0.08)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.025)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? iconColor.withValues(alpha: 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with gradient background circle
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  gradientColors.first.withValues(alpha: 0.15),
                  gradientColors.last.withValues(alpha: 0.08),
                ]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: isPrimary ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            if (isPrimary && progress != null) ...[
              const SizedBox(height: 10),
              _AnimatedGradientProgressBar(
                value: progress! / 100.0,
                gradientColors: gradientColors,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated gradient progress bar replicating the Prototype's colored bar.
class _AnimatedGradientProgressBar extends StatelessWidget {
  final double value;
  final List<Color> gradientColors;
  final bool isDark;

  const _AnimatedGradientProgressBar({
    required this.value,
    required this.gradientColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: animValue.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
