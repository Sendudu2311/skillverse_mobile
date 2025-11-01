import '../models/lesson_models.dart';
import 'api_client.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get lesson detail by ID
  /// GET /api/lessons/{lessonId}
  Future<LessonDetailDto> getLesson({
    required int lessonId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/lessons/$lessonId',
      );
      return LessonDetailDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// List lessons by module
  /// GET /api/lessons/modules/{moduleId}/lessons
  Future<List<LessonBriefDto>> listLessonsByModule({
    required int moduleId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/lessons/modules/$moduleId/lessons',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => LessonBriefDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get next lesson in a module
  /// GET /api/lessons/modules/{moduleId}/lessons/{lessonId}/next
  Future<LessonBriefDto?> getNextLesson({
    required int moduleId,
    required int lessonId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/lessons/modules/$moduleId/lessons/$lessonId/next',
      );
      return LessonBriefDto.fromJson(response.data);
    } catch (e) {
      // Return null if no next lesson (404)
      return null;
    }
  }

  /// Get previous lesson in a module
  /// GET /api/lessons/modules/{moduleId}/lessons/{lessonId}/prev
  Future<LessonBriefDto?> getPreviousLesson({
    required int moduleId,
    required int lessonId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/lessons/modules/$moduleId/lessons/$lessonId/prev',
      );
      return LessonBriefDto.fromJson(response.data);
    } catch (e) {
      // Return null if no previous lesson (404)
      return null;
    }
  }

  /// Mark lesson as completed for a user
  /// PUT /api/lessons/modules/{moduleId}/lessons/{lessonId}/complete?userId={userId}
  Future<void> markLessonCompleted({
    required int moduleId,
    required int lessonId,
    required int userId,
  }) async {
    try {
      await _apiClient.dio.put(
        '/api/lessons/modules/$moduleId/lessons/$lessonId/complete',
        queryParameters: {'userId': userId},
      );
    } catch (e) {
      rethrow;
    }
  }
}
