import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../data/models/task_board_models.dart';
import 'task_detail_sheet.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  static const _vnDays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];

  String _formatSelectedDay(DateTime d) {
    final dayName = _vnDays[d.weekday - 1];
    return '$dayName, ${d.day}/${d.month}/${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _weekStart(DateTime d) {
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  void _goToPreviousWeek(TaskBoardProvider provider) {
    provider.goToPreviousWeek();
    setState(() {
      _selectedDay = _weekStart(_selectedDay).subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek(TaskBoardProvider provider) {
    provider.goToNextWeek();
    setState(() {
      _selectedDay = _weekStart(_selectedDay).add(const Duration(days: 7));
    });
  }

  void _goToCurrentWeek(TaskBoardProvider provider) {
    provider.goToCurrentWeek();
    final now = DateTime.now();
    setState(() {
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _buildWeekNav(context, provider),
            _buildDayTabs(context, provider),
            const Divider(height: 1, thickness: 0.5),
            Expanded(child: _buildDayTaskList(context, provider)),
          ],
        );
      },
    );
  }

  Widget _buildWeekNav(BuildContext context, TaskBoardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekStart = _weekStart(_selectedDay);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final label =
        weekStart.month == weekEnd.month
            ? DateFormat('MMMM yyyy').format(weekStart).toUpperCase()
            : '${DateFormat('MMM').format(weekStart)} – ${DateFormat('MMM yyyy').format(weekEnd)}'.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildNavButton(context, Icons.chevron_left, isDark, () => _goToPreviousWeek(provider)),
          Expanded(
            child: GestureDetector(
              onTap: () => _goToCurrentWeek(provider),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: AppTheme.primaryBlueDark,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          _buildNavButton(context, Icons.chevron_right, isDark, () => _goToNextWeek(provider)),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryBlueDark),
        ),
        child: Icon(icon, color: AppTheme.primaryBlueDark, size: 20),
      ),
    );
  }

  Widget _buildDayTabs(BuildContext context, TaskBoardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekStart = _weekStart(_selectedDay);
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected = _isSameDay(day, _selectedDay);
          final isToday = _isSameDay(day, today);
          final isSunday = index == 6;
          final hasTasks = provider.getTasksForDay(day).isNotEmpty;

          final textColor = isSelected
              ? Colors.white
              : isSunday
                  ? Colors.red
                  : isToday
                      ? AppTheme.primaryBlueDark
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlueDark
                      : isToday
                          ? AppTheme.primaryBlueDark.withValues(alpha: 0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: AppTheme.primaryBlueDark.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayLabels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasTasks
                            ? (isSelected ? Colors.white : AppTheme.accentCyan)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayTaskList(BuildContext context, TaskBoardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var tasks = List<Task>.from(provider.getTasksForDay(_selectedDay));

    // Sort by startDate, fallback to deadline
    tasks.sort((a, b) {
      final aTime = a.startDate ?? a.deadline;
      final bTime = b.startDate ?? b.deadline;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Không có nhiệm vụ nào',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatSelectedDay(_selectedDay),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskRow(context, tasks[index], isDark);
      },
    );
  }

  Widget _buildTaskRow(BuildContext context, Task task, bool isDark) {
    final time = task.startDate ?? task.deadline;
    final timeLabel = time != null ? DateFormat('HH:mm').format(time) : '--:--';
    final color = _priorityColor(task.priority);

    return GestureDetector(
      onTap: () => TaskDetailSheet.show(context, task: task, columnId: task.columnId ?? ''),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: 44,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: task.isOverdue
                        ? Colors.red
                        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Timeline dot + line
            Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: color.withValues(alpha: 0.2),
                ),
              ],
            ),

            const SizedBox(width: 10),

            // Task card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCardBackground
                      : AppTheme.lightCardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        if (task.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.status!,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: color,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (task.userProgress != null && task.userProgress! > 0) ...[
                          SizedBox(
                            width: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: task.userProgress! / 100,
                                minHeight: 4,
                                backgroundColor: color.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${task.userProgress}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
