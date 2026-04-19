import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../data/models/task_board_models.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../widgets/common_loading.dart';

class TaskArchiveSheet extends StatefulWidget {
  const TaskArchiveSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaskArchiveSheet(),
    );
  }

  @override
  State<TaskArchiveSheet> createState() => _TaskArchiveSheetState();
}

class _TaskArchiveSheetState extends State<TaskArchiveSheet> {
  bool _isLoading = true;
  List<Task> _archivedTasks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArchivedTasks();
    });
  }

  Future<void> _loadArchivedTasks() async {
    try {
      final data = await context.read<TaskBoardProvider>().getArchivedTasks();
      if (mounted && data != null) {
        final content = data['items'] as List<dynamic>?;
        setState(() {
          _archivedTasks = content?.map((j) => Task.fromJson(j)).toList() ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unarchive(Task task) async {
    try {
      await context.read<TaskBoardProvider>().unarchiveTask(task.id);
      if (mounted) {
        setState(() {
          _archivedTasks.removeWhere((t) => t.id == task.id);
        });
        ErrorHandler.showSuccessSnackBar(context, 'Đã khôi phục nhiệm vụ');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackgroundPrimary : AppTheme.lightBackgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppTheme.accentOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Thùng rác & Lưu trữ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_archivedTasks.length}',
                        style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CommonLoading())
                    : _archivedTasks.isEmpty
                        ? Center(
                            child: Text(
                              'Không có nhiệm vụ lưu trữ',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _archivedTasks.length,
                            itemBuilder: (context, index) {
                              final task = _archivedTasks[index];
                              return Card(
                                color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: (isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.lineThrough,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  subtitle: task.description?.isNotEmpty == true
                                      ? Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                                      : null,
                                  trailing: FilledButton.icon(
                                    onPressed: () => _unarchive(task),
                                    icon: const Icon(Icons.restore, size: 16),
                                    label: const Text('Khôi phục', style: TextStyle(fontSize: 12)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
