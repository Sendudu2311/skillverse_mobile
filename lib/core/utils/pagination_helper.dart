import 'package:flutter/widgets.dart';

/// Paginated response model
///
/// This is a generic model for paginated API responses.
/// Your API should return data in this format or you can adapt it.
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasMore;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      data: (json['data'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['current_page'] ?? json['page'] ?? 1,
      totalPages: json['total_pages'] ?? json['totalPages'] ?? 1,
      totalItems: json['total_items'] ?? json['total'] ?? 0,
      hasMore: json['has_more'] ?? json['hasMore'] ?? false,
    );
  }

  /// Check if there are more pages to load
  bool get canLoadMore => hasMore || currentPage < totalPages;
}

/// Pagination state enum
enum PaginationState {
  /// Initial state before any data is loaded
  initial,

  /// Loading first page
  loading,

  /// First page loaded successfully
  loaded,

  /// Loading more pages
  loadingMore,

  /// All pages loaded, no more data
  completed,

  /// Error occurred
  error,

  /// Refreshing data (pull-to-refresh)
  refreshing,
}

/// Pagination Helper for managing paginated lists
///
/// This helper manages pagination state, loading, errors, and infinite scroll.
/// It works with ChangeNotifier for easy integration with Provider.
///
/// Usage:
/// ```dart
/// class CourseProvider extends ChangeNotifier {
///   late final PaginationHelper<Course> _pagination;
///
///   CourseProvider() {
///     _pagination = PaginationHelper<Course>(
///       fetchPage: (page) async {
///         final response = await apiService.getCourses(page: page, limit: 20);
///         return PaginatedResponse.fromJson(
///           response.data,
///           (json) => Course.fromJson(json),
///         );
///       },
///       onStateChanged: () => notifyListeners(),
///     );
///   }
///
///   List<Course> get courses => _pagination.items;
///   bool get isLoading => _pagination.isLoading;
///   bool get hasMore => _pagination.hasMore;
///
///   Future<void> loadCourses() => _pagination.loadFirstPage();
///   Future<void> loadMore() => _pagination.loadNextPage();
///   Future<void> refresh() => _pagination.refresh();
/// }
/// ```
class PaginationHelper<T> {
  /// Fetch function that returns a page of data
  final Future<PaginatedResponse<T>> Function(int page) fetchPage;

  /// Callback when state changes (for notifyListeners)
  final VoidCallback? onStateChanged;

  /// Items per page (default: 20)
  final int itemsPerPage;

  /// Whether to automatically load next page when reaching end
  final bool autoLoadMore;

  // Internal state
  final List<T> _items = [];
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalItems = 0;
  PaginationState _state = PaginationState.initial;
  String? _error;

  PaginationHelper({
    required this.fetchPage,
    this.onStateChanged,
    this.itemsPerPage = 20,
    this.autoLoadMore = true,
  });

  /// Current list of items
  List<T> get items => List.unmodifiable(_items);

  /// Current pagination state
  PaginationState get state => _state;

  /// Current page number (1-based)
  int get currentPage => _currentPage;

  /// Total number of pages
  int get totalPages => _totalPages;

  /// Total number of items across all pages
  int get totalItems => _totalItems;

  /// Whether there are more pages to load
  bool get hasMore => _currentPage < _totalPages;

  /// Whether currently loading (any state)
  bool get isLoading =>
      _state == PaginationState.loading ||
      _state == PaginationState.loadingMore ||
      _state == PaginationState.refreshing;

  /// Whether in initial loading state
  bool get isInitialLoading => _state == PaginationState.loading;

  /// Whether loading more pages
  bool get isLoadingMore => _state == PaginationState.loadingMore;

  /// Whether refreshing
  bool get isRefreshing => _state == PaginationState.refreshing;

  /// Whether in error state
  bool get hasError => _state == PaginationState.error;

  /// Error message if any
  String? get error => _error;

  /// Whether list is empty
  bool get isEmpty => _items.isEmpty;

  /// Whether data is loaded (at least first page)
  bool get isLoaded =>
      _state == PaginationState.loaded ||
      _state == PaginationState.completed;

  /// Update state and notify listeners
  void _setState(PaginationState newState) {
    _state = newState;
    onStateChanged?.call();
  }

  /// Load first page
  ///
  /// This clears existing data and loads the first page.
  /// Use this for initial load or when filters change.
  Future<void> loadFirstPage() async {
    if (isLoading) return;

    _setState(PaginationState.loading);
    _items.clear();
    _currentPage = 0;
    _totalPages = 1;
    _totalItems = 0;
    _error = null;

    try {
      final response = await fetchPage(1);
      _items.addAll(response.data);
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _totalItems = response.totalItems;

      if (_currentPage >= _totalPages) {
        _setState(PaginationState.completed);
      } else {
        _setState(PaginationState.loaded);
      }
    } catch (e) {
      _error = e.toString();
      _setState(PaginationState.error);
      rethrow;
    }
  }

