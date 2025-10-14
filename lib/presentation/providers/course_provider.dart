import 'package:flutter/material.dart';
import '../../data/models/course_models.dart';
import '../../data/services/course_service.dart';

class CourseProvider with ChangeNotifier {
  final CourseService _courseService = CourseService();

  List<CourseSummaryDto> _courses = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMorePages = true;

  List<CourseSummaryDto> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;

  /// Load courses with pagination
  Future<void> loadCourses({
    bool refresh = false,
    String? search,
    CourseLevel? level,
    CourseStatus? status,
  }) async {
    if (refresh) {
      _currentPage = 0;
      _courses.clear();
      _hasMorePages = true;
    }

    if (!_hasMorePages || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pageResponse = await _courseService.getCourses(
        page: _currentPage,
        size: 10,
        search: search,
        level: level,
        status: status,
      );

      // Add null safety check for content
      if (pageResponse.content != null && pageResponse.content!.isNotEmpty) {
        _courses.addAll(pageResponse.content!);
        _currentPage++;
      }

      _hasMorePages = !pageResponse.last;
    } catch (e) {
      _error = e.toString();
      // Ensure we don't get stuck in loading state
      _isLoading = false;
      notifyListeners();
      return;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search courses
  Future<void> searchCourses(String query) async {
    _currentPage = 0;
    _courses.clear();
    _hasMorePages = true;
    _error = null;
    notifyListeners();

    try {
      final pageResponse = await _courseService.searchCourses(query);
      _courses = pageResponse.content ?? [];
      _hasMorePages = !pageResponse.last;
      _currentPage = pageResponse.last ? 0 : 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get course by ID
  Future<CourseSummaryDto?> getCourseById(int courseId) async {
    try {
      return await _courseService.getCourseById(courseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh courses
  Future<void> refresh() async {
    await loadCourses(refresh: true);
  }
}