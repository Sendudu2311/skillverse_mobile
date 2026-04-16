import 'package:json_annotation/json_annotation.dart';

part 'lesson_models.g.dart';

/// Attachment type enum — matches backend AttachmentType.java
enum AttachmentType {
  @JsonValue('PDF')
  pdf,
  @JsonValue('DOCX')
  docx,
  @JsonValue('PPTX')
  pptx,
  @JsonValue('XLSX')
  xlsx,
  @JsonValue('EXTERNAL_LINK')
  externalLink,
  @JsonValue('GOOGLE_DRIVE')
  googleDrive,
  @JsonValue('GITHUB')
  github,
  @JsonValue('YOUTUBE')
  youtube,
  @JsonValue('WEBSITE')
  website,
}

/// Lesson attachment — matches backend LessonAttachmentDTO.java
@JsonSerializable()
class LessonAttachmentDto {
  final int id;
  final String title;
  final String? description;
  final String? downloadUrl;
  final AttachmentType? type;
  final int? fileSize;
  final String? fileSizeFormatted;
  final int? orderIndex;
  final String? createdAt;

  const LessonAttachmentDto({
    required this.id,
    required this.title,
    this.description,
    this.downloadUrl,
    this.type,
    this.fileSize,
    this.fileSizeFormatted,
    this.orderIndex,
    this.createdAt,
  });

  factory LessonAttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$LessonAttachmentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LessonAttachmentDtoToJson(this);
}

/// Lesson type enum
enum LessonType {
  @JsonValue('VIDEO')
  video,
  @JsonValue('READING')
  reading,
  @JsonValue('QUIZ')
  quiz,
  @JsonValue('ASSIGNMENT')
  assignment,
  @JsonValue('CODELAB')
  codelab,
}

/// Brief lesson info (for lists)
@JsonSerializable()
class LessonBriefDto {
  final int id;
  final String? title;
  final LessonType? type;
  final int? orderIndex;
  final int? durationSec;
  final String? resourceUrl;

  const LessonBriefDto({
    required this.id,
    this.title,
    this.type,
    this.orderIndex,
    this.durationSec,
    this.resourceUrl,
  });

  factory LessonBriefDto.fromJson(Map<String, dynamic> json) =>
      _$LessonBriefDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LessonBriefDtoToJson(this);
}

/// Detailed lesson info (with content)
@JsonSerializable()
class LessonDetailDto {
  final int id;
  final String title;
  final String type; // String from backend instead of enum
  final int orderIndex;
  final int? durationSec;
  final String? contentText;
  final String? resourceUrl;
  final String? videoUrl;
  final int? videoMediaId;
  final List<LessonAttachmentDto>? attachments;

  const LessonDetailDto({
    required this.id,
    required this.title,
    required this.type,
    required this.orderIndex,
    this.durationSec,
    this.contentText,
    this.resourceUrl,
    this.videoUrl,
    this.videoMediaId,
    this.attachments,
  });

  factory LessonDetailDto.fromJson(Map<String, dynamic> json) =>
      _$LessonDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LessonDetailDtoToJson(this);

  /// Helper to convert string type to enum
  LessonType get lessonType {
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return LessonType.video;
      case 'READING':
        return LessonType.reading;
      case 'QUIZ':
        return LessonType.quiz;
      case 'ASSIGNMENT':
        return LessonType.assignment;
      case 'CODELAB':
        return LessonType.codelab;
      default:
        return LessonType.reading;
    }
  }
}

/// Impacted learning item — returned by revision-info endpoint
@JsonSerializable()
class ImpactedLearningItemDto {
  final int? itemId;
  final String? itemType;
  final String? title;
  final bool? isBreakingChanged;
  final String? breakingReason;
  final String? reasonCode;
  final String? reason;
  final int? sourceRevisionId;
  final int? targetRevisionId;
  final bool? requiresRetake;

  const ImpactedLearningItemDto({
    this.itemId,
    this.itemType,
    this.title,
    this.isBreakingChanged,
    this.breakingReason,
    this.reasonCode,
    this.reason,
    this.sourceRevisionId,
    this.targetRevisionId,
    this.requiresRetake,
  });

  factory ImpactedLearningItemDto.fromJson(Map<String, dynamic> json) =>
      _$ImpactedLearningItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ImpactedLearningItemDtoToJson(this);
}

/// Revision info for a learner on a course
@JsonSerializable()
class CourseLearningRevisionInfoDto {
  final int courseId;
  final int userId;
  final int? learningRevisionId;
  final int? activeRevisionId;
  final int? latestRevisionId;
  final String? upgradePolicy;
  final bool hasNewerRevision;
  final List<ImpactedLearningItemDto> impactedItems;

  const CourseLearningRevisionInfoDto({
    required this.courseId,
    required this.userId,
    this.learningRevisionId,
    this.activeRevisionId,
    this.latestRevisionId,
    this.upgradePolicy,
    this.hasNewerRevision = false,
    this.impactedItems = const [],
  });

  factory CourseLearningRevisionInfoDto.fromJson(Map<String, dynamic> json) =>
      _$CourseLearningRevisionInfoDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$CourseLearningRevisionInfoDtoToJson(this);
}

/// Lesson progress
@JsonSerializable()
class LessonProgressDto {
  final int lessonId;
  final bool completed;
  final DateTime? completedAt;
  final int? watchedSeconds;

  const LessonProgressDto({
    required this.lessonId,
    required this.completed,
    this.completedAt,
    this.watchedSeconds,
  });

  factory LessonProgressDto.fromJson(Map<String, dynamic> json) =>
      _$LessonProgressDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LessonProgressDtoToJson(this);
}
