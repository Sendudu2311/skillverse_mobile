import 'package:flutter/material.dart';
import '../../../data/models/learning_report_model.dart';
import '../../themes/app_theme.dart';
import '../glass_card.dart';

class RecommendationCardsWidget extends StatelessWidget {
  final List<ReportRecommendation> recommendations;
  final bool isDark;
  final Function(String)? onNavigate;

  const RecommendationCardsWidget({
    super.key,
    required this.recommendations,
    required this.isDark,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
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
                  colors: [AppTheme.accentGold, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ĐỀ XUẤT TẬP TRUNG',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RecommendationCard(
            recommendation: rec,
            isDark: isDark,
            onNavigate: onNavigate,
          ),
        )),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ReportRecommendation recommendation;
  final bool isDark;
  final Function(String)? onNavigate;

  const _RecommendationCard({
    required this.recommendation,
    required this.isDark,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _getTierMeta(recommendation.tier);

    return GlassCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: meta.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon, size: 14, color: meta.color),
                        const SizedBox(width: 4),
                        Text(
                          meta.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: meta.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recommendation.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recommendation.category!,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recommendation.title ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              if (recommendation.analysis != null) ...[
                const SizedBox(height: 6),
                Text(
                  recommendation.analysis!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (recommendation.action != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: meta.color),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        recommendation.action!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (recommendation.hasMetric || recommendation.linkPath != null) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (recommendation.hasMetric)
                      Expanded(
                        child: Text(
                          _formatMetric(recommendation),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: meta.color,
                          ),
                        ),
                      ),
                    if (recommendation.linkPath != null)
                      InkWell(
                        onTap: () => onNavigate?.call(recommendation.linkPath!),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                recommendation.linkLabel ?? 'Mở',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatMetric(ReportRecommendation rec) {
    if (rec.metricValue == null) return '';
    final unit = rec.metricUnit ?? '';
    final current = '${rec.metricValue}$unit';
    if (rec.metricTarget != null) {
      return '$current → mục tiêu ${rec.metricTarget}$unit';
    }
    return current;
  }

  _TierMeta _getTierMeta(String? tier) {
    switch (tier?.toUpperCase()) {
      case 'CRITICAL':
        return _TierMeta('Cần Xử Lý Ngay', AppTheme.errorColor, Icons.warning_amber_rounded);
      case 'IMPROVE':
        return _TierMeta('Cải Thiện', AppTheme.primaryBlueDark, Icons.trending_up);
      case 'NEXT_STEP':
        return _TierMeta('Bước Tiếp Theo', AppTheme.secondaryPurple, Icons.rocket_launch);
      case 'STRENGTH':
        return _TierMeta('Điểm Mạnh', AppTheme.accentGold, Icons.emoji_events);
      default:
        return _TierMeta('Cải Thiện', AppTheme.primaryBlueDark, Icons.trending_up);
    }
  }
}

class _TierMeta {
  final String label;
  final Color color;
  final IconData icon;

  _TierMeta(this.label, this.color, this.icon);
}
