import 'package:flutter/material.dart';
import '../../../data/models/module_with_content_models.dart';
import '../../../data/models/lesson_models.dart';
import '../../themes/app_theme.dart';

// =============================================================================
// STAT ITEM — small icon+value+label column for the stats row
// =============================================================================

class CourseStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const CourseStatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BENEFIT ITEM — icon + text row for the "what you'll learn" section
// =============================================================================

class CourseBenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const CourseBenefitItem({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 14,
            ),
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: AppTheme.themeGreenStart,
          size: 20,
        ),
      ],
    );
  }
}

// =============================================================================
// MODULE ITEM — collapsible module card with lessons / quizzes / assignments
// =============================================================================

class CourseModuleItem extends StatelessWidget {
  final ModuleWithContentDto module;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final bool isDark;

  const CourseModuleItem({
    super.key,
    required this.module,
    required this.isExpanded,
    required this.onTap,
    required this.gradientColors,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems =
        module.lessons.length +
        module.quizzes.length +
        module.assignments.length;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpanded
                    ? (isDark
                          ? gradientColors[0].withValues(alpha: 0.12)
                          : gradientColors[0].withValues(alpha: 0.06))
                    : (isDark
                          ? AppTheme.darkBackgroundSecondary.withValues(
                              alpha: 0.6,
                            )
                          : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isExpanded
                      ? gradientColors[0].withValues(alpha: 0.4)
                      : (isDark
                            ? AppTheme.darkBorderColor.withValues(alpha: 0.3)
                            : Colors.grey.shade200),
                  width: isExpanded ? 1.5 : 1,
                ),
                boxShadow: isExpanded
                    ? [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Number badge with gradient
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${module.orderIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title & subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                        if (totalItems > 0) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (module.lessons.isNotEmpty)
                                _buildModuleCountChip(
                                  Icons.play_circle_outline,
                                  '${module.lessons.length} bài học',
                                  gradientColors[0],
                                ),
                              if (module.quizzes.isNotEmpty)
                                _buildModuleCountChip(
                                  Icons.quiz_outlined,
                                  '${module.quizzes.length} quiz',
                                  Colors.amber,
                                ),
                              if (module.assignments.isNotEmpty)
                                _buildModuleCountChip(
                                  Icons.assignment_outlined,
                                  '${module.assignments.length} bài tập',
                                  AppTheme.themeOrangeStart,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Animated chevron
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    turns: isExpanded ? 0.5 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: gradientColors[0].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: gradientColors[0],
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          if (module.description != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBackgroundSecondary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                module.description!,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          // Lessons
          ...module.lessons.asMap().entries.map((entry) {
            final lesson = entry.value;
            final isReading = lesson.type == LessonType.reading;
            return _buildContentItem(
              icon: isReading
                  ? Icons.menu_book_outlined
                  : Icons.play_circle_outline,
              typeLabel: 'BÀI HỌC ${entry.key + 1}',
              title: lesson.title,
              meta: isReading ? 'Bài đọc' : null,
              color: gradientColors[0],
            );
          }),
          // Quizzes
          ...module.quizzes.map((quiz) {
            return _buildContentItem(
              icon: Icons.quiz_outlined,
              typeLabel: 'BÀI KIỂM TRA',
              title: quiz.title ?? 'Bài kiểm tra',
              meta: '${quiz.questionCount} câu hỏi',
              color: Colors.amber,
            );
          }),
          // Assignments
          ...module.assignments.map((assignment) {
            return _buildContentItem(
              icon: Icons.assignment_outlined,
              typeLabel: 'BÀI TẬP',
              title: assignment.title ?? 'Bài tập',
              meta: '${assignment.maxScore} điểm',
              color: AppTheme.themeOrangeStart,
            );
          }),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContentItem({
    required IconData icon,
    required String typeLabel,
    required String title,
    String? meta,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBackgroundSecondary.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (meta != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                meta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCountChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
