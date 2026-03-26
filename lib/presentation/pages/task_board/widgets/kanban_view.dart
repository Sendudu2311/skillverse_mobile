import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../data/models/task_board_models.dart';
import 'task_detail_sheet.dart';

class KanbanView extends StatelessWidget {
  const KanbanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: provider.columns.length,
          itemBuilder: (context, index) {
            final column = provider.columns[index];
            return KanbanColumn(
              column: column,
              onAddTask: () => TaskDetailSheet.show(context, columnId: column.id),
            );
          },
        );
      },
    );
  }
}

class KanbanColumn extends StatelessWidget {
  final TaskColumn column;
  final VoidCallback onAddTask;

  const KanbanColumn({
    super.key,
    required this.column,
    required this.onAddTask,
  });

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
          _buildHeader(isDark),
          DragTarget<Task>(
            onAcceptWithDetails: (details) {
              final task = details.data;
              if (task.columnId != column.id) {
                context.read<TaskBoardProvider>().moveTask(task.id, column.id);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: candidateData.isNotEmpty
                    ? BoxDecoration(
                        color: _columnColor.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      )
                    : null,
                child: Column(
                  children: [
                    if (column.tasks.isEmpty) _buildEmptyState(isDark),
                    ...column.tasks.map(
                      (task) => DraggableTaskCard(task: task),
                    ),
                    _buildAddButton(isDark),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _columnColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${column.tasks.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _columnColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Chưa có nhiệm vụ',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return InkWell(
      onTap: onAddTask,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppTheme.darkBorderColor
                  : AppTheme.lightBorderColor,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 15,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Thêm nhiệm vụ',
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
    );
  }
}

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
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 48,
            child: Opacity(
              opacity: 0.85,
              child: _buildCard(isDark),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: _buildCard(isDark),
        ),
        child: _buildCard(isDark),
      ),
    );
  }

  Widget _buildCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _priorityColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
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

          // Description
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // User Notes
          if (task.userNotes != null && task.userNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.themeOrangeStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.themeOrangeStart.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 11,
                    color: AppTheme.themeOrangeStart,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.userNotes!,
                      style: TextStyle(
                        fontSize: 10,
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
            const SizedBox(height: 8),
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
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Status + satisfaction + deadline row
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
                    color: _priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.status!,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: _priorityColor,
                    ),
                  ),
                ),
              const Spacer(),
              if (task.satisfactionLevel != null) ...[
                Icon(
                  task.satisfactionLevel == 'Satisfied'
                      ? Icons.sentiment_satisfied
                      : task.satisfactionLevel == 'Unsatisfied'
                          ? Icons.sentiment_dissatisfied
                          : Icons.sentiment_neutral,
                  size: 16,
                  color: task.satisfactionLevel == 'Satisfied'
                      ? Colors.green
                      : task.satisfactionLevel == 'Unsatisfied'
                          ? Colors.red
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
              ],
              if (task.deadline != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: task.isOverdue
                          ? Colors.red
                          : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: task.isOverdue
                            ? Colors.red
                            : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
