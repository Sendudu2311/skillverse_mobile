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

/// Quiz summary (for lists)
@JsonSerializable()
class QuizSummaryDto {
  final int id;
  final String title;
  final String? description;
  final int passScore;
  final int? questionCount;
  final int? moduleId;

  const QuizSummaryDto({
    required this.id,
    required this.title,
    this.description,
    required this.passScore,
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
  final int? moduleId;
  final List<QuizQuestionDetailDto>? questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuizDetailDto({
    required this.id,
    required this.title,
    this.description,
    required this.passScore,
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
  final List<QuizOptionDto>? options;

  const QuizQuestionDetailDto({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.score,
    required this.orderIndex,
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

  const SubmitQuizDto({required this.quizId, required this.answers});

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

  @JsonKey(name: 'userId')
  final int studentId;

  final int score;
  final bool passed;
  final int? correctAnswers;
  final int? totalQuestions;

  final DateTime? submittedAt;
  final DateTime? createdAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final DateTime? startedAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final DateTime? completedAt;

  final List<QuizAnswerResultDto>? answers;

  const QuizAttemptDto({
    this.id,
    required this.quizId,
    this.quizTitle,
    required this.studentId,
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

/// Quiz submit response
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

  factory QuizSubmitResponseDto.fromJson(Map<String, dynamic> json) =>
      _$QuizSubmitResponseDtoFromJson(json);

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
