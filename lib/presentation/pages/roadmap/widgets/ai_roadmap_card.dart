import 'package:flutter/material.dart';
import '../../../../data/models/roadmap_models.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/status_badge.dart';
import '../../../../core/utils/date_time_helper.dart';

/// Card widget for displaying AI Roadmap session in list view
class AiRoadmapCard extends StatelessWidget {
  final RoadmapSessionSummary roadmap;
  final VoidCallback? onTap;
  final void Function(String action)? onLifecycleAction;
  final bool isDeletedScope;

  const AiRoadmapCard({
    super.key,
    required this.roadmap,
    this.onTap,
    this.onLifecycleAction,
    this.isDeletedScope = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryBlueDark.withValues(alpha: 0.3)
              : AppTheme.lightBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Status badge + Experience badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roadmap.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              StatusBadge(status: roadmap.status ?? 'ACTIVE'),
                              const SizedBox(width: 8),
                              _buildExperienceBadge(
                                context,
                                roadmap.experienceLevel,
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onLifecycleAction != null) _buildLifecycleMenu(isDark),
                  ],
                ),
                const SizedBox(height: 8),

                // Goal preview
                Text(
                  roadmap.originalGoal,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Progress bar
                _buildProgressBar(context, isDark),
                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      context,
                      Icons.layers_outlined,
                      '${roadmap.totalQuests} nhiệm vụ',
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      context,
                      Icons.schedule_outlined,
                      roadmap.duration,
                      isDark,
                    ),
                    const Spacer(),
                    Text(
                      DateTimeHelper.formatRelativeTime(
                        DateTimeHelper.tryParseIso8601(roadmap.createdAt) ??
                            DateTime.now(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary.withValues(alpha: 0.6)
                            : AppTheme.lightTextSecondary.withValues(
                                alpha: 0.6,
                              ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceBadge(
    BuildContext context,
    String experience,
    bool isDark,
  ) {
    Color badgeColor;
    String displayText;

    switch (experience.toLowerCase()) {
      case 'beginner':
      case 'mới bắt đầu':
        badgeColor = AppTheme.themeGreenStart;
        displayText = 'Mới bắt đầu';
        break;
      case 'intermediate':
      case 'trung cấp':
        badgeColor = AppTheme.themeOrangeStart;
        displayText = 'Trung cấp';
        break;
      case 'advanced':
      case 'nâng cao':
        badgeColor = AppTheme.themePurpleStart;
        displayText = 'Nâng cao';
        break;
      default:
        badgeColor = AppTheme.primaryBlue;
        displayText = experience;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, bool isDark) {
    final progress = roadmap.progressPercentage;
    final progressColor = _getProgressColor(progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến độ sơ mệnh',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${progress.round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 6,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return AppTheme.themeGreenStart;
    if (progress >= 50) return AppTheme.themeOrangeStart;
    if (progress > 0) return AppTheme.primaryBlue;
    return Colors.grey;
  }

  Widget _buildLifecycleMenu(bool isDark) {
    final currentStatus = (roadmap.status ?? 'ACTIVE').toUpperCase();

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (action) => onLifecycleAction?.call(action),
      itemBuilder: (_) => isDeletedScope
          ? [
              const PopupMenuItem(
                value: 'restore',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.restore, color: Colors.green),
                  title: Text('Khôi phục'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'permanent_delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Xóa vĩnh viễn'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ]
          : [
              if (currentStatus != 'ACTIVE')
                const PopupMenuItem(
                  value: 'activate',
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.play_circle_outline,
                      color: Colors.green,
                    ),
                    title: Text('Kích hoạt'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (currentStatus == 'ACTIVE')
                const PopupMenuItem(
                  value: 'pause',
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.pause_circle_outline,
                      color: Colors.amber,
                    ),
                    title: Text('Tạm dừng'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Xoá'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
    );
  }
}

/// Skeleton loading widget for roadmap card
class AiRoadmapCardSkeleton extends StatelessWidget {
  const AiRoadmapCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSkeletonBox(height: 20, isDark: isDark)),
              const SizedBox(width: 8),
              _buildSkeletonBox(width: 70, height: 24, isDark: isDark),
            ],
          ),
          const SizedBox(height: 8),
          _buildSkeletonBox(height: 14, width: double.infinity, isDark: isDark),
          const SizedBox(height: 4),
          _buildSkeletonBox(height: 14, width: 200, isDark: isDark),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonBox(width: 80, height: 12, isDark: isDark),
              _buildSkeletonBox(width: 30, height: 12, isDark: isDark),
            ],
          ),
          const SizedBox(height: 6),
          _buildSkeletonBox(height: 6, width: double.infinity, isDark: isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSkeletonBox(width: 80, height: 16, isDark: isDark),
              const SizedBox(width: 12),
              _buildSkeletonBox(width: 60, height: 16, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({
    double? width,
    required double height,
    required bool isDark,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
