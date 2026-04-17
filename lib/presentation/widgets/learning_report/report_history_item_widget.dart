import 'package:flutter/material.dart';
import '../../../data/models/learning_report_model.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/date_time_helper.dart';
import '../glass_card.dart';

/// History list item card with report info and actions.
class ReportHistoryItemWidget extends StatelessWidget {
  final StudentLearningReportResponse report;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final bool isDownloading;
  final bool isDark;

  const ReportHistoryItemWidget({
    super.key,
    required this.report,
    required this.onTap,
    required this.onDownload,
    this.isDownloading = false,
    required this.isDark,
  });

  static final _typeBadges = {
    'COMPREHENSIVE': ('Toàn diện', Color(0xFF8B5CF6)),
    'WEEKLY_SUMMARY': ('Tuần', Color(0xFF3B82F6)),
    'MONTHLY_SUMMARY': ('Tháng', Color(0xFF10B981)),
    'SKILL_ASSESSMENT': ('Kỹ năng', Color(0xFFF59E0B)),
    'GOAL_TRACKING': ('Mục tiêu', Color(0xFFEC4899)),
  };

  static final _trendColors = {
    'improving': const Color(0xFF22C55E),
    'stable': const Color(0xFFFBBF24),
    'declining': const Color(0xFFEF4444),
  };

  static final _trendLabels = {
    'improving': 'Tiến bộ',
    'stable': 'Ổn định',
    'declining': 'Cần cải thiện',
  };

  @override
  Widget build(BuildContext context) {
    final typeKey = (report.reportType ?? 'COMPREHENSIVE').toUpperCase();
    final (typeLabel, typeColor) =
        _typeBadges[typeKey] ?? (typeKey, Color(0xFF6B7280));
    final trend = (report.learningTrend ?? '').toLowerCase();
    final trendColor = _trendColors[trend] ?? AppTheme.darkTextSecondary;
    final trendLabel = _trendLabels[trend] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 380;
                final leading = Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: typeColor,
                    size: 22,
                  ),
                );

                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact) ...[
                      Text(
                        'Báo cáo #${report.id ?? 'N/A'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildTypeBadge(typeLabel, typeColor),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Báo cáo #${report.id ?? 'N/A'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: _buildTypeBadge(typeLabel, typeColor),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _buildMetaItem(
                          icon: Icons.calendar_today_outlined,
                          text: _formatDateTime(report.generatedAt ?? ''),
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        _buildMetaItem(
                          icon: Icons.speed,
                          text: '${report.overallProgress ?? 0}%',
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        if (trendLabel.isNotEmpty)
                          _buildMetaItem(
                            icon: Icons.trending_up,
                            text: trendLabel,
                            color: trendColor,
                            isHighlighted: true,
                          ),
                      ],
                    ),
                  ],
                );

                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: isDownloading ? null : onDownload,
                      icon: isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.download_outlined,
                              size: 20,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                      tooltip: 'Tải PDF',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                    const SizedBox(width: 8),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String text,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'N/A';
    final dt = DateTimeHelper.tryParseIso8601(isoString);
    return dt != null ? DateTimeHelper.formatDate(dt) : isoString;
  }
}
