import 'package:flutter/material.dart';
import '../../data/models/post_models.dart';
import '../../data/services/post_service.dart';
import '../../core/utils/pagination_helper.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class PostProvider with ChangeNotifier, LoadingStateProviderMixin {
  final PostService _postService = PostService();

  // Filter state
  PostStatus? _statusFilter;
  String? _searchQuery;
  int? _authorFilter;
  String? _categoryFilter;
  bool _showSavedOnly = false;

  // Stats and Trends
  PostStats? _stats;
  List<Trend> _trends = [];
  bool _isLoadingStats = false;

  PostStatus? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;
  bool get showSavedOnly => _showSavedOnly;

  PostStats? get stats => _stats;
  List<Trend> get trends => _trends;
  bool get isLoadingStats => _isLoadingStats;

  // Lazy initialization to avoid LateInitializationError
  PaginationHelper<Post>? _paginationHelper;

  PaginationHelper<Post> get _pagination {
    _paginationHelper ??= PaginationHelper<Post>(
      fetchPage: (page) async {
        final PageResponse<Post> response;

        if (_showSavedOnly) {
          response = await _postService.getSavedPosts(
            page: page - 1, // API uses 0-based pagination
            size: 20,
          );
        } else {
          response = await _postService.getPosts(
            search: _searchQuery,
            status: _statusFilter,
            authorId: _authorFilter,
            page: page - 1,
            size: 20,
          );
        }

        return PaginatedResponse<Post>(
          data: response.content,
          currentPage: page,
          totalPages: response.totalPages,
          totalItems: response.totalElements,
          hasMore: !response.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
    return _paginationHelper!;
  }

  /// Get posts (with client-side category filter)
  List<Post> get posts {
    final allPosts = _pagination.items;

    // Apply client-side category filter
    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      return allPosts
          .where((post) => post.category == _categoryFilter)
          .toList();
    }

    return allPosts;
  }

  /// Check if has more pages
  bool get hasMorePages => _pagination.hasMore;

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
  PaginationHelper<Post> get pagination => _pagination;

  /// Load posts
  Future<void> loadPosts({bool refresh = false}) async {
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

  /// Search posts
  Future<void> searchPosts(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    _paginationHelper = null; // Reset pagination
    await loadPosts(refresh: true);
  }

  /// Filter by status
  Future<void> filterByStatus(PostStatus? status) async {
    _statusFilter = status;
    _showSavedOnly = false;
    _paginationHelper = null; // Reset pagination
    await loadPosts(refresh: true);
  }

  /// Filter by author
  Future<void> filterByAuthor(int? authorId) async {
    _authorFilter = authorId;
    _showSavedOnly = false;
    _paginationHelper = null; // Reset pagination
    await loadPosts(refresh: true);
  }

  /// Filter by category.
  /// Client-side when already in normal mode; reloads from API when
  /// transitioning out of saved-posts mode (pagination holds wrong dataset).
  Future<void> filterByCategory(String? category) async {
    _categoryFilter = category;
    if (_showSavedOnly) {
      // Must reload: pagination was fetching saved posts, need regular posts.
      _showSavedOnly = false;
      _paginationHelper = null;
      await loadPosts(refresh: true);
    } else {
      _showSavedOnly = false;
      notifyListeners();
    }
  }

  /// Show saved posts only
  Future<void> showSavedPosts() async {
    _showSavedOnly = true;
    _statusFilter = null;
    _authorFilter = null;
    _searchQuery = null;
    _paginationHelper = null; // Reset pagination
    await loadPosts(refresh: true);
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _statusFilter = null;
    _searchQuery = null;
    _authorFilter = null;
    _categoryFilter = null;
    _showSavedOnly = false;
    _paginationHelper = null; // Reset pagination
    await loadPosts(refresh: true);
  }

  /// Create new post
  Future<Post?> createPost(String content, {String? title}) async {
    return await executeAsync(() async {
      final request = PostCreateRequest(
        title: title,
        content: content,
        status: PostStatus.published,
      );
      final post = await _postService.createPost(request);

      // Add to beginning of list if no filters active
      if (_statusFilter == null &&
          _searchQuery == null &&
          _authorFilter == null &&
          !_showSavedOnly) {
        _pagination.items.insert(0, post);
        notifyListeners();
      }

      return post;
    }, errorMessageBuilder: (e) => 'Lỗi tạo bài viết: ${e.toString()}');
  }

  /// Update post
  Future<Post?> updatePost(
    int postId, {
    String? title,
    String? content,
    PostStatus? status,
  }) async {
    return await executeAsync(() async {
      final request = PostUpdateRequest(
        title: title,
        content: content,
        status: status,
      );
      final updatedPost = await _postService.updatePost(postId, request);

      // Update in list
      final index = _pagination.items.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _pagination.items[index] = updatedPost;
        notifyListeners();
      }

      return updatedPost;
    }, errorMessageBuilder: (e) => 'Lỗi cập nhật bài viết: ${e.toString()}');
  }

  /// Delete post
  Future<void> deletePost(int postId) async {
    await executeAsync(() async {
      await _postService.deletePost(postId);

      // Remove from list
      _pagination.items.removeWhere((p) => p.id == postId);
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi xóa bài viết: ${e.toString()}');
  }

  /// Toggle like on post
  Future<void> toggleLike(int postId) async {
    // Find post in list
    final index = _pagination.items.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _pagination.items[index];
    final wasLiked = post.isLiked;

    // Optimistic update
    _pagination.items[index] = post.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    notifyListeners();

    // API call
    try {
      final updatedPost = wasLiked
          ? await _postService.unlikePost(postId)
          : await _postService.likePost(postId);

      // Update with real data
      _pagination.items[index] = updatedPost;
      notifyListeners();
    } catch (e) {
      // Revert on error
      _pagination.items[index] = post;
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle save on post
  Future<void> toggleSave(int postId) async {
    // Find post in list
    final index = _pagination.items.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _pagination.items[index];
    final wasSaved = post.isSaved;

    // Optimistic update
    _pagination.items[index] = post.copyWith(isSaved: !wasSaved);
    notifyListeners();

    // API call
    try {
      await _postService.savePost(postId);
    } catch (e) {
      // Revert on error
      _pagination.items[index] = post;
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh posts
  Future<void> refresh() async {
    // Refresh stats and trends concurrently with posts
    fetchStatsAndTrends();
    await _pagination.refresh();
  }

  /// Fetch stats and trends
  Future<void> fetchStatsAndTrends() async {
    _isLoadingStats = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _postService.getStats(),
        _postService.getTrends(),
      ]);
      _stats = results[0] as PostStats;
      _trends = results[1] as List<Trend>;
    } catch (e) {
      debugPrint('Error fetching stats/trends: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Reset provider state
  void reset() {
    _pagination.reset();
    _statusFilter = null;
    _searchQuery = null;
    _authorFilter = null;
    _showSavedOnly = false;
    _stats = null;
    _trends = [];
    resetState();
  }

  @override
  void dispose() {
    _paginationHelper?.dispose();
    super.dispose();
  }
}
