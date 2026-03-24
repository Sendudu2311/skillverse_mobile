import 'package:flutter/material.dart';
import '../../data/models/course_models.dart';
import '../../data/services/course_service.dart';
import '../../core/utils/pagination_helper.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class CourseProvider with ChangeNotifier, LoadingStateProviderMixin {
  final CourseService _courseService = CourseService();

  CourseLevel? _selectedLevel;
  String? _currentSearchQuery;
  CourseStatus? _currentStatus;
  String? _sortField = 'createdAt';
  String _sortDirection = 'desc';

  // Lazy initialization to avoid LateInitializationError
  PaginationHelper<CourseSummaryDto>? _paginationHelper;

  PaginationHelper<CourseSummaryDto> get _pagination {
    _paginationHelper ??= PaginationHelper<CourseSummaryDto>(
      fetchPage: (page) async {
        final pageResponse = await _courseService.getCourses(
          page: page - 1, // API uses 0-based pagination
          size: 10,
          search: _currentSearchQuery,
          status: _currentStatus,
          sortField: _sortField,
          sortDirection: _sortDirection,
        );

        return PaginatedResponse<CourseSummaryDto>(
          data: pageResponse.content ?? [],
          currentPage: page,
          totalPages: pageResponse.totalPages,
          totalItems: pageResponse.totalElements,
          hasMore: !pageResponse.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
    return _paginationHelper!;
  }

  /// Get courses (filtered by selected level if set)
  List<CourseSummaryDto> get courses {
    if (_selectedLevel == null) {
      return _pagination.items;
    }
    return _pagination.items
        .where((course) => course.level == _selectedLevel)
        .toList();
  }

  /// Get all courses (unfiltered)
  List<CourseSummaryDto> get allCourses => _pagination.items;

  /// Check if has more pages
  bool get hasMorePages => _pagination.hasMore;

  /// Get selected level filter
  CourseLevel? get selectedLevel => _selectedLevel;

  /// Check if pagination is loading
  bool get isPaginationLoading => _pagination.isLoading;

  /// Check if pagination is in initial loading state
  bool get isInitialLoading => _pagination.isInitialLoading;

  /// Check if loading more pages
  bool get isLoadingMore => _pagination.isLoadingMore;

  /// Check if list is empty
  bool get isEmpty => _pagination.isEmpty;

  /// Get pagination error
  String? get paginationError => _pagination.error;

  /// Get pagination helper (for scroll listener)
  PaginationHelper<CourseSummaryDto> get pagination => _pagination;

  /// Set level filter (client-side filtering)
  void setLevelFilter(CourseLevel? level) {
    _selectedLevel = level;
    notifyListeners();
  }

  /// Set sort order and reload
  Future<void> setSortOrder(String field, String direction) async {
    _sortField = field;
    _sortDirection = direction;
    // Need to recreate pagination with new sort
    _paginationHelper?.dispose();
    _paginationHelper = null;
    await _pagination.loadFirstPage();
  }

  /// Load courses with pagination
  Future<void> loadCourses({
    bool refresh = false,
    String? search,
    CourseStatus? status,
  }) async {
    // Update search/status filters
    _currentSearchQuery = search;
    _currentStatus = status;

    if (refresh) {
      await _pagination.loadFirstPage();
    } else {
      // Load first page if not initialized
      if (_pagination.state == PaginationState.initial) {
        await _pagination.loadFirstPage();
      }
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    await _pagination.loadNextPage();
  }

  /// Search courses
  Future<void> searchCourses(String query) async {
    _currentSearchQuery = query;
    await _pagination.loadFirstPage();
  }

  /// Get course by ID (with error handling)
  Future<CourseSummaryDto?> getCourseById(int courseId) async {
    return await executeAsync(
      () async {
        return await _courseService.getCourseById(courseId);
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('404')) {
          return 'Không tìm thấy khóa học';
        } else if (error.toString().contains('timeout')) {
          return 'Không có kết nối Internet';
        }
        return 'Lỗi tải khóa học: ${error.toString()}';
      },
    );
  }

  /// Refresh courses
  Future<void> refresh() async {
    await _pagination.refresh();
  }

  /// Reset pagination state
  void reset() {
    _pagination.reset();
    _selectedLevel = null;
    _currentSearchQuery = null;
    _currentStatus = null;
    resetState();
  }

  @override
  void dispose() {
    _paginationHelper?.dispose();
    super.dispose();
  }
}
