import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../data/models/study_planner_models.dart';

/// Timeline View - Week Calendar
class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Month Navigation
            _buildMonthNavigation(context, provider),

            // Week Header
            _buildWeekHeader(context, provider),

            // Time Grid
            Expanded(child: _buildTimeGrid(context, provider)),
          ],
        );
      },
    );
  }

  Widget _buildMonthNavigation(
    BuildContext context,
    TaskBoardProvider provider,
  ) {
    // Use English locale to avoid LocaleDataException
    final monthYear = DateFormat(
      'MMMM yyyy',
    ).format(provider.selectedWeekStart).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavButton(
            context,
            Icons.chevron_left,
            () => provider.goToPreviousWeek(),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => provider.goToCurrentWeek(),
            child: Text(
              monthYear,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppTheme.primaryBlueDark,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildNavButton(
            context,
            Icons.chevron_right,
            () => provider.goToNextWeek(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryBlueDark, width: 1),
        ),
        child: Icon(icon, color: AppTheme.primaryBlueDark, size: 20),
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context, TaskBoardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekStart = provider.selectedWeekStart;
    final today = DateTime.now();

    final days = ['TIME', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: List.generate(8, (index) {
          if (index == 0) {
            return SizedBox(
              width: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            );
          }

          final dayDate = weekStart.add(Duration(days: index - 1));
          final isToday =
              dayDate.year == today.year &&
              dayDate.month == today.month &&
              dayDate.day == today.day;
          final isSunday = index == 7;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: isToday
                  ? BoxDecoration(
                      color: AppTheme.primaryBlueDark.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: isSunday
                          ? Colors.red
                          : (isToday
                                ? AppTheme.primaryBlueDark
                                : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dayDate.day}/${dayDate.month}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: isSunday
                          ? Colors.red.withValues(alpha: 0.7)
                          : (isToday
                                ? AppTheme.primaryBlueDark.withValues(
                                    alpha: 0.8,
                                  )
                                : (isDark
                                      ? AppTheme.darkTextSecondary.withValues(
                                          alpha: 0.7,
                                        )
                                      : AppTheme.lightTextSecondary.withValues(
                                          alpha: 0.7,
                                        ))),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeGrid(BuildContext context, TaskBoardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = List.generate(19, (i) => i + 4); // 04:00 - 22:00
    final weekStart = provider.selectedWeekStart;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: hours.map((hour) {
            return Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        (isDark
                                ? AppTheme.darkBorderColor
                                : AppTheme.lightBorderColor)
                            .withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Time label
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                  // Day columns
                  ...List.generate(7, (dayIndex) {
                    final dayDate = weekStart.add(Duration(days: dayIndex));
                    final sessions = provider.getSessionsForDay(dayDate);
                    final sessionAtHour = sessions
                        .where((s) => s.startTime.hour == hour)
                        .toList();

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color:
                                  (isDark
                                          ? AppTheme.darkBorderColor
                                          : AppTheme.lightBorderColor)
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: sessionAtHour.isEmpty
                            ? const SizedBox()
                            : _buildSessionCard(context, sessionAtHour.first),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, StudySessionResponse session) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            session.subject ?? 'Task',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            DateFormat('HH:mm').format(session.startTime),
            style: const TextStyle(
              fontSize: 8,
              fontFamily: 'monospace',
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
