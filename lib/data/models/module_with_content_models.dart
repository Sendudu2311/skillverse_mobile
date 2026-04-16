import 'package:json_annotation/json_annotation.dart';
import 'lesson_models.dart';

part 'module_with_content_models.g.dart';

/// Brief quiz info returned from /modules/full endpoint
@JsonSerializable()
class QuizBriefDto {
  final int id;
  final String? title;
  final String? description;
  final int? passScore;
  final int? orderIndex;
  final int? questionCount;

  const QuizBriefDto({
    required this.id,
    this.title,
    this.description,
    this.passScore,
    this.orderIndex,
    this.questionCount,
  });

  factory QuizBriefDto.fromJson(Map<String, dynamic> json) =>
      _$QuizBriefDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizBriefDtoToJson(this);
}

/// Brief assignment info returned from /modules/full endpoint
@JsonSerializable()
class AssignmentBriefDto {
  final int id;
  final String? title;
  final String? description;
  final String? submissionType;
  final int? maxScore;
  final int? orderIndex;

  const AssignmentBriefDto({
    required this.id,
    this.title,
    this.description,
    this.submissionType,
    this.maxScore,
    this.orderIndex,
  });

  factory AssignmentBriefDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentBriefDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentBriefDtoToJson(this);
}

/// Module with full content (lessons + quizzes + assignments)
/// Returned from GET /courses/{courseId}/modules/full
@JsonSerializable()
class ModuleWithContentDto {
  final int id;
  final String? title;
  final String? description;
  final int? orderIndex;
  final List<LessonBriefDto> lessons;
  final List<QuizBriefDto> quizzes;
  final List<AssignmentBriefDto> assignments;

  const ModuleWithContentDto({
    required this.id,
    this.title,
    this.description,
    this.orderIndex,
    this.lessons = const [],
    this.quizzes = const [],
    this.assignments = const [],
  });

  factory ModuleWithContentDto.fromJson(Map<String, dynamic> json) =>
      _$ModuleWithContentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleWithContentDtoToJson(this);
}
