import 'package:flutter/foundation.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/task_board_models.dart';
import '../../data/models/study_planner_models.dart';
import '../../data/services/task_board_service.dart';
import '../../data/services/study_planner_service.dart';

/// Task Board Provider for state management
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class TaskBoardProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final TaskBoardService _taskBoardService;
  final StudyPlannerService _studyPlannerService;

  TaskBoardProvider({
    TaskBoardService? taskBoardService,
    StudyPlannerService? studyPlannerService,
  }) : _taskBoardService = taskBoardService ?? TaskBoardService(),
       _studyPlannerService = studyPlannerService ?? StudyPlannerService();

  // State (chỉ giữ domain data — loading/error do mixin quản lý)
  List<TaskColumn> _columns = [];
  List<DashboardNote> _notes = [];
  List<StudySessionResponse> _sessions = [];
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  int _selectedTabIndex = 1; // 0: AI, 1: Timeline, 2: Kanban

  // Getters
  List<TaskColumn> get columns => _columns;
  List<DashboardNote> get notes => _notes;
  List<StudySessionResponse> get sessions => _sessions;
  DateTime get selectedWeekStart => _selectedWeekStart;
  String? get error => errorMessage; // Alias for backward compatibility
  int get selectedTabIndex => _selectedTabIndex;

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
    final now = DateTime.now();
    return _columns
        .expand((col) => col.tasks)
        .where(
          (task) =>
              task.deadline != null &&
              task.deadline!.isBefore(now) &&
              (task.isOverdue || true),
        ) // Check if not completed
        .length;
  }

  // ==================== TASKS ====================

  /// Create a new task
  Future<void> createTask(CreateTaskRequest request) async {
    await executeAsync(() async {
      final response = await _taskBoardService.createTask(request);
      final task = response.toTask();

      // Add to appropriate column
      final columnId = request.columnId ?? 'todo';
      final columnIndex = _columns.indexWhere((c) => c.id == columnId);
      if (columnIndex != -1) {
        final column = _columns[columnIndex];
        _columns[columnIndex] = column.copyWith(tasks: [...column.tasks, task]);
      }

      notifyListeners();
    }, errorMessageBuilder: (e) {
      debugPrint('❌ TaskBoardProvider Error: $e');
      return 'Không thể tạo nhiệm vụ: $e';
    });
  }

  /// Update a task
  Future<void> updateTask(String taskId, UpdateTaskRequest request) async {
    await executeAsync(() async {
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
    }, errorMessageBuilder: (e) {
      debugPrint('❌ TaskBoardProvider Error: $e');
      return 'Không thể cập nhật nhiệm vụ: $e';
    });
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await executeAsync(() async {
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
    }, errorMessageBuilder: (e) {
      debugPrint('❌ TaskBoardProvider Error: $e');
      return 'Không thể xóa nhiệm vụ: $e';
    });
  }

  /// Move task to another column
  Future<void> moveTask(String taskId, String targetColumnId) async {
    try {
      await _taskBoardService.moveTask(taskId, targetColumnId);

      // Move locally
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

      if (taskToMove != null && sourceColumnIndex != -1) {
        // Remove from source
        final sourceTasks = _columns[sourceColumnIndex].tasks
            .where((t) => t.id != taskId)
            .toList();
        _columns[sourceColumnIndex] = _columns[sourceColumnIndex].copyWith(
          tasks: sourceTasks,
        );

        // Add to target
        final targetIndex = _columns.indexWhere((c) => c.id == targetColumnId);
        if (targetIndex != -1) {
          final movedTask = taskToMove.copyWith(columnId: targetColumnId);
          _columns[targetIndex] = _columns[targetIndex].copyWith(
            tasks: [..._columns[targetIndex].tasks, movedTask],
          );
        }

        notifyListeners();
      }
    } catch (e) {
      setError('Không thể di chuyển nhiệm vụ: $e');
      debugPrint('❌ TaskBoardProvider Error: $e');
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

  // ==================== STUDY PLANNER ====================

  /// Load study sessions
  Future<void> loadSessions() async {
    try {
      _sessions = await _studyPlannerService.getSessions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  /// Generate AI schedule proposal
  Future<List<StudySessionResponse>> generateProposal(
    GenerateScheduleRequest request,
  ) async {
    final result = await executeAsync(() async {
      final generatedSessions = await _studyPlannerService.generateProposal(
        request,
      );
      _sessions = [..._sessions, ...generatedSessions];
      notifyListeners();
      return generatedSessions;
    }, errorMessageBuilder: (e) {
      debugPrint('❌ TaskBoardProvider Error: $e');
      return 'Không thể tạo lịch học: $e';
    });
    return result ?? [];
  }

  /// Update session status
  Future<void> updateSessionStatus(String sessionId, String status) async {
    try {
      await _studyPlannerService.updateSessionStatus(sessionId, status);

      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        // Update locally - create new session with updated status
        final oldSession = _sessions[index];
        _sessions[index] = StudySessionResponse(
          id: oldSession.id,
          subject: oldSession.subject,
          topic: oldSession.topic,
          startTime: oldSession.startTime,
          endTime: oldSession.endTime,
          durationMinutes: oldSession.durationMinutes,
          status: status,
          notes: oldSession.notes,
        );
        notifyListeners();
      }
    } catch (e) {
      setError('Không thể cập nhật trạng thái: $e');
      debugPrint('❌ TaskBoardProvider Error: $e');
    }
  }

  /// Get sessions for a specific day
  List<StudySessionResponse> getSessionsForDay(DateTime date) {
    return _sessions.where((session) {
      return session.startTime.year == date.year &&
          session.startTime.month == date.month &&
          session.startTime.day == date.day;
    }).toList();
  }

  // ==================== HELPERS ====================

  void clearError() => super.clearError();
}
