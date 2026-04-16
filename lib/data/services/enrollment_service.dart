import '../models/enrollment_models.dart';
import '../models/course_models.dart';
import '../../core/network/api_client.dart';

class EnrollmentService {
  static final EnrollmentService _instance = EnrollmentService._internal();
  factory EnrollmentService() => _instance;
  EnrollmentService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Enroll current user (via JWT) in a course
  /// POST /enrollments
  /// Body: {courseId: xxx}
  Future<EnrollmentDetailDto> enrollUser({
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/enrollments',
        data: EnrollRequestDto(courseId: courseId).toJson(),
      );
      return EnrollmentDetailDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Unenroll current user (via JWT) from a course
  /// DELETE /enrollments/course/{courseId}
  Future<void> unenrollUser({
    required int courseId,
  }) async {
    try {
      await _apiClient.dio.delete('/enrollments/course/$courseId');
    } catch (e) {
      rethrow;
    }
  }

  /// Get enrollment details for current user
  /// GET /enrollments/me/course/{courseId}
  Future<EnrollmentDetailDto> getEnrollment({
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/enrollments/me/course/$courseId',
      );
      return EnrollmentDetailDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if current user is enrolled in a course
  /// GET /enrollments/me/course/{courseId}/status
  /// Returns: {enrolled: true/false}
  Future<bool> checkEnrollmentStatus({
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/enrollments/me/course/$courseId/status',
      );
      final statusDto = EnrollmentStatusDto.fromJson(response.data);
      return statusDto.enrolled;
    } catch (e) {
      // If 404 or error, assume not enrolled
      return false;
    }
  }

  /// List enrollments for current user (via JWT)
  /// GET /enrollments/me?page=0&size=20
  Future<PageResponse<EnrollmentDetailDto>> getUserEnrollments({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/enrollments/me',
        queryParameters: {'page': page, 'size': size},
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
  /// PUT /enrollments/course/{courseId}/user/{userId}/completion?completed=true
  Future<void> updateCompletionStatus({
    required int courseId,
    required int userId,
    required bool completed,
  }) async {
    try {
      await _apiClient.dio.put(
        '/enrollments/course/$courseId/user/$userId/completion',
        queryParameters: {'completed': completed},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update enrollment progress percentage
  /// PUT /enrollments/course/{courseId}/user/{userId}/progress?progressPercentage=50
  Future<void> updateProgress({
    required int courseId,
    required int userId,
    required int progressPercentage,
  }) async {
    try {
      await _apiClient.dio.put(
        '/enrollments/course/$courseId/user/$userId/progress',
        queryParameters: {'progressPercentage': progressPercentage},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get enrollment statistics for a course (instructor/admin only)
  /// GET /enrollments/course/{courseId}/stats
  Future<EnrollmentStatsDto> getEnrollmentStats({
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/enrollments/course/$courseId/stats',
      );
      return EnrollmentStatsDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get recent enrollments (admin only)
  /// GET /enrollments/recent?page=0&size=20
  Future<PageResponse<EnrollmentDetailDto>> getRecentEnrollments({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/enrollments/recent',
        queryParameters: {'page': page, 'size': size},
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
