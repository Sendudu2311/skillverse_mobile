import '../models/enrollment_models.dart';
import '../models/course_models.dart';
import '../../core/network/api_client.dart';

class EnrollmentService {
  static final EnrollmentService _instance = EnrollmentService._internal();
  factory EnrollmentService() => _instance;
  EnrollmentService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Enroll a user in a course
  /// POST /api/enrollments?userId={userId}
  /// Body: {courseId: xxx}
  Future<EnrollmentDetailDto> enrollUser({
    required int courseId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/enrollments',
        queryParameters: {'userId': userId},
        data: EnrollRequestDto(courseId: courseId).toJson(),
      );
      return EnrollmentDetailDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Unenroll a user from a course
  /// DELETE /api/enrollments/course/{courseId}/user/{userId}
  Future<void> unenrollUser({
    required int courseId,
    required int userId,
  }) async {
    try {
      await _apiClient.dio.delete(
        '/api/enrollments/course/$courseId/user/$userId',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get enrollment details
  /// GET /api/enrollments/course/{courseId}/user/{userId}
  Future<EnrollmentDetailDto> getEnrollment({
    required int courseId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/enrollments/course/$courseId/user/$userId',
      );
      return EnrollmentDetailDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is enrolled in course
  /// GET /api/enrollments/course/{courseId}/user/{userId}/status
  /// Returns: {enrolled: true/false}
  Future<bool> checkEnrollmentStatus({
    required int courseId,
    required int userId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/enrollments/course/$courseId/user/$userId/status',
      );
      final statusDto = EnrollmentStatusDto.fromJson(response.data);
      return statusDto.enrolled;
    } catch (e) {
      // If 404 or error, assume not enrolled
      return false;
    }
  }

  /// List enrollments for a user
  /// GET /api/enrollments/user/{userId}?page=0&size=20
  Future<PageResponse<EnrollmentDetailDto>> getUserEnrollments({
    required int userId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/enrollments/user/$userId',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      return PageResponse<EnrollmentDetailDto>.fromJson(
        response.data,
        (json) => EnrollmentDetailDto.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update course completion status
  /// PUT /api/enrollments/course/{courseId}/user/{userId}/completion?completed=true
  Future<void> updateCompletionStatus({
    required int courseId,
    required int userId,
    required bool completed,
  }) async {
    try {
      await _apiClient.dio.put(
        '/api/enrollments/course/$courseId/user/$userId/completion',
        queryParameters: {'completed': completed},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update enrollment progress percentage
  /// PUT /api/enrollments/course/{courseId}/user/{userId}/progress?progressPercentage=50
  Future<void> updateProgress({
    required int courseId,
    required int userId,
    required int progressPercentage,
  }) async {
    try {
      await _apiClient.dio.put(
        '/api/enrollments/course/$courseId/user/$userId/progress',
        queryParameters: {'progressPercentage': progressPercentage},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get enrollment statistics for a course (instructor/admin only)
  /// GET /api/enrollments/course/{courseId}/stats?actorId={actorId}
  Future<EnrollmentStatsDto> getEnrollmentStats({
    required int courseId,
    required int actorId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/enrollments/course/$courseId/stats',
        queryParameters: {'actorId': actorId},
      );
      return EnrollmentStatsDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get recent enrollments (admin only)
  /// GET /api/enrollments/recent?actorId={actorId}&page=0&size=20
  Future<PageResponse<EnrollmentDetailDto>> getRecentEnrollments({
    required int actorId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/enrollments/recent',
        queryParameters: {
          'actorId': actorId,
          'page': page,
          'size': size,
        },
      );

      return PageResponse<EnrollmentDetailDto>.fromJson(
        response.data,
        (json) => EnrollmentDetailDto.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }
}
