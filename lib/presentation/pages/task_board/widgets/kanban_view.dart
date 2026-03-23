import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../data/models/task_board_models.dart';
import 'task_detail_sheet.dart';

/// Kanban View - Horizontal scrollable rows with drag & drop
class KanbanView extends StatelessWidget {
  const KanbanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.columns.length,
          itemBuilder: (context, index) {
            final column = provider.columns[index];
            return KanbanRow(
              column: column,
              onAddTask: () => _showCreateTaskDialog(context, column.id),
            );
          },
        );
      },
    );
  }

  void _showCreateTaskDialog(BuildContext context, String columnId) {
    TaskDetailSheet.show(context, columnId: columnId);
  }
}

/// Kanban Row Widget - Horizontal scrollable row
class KanbanRow extends StatelessWidget {
  final TaskColumn column;
  final VoidCallback onAddTask;

  const KanbanRow({super.key, required this.column, required this.onAddTask});

  Color get _columnColor {
    if (column.color != null) {
      try {
        return Color(int.parse(column.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppTheme.primaryBlueDark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Row Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _columnColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    column.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: _columnColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  '(${column.tasks.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ],
            ),
          ),

          // Horizontal Scrollable Tasks
          SizedBox(
            height: 200,
            child: DragTarget<Task>(
              onAcceptWithDetails: (details) {
                final task = details.data;
                if (task.columnId != column.id) {
                  context.read<TaskBoardProvider>().moveTask(
                    task.id,
                    column.id,
                  );
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: candidateData.isNotEmpty
                      ? BoxDecoration(
                          color: _columnColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        )
                      : null,
                  child: column.tasks.isEmpty
                      ? Center(
                          child: GestureDetector(
                            onTap: onAddTask,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Thêm Nhiệm Vụ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          itemCount: column.tasks.length + 1,
                          itemBuilder: (context, index) {
                            if (index == column.tasks.length) {
                              // Add task button at the end
                              return GestureDetector(
                                onTap: onAddTask,
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? AppTheme.darkBorderColor
                                          : AppTheme.lightBorderColor,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 20,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Thêm',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final task = column.tasks[index];
                            return DraggableTaskCard(task: task);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Draggable Task Card Widget
class DraggableTaskCard extends StatelessWidget {
  final Task task;

  const DraggableTaskCard({super.key, required this.task});

  Color get _priorityColor {
    switch (task.priority) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => TaskDetailSheet.show(
        context,
        task: task,
        columnId: task.columnId ?? '',
      ),
      child: Draggable<Task>(
        data: task,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: 0.8,
            child: _buildTaskCard(context, isDark, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildTaskCard(context, isDark),
        ),
        child: _buildTaskCard(context, isDark),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    bool isDark, {
    bool isDragging = false,
  }) {
    return Container(
      width: isDragging ? 220 : 200,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _priorityColor, width: 3)),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            task.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Description
          if (task.description != null) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // User Notes
          if (task.userNotes != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.themeOrangeStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.themeOrangeStart.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, size: 10, color: AppTheme.themeOrangeStart),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.userNotes!,
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: AppTheme.themeOrangeStart,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress bar
          if (task.userProgress != null && task.userProgress! > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: task.userProgress! / 100,
                      minHeight: 4,
                      backgroundColor: _priorityColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(_priorityColor),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${task.userProgress}%',
                  style: TextStyle(
                    fontSize: 9, fontFamily: 'monospace',
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Status + Satisfaction row
          const SizedBox(height: 6),
          Row(
            children: [
              // Status badge
              if (task.status != null) ...[  
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.status!,
                    style: TextStyle(fontSize: 8, fontFamily: 'monospace', color: _priorityColor),
                  ),
                ),
              ],
              const Spacer(),
              // Satisfaction icon
              if (task.satisfactionLevel != null)
                Icon(
                  task.satisfactionLevel == 'Satisfied'
                      ? Icons.sentiment_satisfied
                      : task.satisfactionLevel == 'Unsatisfied'
                          ? Icons.sentiment_dissatisfied
                          : Icons.sentiment_neutral,
                  size: 14,
                  color: task.satisfactionLevel == 'Satisfied'
                      ? Colors.green
                      : task.satisfactionLevel == 'Unsatisfied'
                          ? Colors.red
                          : Colors.orange,
                ),
            ],
          ),

          // Deadline
          if (task.deadline != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.access_time, size: 11,
                  color: task.isOverdue ? Colors.red
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
                const SizedBox(width: 4),
                Text(
                  '${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}',
                  style: TextStyle(
                    fontSize: 10, fontFamily: 'monospace',
                    color: task.isOverdue ? Colors.red
                        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
