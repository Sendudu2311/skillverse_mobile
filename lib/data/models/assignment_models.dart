import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/date_time_helper.dart';

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
  /// AI has graded; awaiting mentor confirmation (trustAi=false path)
  @JsonValue('AI_PENDING')
  aiPending,
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
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? dueAt;
  final int? moduleId;
  final String? instructions;
  final List<AssignmentCriteriaDto>? criteria;
  final bool? allowLateSubmission;
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? createdAt;
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? updatedAt;

  /// Whether AI grading is enabled for this assignment (maps to backend aiGradingEnabled).
  final bool? aiGradingEnabled;

  /// Whether AI grade is trusted and auto-confirmed without mentor review (maps to backend trustAiEnabled).
  final bool? trustAiEnabled;

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
    this.aiGradingEnabled,
    this.trustAiEnabled,
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
  final double? score;
  final bool? isPassed;
  final SubmissionStatus? status;
  final String? fileMediaUrl;
  final String? submissionText;
  final String? linkUrl;
  final String? feedback;
  final List<CriteriaScoreDto>? criteriaScores;
  final bool? isLate;
  @JsonKey(name: 'gradedByName')
  final String? graderName;
  @JsonKey(name: 'gradedBy')
  final int? graderId;
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? submittedAt;
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? gradedAt;
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? createdAt;

  // AI Grading fields (matches backend AssignmentSubmissionDetailDTO)
  final bool? isAiGraded;
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? aiGradedAt;
  final double? aiScore;
  final String? aiFeedback;
  final double? aiConfidence;
  final bool? mentorConfirmed;
  final int? aiGradeAttemptCount;
  final bool? disputeFlag;
  @JsonKey(fromJson: DateTimeHelper.tryParseIso8601)
  final DateTime? disputeAt;
  final String? disputeReason;

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
    this.isAiGraded,
    this.aiGradedAt,
    this.aiScore,
    this.aiFeedback,
    this.aiConfidence,
    this.mentorConfirmed,
    this.aiGradeAttemptCount,
    this.disputeFlag,
    this.disputeAt,
    this.disputeReason,
  });

  factory AssignmentSubmissionDetailDto.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSubmissionDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentSubmissionDetailDtoToJson(this);
}
