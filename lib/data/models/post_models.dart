import 'package:json_annotation/json_annotation.dart';

part 'post_models.g.dart';

/// Post status enum
enum PostStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('PUBLISHED')
  published,
  @JsonValue('ARCHIVED')
  archived,
}

/// Main post model
@JsonSerializable()
class Post {
  final int id;
  final String? title;
  final String content;
  final PostStatus status;
  @JsonKey(name: 'userId')
  final int authorId;
  @JsonKey(name: 'userFullName')
  final String? authorName;
  @JsonKey(name: 'userAvatar')
  final String? authorAvatar;
  final int likeCount;
  final int commentCount;
  @JsonKey(defaultValue: false)
  final bool isLiked;
  @JsonKey(defaultValue: false)
  final bool isSaved;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? thumbnailUrl;
  final String? category;
  @JsonKey(defaultValue: [])
  final List<String>? tags;
  @JsonKey(defaultValue: 0)
  final int viewCount;
  @JsonKey(defaultValue: 0)
  final int dislikeCount;

  Post({
    required this.id,
    this.title,
    required this.content,
    required this.status,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
    this.updatedAt,
    this.thumbnailUrl,
    this.category,
    this.tags,
    this.viewCount = 0,
    this.dislikeCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({
    int? id,
    String? title,
    String? content,
    PostStatus? status,
    int? authorId,
    String? authorName,
    String? authorAvatar,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailUrl,
    String? category,
    List<String>? tags,
    int? viewCount,
    int? dislikeCount,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
    );
  }
}

/// Comment model
@JsonSerializable()
class Comment {
  final int id;
  final int postId;
  @JsonKey(name: 'userId')
  final int authorId;
  @JsonKey(name: 'userFullName')
  final String? authorName;
  @JsonKey(name: 'userAvatar')
  final String? authorAvatar;
  final String content;
  final bool isHidden;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.content,
    this.isHidden = false,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}

/// Request models
@JsonSerializable()
class PostCreateRequest {
  final String? title;
  final String content;
  final PostStatus status;

  PostCreateRequest({
    this.title,
    required this.content,
    this.status = PostStatus.published,
  });

  factory PostCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PostCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PostCreateRequestToJson(this);
}

@JsonSerializable()
class PostUpdateRequest {
  final String? title;
  final String? content;
  final PostStatus? status;

  PostUpdateRequest({this.title, this.content, this.status});

  factory PostUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$PostUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PostUpdateRequestToJson(this);
}

@JsonSerializable()
class CommentCreateRequest {
  final String content;

  CommentCreateRequest({required this.content});

  factory CommentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$CommentCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CommentCreateRequestToJson(this);
}

/// Paginated response wrapper
@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  final List<T> content;
  @JsonKey(name: 'number')
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;

  PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PageResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}

@JsonSerializable()
class PostStats {
  final int totalPosts;
  final int totalUsers;
  final int totalComments;
  final int totalLikes;
  final int signal;

  PostStats({
    this.totalPosts = 0,
    this.totalUsers = 0,
    this.totalComments = 0,
    this.totalLikes = 0,
    this.signal = 0,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) =>
      _$PostStatsFromJson(json);
  Map<String, dynamic> toJson() => _$PostStatsToJson(this);
}

@JsonSerializable()
class Trend {
  final int count;
  final String topic;

  Trend({required this.count, required this.topic});

  factory Trend.fromJson(Map<String, dynamic> json) => _$TrendFromJson(json);
  Map<String, dynamic> toJson() => _$TrendToJson(this);
}

@JsonSerializable()
class TrendsResponse {
  final List<Trend> trends;

  TrendsResponse({required this.trends});

  factory TrendsResponse.fromJson(Map<String, dynamic> json) =>
      _$TrendsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TrendsResponseToJson(this);
}
