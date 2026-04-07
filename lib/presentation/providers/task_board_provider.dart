import 'package:flutter/foundation.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/task_board_models.dart';
import '../../data/services/task_board_service.dart';

/// Task Board Provider for state management
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class TaskBoardProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final TaskBoardService _taskBoardService;

  TaskBoardProvider({TaskBoardService? taskBoardService})
    : _taskBoardService = taskBoardService ?? TaskBoardService();

  // State
  List<TaskColumn> _columns = [];
  List<DashboardNote> _notes = [];
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  int _selectedTabIndex = 1; // 0: AI, 1: Timeline, 2: Kanban

  // Getters
  List<TaskColumn> get columns => _columns;
  List<DashboardNote> get notes => _notes;
  DateTime get selectedWeekStart => _selectedWeekStart;
  String? get error => errorMessage;
  int get selectedTabIndex => _selectedTabIndex;

  /// All tasks flattened from columns — used by TimelineView
  List<Task> get allTasks => _columns.expand((col) => col.tasks).toList();

  // Default columns
  static const List<Map<String, String>> defaultColumns = [
    {'id': 'todo', 'name': 'TO DO', 'color': '#3B82F6'},
    {'id': 'inprogress', 'name': 'IN PROGRESS', 'color': '#F59E0B'},
    {'id': 'done', 'name': 'DONE', 'color': '#10B981'},
    {'id': 'overdue', 'name': 'OVERDUE', 'color': '#DC2626'},
  ];

  // Get week start (Monday)
  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  // Tab management
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Week navigation
  void goToPreviousWeek() {
    _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    notifyListeners();
  }

  void goToNextWeek() {
    _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    notifyListeners();
  }

  void goToCurrentWeek() {
    _selectedWeekStart = _getWeekStart(DateTime.now());
    notifyListeners();
  }

  // Load board data from backend
  Future<void> loadBoard() async {
    setLoading(true);
    try {
      final boardData = await _taskBoardService.getBoard();
      _columns = boardData.map((col) => col.toTaskColumn()).toList();

      // If no columns, initialize with defaults
      if (_columns.isEmpty) {
        _columns = _buildDefaultColumns();
      }

      setLoading(false);
    } catch (e) {
      debugPrint('Error loading board: $e');
      // Fallback to default columns on error
      _columns = _buildDefaultColumns();
      setLoading(false);
    }
  }

  List<TaskColumn> _buildDefaultColumns() {
    return defaultColumns
        .map(
          (col) => TaskColumn(
            id: col['id']!,
            name: col['name']!,
            color: col['color'],
            tasks: [],
          ),
        )
        .toList();
  }

  // Get overdue count
  int get overdueCount {
    return allTasks.where((task) => task.isOverdue).length;
  }

  // ==================== TASKS ====================

  /// Create a new task
  Future<void> createTask(CreateTaskRequest request) async {
    await executeAsync(
      () async {
        final response = await _taskBoardService.createTask(request);
        final task = response.toTask();

        // Add to appropriate column
        final columnId = request.columnId ?? 'todo';
        final columnIndex = _columns.indexWhere((c) => c.id == columnId);
        if (columnIndex != -1) {
          final column = _columns[columnIndex];
          _columns[columnIndex] = column.copyWith(
            tasks: [...column.tasks, task],
          );
        }

        notifyListeners();
      },
      errorMessageBuilder: (e) {
        debugPrint('❌ TaskBoardProvider Error: $e');
        return 'Không thể tạo nhiệm vụ: $e';
      },
    );
  }

  /// Update a task
  Future<void> updateTask(String taskId, UpdateTaskRequest request) async {
    await executeAsync(
      () async {
        final response = await _taskBoardService.updateTask(taskId, request);
        final updatedTask = response.toTask();

        // Update in columns
        for (int i = 0; i < _columns.length; i++) {
          final taskIndex = _columns[i].tasks.indexWhere((t) => t.id == taskId);
          if (taskIndex != -1) {
            final updatedTasks = List<Task>.from(_columns[i].tasks);
            updatedTasks[taskIndex] = updatedTask;
            _columns[i] = _columns[i].copyWith(tasks: updatedTasks);
            break;
          }
        }

        notifyListeners();
      },
      errorMessageBuilder: (e) {
        debugPrint('❌ TaskBoardProvider Error: $e');
        return 'Không thể cập nhật nhiệm vụ: $e';
      },
    );
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await executeAsync(
      () async {
        await _taskBoardService.deleteTask(taskId);

        // Remove from columns
        for (int i = 0; i < _columns.length; i++) {
          final updatedTasks = _columns[i].tasks
              .where((t) => t.id != taskId)
              .toList();
          if (updatedTasks.length != _columns[i].tasks.length) {
            _columns[i] = _columns[i].copyWith(tasks: updatedTasks);
            break;
          }
        }

        notifyListeners();
      },
      errorMessageBuilder: (e) {
        debugPrint('❌ TaskBoardProvider Error: $e');
        return 'Không thể xóa nhiệm vụ: $e';
      },
    );
  }

  /// Move task to another column (Optimistic UI)
  Future<void> moveTask(String taskId, String targetColumnId) async {
    // 1. Prepare for local update
    Task? taskToMove;
    int sourceColumnIndex = -1;

    for (int i = 0; i < _columns.length; i++) {
      final taskIndex = _columns[i].tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        taskToMove = _columns[i].tasks[taskIndex];
        sourceColumnIndex = i;
        break;
      }
    }

    if (taskToMove == null || sourceColumnIndex == -1) return;

    // 2. Perform local update immediately (Optimistic)
    final targetIndex = _columns.indexWhere((c) => c.id == targetColumnId);
    if (targetIndex != -1) {
      final targetColumn = _columns[targetIndex];

      // Update both columnId and display status tag
      final movedTask = taskToMove.copyWith(
        columnId: targetColumnId,
        status: targetColumn.name, // Immediate tag update
      );

      // Remove from source
      final updatedSourceTasks = _columns[sourceColumnIndex].tasks
          .where((t) => t.id != taskId)
          .toList();
      _columns[sourceColumnIndex] = _columns[sourceColumnIndex].copyWith(
        tasks: updatedSourceTasks,
      );

      // Add to target
      _columns[targetIndex] = targetColumn.copyWith(
        tasks: [...targetColumn.tasks, movedTask],
      );

      notifyListeners();
    }

    // 3. Call API in the background
    try {
      await _taskBoardService.moveTask(taskId, targetColumnId);
      debugPrint('✅ Task $taskId moved to $targetColumnId successfully');
    } catch (e) {
      debugPrint('❌ TaskBoardProvider Move Error: $e');
      setError('Không thể di chuyển nhiệm vụ: $e');
      // Rollback: Reload from server on failure
      await loadBoard();
    }
  }

  /// Add task locally (for optimistic updates)
  void addTaskLocally(Task task) {
    final columnId = task.columnId ?? 'todo';
    final columnIndex = _columns.indexWhere((c) => c.id == columnId);
    if (columnIndex != -1) {
      _columns[columnIndex] = _columns[columnIndex].copyWith(
        tasks: [..._columns[columnIndex].tasks, task],
      );
      notifyListeners();
    }
  }

  // ==================== NOTES ====================

  /// Load notes
  Future<void> loadNotes() async {
    try {
      _notes = await _taskBoardService.getNotes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }

  /// Create note
  Future<void> createNote(String content) async {
    try {
      final note = await _taskBoardService.createNote(content);
      _notes.add(note);
      notifyListeners();
    } catch (e) {
      setError('Không thể tạo ghi chú: $e');
      debugPrint('❌ TaskBoardProvider Error: $e');
    }
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      await _taskBoardService.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
    } catch (e) {
      setError('Không thể xóa ghi chú: $e');
      debugPrint('❌ TaskBoardProvider Error: $e');
    }
  }

  // ==================== CLEAR OVERDUE ====================

  /// Clear overdue tasks
  Future<Map<String, dynamic>> clearOverdueTasks({
    int overdueDays = 30,
    String? columnId,
  }) async {
    final result = await executeAsync(
      () async {
        final response = await _taskBoardService.clearOverdueTasks(
          overdueDays: overdueDays,
          columnId: columnId,
        );
        // Reload board after clearing
        await loadBoard();
        return response;
      },
      errorMessageBuilder: (e) {
        debugPrint('❌ TaskBoardProvider Error: $e');
        return 'Không thể xóa task quá hạn: $e';
      },
    );
    return result ?? {};
  }

  // ==================== HELPERS ====================

  /// Get tasks for a specific day — used by TimelineView
  List<Task> getTasksForDay(DateTime date) {
    return allTasks.where((task) {
      // Check startDate
      if (task.startDate != null) {
        return task.startDate!.year == date.year &&
            task.startDate!.month == date.month &&
            task.startDate!.day == date.day;
      }
      // Fallback to deadline
      if (task.deadline != null) {
        return task.deadline!.year == date.year &&
            task.deadline!.month == date.month &&
            task.deadline!.day == date.day;
      }
      return false;
    }).toList();
  }
}
