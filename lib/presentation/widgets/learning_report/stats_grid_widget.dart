import 'package:flutter/material.dart';
import '../../../data/models/learning_report_model.dart';
import '../../../data/services/streak_service.dart';
import '../../themes/app_theme.dart';
import '../glass_card.dart';

/// 8-item stats grid with animated entrance, gradient accent bars,
/// and animated progress indicator — matches Web Prototype's premium stats.
class StatsGridWidget extends StatelessWidget {
  final StudentLearningReportResponse report;
  final StreakInfo? streakInfo;
  final ({int value, String emoji, String description}) streakDisplay;
  final bool isDark;

  const StatsGridWidget({
    super.key,
    required this.report,
    this.streakInfo,
    required this.streakDisplay,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final overallProgress = report.overview?.overallProgress ?? 0;
    final studyHours = report.studyStats?.totalStudyHours ?? 0;
    final inProgressRoadmaps = report.roadmapStats?.inProgressRoadmaps ?? 0;
    final completedMissions = report.roadmapStats?.completedMissions ?? 0;
    final completedTasks = report.taskStats?.completedTasks ?? 0;
    final activeCourses = report.courseStats?.activeCourses ?? 0;
    final completedJobs = report.jobStats?.completedJobs ?? 0;

    final statCards = [
      _StatCard(
        icon: Icons.speed,
        iconColor: AppTheme.primaryBlueDark,
        gradientColors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
        value: '$overallProgress%',
        label: 'Tiến độ',
        isPrimary: true,
        progress: overallProgress,
        isDark: isDark,
        delay: 0,
      ),
      _StatCard(
        icon: Icons.schedule,
        iconColor: AppTheme.accentCyan,
        gradientColors: [AppTheme.accentCyan, const Color(0xFF06B6D4)],
        value: '${studyHours}h',
        label: 'Giờ học',
        isDark: isDark,
        delay: 1,
      ),
      _StatCard(
        icon: Icons.local_fire_department,
        iconColor: Colors.orange,
        gradientColors: [Colors.orange, Colors.deepOrange],
        value: '${streakDisplay.emoji} ${streakDisplay.value}',
        label: streakDisplay.description,
        isDark: isDark,
        delay: 2,
      ),
      _StatCard(
        icon: Icons.map_outlined,
        iconColor: AppTheme.secondaryPurple,
        gradientColors: [AppTheme.secondaryPurple, Colors.deepPurpleAccent],
        value: '$inProgressRoadmaps',
        label: 'Roadmap đang học',
        isDark: isDark,
        delay: 3,
      ),
      _StatCard(
        icon: Icons.flag_circle,
        iconColor: AppTheme.successColor,
        gradientColors: [AppTheme.successColor, const Color(0xFF059669)],
        value: '$completedMissions',
        label: 'Node hoàn thành',
        isDark: isDark,
        delay: 4,
      ),
      _StatCard(
        icon: Icons.task_alt,
        iconColor: AppTheme.primaryBlueDark,
        gradientColors: [AppTheme.primaryBlueDark, Colors.blueAccent],
        value: '$completedTasks',
        label: 'Tasks đã xong',
        isDark: isDark,
        delay: 5,
      ),
      _StatCard(
        icon: Icons.school_outlined,
        iconColor: AppTheme.accentGold,
        gradientColors: [AppTheme.accentGold, Colors.orangeAccent],
        value: '$activeCourses',
        label: 'Khóa học',
        isDark: isDark,
        delay: 6,
      ),
      _StatCard(
        icon: Icons.work_outline,
        iconColor: Colors.teal,
        gradientColors: [Colors.teal, Colors.tealAccent.shade700],
        value: '$completedJobs',
        label: 'Jobs hoàn thành',
        isDark: isDark,
        delay: 7,
      ),
    ];

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
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 420;
                final spacing = 12.0;
                // With 8 items, let's use 2 columns or 3 depending on width
                int columns = isCompact ? 2 : 3;
                final cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 12,
                  children: [
                    for (final card in statCards)
                      SizedBox(width: cardWidth, child: card),
                  ],
                );
              },
            ),
            // Additional mini stats row
            if (report.studyStats?.studyMinutesWeek != null ||
                report.studyStats?.studyMinutesMonth != null ||
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.studyStats?.studyMinutesWeek != null)
                    Expanded(
                      child: _MiniStat(
                        label: 'Học tuần này',
                        value: _formatDuration(
                          report.studyStats!.studyMinutesWeek!,
                        ),
                        isDark: isDark,
                      ),
                    ),
                  if (report.studyStats?.studyMinutesMonth != null)
                    Expanded(
                      child: _MiniStat(
                        label: 'Học tháng này',
                        value: _formatDuration(
                          report.studyStats!.studyMinutesMonth!,
                        ),
                        isDark: isDark,
                      ),
                    ),
                  if ((streakInfo?.longestStreak ?? 0) > 0)
                    Expanded(
                      child: _MiniStat(
                        label: 'Streak dài nhất',
                        value: '${streakInfo!.longestStreak} ngày',
                        isDark: isDark,
                      ),
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
      duration: Duration(milliseconds: 500 + (delay % 4) * 120),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - anim)),
            child: Transform.scale(scale: 0.95 + 0.05 * anim, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
                gradient: LinearGradient(
                  colors: [
                    gradientColors.first.withValues(alpha: 0.15),
                    gradientColors.last.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isPrimary ? 20 : 16,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
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
