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
}
