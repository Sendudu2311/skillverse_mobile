import 'package:json_annotation/json_annotation.dart';

part 'course_models.g.dart';

enum CourseStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('PENDING')
  pending,
  @JsonValue('PUBLIC')
  public,
  @JsonValue('ARCHIVED')
  archived,
}

enum CourseLevel {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('INTERMEDIATE')
  intermediate,
  @JsonValue('ADVANCED')
  advanced,
}

@JsonSerializable()
class AuthorDto {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? fullName;

  AuthorDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.fullName,
  });

  factory AuthorDto.fromJson(Map<String, dynamic> json) => _$AuthorDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorDtoToJson(this);
}

@JsonSerializable()
class MediaDto {
  final int id;
  final String url;
  final String type;
  final String fileName;
  final int? fileSize;
  final int? uploadedBy;
  final String? uploadedByName;
  final String? uploadedAt;

  MediaDto({
    required this.id,
    required this.url,
    required this.type,
    required this.fileName,
    this.fileSize,
    this.uploadedBy,
    this.uploadedByName,
    this.uploadedAt,
  });

  factory MediaDto.fromJson(Map<String, dynamic> json) => _$MediaDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MediaDtoToJson(this);
}

@JsonSerializable()
class CourseSummaryDto {
  final int id;
  final String title;
  final String description;
  final String? shortDescription;
  final CourseLevel level;
  final CourseStatus status;
  final AuthorDto author;
  final String? authorName;
  final MediaDto? thumbnail;
  final String? thumbnailUrl;
  final int enrollmentCount;
  final double? price;
  final String? currency;
  final double? rating;
  final int? reviewCount;
  final String? createdAt;
  final String? updatedAt;

  CourseSummaryDto({
    required this.id,
    required this.title,
    required this.description,
    this.shortDescription,
    required this.level,
    required this.status,
    required this.author,
    this.authorName,
    this.thumbnail,
    this.thumbnailUrl,
    required this.enrollmentCount,
    this.price,
    this.currency,
    this.rating,
    this.reviewCount,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseSummaryDto.fromJson(Map<String, dynamic> json) => _$CourseSummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseSummaryDtoToJson(this);
}

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  @JsonKey(name: 'items', defaultValue: [])
  final List<T>? content;
  @JsonKey(defaultValue: 0)
  final int page;
  @JsonKey(defaultValue: 10)
  final int size;
  @JsonKey(name: 'total', defaultValue: 0)
  final int totalElements;
  @JsonKey(defaultValue: 1)
  final int totalPages;
  @JsonKey(defaultValue: true)
  final bool first;
  @JsonKey(defaultValue: true)
  final bool last;
  @JsonKey(defaultValue: true)
  final bool empty;

  PageResponse({
    this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PageResponseFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => _$PageResponseToJson(this, toJsonT);
}