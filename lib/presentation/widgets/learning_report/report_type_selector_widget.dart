import 'package:flutter/material.dart';
import '../../../data/models/learning_report_model.dart';
import '../../themes/app_theme.dart';

/// Dropdown selector for report type.
/// Shows 5 types with emoji indicators.
class ReportTypeSelectorWidget extends StatelessWidget {
  final ReportType value;
  final ValueChanged<ReportType> onChanged;
  final bool isDark;

  const ReportTypeSelectorWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  static final _types = [
    (ReportType.comprehensive, '📋', 'Toàn diện', Color(0xFF8B5CF6)),
    (ReportType.weeklySummary, '📅', 'Tuần', Color(0xFF3B82F6)),
    (ReportType.monthlySummary, '🗓️', 'Tháng', Color(0xFF10B981)),
    (ReportType.skillAssessment, '🎯', 'Kỹ năng', Color(0xFFF59E0B)),
    (ReportType.goalTracking, '🏁', 'Mục tiêu', Color(0xFFEC4899)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportType>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
          dropdownColor: isDark ? AppTheme.galaxyMid : Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
          items: _types.map((type) {
            return DropdownMenuItem(
              value: type.$1,
              child: Row(
                children: [
                  Text(type.$2, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: type.$4.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.$3,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: type.$4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
