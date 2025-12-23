import 'package:flutter/material.dart';
import '../../data/models/post_models.dart';
import '../../data/services/post_service.dart';
import '../../core/utils/pagination_helper.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class CommentProvider with ChangeNotifier, LoadingStateProviderMixin {
  final PostService _postService = PostService();
  int? _currentPostId;

  PaginationHelper<Comment>? _paginationHelper;

  PaginationHelper<Comment> get _pagination {
    _paginationHelper ??= PaginationHelper<Comment>(
      fetchPage: (page) async {
        if (_currentPostId == null) {
          throw Exception('Post ID not set');
        }

        final PageResponse<Comment> response = await _postService.getComments(
          _currentPostId!,
          page: page - 1, // API uses 0-based pagination
          size: 20,
        );

        return PaginatedResponse<Comment>(
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

  /// Get comments
  List<Comment> get comments => _pagination.items;

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
  PaginationHelper<Comment> get pagination => _pagination;

  /// Load comments for a post
  Future<void> loadComments(int postId, {bool refresh = false}) async {
    if (_currentPostId != postId) {
      _currentPostId = postId;
      _paginationHelper = null; // Reset pagination when post changes
    }

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

  /// Add new comment
  Future<Comment?> addComment(int postId, String content) async {
    return await executeAsync(() async {
      final comment = await _postService.addComment(postId, content);

      // Add to beginning of list
      _pagination.items.insert(0, comment);
      notifyListeners();

      return comment;
    }, errorMessageBuilder: (e) => 'Lỗi thêm bình luận: ${e.toString()}');
  }

  /// Hide comment
  Future<void> hideComment(int postId, int commentId, {String? reason}) async {
    await executeAsync(() async {
      await _postService.hideComment(postId, commentId, reason);

      // Update in list
      final index = _pagination.items.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final updatedComment = Comment(
          id: _pagination.items[index].id,
          postId: _pagination.items[index].postId,
          authorId: _pagination.items[index].authorId,
          authorName: _pagination.items[index].authorName,
          authorAvatar: _pagination.items[index].authorAvatar,
          content: _pagination.items[index].content,
          isHidden: true,
          createdAt: _pagination.items[index].createdAt,
        );
        _pagination.items[index] = updatedComment;
        notifyListeners();
      }
    }, errorMessageBuilder: (e) => 'Lỗi ẩn bình luận: ${e.toString()}');
  }

  /// Refresh comments
  Future<void> refresh() async {
    await _pagination.refresh();
  }

  /// Reset provider state
  void reset() {
    _pagination.reset();
    _currentPostId = null;
    resetState();
  }

  @override
  void dispose() {
    _paginationHelper?.dispose();
    super.dispose();
  }
}
