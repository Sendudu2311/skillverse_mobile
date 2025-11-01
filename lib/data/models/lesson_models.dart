import 'package:json_annotation/json_annotation.dart';

part 'lesson_models.g.dart';

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
  final String title;
  final LessonType type;
  final int orderIndex;
  final int? durationSec;

  const LessonBriefDto({
    required this.id,
    required this.title,
    required this.type,
    required this.orderIndex,
    this.durationSec,
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
  final String? videoUrl;
  final int? videoMediaId;

  const LessonDetailDto({
    required this.id,
    required this.title,
    required this.type,
    required this.orderIndex,
    this.durationSec,
    this.contentText,
    this.videoUrl,
    this.videoMediaId,
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
