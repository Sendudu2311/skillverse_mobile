import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// Section title map for navigation chips.
const kReportSectionTitles = <String, String>{
  'currentSkills': 'Kỹ năng',
  'learningGoals': 'Mục tiêu',
  'progressSummary': 'Tiến độ',
  'strengths': 'Điểm mạnh',
  'areasToImprove': 'Cải thiện',
  'recommendations': 'Khuyến nghị',
  'skillGaps': 'Khoảng trống',
  'nextSteps': 'Bước tiếp',
  'motivation': 'Động lực',
};

/// Horizontal scrollable chips for navigating between report sections.
class SectionNavigationWidget extends StatelessWidget {
  final List<String> sections;
  final String activeSection;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const SectionNavigationWidget({
    super.key,
    required this.sections,
    required this.activeSection,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = sections[index];
          final label = kReportSectionTitles[key] ?? key;
          final isActive = activeSection == key;

          return _SectionChip(
            label: label,
            isActive: isActive,
            isDark: isDark,
            onTap: () => onChanged(key),
          );
        },
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _SectionChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryBlueDark
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryBlueDark
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.12)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? Colors.white
                  : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
