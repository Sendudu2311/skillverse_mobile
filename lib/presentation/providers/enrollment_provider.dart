import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/enrollment_models.dart';
import '../../data/services/enrollment_service.dart';

/// Enrollment Provider
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class EnrollmentProvider with ChangeNotifier, LoadingStateProviderMixin {
  final EnrollmentService _enrollmentService = EnrollmentService();

  // State (chỉ giữ domain data — loading/error do mixin quản lý)
  List<EnrollmentDetailDto> _enrollments = [];
  Map<int, bool> _enrollmentStatusCache = {}; // courseId -> enrolled status

  // Getters
  List<EnrollmentDetailDto> get enrollments => _enrollments;

  /// Check if user is enrolled in a specific course
  bool isEnrolled(int courseId) {
    return _enrollmentStatusCache[courseId] ?? false;
  }

  /// Enroll user in a course
  Future<bool> enrollInCourse({
    required int courseId,
    required int userId,
  }) async {
    final result = await executeAsync(() async {
      final enrollment = await _enrollmentService.enrollUser(
        courseId: courseId,
        userId: userId,
      );

      // Add to enrollments list
      _enrollments.add(enrollment);

      // Update cache
      _enrollmentStatusCache[courseId] = true;
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => _extractErrorMessage(e, 'Failed to enroll in course'));
    return result ?? false;
  }

  /// Unenroll user from a course
  Future<bool> unenrollFromCourse({
    required int courseId,
    required int userId,
  }) async {
    final result = await executeAsync(() async {
      await _enrollmentService.unenrollUser(
        courseId: courseId,
        userId: userId,
      );

      // Remove from enrollments list
      _enrollments.removeWhere((e) => e.courseId == courseId);

      // Update cache
      _enrollmentStatusCache[courseId] = false;
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => _extractErrorMessage(e, 'Failed to unenroll from course'));
    return result ?? false;
  }

  /// Check enrollment status for a course
  Future<bool> checkEnrollmentStatus({
    required int courseId,
    required int userId,
  }) async {
    try {
      final enrolled = await _enrollmentService.checkEnrollmentStatus(
        courseId: courseId,
        userId: userId,
      );

      _enrollmentStatusCache[courseId] = enrolled;
      notifyListeners();
      return enrolled;
    } catch (e) {
      debugPrint('Error checking enrollment status: $e');
      return false;
    }
  }

  /// Fetch user's enrollments
  Future<void> fetchUserEnrollments({
    required int userId,
    int page = 0,
    int size = 20,
  }) async {
    await executeAsync(() async {
      final response = await _enrollmentService.getUserEnrollments(
        userId: userId,
        page: page,
        size: size,
      );

      if (page == 0) {
        _enrollments = response.content ?? [];
      } else {
        _enrollments.addAll(response.content ?? []);
      }

      // Update cache
      for (var enrollment in response.content ?? []) {
        _enrollmentStatusCache[enrollment.courseId] = true;
      }
      notifyListeners();
    }, errorMessageBuilder: (e) => _extractErrorMessage(e, 'Failed to fetch enrollments'));
  }

  /// Update course progress
  Future<bool> updateProgress({
    required int courseId,
    required int userId,
    required int progressPercentage,
  }) async {
    try {
      await _enrollmentService.updateProgress(
        courseId: courseId,
        userId: userId,
        progressPercentage: progressPercentage,
      );

      // Update local enrollment
      final index = _enrollments.indexWhere((e) => e.courseId == courseId);
      if (index != -1) {
        _enrollments[index] = EnrollmentDetailDto(
          id: _enrollments[index].id,
          courseId: _enrollments[index].courseId,
          courseTitle: _enrollments[index].courseTitle,
          courseSlug: _enrollments[index].courseSlug,
          userId: _enrollments[index].userId,
          status: _enrollments[index].status,
          progressPercent: progressPercentage,
          entitlementSource: _enrollments[index].entitlementSource,
          entitlementRef: _enrollments[index].entitlementRef,
          enrolledAt: _enrollments[index].enrolledAt,
          completedAt: _enrollments[index].completedAt,
          completed: _enrollments[index].completed,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating progress: $e');
      return false;
    }
  }

  /// Mark course as completed
  Future<bool> markAsCompleted({
    required int courseId,
    required int userId,
  }) async {
    try {
      await _enrollmentService.updateCompletionStatus(
        courseId: courseId,
        userId: userId,
        completed: true,
      );

      // Update local enrollment
      final index = _enrollments.indexWhere((e) => e.courseId == courseId);
      if (index != -1) {
        _enrollments[index] = EnrollmentDetailDto(
          id: _enrollments[index].id,
          courseId: _enrollments[index].courseId,
          courseTitle: _enrollments[index].courseTitle,
          courseSlug: _enrollments[index].courseSlug,
          userId: _enrollments[index].userId,
          status: 'COMPLETED',
          progressPercent: 100,
          entitlementSource: _enrollments[index].entitlementSource,
          entitlementRef: _enrollments[index].entitlementRef,
          enrolledAt: _enrollments[index].enrolledAt,
          completedAt: DateTime.now(),
          completed: true,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error marking as completed: $e');
      return false;
    }
  }

  /// Get enrollment for a specific course
  EnrollmentDetailDto? getEnrollment(int courseId) {
    try {
      return _enrollments.firstWhere((e) => e.courseId == courseId);
    } catch (e) {
      return null;
    }
  }

  // Helper: extract error message from DioException or generic error
  String _extractErrorMessage(dynamic e, String fallback) {
    if (e is DioException && e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Error: ${e.response!.statusCode}';
    }
    return '$fallback: $e';
  }

  /// Clear all data
  void clear() {
    _enrollments = [];
    _enrollmentStatusCache = {};
    resetState(); // Clears isLoading + errorMessage + notifyListeners()
  }
}
