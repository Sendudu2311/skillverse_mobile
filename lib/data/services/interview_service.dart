import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';
import '../models/interview_models.dart';

/// Service for Interview Schedule management
/// Backend: InterviewScheduleController.java — /api/interviews
class InterviewService {
  static final InterviewService _instance = InterviewService._internal();
  factory InterviewService() => _instance;
  InterviewService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Schedule a new interview
  /// POST /api/interviews
  Future<InterviewScheduleResponse> scheduleInterview(
    CreateInterviewRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/interviews',
        data: request.toJson(),
      );
      return InterviewScheduleResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error scheduling interview: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Lên lịch phỏng vấn thất bại: ${e.toString()}');
    }
  }

  /// Get interview by application ID
  /// GET /api/interviews/application/{applicationId}
  Future<InterviewScheduleResponse> getByApplication(int applicationId) async {
    try {
      final response = await _apiClient.dio.get(
        '/interviews/application/$applicationId',
      );
      return InterviewScheduleResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error getting interview by application: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy lịch phỏng vấn theo đơn thất bại: ${e.toString()}',
      );
    }
  }

  /// Get interviews by job posting ID
  /// GET /api/interviews/job/{jobPostingId}
  Future<List<InterviewScheduleResponse>> getByJob(int jobPostingId) async {
    try {
      final response = await _apiClient.dio.get(
        '/interviews/job/$jobPostingId',
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (e) =>
                InterviewScheduleResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting interviews by job: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy danh sách phỏng vấn theo job thất bại: ${e.toString()}',
      );
    }
  }

  /// Get my interviews (for current user)
  /// GET /api/interviews/me
  Future<List<InterviewScheduleResponse>> getMyInterviews() async {
    try {
      final response = await _apiClient.dio.get('/interviews/me');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (e) =>
                InterviewScheduleResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting my interviews: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy lịch phỏng vấn của bạn thất bại: ${e.toString()}',
      );
    }
  }

  /// Complete an interview
  /// PATCH /api/interviews/{interviewId}/complete?notes=...
  Future<InterviewScheduleResponse> completeInterview(
    int interviewId, {
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/interviews/$interviewId/complete',
        queryParameters: {if (notes != null) 'notes': notes},
      );
      return InterviewScheduleResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error completing interview: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Hoàn thành phỏng vấn thất bại: ${e.toString()}');
    }
  }

  /// Candidate confirms an interview (PENDING → CONFIRMED)
  /// PATCH /api/interviews/{interviewId}/confirm
  Future<InterviewScheduleResponse> confirmInterview(int interviewId) async {
    try {
      final response = await _apiClient.dio.patch(
        '/interviews/$interviewId/confirm',
      );
      return InterviewScheduleResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error confirming interview: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Xác nhận phỏng vấn thất bại: ${e.toString()}');
    }
  }

  /// Candidate declines an interview (PENDING → CANCELLED, cancelledBy=CANDIDATE)
  /// PATCH /api/interviews/{interviewId}/decline
  Future<InterviewScheduleResponse> declineInterview(
    int interviewId, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/interviews/$interviewId/decline',
        data: DeclineInterviewRequest(reason: reason).toJson(),
      );
      return InterviewScheduleResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error declining interview: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Từ chối phỏng vấn thất bại: ${e.toString()}');
    }
  }

  /// Cancel an interview (recruiter-only — candidate should use declineInterview)
  /// PATCH /api/interviews/{interviewId}/cancel
  Future<InterviewScheduleResponse> cancelInterview(int interviewId) async {
    try {
      final response = await _apiClient.dio.patch(
        '/interviews/$interviewId/cancel',
      );
      return InterviewScheduleResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error cancelling interview: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Hủy phỏng vấn thất bại: ${e.toString()}');
    }
  }
}
