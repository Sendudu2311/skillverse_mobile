import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../data/models/enrollment_models.dart';
import '../../data/services/enrollment_service.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentService _enrollmentService = EnrollmentService();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<EnrollmentDetailDto> _enrollments = [];
  Map<int, bool> _enrollmentStatusCache = {}; // courseId -> enrolled status

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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
    _setLoading(true);
    _clearError();

    try {
      final enrollment = await _enrollmentService.enrollUser(
        courseId: courseId,
        userId: userId,
      );

      // Add to enrollments list
      _enrollments.add(enrollment);

      // Update cache
      _enrollmentStatusCache[courseId] = true;

      _setLoading(false);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to enroll in course: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Unenroll user from a course
  Future<bool> unenrollFromCourse({
    required int courseId,
    required int userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _enrollmentService.unenrollUser(
        courseId: courseId,
        userId: userId,
      );

      // Remove from enrollments list
      _enrollments.removeWhere((e) => e.courseId == courseId);

      // Update cache
      _enrollmentStatusCache[courseId] = false;

      _setLoading(false);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to unenroll from course: $e');
      _setLoading(false);
      return false;
    }
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
    _setLoading(true);
    _clearError();

    try {
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

      _setLoading(false);
      notifyListeners();
    } on DioException catch (e) {
      _handleError(e);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch enrollments: $e');
      _setLoading(false);
    }
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

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        _setError(data['message']);
      } else {
        _setError('Error: ${e.response!.statusCode}');
      }
    } else {
      _setError('Network error: ${e.message}');
    }
  }

  /// Clear all data
  void clear() {
    _enrollments = [];
    _enrollmentStatusCache = {};
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
