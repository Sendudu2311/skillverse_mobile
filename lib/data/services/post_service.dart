import 'package:flutter/foundation.dart';
import '../models/post_models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';

class PostService {
  final ApiClient _apiClient = ApiClient();

  /// Get posts with optional filters
  Future<PageResponse<Post>> getPosts({
    String? search,
    PostStatus? status,
    int? authorId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (status != null) {
        queryParams['status'] = status.name.toUpperCase();
      }

      if (authorId != null) {
        queryParams['authorId'] = authorId;
      }

      final response = await _apiClient.dio.get(
        '/posts',
        queryParameters: queryParams,
      );

      try {
        return PageResponse.fromJson(response.data, (json) {
          try {
            final jsonMap = json as Map<String, dynamic>;
            return Post.fromJson(jsonMap);
          } catch (e, stackTrace) {
            debugPrint('❌ Error parsing post JSON: $e\nStackTrace: $stackTrace');
            rethrow;
          }
        });
      } catch (e, stackTrace) {
        debugPrint('❌ Error in PageResponse.fromJson: $e\nStackTrace: $stackTrace');
        rethrow;
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single post by ID
  Future<Post> getPostById(int id) async {
    try {
      final response = await _apiClient.dio.get('/posts/$id');
      return Post.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new post
  Future<Post> createPost(PostCreateRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/posts',
        data: request.toJson(),
      );
      return Post.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update existing post
  Future<Post> updatePost(int id, PostUpdateRequest request) async {
    try {
      final response = await _apiClient.dio.put(
        '/posts/$id',
        data: request.toJson(),
      );
      return Post.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete post
  Future<void> deletePost(int id) async {
    try {
      await _apiClient.dio.delete('/posts/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Like a post
  Future<Post> likePost(int id) async {
    try {
      final response = await _apiClient.dio.post('/posts/$id/like');
      return Post.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Unlike a post (dislike endpoint)
  Future<Post> unlikePost(int id) async {
    try {
      final response = await _apiClient.dio.post('/posts/$id/dislike');
      return Post.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Save/bookmark a post
  Future<void> savePost(int id) async {
    try {
      await _apiClient.dio.post('/posts/$id/save');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get saved posts
  Future<PageResponse<Post>> getSavedPosts({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/posts/saved',
        queryParameters: {'page': page, 'size': size},
      );

      return PageResponse.fromJson(
        response.data,
        (json) => Post.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get comments for a post
  Future<PageResponse<Comment>> getComments(
    int postId, {
    bool includeHidden = false,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/posts/$postId/comments',
        queryParameters: {
          'includeHidden': includeHidden,
          'page': page,
          'size': size,
        },
      );

      return PageResponse.fromJson(
        response.data,
        (json) => Comment.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Add comment to a post
  Future<Comment> addComment(int postId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/posts/$postId/comments',
        data: CommentCreateRequest(content: content).toJson(),
      );
      return Comment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Hide comment (soft delete)
  Future<void> hideComment(int postId, int commentId, String? reason) async {
    try {
      await _apiClient.dio.post(
        '/posts/$postId/comments/$commentId/hide',
        data: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Unhide comment
  Future<void> unhideComment(int postId, int commentId) async {
    try {
      await _apiClient.dio.post('/posts/$postId/comments/$commentId/unhide');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Report comment
  Future<void> reportComment(int postId, int commentId, String reason) async {
    try {
      await _apiClient.dio.post(
        '/posts/$postId/comments/$commentId/report',
        data: {'reason': reason},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get post statistics
  Future<PostStats> getStats() async {
    try {
      final response = await _apiClient.dio.get('/posts/stats');
      return PostStats.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get trending posts
  Future<List<Trend>> getTrends() async {
    try {
      final response = await _apiClient.dio.get('/posts/trends');
      return TrendsResponse.fromJson(response.data).trends;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors
  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
