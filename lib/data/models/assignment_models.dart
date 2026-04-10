import 'package:json_annotation/json_annotation.dart';

part 'assignment_models.g.dart';

/// Submission type enum
enum SubmissionType {
  @JsonValue('TEXT')
  text,
  @JsonValue('LINK')
  link,
  @JsonValue('FILE')
  file,
  @JsonValue('TEXT_AND_FILE')
  textAndFile,
  @JsonValue('LINK_AND_FILE')
  linkAndFile,
}

/// Submission status enum
enum SubmissionStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('LATE_PENDING')
  latePending,
  @JsonValue('GRADED')
  graded,
  @JsonValue('LATE_GRADED')
  lateGraded,
  @JsonValue('REJECTED')
  rejected,
}

/// Assignment detail (full info)
@JsonSerializable()
class AssignmentDetailDto {
  final int id;
  final String title;
  final String? description;
  final int? maxScore;
  final int? passingScore;
  final SubmissionType? submissionType;
  final DateTime? dueAt;
  final int? moduleId;
  final String? instructions;
  final List<AssignmentCriteriaDto>? criteria;
  final bool? allowLateSubmission;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssignmentDetailDto({
    required this.id,
    required this.title,
    this.description,
    this.maxScore,
    this.passingScore,
    this.submissionType,
    this.dueAt,
    this.moduleId,
    this.instructions,
    this.criteria,
    this.allowLateSubmission,
    this.createdAt,
    this.updatedAt,
  });

  factory AssignmentDetailDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentDetailDtoToJson(this);
}

/// Assignment rubric criteria
@JsonSerializable()
class AssignmentCriteriaDto {
  final int id;
  final String name;
  final String? description;
  final int maxPoints;
  final int passingPoints;
  final int? orderIndex;

  const AssignmentCriteriaDto({
    required this.id,
    required this.name,
    this.description,
    required this.maxPoints,
    required this.passingPoints,
    this.orderIndex,
  });

  factory AssignmentCriteriaDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentCriteriaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentCriteriaDtoToJson(this);
}

/// Criteria score (in submission grading result)
@JsonSerializable()
class CriteriaScoreDto {
  final int? criteriaId;
  final String? criteriaName;
  final int? score;
  final int? maxPoints;
  final int? passingPoints;
  final bool? passed;
  final String? feedback;

  const CriteriaScoreDto({
    this.criteriaId,
    this.criteriaName,
    this.score,
    this.maxPoints,
    this.passingPoints,
    this.passed,
    this.feedback,
  });

  factory CriteriaScoreDto.fromJson(Map<String, dynamic> json) =>
      _$CriteriaScoreDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CriteriaScoreDtoToJson(this);
}

/// Assignment submission DTO (for submit request)
@JsonSerializable()
class AssignmentSubmissionCreateDto {
  /// Media ID if submitting a file
  final int? fileMediaId;
  /// Text content for TEXT submission type
  final String? submissionText;
  /// URL for LINK submission type
  final String? linkUrl;

  const AssignmentSubmissionCreateDto({
    this.fileMediaId,
    this.submissionText,
    this.linkUrl,
  });

  factory AssignmentSubmissionCreateDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSubmissionCreateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentSubmissionCreateDtoToJson(this);
}

/// Assignment submission detail (full response from API)
@JsonSerializable()
class AssignmentSubmissionDetailDto {
  final int id;
  final int assignmentId;
  final String? assignmentTitle;
  final int? userId;
  final int attemptNumber;
  final bool isNewest;
  final bool isPrevious;
  final int? score;
  final bool? isPassed;
  final SubmissionStatus? status;
  final String? fileMediaUrl;
  final String? submissionText;
  final String? linkUrl;
  final String? feedback;
  final List<CriteriaScoreDto>? criteriaScores;
  final bool? isLate;
  final String? graderName;
  final int? graderId;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime? createdAt;

  const AssignmentSubmissionDetailDto({
    required this.id,
    required this.assignmentId,
    this.assignmentTitle,
    this.userId,
    required this.attemptNumber,
    required this.isNewest,
    required this.isPrevious,
    this.score,
    this.isPassed,
    this.status,
    this.fileMediaUrl,
    this.submissionText,
    this.linkUrl,
    this.feedback,
    this.criteriaScores,
    this.isLate,
    this.graderName,
    this.graderId,
    this.submittedAt,
    this.gradedAt,
    this.createdAt,
  });

  factory AssignmentSubmissionDetailDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSubmissionDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentSubmissionDetailDtoToJson(this);
}