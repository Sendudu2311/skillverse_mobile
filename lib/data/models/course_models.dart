import 'package:json_annotation/json_annotation.dart';
import 'module_models.dart';

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
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('SUSPENDED')
  suspended,
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
  final String? category;
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
  final int? estimatedDurationHours;
  final String? language;
  final double? rating;
  final int? reviewCount;
  final String? createdAt;
  final String? updatedAt;
  final String? submittedDate;
  final String? publishedDate;
  final String? rejectionReason;

  CourseSummaryDto({
    required this.id,
    required this.title,
    this.description,
    this.shortDescription,
    this.category,
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
    this.estimatedDurationHours,
    this.language,
    this.rating,
    this.reviewCount,
    this.createdAt,
    this.updatedAt,
    this.submittedDate,
    this.publishedDate,
    this.rejectionReason,
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
  final String? description;
  final String? shortDescription;
  final String? category;
  final String? level;
  final String? status;
  final AuthorDto author;
  final MediaDto? thumbnail;
  final double? price;
  final String? currency;
  final String? authorName;
  final String? thumbnailUrl;
  final int enrollmentCount;
  final int? moduleCount;
  final int? lessonCount;
  final int? estimatedDurationHours;
  final String? language;
  final List<String>? learningObjectives;
  final List<String>? requirements;
  final List<String>? courseSkills;
  final double? rating;
  final int? reviewCount;
  final String? createdAt;
  final String? updatedAt;
  final String? submittedDate;
  final String? publishedDate;
  final String? rejectionReason;
  final String? rejectedAt;
  final String? suspensionReason;
  final String? suspendedAt;
  final String? upgradePolicy;
  final String? upgradePolicyStatusMessage;
  final List<ModuleSummaryDto>? modules;

  CourseDetailDto({
    required this.id,
    required this.title,
    this.description,
    this.shortDescription,
    this.category,
    this.level,
    this.status,
    required this.author,
    this.thumbnail,
    this.price,
    this.currency,
    this.authorName,
    this.thumbnailUrl,
    required this.enrollmentCount,
    this.moduleCount,
    this.lessonCount,
    this.estimatedDurationHours,
    this.language,
    this.learningObjectives,
    this.requirements,
    this.courseSkills,
    this.rating,
    this.reviewCount,
    this.createdAt,
    this.updatedAt,
    this.submittedDate,
    this.publishedDate,
    this.rejectionReason,
    this.rejectedAt,
    this.suspensionReason,
    this.suspendedAt,
    this.upgradePolicy,
    this.upgradePolicyStatusMessage,
    this.modules,
  });

  factory CourseDetailDto.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CourseDetailDtoToJson(this);
}
