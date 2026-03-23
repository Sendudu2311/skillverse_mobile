import 'package:json_annotation/json_annotation.dart';

part 'journey_models.g.dart';

// ============================================================
// Enums
// ============================================================

/// Journey type: career-focused or skill-focused
enum JourneyType {
  @JsonValue('CAREER')
  career,
  @JsonValue('SKILL')
  skill,
}

/// Journey status — 10 states in the lifecycle
enum JourneyStatus {
  @JsonValue('NOT_STARTED')
  notStarted,
  @JsonValue('ASSESSMENT_PENDING')
  assessmentPending,
  @JsonValue('TEST_IN_PROGRESS')
  testInProgress,
  @JsonValue('EVALUATION_PENDING')
  evaluationPending,
  @JsonValue('ROADMAP_GENERATED')
  roadmapGenerated,
  @JsonValue('STUDY_PLAN_IN_PROGRESS')
  studyPlanInProgress,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('PAUSED')
  paused,
  @JsonValue('CANCELLED')
  cancelled,
}

/// Skill level assessed by AI
enum SkillLevel {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('ELEMENTARY')
  elementary,
  @JsonValue('INTERMEDIATE')
  intermediate,
  @JsonValue('ADVANCED')
  advanced,
  @JsonValue('EXPERT')
  expert,
}

/// Assessment test status
enum TestStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('EXPIRED')
  expired,
}

/// Journey milestones for progress tracking
enum JourneyMilestone {
  @JsonValue('ASSESSMENT_COMPLETED')
  assessmentCompleted,
  @JsonValue('TEST_GENERATED')
  testGenerated,
  @JsonValue('TEST_COMPLETED')
  testCompleted,
  @JsonValue('EVALUATION_COMPLETED')
  evaluationCompleted,
  @JsonValue('ROADMAP_CREATED')
  roadmapCreated,
  @JsonValue('STUDY_PLAN_CREATED')
  studyPlanCreated,
  @JsonValue('FIRST_NODE_COMPLETED')
  firstNodeCompleted,
  @JsonValue('JOURNEY_COMPLETED')
  journeyCompleted,
}

// ============================================================
// Request DTOs
// ============================================================

/// Request to start a new guided journey
@JsonSerializable()
class StartJourneyRequest {
  @JsonKey(unknownEnumValue: JourneyType.skill)
  final JourneyType? type;
  final String domain;
  final String goal;
  final String level;
  final String? jobRole;
  final String? subCategory;
  final List<String>? skills;
  final List<String>? focusAreas;
  final String? language;
  final String? duration;

  const StartJourneyRequest({
    this.type,
    required this.domain,
    required this.goal,
    required this.level,
    this.jobRole,
    this.subCategory,
    this.skills,
    this.focusAreas,
    this.language,
    this.duration,
  });

  factory StartJourneyRequest.fromJson(Map<String, dynamic> json) =>
      _$StartJourneyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartJourneyRequestToJson(this);
}

/// Request to submit test answers
@JsonSerializable()
class SubmitTestRequest {
  final int testId;
  final Map<String, String> answers;
  final int? timeSpentSeconds;

  const SubmitTestRequest({
    required this.testId,
    required this.answers,
    this.timeSpentSeconds,
  });

  factory SubmitTestRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitTestRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitTestRequestToJson(this);
}

// ============================================================
// Response DTOs
// ============================================================

/// Milestone progress within a journey
@JsonSerializable()
class MilestoneDto {
  final String milestone;
  final bool isCompleted;
  final String? completedAt;

  const MilestoneDto({
    required this.milestone,
    required this.isCompleted,
    this.completedAt,
  });

  factory MilestoneDto.fromJson(Map<String, dynamic> json) =>
      _$MilestoneDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MilestoneDtoToJson(this);
}

/// Test result summary (nested in JourneySummaryDto)
@JsonSerializable()
class TestResultSummaryDto {
  final int? resultId;
  final int scorePercentage;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel evaluatedLevel;
  final int skillGapsCount;
  final int strengthsCount;
  final String? evaluatedAt;

  const TestResultSummaryDto({
    this.resultId,
    required this.scorePercentage,
    required this.evaluatedLevel,
    required this.skillGapsCount,
    required this.strengthsCount,
    this.evaluatedAt,
  });

  factory TestResultSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TestResultSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TestResultSummaryDtoToJson(this);
}

