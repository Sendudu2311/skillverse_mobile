import '../models/lesson_models.dart';
import '../../core/network/api_client.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get lesson detail by ID
  /// GET /api/lessons/{lessonId}
  Future<LessonDetailDto> getLesson({required int lessonId}) async {
    try {
      final response = await _apiClient.dio.get('/lessons/$lessonId');
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
        '/lessons/modules/$moduleId/lessons',
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
        '/lessons/modules/$moduleId/lessons/$lessonId/next',
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
        '/lessons/modules/$moduleId/lessons/$lessonId/prev',
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
        '/lessons/modules/$moduleId/lessons/$lessonId/complete',
        queryParameters: {'userId': userId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get completed lesson IDs for a user in a course
  /// GET /api/lessons/progress/course/{courseId}/user/{userId}/completed-ids
  Future<List<int>> getCompletedLessonIds({
    required int courseId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/lessons/progress/course/$courseId/user/$userId/completed-ids',
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => (e as num).toInt()).toList();
    } catch (e) {
      // Return empty list if endpoint fails (e.g. no progress yet)
      return [];
    }
  }

  /// Get aggregated course learning status (progress, certificate, completed IDs)
  /// GET /api/course-learning/courses/{courseId}/status
  Future<CourseLearningStatusDto> getCourseLearningStatus({
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/course-learning/courses/$courseId/status',
      );
      return CourseLearningStatusDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Aggregated course learning status from backend
class CourseLearningStatusDto {
  final int courseId;
  final int userId;
  final List<int> completedLessonIds;
  final List<int> completedQuizIds;
  final List<int> completedAssignmentIds;
  final int completedItemCount;
  final int totalItemCount;
  final int percent;
  final int? certificateId;
  final String? certificateSerial;
  final bool certificateRevoked;

  const CourseLearningStatusDto({
    required this.courseId,
    required this.userId,
    required this.completedLessonIds,
    required this.completedQuizIds,
    required this.completedAssignmentIds,
    required this.completedItemCount,
    required this.totalItemCount,
    required this.percent,
    this.certificateId,
    this.certificateSerial,
    this.certificateRevoked = false,
  });

  factory CourseLearningStatusDto.fromJson(Map<String, dynamic> json) {
    return CourseLearningStatusDto(
      courseId: (json['courseId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      completedLessonIds: (json['completedLessonIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      completedQuizIds: (json['completedQuizIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      completedAssignmentIds:
          (json['completedAssignmentIds'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              [],
      completedItemCount: (json['completedItemCount'] as num?)?.toInt() ?? 0,
      totalItemCount: (json['totalItemCount'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      certificateId: (json['certificateId'] as num?)?.toInt(),
      certificateSerial: json['certificateSerial'] as String?,
      certificateRevoked: json['certificateRevoked'] == true,
    );
  }
}
