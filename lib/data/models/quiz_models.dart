import 'package:json_annotation/json_annotation.dart';

part 'quiz_models.g.dart';

/// Question type enum
enum QuestionType {
  @JsonValue('MULTIPLE_CHOICE')
  multipleChoice,
  @JsonValue('TRUE_FALSE')
  trueFalse,
  @JsonValue('SHORT_ANSWER')
  shortAnswer,
}

/// Quiz grading method enum
enum QuizGradingMethod {
  @JsonValue('HIGHEST')
  highest,
  @JsonValue('AVERAGE')
  average,
  @JsonValue('FIRST')
  first,
  @JsonValue('LAST')
  last,
}

/// Quiz summary (for lists)
@JsonSerializable()
class QuizSummaryDto {
  final int id;
  final String title;
  final String? description;
  final int passScore;
  final int? maxAttempts;
  final int? timeLimitMinutes;
  final int? cooldownHours;
  @JsonKey(unknownEnumValue: QuizGradingMethod.highest)
  final QuizGradingMethod? gradingMethod;
  final bool? isAssessment;
  final int? orderIndex;
  final int? questionCount;
  final int? moduleId;

  const QuizSummaryDto({
    required this.id,
    required this.title,
    this.description,
    required this.passScore,
    this.maxAttempts,
    this.timeLimitMinutes,
    this.cooldownHours,
    this.gradingMethod,
    this.isAssessment,
    this.orderIndex,
    this.questionCount,
    this.moduleId,
  });

  factory QuizSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$QuizSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizSummaryDtoToJson(this);
}

/// Quiz detail (with questions)
@JsonSerializable()
class QuizDetailDto {
  final int id;
  final String title;
  final String? description;
  final int passScore;
  final int? maxAttempts;
  final int? timeLimitMinutes;
  final int? cooldownHours;
  @JsonKey(unknownEnumValue: QuizGradingMethod.highest)
  final QuizGradingMethod? gradingMethod;
  final bool? isAssessment;
  final int? orderIndex;
  final int? moduleId;
  final List<QuizQuestionDetailDto>? questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuizDetailDto({
    required this.id,
    required this.title,
    this.description,
    required this.passScore,
    this.maxAttempts,
    this.timeLimitMinutes,
    this.cooldownHours,
    this.gradingMethod,
    this.isAssessment,
    this.orderIndex,
    this.moduleId,
    this.questions,
    this.createdAt,
    this.updatedAt,
  });

  factory QuizDetailDto.fromJson(Map<String, dynamic> json) =>
      _$QuizDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizDetailDtoToJson(this);
}

/// Quiz question detail
@JsonSerializable()
class QuizQuestionDetailDto {
  final int id;
  final String questionText;
  final QuestionType questionType;
  final int score;
  final int orderIndex;
  final int? correctOptionCount;
  final List<QuizOptionDto>? options;

  const QuizQuestionDetailDto({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.score,
    required this.orderIndex,
    this.correctOptionCount,
    this.options,
  });

  factory QuizQuestionDetailDto.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionDetailDtoToJson(this);
}

/// Quiz option
@JsonSerializable()
class QuizOptionDto {
  final int id;
  final String optionText;
  final bool correct;
  final String? feedback;
  final int? orderIndex;

  const QuizOptionDto({
    required this.id,
    required this.optionText,
    required this.correct,
    this.feedback,
    this.orderIndex,
  });

  factory QuizOptionDto.fromJson(Map<String, dynamic> json) =>
      _$QuizOptionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizOptionDtoToJson(this);
}

/// Quiz answer (for submission)
@JsonSerializable()
class QuizAnswerDto {
  final int questionId;
  final List<int>? selectedOptionIds;
  final String? textAnswer;

  const QuizAnswerDto({
    required this.questionId,
    this.selectedOptionIds,
    this.textAnswer,
  });

  factory QuizAnswerDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAnswerDtoToJson(this);
}

/// Submit quiz DTO
@JsonSerializable()
class SubmitQuizDto {
  final int quizId;
  final List<QuizAnswerDto> answers;

  /// Optional session token for in-progress attempt session tracking
  final String? sessionToken;

  const SubmitQuizDto({
    required this.quizId,
    required this.answers,
    this.sessionToken,
  });

  factory SubmitQuizDto.fromJson(Map<String, dynamic> json) =>
      _$SubmitQuizDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitQuizDtoToJson(this);
}

/// Quiz attempt result
@JsonSerializable()
class QuizAttemptDto {
  final int? id;
  final int quizId;
  final String? quizTitle;
  final int? userId;

  /// Legacy field — kept for backward compatibility
  @JsonKey(name: 'studentId')
  final int? studentId;

  final int score;
  final bool passed;
  final int? correctAnswers;
  final int? totalQuestions;

  final DateTime? submittedAt;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  final List<QuizAnswerResultDto>? answers;

  const QuizAttemptDto({
    this.id,
    required this.quizId,
    this.quizTitle,
    this.userId,
    this.studentId,
    required this.score,
    required this.passed,
    this.correctAnswers,
    this.totalQuestions,
    this.submittedAt,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.answers,
  });

  factory QuizAttemptDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAttemptDtoToJson(this);
}

