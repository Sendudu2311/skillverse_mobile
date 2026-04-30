import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/node_mentoring_models.dart';

/// Service for Per-Node Mentoring API calls.
/// Base: /api/v1/journeys/{journeyId}/nodes/{nodeId}
class NodeMentoringService {
  static final NodeMentoringService _instance =
      NodeMentoringService._internal();
  factory NodeMentoringService() => _instance;
  NodeMentoringService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get the mentor assignment for a node.
  /// GET /api/v1/journeys/{journeyId}/nodes/{nodeId}/assignment
  Future<NodeAssignmentResponse?> getAssignment(
    int journeyId,
    String nodeId,
  ) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/journeys/$journeyId/nodes/${Uri.encodeComponent(nodeId)}/assignment',
      );
      if (response.data == null) return null;
      return NodeAssignmentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      // 404 means no assignment set yet — return null silently
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e, 'Lỗi lấy thông tin bài tập');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get the learner's submitted evidence for a node.
  /// GET /api/v1/journeys/{journeyId}/nodes/{nodeId}/evidence
  Future<NodeEvidenceRecordResponse?> getEvidence(
    int journeyId,
    String nodeId,
  ) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/journeys/$journeyId/nodes/${Uri.encodeComponent(nodeId)}/evidence',
      );
      if (response.data == null) return null;
      return NodeEvidenceRecordResponse.fromJson(response.data!);
    } on DioException catch (e) {
      // 404 means not submitted yet — return null silently
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e, 'Lỗi lấy bằng chứng');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Submit or update evidence for a node.
  /// POST /api/v1/journeys/{journeyId}/nodes/{nodeId}/evidence
  Future<NodeEvidenceRecordResponse> submitEvidence(
    int journeyId,
    String nodeId,
    SubmitNodeEvidenceRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/journeys/$journeyId/nodes/${Uri.encodeComponent(nodeId)}/evidence',
        data: request.toJson(),
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return NodeEvidenceRecordResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Nộp bằng chứng thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  // ─── Output Assessment (Final Assessment) ──────────────────────────────

  /// Get latest output assessment for a journey (null if none).
  /// GET /api/v1/journeys/{journeyId}/output-assessment
  Future<JourneyOutputAssessmentResponse?> getLatestOutputAssessment(
    int journeyId,
  ) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/journeys/$journeyId/output-assessment',
      );
      if (response.data == null) return null;
      return JourneyOutputAssessmentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e, 'Lấy bài đánh giá cuối kỳ thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Submit output assessment for a journey.
  /// POST /api/v1/journeys/{journeyId}/output-assessment
  Future<JourneyOutputAssessmentResponse> submitOutputAssessment(
    int journeyId,
    SubmitJourneyOutputAssessmentRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/journeys/$journeyId/output-assessment',
        data: request.toJson(),
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return JourneyOutputAssessmentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Nộp bài đánh giá cuối kỳ thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  // ─── Completion Gate ───────────────────────────────────────────────────

  /// Get the completion gate status for a journey.
  /// GET /api/v1/journeys/{journeyId}/completion-gate
  Future<JourneyCompletionGateResponse?> getCompletionGate(
    int journeyId,
  ) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/journeys/$journeyId/completion-gate',
      );
      if (response.data == null) return null;
      return JourneyCompletionGateResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e, 'Lấy trạng thái cổng hoàn thành thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  // ─── Verification History ──────────────────────────────────────────────

  /// Get full verification history (all attempts) for a journey.
  /// GET /api/v1/journeys/{journeyId}/verification-history
  Future<List<VerificationEvidenceReportResponse>> getVerificationHistory(
    int journeyId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/v1/journeys/$journeyId/verification-history',
      );
      if (response.data == null) return [];
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => VerificationEvidenceReportResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleDioError(e, 'Lấy lịch sử xác thực thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  // ─── Verified Skills ───────────────────────────────────────────────────

  /// Get verified skills for own portfolio.
  /// GET /api/portfolio/verified-skills
  /// Upload an attachment file (PDF/DOCX/IMG) for evidence and return its public URL.
  /// POST /api/media/upload
  Future<String> uploadAttachment({
    required String filePath,
    required String fileName,
    required int actorId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'actorId': actorId,
      });
      final response = await _apiClient.dio.post(
        '/media/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['url'] as String;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Tải file lên thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định khi tải file');
    }
  }

  Future<List<UserVerifiedSkillDTO>> getVerifiedSkills() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/verified-skills');
      if (response.data == null) return [];
      // Backend returns { success: bool, data: [...] }
      final dynamic data = response.data;
      List<dynamic> list;
      if (data is Map<String, dynamic> && data['data'] is List) {
        list = data['data'] as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        return [];
      }
      return list
          .map(
            (json) =>
                UserVerifiedSkillDTO.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleDioError(e, 'Lấy danh sách skill đã xác thực thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Converts DioException to AppException, preserving backend message.
  AppException _handleDioError(DioException e, String defaultMessage) {
    debugPrint(
      '🛑 NodeMentoringService Error: ${e.type} | ${e.response?.statusCode}',
    );
    if (e.error is AppException) return e.error as AppException;
    if (e.response?.data != null) {
      try {
        final dynamic data = e.response?.data;
        Map<String, dynamic>? errorMap;
        if (data is Map) {
          errorMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) errorMap = Map<String, dynamic>.from(decoded);
        }
        if (errorMap != null) {
          final msg =
              errorMap['message'] ?? errorMap['error'] ?? errorMap['details'];
          if (msg != null) {
            return ServerException(
              msg.toString(),
              statusCode: e.response?.statusCode,
            );
          }
        }
      } catch (_) {}
    }
    return ServerException(defaultMessage, statusCode: e.response?.statusCode);
  }
}
