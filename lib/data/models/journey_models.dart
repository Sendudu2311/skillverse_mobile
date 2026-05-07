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
  @JsonValue('COMPLETED_UNVERIFIED')
  completedUnverified,
  @JsonValue('AWAITING_VERIFICATION')
  awaitingVerification,
  @JsonValue('COMPLETED_VERIFIED')
  completedVerified,
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
  final String? industry;
  final String goal;
  final String level;
  final String? jobRole;
  final String? subCategory;
  final List<String>? skills;
  final List<String>? existingSkills;
  final List<String>? focusAreas;
  final String? language;
  final String? duration;
  final int? questionCount;

  const StartJourneyRequest({
    this.type,
    required this.domain,
    this.industry,
    required this.goal,
    required this.level,
    this.jobRole,
    this.subCategory,
    this.skills,
    this.existingSkills,
    this.focusAreas,
    this.language,
    this.duration,
    this.questionCount,
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

  // Adaptive testing fields (V4)
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? baseLevel;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? testedLevel;
  final bool? provisional;
  final bool? challengeRequired;
  final bool? challengeAvailable;

  const TestResultSummaryDto({
    this.resultId,
    required this.scorePercentage,
    required this.evaluatedLevel,
    required this.skillGapsCount,
    required this.strengthsCount,
    this.evaluatedAt,
    this.baseLevel,
    this.testedLevel,
    this.provisional,
    this.challengeRequired,
    this.challengeAvailable,
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
  final String? industry;
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

  // V3 Phase 1 fields
  final String? skillName;
  final bool? finalVerificationRequired;

  // V3 Phase 3 fields
  final bool? hasActiveMentorBooking;

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
    this.industry,
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
    this.skillName,
    this.finalVerificationRequired,
    this.hasActiveMentorBooking,
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

  // Adaptive testing fields (V4)
  final String? assessmentPhase;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? baseLevel;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? testedLevel;
  final int? parentTestId;
  final String? questionSource;

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
    this.assessmentPhase,
    this.baseLevel,
    this.testedLevel,
    this.parentTestId,
    this.questionSource,
  });

  factory AssessmentTestDto.fromJson(Map<String, dynamic> json) =>
      _$AssessmentTestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AssessmentTestDtoToJson(this);
}

/// Skill gap or strength analysis breakdown per skill area
@JsonSerializable()
class SkillAnalysisDto {
  final String skillName;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel currentLevel;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? targetLevel;
  final double? gap;
  @JsonKey(defaultValue: [])
  final List<String> strengths;
  @JsonKey(defaultValue: [])
  final List<String> weaknesses;
  @JsonKey(defaultValue: [])
  final List<String> recommendations;

  const SkillAnalysisDto({
    required this.skillName,
    required this.currentLevel,
    this.targetLevel,
    this.gap,
    this.strengths = const [],
    this.weaknesses = const [],
    this.recommendations = const [],
  });

  factory SkillAnalysisDto.fromJson(Map<String, dynamic> json) =>
      _$SkillAnalysisDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SkillAnalysisDtoToJson(this);
}

/// Per-question review item returned with test result
@JsonSerializable()
class QuestionReviewItemDto {
  final int questionId;
  final String question;
  final String? skillArea;
  final String? difficulty;
  @JsonKey(defaultValue: [])
  final List<String> options;
  final String? userAnswer;
  final String? correctAnswer;
  final bool isCorrect;
  final String? explanation;

  const QuestionReviewItemDto({
    required this.questionId,
    required this.question,
    this.skillArea,
    this.difficulty,
    this.options = const [],
    this.userAnswer,
    this.correctAnswer,
    required this.isCorrect,
    this.explanation,
  });

  factory QuestionReviewItemDto.fromJson(Map<String, dynamic> json) =>
      _$QuestionReviewItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionReviewItemDtoToJson(this);
}

/// Detailed test result with AI evaluation
@JsonSerializable()
class TestResultDto {
  final int id;
  final int? journeyId;
  final int? assessmentTestId;
  // Web uses 'score', mobile was 'scorePercentage' — backend may return either
  @JsonKey(name: 'scorePercentage')
  final int scorePercentage;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel evaluatedLevel;
  final String? evaluationSummary;
  final String? detailedFeedback;
  final String? userAnswersJson;
  final String? correctAnswersJson;
  final String? evaluatedAt;
  final String? createdAt;

  // Computed metrics
  final int? totalQuestions;
  final int? correctAnswers;
  final int? incorrectAnswers;
  final int? answeredQuestions;
  final int? passingScore;
  @JsonKey(defaultValue: false)
  final bool passed;
  final String? scoreBand;
  final String? scoreBandLabel;
  final String? recommendationMode;
  final String? recommendationLabel;
  final int? assessmentConfidence;
  final bool? reassessmentRecommended;

  // Adaptive testing fields (V4)
  final String? assessmentPhase;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? baseLevel;
  @JsonKey(unknownEnumValue: SkillLevel.beginner)
  final SkillLevel? testedLevel;
  @JsonKey(defaultValue: false)
  final bool provisional;
  @JsonKey(defaultValue: false)
  final bool challengeRequired;
  @JsonKey(defaultValue: false)
  final bool challengeAvailable;
  final int? challengeTestId;

  // Detailed analysis (new Web V2 fields)
  @JsonKey(defaultValue: [])
  final List<SkillAnalysisDto> skillAnalysis;
  @JsonKey(defaultValue: [])
  final List<QuestionReviewItemDto> questionReviews;
  @JsonKey(defaultValue: [])
  final List<String> overallStrengths;
  @JsonKey(defaultValue: [])
  final List<String> overallWeaknesses;
  @JsonKey(defaultValue: [])
  final List<String> skillGaps;
  @JsonKey(defaultValue: [])
  final List<String> highlightKeywords;
  @JsonKey(defaultValue: [])
  final List<String> improvementTips;

  // Legacy JSON string fields (kept for backward compat, may be null)
  final String? skillGapsJson;
  final String? strengthsJson;
  final String? highlightKeywordsJson;

  // resultId alias for use in inline summary
  int? get resultId => id;

  const TestResultDto({
    required this.id,
    this.journeyId,
    this.assessmentTestId,
    required this.scorePercentage,
    required this.evaluatedLevel,
    this.evaluationSummary,
    this.detailedFeedback,
    this.userAnswersJson,
    this.correctAnswersJson,
    this.evaluatedAt,
    this.createdAt,
    this.totalQuestions,
    this.correctAnswers,
    this.incorrectAnswers,
    this.answeredQuestions,
    this.passingScore,
    this.passed = false,
    this.scoreBand,
    this.scoreBandLabel,
    this.recommendationMode,
    this.recommendationLabel,
    this.assessmentConfidence,
    this.reassessmentRecommended,
    this.assessmentPhase,
    this.baseLevel,
    this.testedLevel,
    this.provisional = false,
    this.challengeRequired = false,
    this.challengeAvailable = false,
    this.challengeTestId,
    this.skillAnalysis = const [],
    this.questionReviews = const [],
    this.overallStrengths = const [],
    this.overallWeaknesses = const [],
    this.skillGaps = const [],
    this.highlightKeywords = const [],
    this.improvementTips = const [],
    this.skillGapsJson,
    this.strengthsJson,
    this.highlightKeywordsJson,
  });

  factory TestResultDto.fromJson(Map<String, dynamic> json) =>
      _$TestResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TestResultDtoToJson(this);
}
