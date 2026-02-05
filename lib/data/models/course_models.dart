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

extension CourseStatusExtension on CourseStatus {
  static CourseStatus? fromString(String? value) {
    if (value == null) return null;
    final upperValue = value.toUpperCase();
    return CourseStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == upperValue,
      orElse: () => CourseStatus.public,
    );
  }
}

enum CourseLevel {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('INTERMEDIATE')
  intermediate,
  @JsonValue('ADVANCED')
  advanced,
}

extension CourseLevelExtension on CourseLevel {
  static CourseLevel? fromString(String? value) {
    if (value == null) return null;
    final upperValue = value.toUpperCase();
    return CourseLevel.values.firstWhere(
      (e) => e.name.toUpperCase() == upperValue,
      orElse: () => CourseLevel.beginner,
    );
  }
}

@JsonSerializable()
class AuthorDto {
  final int id;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? fullName;
  final List<String>? roles;
  final String? authProvider;
  final bool? googleLinked;

  AuthorDto({
    required this.id,
    this.firstName,
    this.lastName,
    required this.email,
    this.fullName,
    this.roles,
    this.authProvider,
    this.googleLinked,
  });

  factory AuthorDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorDtoFromJson(json);
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

  factory MediaDto.fromJson(Map<String, dynamic> json) =>
      _$MediaDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MediaDtoToJson(this);
}

@JsonSerializable()
class CourseSummaryDto {
  final int id;
  final String title;
  final String? description;
  final String? shortDescription;
  @JsonKey(unknownEnumValue: CourseLevel.beginner)
  final CourseLevel level;
  @JsonKey(unknownEnumValue: CourseStatus.public)
  final CourseStatus status;
  final AuthorDto author;
  final String? authorName;
  final MediaDto? thumbnail;
  final String? thumbnailUrl;
  final int enrollmentCount;
  final int? moduleCount;
  final int? lessonCount;
  final double? price;
  final String? currency;
  final double? rating;
  final int? reviewCount;
  final String? createdAt;
  final String? updatedAt;
  final String? submittedDate;
  final String? publishedDate;

  CourseSummaryDto({
    required this.id,
    required this.title,
    this.description,
    this.shortDescription,
    required this.level,
    required this.status,
    required this.author,
    this.authorName,
    this.thumbnail,
    this.thumbnailUrl,
    required this.enrollmentCount,
    this.moduleCount,
    this.lessonCount,
    this.price,
    this.currency,
    this.rating,
    this.reviewCount,
    this.createdAt,
    this.updatedAt,
    this.submittedDate,
    this.publishedDate,
  });

  factory CourseSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$CourseSummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseSummaryDtoToJson(this);
}

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  @JsonKey(name: 'items')
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
    this.page = 0,
    this.size = 10,
    this.totalElements = 0,
    this.totalPages = 1,
    this.first = true,
    this.last = true,
    this.empty = true,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PageResponseFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}

@JsonSerializable()
class CourseDetailDto {
  final int id;
  final String title;
  final String description;
  final String level;
  final String status;
  final AuthorDto author;
  final MediaDto? thumbnail;
  final double? price;
  final String? currency;
  final String? authorName;
  final String? thumbnailUrl;
  final int enrollmentCount;
  final int? moduleCount;
  final int? lessonCount;
  final double? rating;
  final int? reviewCount;
  final String? createdAt;
  final String? updatedAt;
  final String? submittedDate;
  final String? publishedDate;

  CourseDetailDto({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.status,
    required this.author,
    this.thumbnail,
    this.price,
    this.currency,
    this.authorName,
    this.thumbnailUrl,
    required this.enrollmentCount,
    this.moduleCount,
    this.lessonCount,
    this.rating,
    this.reviewCount,
    this.createdAt,
    this.updatedAt,
    this.submittedDate,
    this.publishedDate,
  });

  factory CourseDetailDto.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseDetailDtoToJson(this);
}
