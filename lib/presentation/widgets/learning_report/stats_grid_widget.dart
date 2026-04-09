import 'package:flutter/material.dart';
import '../../../data/models/learning_report_model.dart';
import '../../../data/services/streak_service.dart';
import '../../themes/app_theme.dart';
import '../glass_card.dart';

/// 2x2 stats grid showing: Progress %, Study Hours, Streak, Tasks Completed.
/// Animated entrance with staggered fade transitions.
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.speed,
                    iconColor: AppTheme.primaryBlueDark,
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
  final String value;
  final String label;
  final bool isPrimary;
  final int? progress;
  final bool isDark;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.iconColor,
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
      duration: Duration(milliseconds: 400 + delay * 100),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.primaryBlueDark.withValues(alpha: 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? Border.all(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isPrimary ? 20 : 18,
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
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress! / 100.0,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
            ],
          ],
        ),
      ),
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
