import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/journey_models.dart';

/// Service for Journey API calls
/// Handles the guided learning journey lifecycle:
/// Start → Assessment Test → AI Evaluation → Roadmap → Study Plans → Complete
class JourneyService {
  static final JourneyService _instance = JourneyService._internal();
  factory JourneyService() => _instance;
  JourneyService._internal();

  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // Journey Lifecycle
  // ============================================================

  /// Start a new guided journey
  /// POST /api/v1/journey
  Future<JourneySummaryDto> startJourney(StartJourneyRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/journey',
        data: request.toJson(),
      );
      return JourneySummaryDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tạo hành trình thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Get journey by ID
  /// GET /api/v1/journey/{journeyId}
  Future<JourneySummaryDto> getJourneyById(int journeyId) async {
    try {
      final response = await _apiClient.dio.get('/v1/journey/$journeyId');
      return JourneySummaryDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy thông tin hành trình thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Get all journeys for current user (paginated)
  /// GET /api/v1/journey?page=0&size=10
  Future<List<JourneySummaryDto>> getUserJourneys({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/journey',
        queryParameters: {'page': page, 'size': size},
      );

      // Backend returns Page<JourneySummaryResponse> with 'content' field
      final data = response.data;
      List<dynamic> content;

      if (data is Map<String, dynamic> && data.containsKey('content')) {
        content = data['content'] as List<dynamic>;
      } else if (data is List) {
        content = data;
      } else {
        return [];
      }

      return content
          .map((json) =>
              JourneySummaryDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy danh sách hành trình thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Get active journeys
  /// GET /api/v1/journey/active
  Future<List<JourneySummaryDto>> getActiveJourneys() async {
    try {
      final response = await _apiClient.dio.get('/v1/journey/active');

      if (response.data == null) return [];
      final list = response.data as List<dynamic>;
      return list
          .map((json) =>
              JourneySummaryDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy hành trình đang hoạt động thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Get current journey progress (for dashboard)
  /// GET /api/v1/journey/current
  Future<JourneySummaryDto?> getCurrentProgress() async {
    try {
      final response = await _apiClient.dio.get('/v1/journey/current');

      if (response.statusCode == 204 || response.data == null) {
        return null;
      }
      return JourneySummaryDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 204 No Content means no active journey
      if (e.response?.statusCode == 204) return null;
      throw _handleDioError(e, 'Lấy tiến độ hành trình thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  // ============================================================
  // Assessment Test Flow
  // ============================================================

  /// Generate AI assessment test for a journey
  /// POST /api/v1/journey/{journeyId}/generate-test
  Future<GenerateTestResponseDto> generateTest(int journeyId) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/journey/$journeyId/generate-test',
        data: {},
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      return GenerateTestResponseDto.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tạo bài đánh giá thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Get assessment test details
  /// GET /api/v1/journey/{journeyId}/test/{testId}
  Future<AssessmentTestDto> getAssessmentTest({
    required int journeyId,
    required int testId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/journey/$journeyId/test/$testId',
      );
      return AssessmentTestDto.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy bài đánh giá thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Submit test answers and get AI evaluation
  /// POST /api/v1/journey/{journeyId}/submit-test
  Future<TestResultDto> submitTest({
    required int journeyId,
    required SubmitTestRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/journey/$journeyId/submit-test',
        data: request.toJson(),
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      return TestResultDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Nộp bài đánh giá thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Get test result details
  /// GET /api/v1/journey/{journeyId}/result/{resultId}
  Future<TestResultDto> getTestResult({
    required int journeyId,
    required int resultId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/journey/$journeyId/result/$resultId',
      );
      return TestResultDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy kết quả bài đánh giá thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  // ============================================================
  // Roadmap Integration
  // ============================================================

  /// Generate roadmap based on test results
  /// POST /api/v1/journey/{journeyId}/generate-roadmap
  Future<JourneySummaryDto> generateRoadmap(int journeyId) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/journey/$journeyId/generate-roadmap',
        data: {},
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      return JourneySummaryDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tạo lộ trình thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Get roadmap for a journey
  /// GET /api/v1/journey/{journeyId}/roadmap
  Future<dynamic> getRoadmap(int journeyId) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/journey/$journeyId/roadmap',
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy lộ trình thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Create study plan for a specific roadmap node via roadmap session ID
  /// POST /api/v1/journey/roadmap/{roadmapSessionId}/study-plan/node/{nodeId}
  Future<Map<String, dynamic>> createStudyPlanForRoadmapNode({
    required int roadmapSessionId,
    required String nodeId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/journey/roadmap/$roadmapSessionId/study-plan/node/${Uri.encodeComponent(nodeId)}',
        data: {},
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'message': 'Đã tạo kế hoạch học tập', 'created': true};
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tạo kế hoạch học tập thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  // ============================================================
  // Status Control
  // ============================================================

  /// Pause a journey
  /// POST /api/v1/journey/{journeyId}/pause
  Future<JourneySummaryDto> pauseJourney(int journeyId) async {
    return _postLifecycleAction(journeyId, 'pause', 'Tạm dừng hành trình thất bại');
  }

  /// Resume a paused journey
  /// POST /api/v1/journey/{journeyId}/resume
  Future<JourneySummaryDto> resumeJourney(int journeyId) async {
    return _postLifecycleAction(journeyId, 'resume', 'Tiếp tục hành trình thất bại');
  }

  /// Cancel a journey
  /// POST /api/v1/journey/{journeyId}/cancel
  Future<JourneySummaryDto> cancelJourney(int journeyId) async {
    return _postLifecycleAction(journeyId, 'cancel', 'Hủy hành trình thất bại');
  }

  /// Complete a journey
  /// POST /api/v1/journey/{journeyId}/complete
  Future<JourneySummaryDto> completeJourney(int journeyId) async {
    return _postLifecycleAction(journeyId, 'complete', 'Hoàn thành hành trình thất bại');
  }

  /// Generate AI summary report
  /// POST /api/v1/journey/{journeyId}/generate-report
  Future<JourneySummaryDto> generateAiReport(int journeyId) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/journey/$journeyId/generate-report',
        data: {},
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      return JourneySummaryDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tạo báo cáo AI thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Shared helper for simple lifecycle POST actions (pause/resume/cancel/complete)
  Future<JourneySummaryDto> _postLifecycleAction(
    int journeyId,
    String action,
    String errorMessage,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/v1/journey/$journeyId/$action',
      );
      return JourneySummaryDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, errorMessage);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định: ${e.toString()}');
    }
  }

  /// Handle DioException — extract server message, fallback to default
  AppException _handleDioError(DioException e, String defaultMessage) {
    debugPrint('🛑 JourneyService Error: ${e.type} | Status: ${e.response?.statusCode}');

    // Priority: Use error from ApiClient interceptor
    if (e.error is AppException) {
      return e.error as AppException;
    }

    // Fallback: Extract message from response
    if (e.response?.data != null) {
      try {
        final dynamic data = e.response?.data;
        Map<String, dynamic>? errorMap;

        if (data is Map) {
          errorMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            errorMap = Map<String, dynamic>.from(decoded);
          }
        }

        if (errorMap != null) {
          final serverMessage =
              errorMap['message'] ?? errorMap['error'] ?? errorMap['details'];
          if (serverMessage != null) {
            return ServerException(serverMessage.toString(),
                statusCode: e.response?.statusCode);
          }
        }
      } catch (err) {
        debugPrint('⚠️ Error parsing server error response: $err');
      }
    }

    return ServerException(defaultMessage, statusCode: e.response?.statusCode);
  }
}