  /// Load next page
  ///
  /// Loads the next page and appends data to existing items.
  /// Returns true if successful, false if no more pages or error.
  Future<bool> loadNextPage() async {
    // Don't load if already loading or no more pages
    if (isLoading || !hasMore) return false;

    _setState(PaginationState.loadingMore);
    _error = null;

    try {
      final nextPage = _currentPage + 1;
      final response = await fetchPage(nextPage);

      _items.addAll(response.data);
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _totalItems = response.totalItems;

      if (_currentPage >= _totalPages) {
        _setState(PaginationState.completed);
      } else {
        _setState(PaginationState.loaded);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      _setState(PaginationState.error);
      return false;
    }
  }

  /// Refresh data (pull-to-refresh)
  ///
  /// Reloads the first page while keeping the UI responsive.
  /// Similar to loadFirstPage but with different state.
  Future<void> refresh() async {
    if (_state == PaginationState.refreshing) return;

    _setState(PaginationState.refreshing);
    _error = null;

    // Keep old data visible while refreshing
    final oldItems = List<T>.from(_items);

    try {
      _items.clear();
      _currentPage = 0;
      _totalPages = 1;
      _totalItems = 0;

      final response = await fetchPage(1);
      _items.addAll(response.data);
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _totalItems = response.totalItems;

      if (_currentPage >= _totalPages) {
        _setState(PaginationState.completed);
      } else {
        _setState(PaginationState.loaded);
      }
    } catch (e) {
      // Restore old data on error
      _items.clear();
      _items.addAll(oldItems);
      _error = e.toString();
      _setState(PaginationState.error);
      rethrow;
    }
  }

  /// Retry after error
  ///
  /// Retries the last failed operation.
  Future<void> retry() async {
    if (_currentPage == 0) {
      await loadFirstPage();
    } else {
      await loadNextPage();
    }
  }

  /// Reset pagination state
  ///
  /// Clears all data and resets to initial state.
  void reset() {
    _items.clear();
    _currentPage = 0;
    _totalPages = 1;
    _totalItems = 0;
    _error = null;
    _setState(PaginationState.initial);
  }

  /// Insert item at beginning (for optimistic updates)
  void insertItem(T item) {
    _items.insert(0, item);
    _totalItems++;
    onStateChanged?.call();
  }

  /// Add item at end
  void addItem(T item) {
    _items.add(item);
    _totalItems++;
    onStateChanged?.call();
  }

  /// Update item by index
  void updateItem(int index, T item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      onStateChanged?.call();
    }
  }

  /// Remove item by index
  void removeItemAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _totalItems--;
      onStateChanged?.call();
    }
  }

  /// Remove item by predicate
  void removeWhere(bool Function(T) test) {
    final removed = _items.length;
    _items.removeWhere(test);
    _totalItems -= (removed - _items.length);
    onStateChanged?.call();
  }

  /// Find item by predicate
  T? findItem(bool Function(T) test) {
    try {
      return _items.firstWhere(test);
    } catch (e) {
      return null;
    }
  }

  /// Find item index
  int findIndex(bool Function(T) test) {
    return _items.indexWhere(test);
  }

  /// Check if should load more (for infinite scroll)
  ///
  /// Call this in your scroll listener:
  /// ```dart
  /// controller.addListener(() {
  ///   if (pagination.shouldLoadMore(controller)) {
  ///     pagination.loadNextPage();
  ///   }
  /// });
  /// ```
  bool shouldLoadMore(ScrollController controller,
      {double threshold = 200.0}) {
    if (!autoLoadMore || !hasMore || isLoading) return false;

    final position = controller.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    return (maxScroll - currentScroll) <= threshold;
  }

  /// Dispose resources
  void dispose() {
    _items.clear();
  }
}

/// Extension for easy scroll controller integration
extension ScrollControllerPaginationExtension on ScrollController {
  /// Add pagination listener
  ///
  /// Usage:
  /// ```dart
  /// _scrollController.addPaginationListener(
  ///   pagination: _pagination,
  ///   onLoadMore: () => _pagination.loadNextPage(),
  /// );
  /// ```
  void addPaginationListener({
    required PaginationHelper pagination,
    required VoidCallback onLoadMore,
    double threshold = 200.0,
  }) {
    addListener(() {
      if (pagination.shouldLoadMore(this, threshold: threshold)) {
        onLoadMore();
      }
    });
  }
}
