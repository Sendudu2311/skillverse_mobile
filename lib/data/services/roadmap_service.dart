import 'package:dio/dio.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/roadmap_models.dart';

/// Service for AI Roadmap API calls
class RoadmapService {
  static final RoadmapService _instance = RoadmapService._internal();
  factory RoadmapService() => _instance;
  RoadmapService._internal();

  final ApiClient _apiClient = ApiClient();

  // Request deduplication for generate
  Future<RoadmapResponse>? _ongoingGenerateRequest;
  String? _lastRequestKey;

  /// Create a unique key for request deduplication
  String _createRequestKey(GenerateRoadmapRequest request) {
    return '${request.goal}_${request.duration}_${request.experience}_${request.style}';
  }

  /// Get all roadmap sessions for the current user
  /// API: GET /api/v1/ai/roadmap
  Future<List<RoadmapSessionSummary>> getUserRoadmaps() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/ai/roadmap',
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
      final message =
          e.response?.data?['message'] ?? 'Lấy danh sách lộ trình thất bại';
      throw ApiException(message.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách lộ trình thất bại: ${e.toString()}');
    }
  }

  /// Get a specific roadmap by ID
  /// API: GET /api/v1/ai/roadmap/{sessionId}
  Future<RoadmapResponse> getRoadmapById(int sessionId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/ai/roadmap/$sessionId',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return RoadmapResponse.fromJson(response.data!);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Lấy thông tin lộ trình thất bại';
      throw ApiException(message.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy thông tin lộ trình thất bại: ${e.toString()}');
    }
  }

  /// Pre-validate roadmap generation request
  /// API: POST /api/v1/ai/roadmap/validate
  Future<List<ValidationResult>> preValidate(
    GenerateRoadmapRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<List<dynamic>>(
        '/v1/ai/roadmap/validate',
        data: request.toJson(),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (json) => ValidationResult.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Xác thực yêu cầu thất bại';
      throw ApiException(message.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Xác thực yêu cầu thất bại: ${e.toString()}');
    }
  }

  /// Generate a new AI-powered roadmap with request deduplication
  /// API: POST /api/v1/ai/roadmap/generate
  Future<RoadmapResponse> generateRoadmap(
    GenerateRoadmapRequest request,
  ) async {
    final requestKey = _createRequestKey(request);

    // If same request is already in progress, return the ongoing promise
    if (_ongoingGenerateRequest != null && _lastRequestKey == requestKey) {
      return _ongoingGenerateRequest!;
    }

    try {
      _lastRequestKey = requestKey;
      _ongoingGenerateRequest = _doGenerateRoadmap(request);
      return await _ongoingGenerateRequest!;
    } finally {
      _ongoingGenerateRequest = null;
      _lastRequestKey = null;
    }
  }

  Future<RoadmapResponse> _doGenerateRoadmap(
    GenerateRoadmapRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/ai/roadmap/generate',
        data: request.toJson(),
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return RoadmapResponse.fromJson(response.data!);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Tạo lộ trình thất bại';
      throw ApiException(message.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tạo lộ trình thất bại: ${e.toString()}');
    }
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
      final message =
          e.response?.data?['message'] ?? 'Lấy câu hỏi làm rõ thất bại';
      throw ApiException(message.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy câu hỏi làm rõ thất bại: ${e.toString()}');
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
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return ProgressResponse.fromJson(response.data!);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Cập nhật tiến độ thất bại';
      throw ApiException(message.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cập nhật tiến độ thất bại: ${e.toString()}');
    }
  }

  // ============================================================================
  // LEGACY METHODS (for backward compatibility with old Roadmap model)
  // ============================================================================

  /// Get all roadmaps (legacy - may not be implemented in backend)
  @Deprecated('Use getUserRoadmaps() instead')
  Future<List<Roadmap>> getRoadmaps() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>('/roadmaps');

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) => Roadmap.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách roadmap thất bại: ${e.toString()}');
    }
  }

  /// Get roadmaps by category (legacy)
  @Deprecated('Use getUserRoadmaps() instead')
  Future<List<Roadmap>> getRoadmapsByCategory(String category) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/roadmaps/category/$category',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) => Roadmap.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy roadmap theo danh mục thất bại: ${e.toString()}');
    }
  }

  /// Update roadmap progress (legacy)
  @Deprecated('Use updateQuestProgress() instead')
  Future<Roadmap> updateRoadmapProgress(
    int roadmapId,
    int completedSteps,
  ) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/roadmaps/$roadmapId/progress',
        data: {'completedSteps': completedSteps},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return Roadmap.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cập nhật tiến độ roadmap thất bại: ${e.toString()}');
    }
  }

  /// Get user's roadmap progress (legacy)
  @Deprecated('Use getUserRoadmaps() instead')
  Future<List<Roadmap>> getLegacyUserRoadmaps() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/roadmaps/user',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) => Roadmap.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy roadmap của người dùng thất bại: ${e.toString()}',
      );
    }
  }

  /// Start a roadmap for user (legacy)
  @Deprecated('Use generateRoadmap() instead')
  Future<Roadmap> startRoadmap(int roadmapId) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/roadmaps/$roadmapId/start',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return Roadmap.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bắt đầu roadmap thất bại: ${e.toString()}');
    }
  }
}
