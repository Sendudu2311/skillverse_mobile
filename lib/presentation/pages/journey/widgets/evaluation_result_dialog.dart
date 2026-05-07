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

    final correctRate = result.totalQuestions != null && result.totalQuestions! > 0
        ? ((result.correctAnswers ?? 0) / result.totalQuestions! * 100).round()
        : 0;

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
                        Text(
                          'Điểm: ${result.scorePercentage}% (${result.correctAnswers ?? 0}/${result.totalQuestions ?? 0} đúng)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: result.passed ? AppTheme.successColor : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trình độ: ${_getLevelLabel(result.evaluatedLevel)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        // Adaptive: scoreBandLabel + recommendationLabel
                        if (result.scoreBandLabel != null ||
                            result.recommendationLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (result.scoreBandLabel != null)
                                result.scoreBandLabel!,
                              if (result.recommendationLabel != null)
                                result.recommendationLabel!,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.accentCyan
                                  : AppTheme.primaryBlue,
                            ),
                          ),
                        ],
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
                    // KPIs
                    if (result.totalQuestions != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildKpiCard('Đúng', '${result.correctAnswers ?? 0}', AppTheme.successColor, isDark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildKpiCard('Sai', '${result.incorrectAnswers ?? 0}', Colors.red, isDark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildKpiCard('Tổng câu', '${result.totalQuestions ?? 0}', AppTheme.primaryBlue, isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Accuracy Bar
                      Text(
                        'Tỷ lệ chính xác: $correctRate%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: correctRate / 100,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        color: AppTheme.successColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 24),
                    ],

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

                    if (result.detailedFeedback != null &&
                        result.detailedFeedback!.trim().isNotEmpty &&
                        result.detailedFeedback != result.evaluationSummary) ...[
                      _buildSectionTitle('Nhận xét chi tiết', Icons.comment, isDark),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade200,
                          ),
                        ),
                        child: FormattedAIResponse(
                          content: result.detailedFeedback!,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Skill Analysis
                    if (result.skillAnalysis.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Phân tích theo nhóm kỹ năng',
                        Icons.insights,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      ...result.skillAnalysis.map((s) => _buildSkillAnalysisCard(s, isDark)),
                      const SizedBox(height: 24),
                    ],

                    // Strengths & Weaknesses (if any)
                    if (result.overallStrengths.isNotEmpty || result.overallWeaknesses.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result.overallStrengths.isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Điểm mạnh', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                                  const SizedBox(height: 8),
                                  ...result.overallStrengths.map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('+ $s', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                                  )),
                                ],
                              ),
                            ),
                          if (result.overallStrengths.isNotEmpty && result.overallWeaknesses.isNotEmpty)
                            const SizedBox(width: 16),
                          if (result.overallWeaknesses.isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Cần cải thiện', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  const SizedBox(height: 8),
                                  ...result.overallWeaknesses.map((w) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('- $w', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                                  )),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Question Reviews
                    if (result.questionReviews.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Chi tiết từng câu hỏi (${result.questionReviews.length})',
                        Icons.list_alt,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      ...result.questionReviews.asMap().entries.map((e) => _buildQuestionReviewCard(e.value, e.key, isDark)),
                      const SizedBox(height: 24),
                    ],

                    // Keywords
                    if (result.highlightKeywords.isNotEmpty) ...[
                      _buildSectionTitle('Từ khóa đề xuất', Icons.tag, isDark),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.highlightKeywords
                            .map((k) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.primaryBlueDark.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(k, style: TextStyle(fontSize: 12, color: AppTheme.primaryBlueDark, fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildKpiCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillAnalysisCard(SkillAnalysisDto skill, bool isDark) {
    final bool isWeak = (skill.gap ?? 0) < 0;
    final color = isWeak ? Colors.orange : AppTheme.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              skill.skillName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getLevelLabel(skill.currentLevel),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(QuestionReviewItemDto q, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: q.isCorrect
              ? AppTheme.successColor.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: #number + skill tag + badge
          Row(
            children: [
              Text('#${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45)),
              if (q.skillArea != null && q.skillArea!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      q.skillArea!,
                      style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: q.isCorrect
                      ? AppTheme.successColor.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(q.isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 14, color: q.isCorrect ? AppTheme.successColor : Colors.red),
                    const SizedBox(width: 4),
                    Text(q.isCorrect ? 'Đúng' : 'Sai',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                            color: q.isCorrect ? AppTheme.successColor : Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Question text
          Text(q.question.replaceAll(RegExp(r'<[^>]*>'), ''),
              style: TextStyle(fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
          const SizedBox(height: 10),
          // Options grid or fallback
          if (q.options.isNotEmpty)
            ...q.options.asMap().entries.map((entry) {
              final optKey = String.fromCharCode(65 + entry.key);
              final userKey = _extractOptionKey(q.userAnswer ?? '');
              final correctKey = _extractOptionKey(q.correctAnswer ?? '');
              final isUserPick = optKey == userKey;
              final isCorrectOpt = optKey == correctKey;

              Color bgColor = Colors.transparent;
              Color borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
              if (isCorrectOpt) {
                bgColor = AppTheme.successColor.withValues(alpha: 0.08);
                borderColor = AppTheme.successColor.withValues(alpha: 0.4);
              }
              if (isUserPick && !isCorrectOpt) {
                bgColor = Colors.red.withValues(alpha: 0.08);
                borderColor = Colors.red.withValues(alpha: 0.4);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text('$optKey. ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54)),
                    Expanded(
                      child: Text(entry.value.replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: TextStyle(fontSize: 13,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                    ),
                    if (isUserPick) ...[
                      const SizedBox(width: 6),
                      Text('Bạn chọn',
                          style: TextStyle(fontSize: 10,
                              color: isCorrectOpt ? AppTheme.successColor : Colors.red,
                              fontWeight: FontWeight.w600)),
                    ],
                    if (isCorrectOpt && !isUserPick) ...[
                      const SizedBox(width: 6),
                      Text('Đáp án',
                          style: TextStyle(fontSize: 10, color: AppTheme.successColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              );
            })
          else ...[
            Text('Bạn chọn: ${q.userAnswer ?? "Không trả lời"}',
                style: TextStyle(fontSize: 13,
                    color: q.isCorrect ? AppTheme.successColor : Colors.red,
                    fontWeight: FontWeight.w500)),
            if (!q.isCorrect)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Đáp án đúng: ${q.correctAnswer ?? ""}',
                    style: TextStyle(fontSize: 13, color: AppTheme.successColor,
                        fontWeight: FontWeight.w500)),
              ),
          ],
          // Expandable explanation
          if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              dense: true,
              title: Text('Giải thích',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue)),
              children: [
                Text(q.explanation!,
                    style: TextStyle(fontSize: 12, height: 1.4,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _extractOptionKey(String value) {
    final match = RegExp(r'^([A-D])(?:\s*[.):\-]|\s+|$)', caseSensitive: false)
        .firstMatch(value.trim());
    return match?.group(1)?.toUpperCase() ?? '';
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
