import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/study_planner_models.dart';

/// Study Planner API Service for AI-generated schedules
class StudyPlannerService {
  final ApiClient _apiClient;

  StudyPlannerService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Generate AI study proposal
  Future<List<StudySessionResponse>> generateProposal(
    GenerateScheduleRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/study-planner/generate-proposal',
        data: request.toJson(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => StudySessionResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error generating proposal: $e');
      rethrow;
    }
  }

  /// Generate full AI schedule (alternative endpoint)
  Future<List<StudySessionResponse>> generateSchedule(
    GenerateScheduleRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/study-planner/generate-schedule',
        data: request.toJson(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => StudySessionResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error generating schedule: $e');
      rethrow;
    }
  }

  /// Get all study sessions
  Future<List<StudySessionResponse>> getSessions() async {
    try {
      final response = await _apiClient.dio.get('/study-planner/sessions');
      final List<dynamic> data = response.data;
      return data.map((json) => StudySessionResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting sessions: $e');
      rethrow;
    }
  }

  /// Create a new study session
  Future<StudySessionResponse> createSession(
    CreateStudySessionRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/study-planner/sessions',
        data: request.toJson(),
      );
      return StudySessionResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error creating session: $e');
      rethrow;
    }
  }

  /// Create multiple study sessions
  Future<List<StudySessionResponse>> createSessions(
    List<CreateStudySessionRequest> requests,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/study-planner/sessions/batch',
        data: requests.map((r) => r.toJson()).toList(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => StudySessionResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error creating sessions: $e');
      rethrow;
    }
  }

  /// Update session status
  Future<StudySessionResponse> updateSessionStatus(
    String sessionId,
    String status,
  ) async {
    try {
      final response = await _apiClient.dio.patch(
        '/study-planner/sessions/$sessionId/status',
        queryParameters: {'status': status},
      );
      return StudySessionResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error updating session status: $e');
      rethrow;
    }
  }

  /// Get sessions in a date range
  /// GET /study-planner/sessions/range?start=...&end=...
  Future<List<StudySessionResponse>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/study-planner/sessions/range',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );
      final List<dynamic> data = response.data;
      return data.map((json) => StudySessionResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting sessions in range: $e');
      rethrow;
    }
  }

  /// Delete a study session
  /// DELETE /study-planner/sessions/{sessionId}
  Future<void> deleteSession(String sessionId) async {
    try {
      await _apiClient.dio.delete('/study-planner/sessions/$sessionId');
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
      rethrow;
    }
  }

  /// Refine schedule with AI based on user feedback
  /// POST /study-planner/refine-schedule
  Future<List<StudySessionResponse>> refineSchedule(
    RefineScheduleRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/study-planner/refine-schedule',
        data: request.toJson(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => StudySessionResponse.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error refining schedule: $e');
      rethrow;
    }
  }

  /// Check schedule health
  /// POST /study-planner/schedule-health
  Future<ScheduleHealthReport> checkScheduleHealth(
    CheckScheduleHealthRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/study-planner/schedule-health',
        data: request.toJson(),
      );
      return ScheduleHealthReport.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error checking schedule health: $e');
      rethrow;
    }
  }

  /// Suggest healthy adjustments for schedule
  /// POST /study-planner/schedule-suggest-fix
  Future<ScheduleHealthReport> suggestFix(
    CheckScheduleHealthRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/study-planner/schedule-suggest-fix',
        data: request.toJson(),
      );
      return ScheduleHealthReport.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error suggesting schedule fix: $e');
      rethrow;
    }
  }
}