/// Quiz answer result (with correctness)
@JsonSerializable()
class QuizAnswerResultDto {
  final int questionId;
  final List<int>? selectedOptionIds;
  final String? textAnswer;
  final bool isCorrect;
  final int scoreEarned;

  const QuizAnswerResultDto({
    required this.questionId,
    this.selectedOptionIds,
    this.textAnswer,
    required this.isCorrect,
    required this.scoreEarned,
  });

  factory QuizAnswerResultDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAnswerResultDtoToJson(this);
}

/// Quiz submit response — backend may return attempt as nested object
@JsonSerializable()
class QuizSubmitResponseDto {
  final int score;
  final bool passed;
  final QuizAttemptDto attempt;

  const QuizSubmitResponseDto({
    required this.score,
    required this.passed,
    required this.attempt,
  });

  /// Custom fromJson to handle both flat and nested response formats.
  /// Backend may return: { score, passed, attempt: {...} }
  /// Or the attempt fields may be at the top level alongside score/passed.
  factory QuizSubmitResponseDto.fromJson(Map<String, dynamic> json) {
    // If 'attempt' is a nested Map, parse normally via codegen
    if (json['attempt'] is Map<String, dynamic>) {
      return _$QuizSubmitResponseDtoFromJson(json);
    }
    // Fallback: attempt fields are at top level (flat response)
    // Construct attempt from the same json map
    return QuizSubmitResponseDto(
      score: (json['score'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      attempt: QuizAttemptDto.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => _$QuizSubmitResponseDtoToJson(this);
}

/// Quiz attempt status (for retry logic and history)
@JsonSerializable()
class QuizAttemptStatusDto {
  final int quizId;
  final int userId;
  final int attemptsUsed;
  final int maxAttempts;
  final bool canRetry;
  final bool hasPassed;
  final int bestScore;
  final int secondsUntilRetry;
  final String? nextRetryAt;
  final List<QuizAttemptDto>? recentAttempts;

  const QuizAttemptStatusDto({
    required this.quizId,
    required this.userId,
    required this.attemptsUsed,
    required this.maxAttempts,
    required this.canRetry,
    required this.hasPassed,
    required this.bestScore,
    required this.secondsUntilRetry,
    this.nextRetryAt,
    this.recentAttempts,
  });

  factory QuizAttemptStatusDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptStatusDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAttemptStatusDtoToJson(this);
}

/// Quiz attempt session (for in-progress guard)
@JsonSerializable()
class QuizAttemptSessionDto {
  final int? quizId;
  final int? userId;
  final String? sessionToken;

  /// Status: IN_PROGRESS, SUBMITTED, EXPIRED, ABANDONED
  final String? status;
  final DateTime? startedAt;
  final DateTime? lastSeenAt;
  final DateTime? expiresAt;

  const QuizAttemptSessionDto({
    this.quizId,
    this.userId,
    this.sessionToken,
    this.status,
    this.startedAt,
    this.lastSeenAt,
    this.expiresAt,
  });

  factory QuizAttemptSessionDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptSessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAttemptSessionDtoToJson(this);
}

// ══════════════════════════════════════════════════════════════
//  MISSING: Quiz Review DTOs — needed for full quiz attempt review
// ══════════════════════════════════════════════════════════════

/// Per-question answer review (returned from /my-latest-review)
@JsonSerializable()
class QuizAttemptAnswerReviewDto {
  final int questionId;
  final int? questionOrderIndex;
  final String? questionText;
  final String? questionTypeRaw;

  /// Submitted answer snapshot — list of selected option IDs
  final List<int>? submittedAnswer;

  /// Snapshot of options at attempt time (for display)
  final List<QuizOptionSnapshotDto>? optionsSnapshot;

  /// Text answer (for SHORT_ANSWER questions)
  final String? submittedAnswerText;

  /// Correct answer display text
  final String? correctAnswerText;

  final bool? answered;
  final bool? correct;
  final int? scoreEarned;

  const QuizAttemptAnswerReviewDto({
    required this.questionId,
    this.questionOrderIndex,
    this.questionText,
    this.questionTypeRaw,
    this.submittedAnswer,
    this.optionsSnapshot,
    this.submittedAnswerText,
    this.correctAnswerText,
    this.answered,
    this.correct,
    this.scoreEarned,
  });

  factory QuizAttemptAnswerReviewDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptAnswerReviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAttemptAnswerReviewDtoToJson(this);
}

/// Option snapshot for review mode
@JsonSerializable()
class QuizOptionSnapshotDto {
  final int optionId;
  final int? orderIndex;
  final String? optionText;
  final bool? correct;
  final bool? selected;
  final String? feedback;

  const QuizOptionSnapshotDto({
    required this.optionId,
    this.orderIndex,
    this.optionText,
    this.correct,
    this.selected,
    this.feedback,
  });

  factory QuizOptionSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$QuizOptionSnapshotDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizOptionSnapshotDtoToJson(this);
}

/// Full quiz attempt review DTO
/// Returned from GET /quizzes/{quizId}/my-latest-review
@JsonSerializable()
class QuizAttemptReviewDto {
  final QuizAttemptDto attempt;
  final List<QuizAttemptAnswerReviewDto>? answers;

  const QuizAttemptReviewDto({
    required this.attempt,
    this.answers,
  });

  factory QuizAttemptReviewDto.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptReviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAttemptReviewDtoToJson(this);
}
