import 'package:dio/dio.dart';
import '../models/assignment_models.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';

class AssignmentService {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;
  AssignmentService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get assignment details by ID
  /// GET /api/assignments/{assignmentId}
  Future<AssignmentDetailDto> getAssignmentById(int assignmentId) async {
    try {
      final response = await _apiClient.dio.get('/assignments/$assignmentId');
      return AssignmentDetailDto.fromJson(response.data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy thông tin bài tập thất bại: ${e.toString()}');
    }
  }

  /// Get current user's submissions for an assignment (all versions)
  /// GET /api/assignments/{assignmentId}/submissions/mine
  Future<List<AssignmentSubmissionDetailDto>> getMySubmissions(
    int assignmentId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/assignments/$assignmentId/submissions/mine',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => AssignmentSubmissionDetailDto.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy lịch sử nộp bài thất bại: ${e.toString()}');
    }
  }

  /// Submit an assignment
  /// POST /api/assignments/{assignmentId}/submissions
  Future<AssignmentSubmissionDetailDto> submitAssignment({
    required int assignmentId,
    required AssignmentSubmissionCreateDto submission,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/assignments/$assignmentId/submissions',
        data: submission.toJson(),
      );
      return AssignmentSubmissionDetailDto.fromJson(response.data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Nộp bài tập thất bại: ${e.toString()}');
    }
  }

  /// Upload a media file and return its mediaId
  /// POST /api/media/upload
  /// Returns: mediaId (Long from backend)
  /// [actorId] is required by backend to identify the uploader.
  Future<int> uploadMediaFile(
    String filePath,
    String fileName, {
    required int actorId,
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
      );

      final data = response.data as Map<String, dynamic>;
      return data['id'] as int;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tải file lên thất bại: ${e.toString()}');
    }
  }
}
