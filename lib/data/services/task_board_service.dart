import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/task_board_models.dart';

/// Task Board API Service
class TaskBoardService {
  final ApiClient _apiClient;

  TaskBoardService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== BOARD ====================

  /// Get board with all columns and tasks
  Future<List<TaskColumnResponse>> getBoard() async {
    try {
      final response = await _apiClient.dio.get('/task-board');
      final List<dynamic> data = response.data;
      return data.map((json) => TaskColumnResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting board: $e');
      rethrow;
    }
  }

  // ==================== TASKS ====================

  /// Create a new task
  Future<TaskResponse> createTask(CreateTaskRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/task-board/tasks',
        data: request.toJson(),
      );
      return TaskResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error creating task: $e');
      rethrow;
    }
  }

  /// Update a task
  Future<TaskResponse> updateTask(
    String taskId,
    UpdateTaskRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.patch(
        '/task-board/tasks/$taskId',
        data: request.toJson(),
      );
      return TaskResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error updating task: $e');
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _apiClient.dio.delete('/task-board/tasks/$taskId');
    } catch (e) {
      debugPrint('❌ Error deleting task: $e');
      rethrow;
    }
  }

  /// Move a task to another column
  Future<void> moveTask(String taskId, String targetColumnId) async {
    try {
      await _apiClient.dio.patch(
        '/task-board/tasks/$taskId/move',
        queryParameters: {'targetColumnId': targetColumnId},
      );
    } catch (e) {
      debugPrint('❌ Error moving task: $e');
      rethrow;
    }
  }

  /// Check overdue tasks
  Future<void> checkOverdueTasks() async {
    try {
      await _apiClient.dio.post('/task-board/check-overdue');
    } catch (e) {
      debugPrint('❌ Error checking overdue tasks: $e');
      rethrow;
    }
  }

  /// Clear overdue tasks
  Future<Map<String, dynamic>> clearOverdueTasks({
    int overdueDays = 30,
    String? columnId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '/task-board/tasks/clear-overdue',
        queryParameters: {
          'overdueDays': overdueDays,
          if (columnId != null) 'columnId': columnId,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error clearing overdue tasks: $e');
      rethrow;
    }
  }

  // ==================== COLUMNS ====================

  /// Create a new column
  Future<TaskColumnResponse> createColumn(String name, {String? color}) async {
    try {
      final response = await _apiClient.dio.post(
        '/task-board/columns',
        queryParameters: {'name': name, if (color != null) 'color': color},
      );
      return TaskColumnResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error creating column: $e');
      rethrow;
    }
  }

  /// Update a column
  Future<TaskColumnResponse> updateColumn(
    String columnId, {
    String? name,
    String? color,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/task-board/columns/$columnId',
        queryParameters: {
          if (name != null) 'name': name,
          if (color != null) 'color': color,
        },
      );
      return TaskColumnResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error updating column: $e');
      rethrow;
    }
  }

  // ==================== NOTES ====================

  /// Get all notes
  Future<List<DashboardNote>> getNotes() async {
    try {
      final response = await _apiClient.dio.get('/task-board/notes');
      final List<dynamic> data = response.data;
      return data.map((json) => DashboardNote.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting notes: $e');
      rethrow;
    }
  }

  /// Create a new note
  Future<DashboardNote> createNote(String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/task-board/notes',
        data: content,
      );
      return DashboardNote.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error creating note: $e');
      rethrow;
    }
  }

  /// Update a note
  Future<DashboardNote> updateNote(String noteId, String content) async {
    try {
      final response = await _apiClient.dio.patch(
        '/task-board/notes/$noteId',
        data: content,
      );
      return DashboardNote.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error updating note: $e');
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _apiClient.dio.delete('/task-board/notes/$noteId');
    } catch (e) {
      debugPrint('❌ Error deleting note: $e');
      rethrow;
    }
  }
}
