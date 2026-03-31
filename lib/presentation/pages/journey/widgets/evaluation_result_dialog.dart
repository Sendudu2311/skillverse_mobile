import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../data/models/journey_models.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/formatted_ai_response.dart';

class EvaluationResultDialog extends StatelessWidget {
  final TestResultDto result;

  const EvaluationResultDialog({super.key, required this.result});

  static void show(BuildContext context, TestResultDto result) {
    showDialog(
      context: context,
      builder: (context) => EvaluationResultDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Parse JSON lists
    List<Map<String, dynamic>> strengths = [];
    List<Map<String, dynamic>> skillGaps = [];
    List<String> keywords = [];

    try {
      if (result.strengthsJson != null) {
        final decoded = jsonDecode(result.strengthsJson!);
        if (decoded is List) {
          strengths = List<Map<String, dynamic>>.from(decoded);
        }
      }
      if (result.skillGapsJson != null) {
        final decoded = jsonDecode(result.skillGapsJson!);
        if (decoded is List) {
          skillGaps = List<Map<String, dynamic>>.from(decoded);
        }
      }
      if (result.highlightKeywordsJson != null) {
        final decoded = jsonDecode(result.highlightKeywordsJson!);
        if (decoded is List) {
          keywords = decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Error parsing JSON fields: $e');
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppTheme.darkCardBackground : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết đánh giá AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Điểm số: ${result.scorePercentage}% | Trình độ: ${_getLevelLabel(result.evaluatedLevel)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.evaluationSummary != null) ...[
                      _buildSectionTitle(
                        'Tổng quan',
                        Icons.dashboard_customize,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.evaluationSummary!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (strengths.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Điểm mạnh',
                        Icons.thumb_up,
                        isDark,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 12),
                      ...strengths.map((s) => _buildStrengthCard(s, isDark)),
                      const SizedBox(height: 24),
                    ],

                    if (skillGaps.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Kỹ năng cần cải thiện',
                        Icons.trending_up,
                        isDark,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      ...skillGaps.map((g) => _buildSkillGapCard(g, isDark)),
                      const SizedBox(height: 24),
                    ],

                    if (result.detailedFeedback != null) ...[
                      _buildSectionTitle(
                        'Nhận xét chi tiết',
                        Icons.comment,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBorderColor
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: FormattedAIResponse(
                          content: result.detailedFeedback!,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (keywords.isNotEmpty) ...[
                      _buildSectionTitle('Từ khóa đề xuất', Icons.tag, isDark),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: keywords
                            .map(
                              (k) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlueDark.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primaryBlueDark.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  k,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlueDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    final c = color ?? AppTheme.primaryBlueDark;
    return Row(
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthCard(Map<String, dynamic> item, bool isDark) {
    final skill = item['skill']?.toString() ?? 'Kỹ năng';
    final desc = item['description']?.toString() ?? '';
    final level = item['level']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
              if (level.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillGapCard(Map<String, dynamic> item, bool isDark) {
    final skill = item['skill']?.toString() ?? 'Kỹ năng';
    final desc = item['description']?.toString() ?? '';
    final priority = item['priority']?.toString() ?? '';
    final howToImprove = item['howToImprove']?.toString() ?? '';

    Color priorityColor = Colors.orange;
    if (priority.toLowerCase() == 'high') priorityColor = Colors.red;
    if (priority.toLowerCase() == 'low') priorityColor = Colors.yellow.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_circle_up, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
              if (priority.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
          if (howToImprove.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      howToImprove,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLevelLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'Mới bắt đầu';
      case SkillLevel.elementary:
        return 'Sơ cấp';
      case SkillLevel.intermediate:
        return 'Trung cấp';
      case SkillLevel.advanced:
        return 'Nâng cao';
      case SkillLevel.expert:
        return 'Chuyên gia';
    }
  }
}