/// Journey summary (main response object)
@JsonSerializable()
class JourneySummaryDto {
  final int id;
  final String? type;
  final String domain;
  final String? subCategory;
  final String? jobRole;
  final String goal;
  @JsonKey(unknownEnumValue: JourneyStatus.notStarted)
  final JourneyStatus status;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? currentLevel;
  final int progressPercentage;
  final String? aiSummaryReport;
  final String? startedAt;
  final String? completedAt;
  final String? lastActivityAt;
  final String? createdAt;

  // Related data
  final int? roadmapSessionId;
  final int? totalNodesCompleted;
  final List<MilestoneDto>? milestones;
  final TestResultSummaryDto? latestTestResult;

  // Assessment test info
  final int? assessmentTestId;
  final String? assessmentTestTitle;
  final int? assessmentTestQuestionCount;
  final String? assessmentTestStatus;
  final int? assessmentAttemptCount;
  final int? maxAssessmentAttempts;
  final int? remainingAssessmentRetakes;

  const JourneySummaryDto({
    required this.id,
    this.type,
    required this.domain,
    this.subCategory,
    this.jobRole,
    required this.goal,
    required this.status,
    this.currentLevel,
    required this.progressPercentage,
    this.aiSummaryReport,
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    this.createdAt,
    this.roadmapSessionId,
    this.totalNodesCompleted,
    this.milestones,
    this.latestTestResult,
    this.assessmentTestId,
    this.assessmentTestTitle,
    this.assessmentTestQuestionCount,
    this.assessmentTestStatus,
    this.assessmentAttemptCount,
    this.maxAssessmentAttempts,
    this.remainingAssessmentRetakes,
  });

  factory JourneySummaryDto.fromJson(Map<String, dynamic> json) =>
      _$JourneySummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$JourneySummaryDtoToJson(this);
}

/// AI-generated assessment test response
@JsonSerializable()
class GenerateTestResponseDto {
  final int? journeyId;
  final int? testId;
  final String? title;
  final String? description;
  final String? targetField;
  final int? questionCount;
  final int? timeLimitMinutes;
  final String? difficultyLevel;
  final String? questionsJson;
  final String? message;

  const GenerateTestResponseDto({
    this.journeyId,
    this.testId,
    this.title,
    this.description,
    this.targetField,
    this.questionCount,
    this.timeLimitMinutes,
    this.difficultyLevel,
    this.questionsJson,
    this.message,
  });

  factory GenerateTestResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GenerateTestResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateTestResponseDtoToJson(this);
}

/// Assessment test details
@JsonSerializable()
class AssessmentTestDto {
  final int id;
  final String title;
  final String? description;
  final String? targetField;
  @JsonKey(unknownEnumValue: TestStatus.pending)
  final TestStatus status;
  final int? questionCount;
  final int? timeLimitMinutes;
  final String? difficultyLevel;
  final String? questionsJson;
  final String? createdAt;
  final bool? showResults;

  const AssessmentTestDto({
    required this.id,
    required this.title,
    this.description,
    this.targetField,
    required this.status,
    this.questionCount,
    this.timeLimitMinutes,
    this.difficultyLevel,
    this.questionsJson,
    this.createdAt,
    this.showResults,
  });

  factory AssessmentTestDto.fromJson(Map<String, dynamic> json) =>
      _$AssessmentTestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssessmentTestDtoToJson(this);
}

/// Test result after AI evaluation
@JsonSerializable()
class TestResultDto {
  final int id;
  final int? journeyId;
  final int? assessmentTestId;
  final int scorePercentage;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel evaluatedLevel;
  final String? skillGapsJson;
  final String? strengthsJson;
  final String? evaluationSummary;
  final String? userAnswersJson;
  final String? correctAnswersJson;
  final String? evaluatedAt;
  final String? createdAt;

  // Computed fields from backend
  final int? totalQuestions;
  final int? correctAnswers;
  final int? incorrectAnswers;
  final int? answeredQuestions;
  final String? scoreBand;
  final String? recommendationMode;
  final int? assessmentConfidence;
  final bool? reassessmentRecommended;

  const TestResultDto({
    required this.id,
    this.journeyId,
    this.assessmentTestId,
    required this.scorePercentage,
    required this.evaluatedLevel,
    this.skillGapsJson,
    this.strengthsJson,
    this.evaluationSummary,
    this.userAnswersJson,
    this.correctAnswersJson,
    this.evaluatedAt,
    this.createdAt,
    this.totalQuestions,
    this.correctAnswers,
    this.incorrectAnswers,
    this.answeredQuestions,
    this.scoreBand,
    this.recommendationMode,
    this.assessmentConfidence,
    this.reassessmentRecommended,
  });

  factory TestResultDto.fromJson(Map<String, dynamic> json) =>
      _$TestResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TestResultDtoToJson(this);
}
