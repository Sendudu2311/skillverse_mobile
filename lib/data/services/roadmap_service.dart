import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/roadmap_models.dart';

/// Service for AI Roadmap API calls
class RoadmapService {
  static final RoadmapService _instance = RoadmapService._internal();
  factory RoadmapService() => _instance;
  RoadmapService._internal();

  final ApiClient _apiClient = ApiClient();

/// Get all roadmap sessions for the current user
  /// API: GET /api/v1/ai/roadmap
  Future<List<RoadmapSessionSummary>> getUserRoadmaps({
    bool includeDeleted = false,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/ai/roadmap',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
          'size': size,
        },
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (json) =>
                RoadmapSessionSummary.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy danh sách lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get a specific roadmap by its session ID
  /// API: GET /api/v1/ai/roadmap/{sessionId}
  Future<RoadmapResponse> getRoadmapById(int sessionId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/ai/roadmap/$sessionId',
      );

      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }

      return RoadmapResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy thông tin lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// @deprecated Tính năng đã chuyển sang Journey.
  Future<List<ValidationResult>> preValidate(
    GenerateRoadmapRequest request,
  ) async {
    throw UnsupportedError('Tính năng đã chuyển sang Journey');
  }

  /// @deprecated Tính năng đã chuyển sang Journey.
  Future<RoadmapResponse> generateRoadmap(
    GenerateRoadmapRequest request,
  ) async {
    throw UnsupportedError('Tính năng đã chuyển sang Journey');
  }

  /// Generate clarification questions for roadmap request
  /// API: POST /api/v1/ai/roadmap/clarify
  Future<List<ClarificationQuestion>> clarify(
    GenerateRoadmapRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<List<dynamic>>(
        '/v1/ai/roadmap/clarify',
        data: request.toJson(),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (json) =>
                ClarificationQuestion.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy câu hỏi làm rõ');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Update quest progress
  /// API: POST /api/v1/ai/roadmap/{sessionId}/progress
  Future<ProgressResponse> updateQuestProgress({
    required int sessionId,
    required String questId,
    required bool completed,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/ai/roadmap/$sessionId/progress',
        data: UpdateProgressRequest(
          questId: questId,
          completed: completed,
        ).toJson(),
      );

      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }

      return ProgressResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi cập nhật tiến độ');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Helper to convert DioException to standard AppException while preserving server message
  AppException _handleDioError(DioException e, String defaultMessage) {
    debugPrint(
      '🛑 RoadmapService Error: ${e.type} | Status: ${e.response?.statusCode}',
    );

    // 1. Priority: Use error from ApiClient interceptor if it's an AppException
    if (e.error is AppException) {
      debugPrint('✅ Found AppException in DioException.error: ${e.error}');
      return e.error as AppException;
    }

    // 2. Fallback: Manually try to extract message from response data
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
            debugPrint('✅ Extracted Server Message (Direct): $serverMessage');
            return ServerException(
              serverMessage.toString(),
              statusCode: e.response?.statusCode,
            );
          }
        }
      } catch (err) {
        debugPrint('⚠️ Error parsing server error response: $err');
      }
    }

    // 3. Last resort: Use default message
    return ServerException(defaultMessage, statusCode: e.response?.statusCode);
  }

  // ============================================================================
  // ROADMAP LIFECYCLE MANAGEMENT (V3)
  // ============================================================================

  /// Activate a roadmap (auto-pauses other active roadmaps)
  /// API: PUT /api/v1/ai/roadmap/{sessionId}/activate
  Future<void> activateRoadmap(int sessionId) async {
    try {
      await _apiClient.dio.put('/v1/ai/roadmap/$sessionId/activate');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi kích hoạt lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Pause a roadmap
  /// API: PUT /api/v1/ai/roadmap/{sessionId}/pause
  Future<void> pauseRoadmap(int sessionId) async {
    try {
      await _apiClient.dio.put('/v1/ai/roadmap/$sessionId/pause');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi tạm dừng lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Soft-delete a roadmap (data preserved, hidden from default list)
  /// API: DELETE /api/v1/ai/roadmap/{sessionId}
  Future<void> softDeleteRoadmap(int sessionId) async {
    try {
      await _apiClient.dio.delete('/v1/ai/roadmap/$sessionId');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi xoá lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Permanently delete a roadmap (must be soft-deleted first)
  /// API: DELETE /api/v1/ai/roadmap/{sessionId}/permanent
  Future<void> permanentDeleteRoadmap(int sessionId) async {
    try {
      await _apiClient.dio.delete('/v1/ai/roadmap/$sessionId/permanent');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi xoá vĩnh viễn lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get only soft-deleted roadmaps
  /// API: GET /api/v1/ai/roadmap/deleted
  Future<List<RoadmapSessionSummary>> getDeletedRoadmaps() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/ai/roadmap/deleted',
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (json) =>
                RoadmapSessionSummary.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy lộ trình đã xoá');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get roadmap counts by lifecycle status
  /// API: GET /api/v1/ai/roadmap/status-counts
  Future<Map<String, int>> getRoadmapStatusCounts() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/ai/roadmap/status-counts',
      );

      if (response.data == null) {
        return {};
      }

      return response.data!.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi lấy thống kê lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Restore a soft-deleted roadmap back to PAUSED status
  /// API: POST /api/v1/ai/roadmap/{sessionId}/restore
  Future<void> restoreRoadmap(int sessionId) async {
    try {
      await _apiClient.dio.post('/v1/ai/roadmap/$sessionId/restore');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi khôi phục lộ trình');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Atomically mark a roadmap node as complete
  /// API: POST /api/v1/ai/roadmap/{sessionId}/nodes/{nodeId}/complete
  Future<Map<String, dynamic>> completeNode(
    int sessionId,
    String nodeId,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/ai/roadmap/$sessionId/nodes/$nodeId/complete',
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return response.data!;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lỗi hoàn thành node');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }
}
