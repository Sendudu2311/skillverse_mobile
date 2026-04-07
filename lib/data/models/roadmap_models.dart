import 'package:json_annotation/json_annotation.dart';

part 'roadmap_models.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Node type in the roadmap tree
enum NodeType {
  @JsonValue('MAIN')
  main,
  @JsonValue('SIDE')
  side,
}

/// Progress status for individual quests
enum ProgressStatus {
  @JsonValue('NOT_STARTED')
  notStarted,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('SKIPPED')
  skipped,
}

/// Difficulty level for nodes and roadmaps
enum DifficultyLevel {
  @JsonValue('easy')
  easy,
  @JsonValue('beginner')
  beginner,
  @JsonValue('medium')
  medium,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('hard')
  hard,
  @JsonValue('advanced')
  advanced,
}

/// Validation severity levels
enum ValidationSeverity {
  @JsonValue('INFO')
  info,
  @JsonValue('WARNING')
  warning,
  @JsonValue('ERROR')
  error,
}

/// Roadmap generation mode
enum RoadmapMode {
  @JsonValue('SKILL_BASED')
  skillBased,
  @JsonValue('CAREER_BASED')
  careerBased,
}

// ============================================================================
// AI ROADMAP MODELS (V2 API)
// ============================================================================

/// Individual node/quest in the roadmap tree
@JsonSerializable()
class RoadmapNode {
  final String id;
  final String title;
  final String description;
  final int estimatedTimeMinutes;
  final NodeType type;
  final DifficultyLevel? difficulty;
  final List<String>? learningObjectives;
  final List<String>? keyConcepts;
  final List<String>? practicalExercises;
  final List<String>? suggestedResources;
  final List<String>? successCriteria;
  final List<String>? prerequisites;
  final List<String> children;
  final String? estimatedCompletionRate;

  // Tree node fields (V3 - Roadmap lifecycle)
  final bool? isCore; // true = main path, false = side quest
  final String? parentId; // parent node ID in tree
  final List<String>? suggestedCourseIds; // validated course IDs from DB
  final String? nodeStatus; // LOCKED, AVAILABLE, IN_PROGRESS, COMPLETED

  RoadmapNode({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedTimeMinutes,
    required this.type,
    this.difficulty,
    this.learningObjectives,
    this.keyConcepts,
    this.practicalExercises,
    this.suggestedResources,
    this.successCriteria,
    this.prerequisites,
    required this.children,
    this.estimatedCompletionRate,
    this.isCore,
    this.parentId,
    this.suggestedCourseIds,
    this.nodeStatus,
  });

  factory RoadmapNode.fromJson(Map<String, dynamic> json) =>
      _$RoadmapNodeFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapNodeToJson(this);

  /// Get estimated time in hours
  double get estimatedTimeHours => estimatedTimeMinutes / 60.0;

  /// Check if this is a main quest
  bool get isMainQuest => type == NodeType.main;

  /// Check if this node is on the core/main path
  bool get isCoreNode => isCore ?? true;
}

/// Roadmap metadata
@JsonSerializable()
class RoadmapMetadata {
  final String title;
  final String originalGoal;
  final String? validatedGoal;
  final String duration;
  final String experienceLevel;
  final String learningStyle;
  final String? detectedIntention;
  final String? validationNotes;
  final String? estimatedCompletion;
  final String? difficultyLevel;
  final List<String>? prerequisites;
  final String? careerRelevance;
  final String? roadmapType;
  final String? target;
  final String? finalObjective;
  final String? currentLevel;
  final String? desiredDuration;
  final String? background;
  final String? dailyTime;
  final String? targetEnvironment;
  final String? location;
  final String? priority;
  final List<String>? toolPreferences;
  final String? difficultyConcern;
  final bool? incomeGoal;
  final RoadmapMode? roadmapMode;
  final SkillModeMeta? skillMode;
  final CareerModeMeta? careerMode;

  RoadmapMetadata({
    required this.title,
    required this.originalGoal,
    this.validatedGoal,
    required this.duration,
    required this.experienceLevel,
    required this.learningStyle,
    this.detectedIntention,
    this.validationNotes,
    this.estimatedCompletion,
    this.difficultyLevel,
    this.prerequisites,
    this.careerRelevance,
    this.roadmapType,
    this.target,
    this.finalObjective,
    this.currentLevel,
    this.desiredDuration,
    this.background,
    this.dailyTime,
    this.targetEnvironment,
    this.location,
    this.priority,
    this.toolPreferences,
    this.difficultyConcern,
    this.incomeGoal,
    this.roadmapMode,
    this.skillMode,
    this.careerMode,
  });

  factory RoadmapMetadata.fromJson(Map<String, dynamic> json) =>
      _$RoadmapMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapMetadataToJson(this);
}

/// Skill-based mode metadata (nested in RoadmapMetadata)
@JsonSerializable()
class SkillModeMeta {
  final String? skillName;
  final String? skillCategory;
  final String? desiredDepth;
  final String? learnerType;
  final String? currentSkillLevel;
  final String? learningGoal;
  final String? dailyLearningTime;
  final String? assessmentPreference;
  final String? difficultyTolerance;
  final List<String>? toolPreference;

  SkillModeMeta({
    this.skillName,
    this.skillCategory,
    this.desiredDepth,
    this.learnerType,
    this.currentSkillLevel,
    this.learningGoal,
    this.dailyLearningTime,
    this.assessmentPreference,
    this.difficultyTolerance,
    this.toolPreference,
  });

  factory SkillModeMeta.fromJson(Map<String, dynamic> json) =>
      _$SkillModeMetaFromJson(json);
  Map<String, dynamic> toJson() => _$SkillModeMetaToJson(this);
}

/// Career-based mode metadata (nested in RoadmapMetadata)
@JsonSerializable()
class CareerModeMeta {
  final String? targetRole;
  final String? careerTrack;
  final String? targetSeniority;
  final String? workMode;
  final String? targetMarket;
  final String? companyType;
  final String? timelineToWork;
  final bool? incomeExpectation;
  final String? workExperience;
  final bool? transferableSkills;
  final String? confidenceLevel;

  CareerModeMeta({
    this.targetRole,
    this.careerTrack,
    this.targetSeniority,
    this.workMode,
    this.targetMarket,
    this.companyType,
    this.timelineToWork,
    this.incomeExpectation,
    this.workExperience,
    this.transferableSkills,
    this.confidenceLevel,
  });

  factory CareerModeMeta.fromJson(Map<String, dynamic> json) =>
      _$CareerModeMetaFromJson(json);
  Map<String, dynamic> toJson() => _$CareerModeMetaToJson(this);
}

/// Roadmap statistics
@JsonSerializable()
class RoadmapStatistics {
  final int totalNodes;
  final int mainNodes;
  final int sideNodes;
  final int totalEstimatedHours;
  final Map<String, int>? difficultyDistribution;

  RoadmapStatistics({
    required this.totalNodes,
    required this.mainNodes,
    required this.sideNodes,
    required this.totalEstimatedHours,
    this.difficultyDistribution,
  });

  factory RoadmapStatistics.fromJson(Map<String, dynamic> json) =>
      _$RoadmapStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapStatisticsToJson(this);
}

/// Quest progress tracking
@JsonSerializable()
class QuestProgress {
  final String questId;
  final ProgressStatus status;
  final int progress;
  final String? completedAt;

  QuestProgress({
    required this.questId,
    required this.status,
    required this.progress,
    this.completedAt,
  });

  factory QuestProgress.fromJson(Map<String, dynamic> json) =>
      _$QuestProgressFromJson(json);
  Map<String, dynamic> toJson() => _$QuestProgressToJson(this);

  bool get isCompleted => status == ProgressStatus.completed;
}

/// Roadmap overview section (V2)
@JsonSerializable()
class RoadmapOverview {
  final String? purpose;
  final String? audience;
  final String? postRoadmapState;

  RoadmapOverview({this.purpose, this.audience, this.postRoadmapState});

  factory RoadmapOverview.fromJson(Map<String, dynamic> json) =>
      _$RoadmapOverviewFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapOverviewToJson(this);
}

/// Roadmap structure phase (V2)
@JsonSerializable()
class StructurePhase {
  final String? phaseId;
  final String? title;
  final String? timeframe;
  final String? goal;
  final List<String>? skillFocus;
  final String? mindsetGoal;
  final String? expectedOutput;

  StructurePhase({
    this.phaseId,
    this.title,
    this.timeframe,
    this.goal,
    this.skillFocus,
    this.mindsetGoal,
    this.expectedOutput,
  });

  factory StructurePhase.fromJson(Map<String, dynamic> json) =>
      _$StructurePhaseFromJson(json);
  Map<String, dynamic> toJson() => _$StructurePhaseToJson(this);
}

/// Project evidence for roadmap (V2)
@JsonSerializable()
class ProjectEvidence {
  final String? phaseId;
  final String? project;
  final String? objective;
  final List<String>? skillsProven;
  final List<String>? kpi;

  ProjectEvidence({
    this.phaseId,
    this.project,
    this.objective,
    this.skillsProven,
    this.kpi,
  });

  factory ProjectEvidence.fromJson(Map<String, dynamic> json) =>
      _$ProjectEvidenceFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectEvidenceToJson(this);
}

/// Next steps after roadmap completion (V2)
@JsonSerializable()
class RoadmapNextSteps {
  final List<String>? jobs;
  final List<String>? nextSkills;
  final List<String>? mentorsMicroJobs;

  RoadmapNextSteps({this.jobs, this.nextSkills, this.mentorsMicroJobs});

  factory RoadmapNextSteps.fromJson(Map<String, dynamic> json) =>
      _$RoadmapNextStepsFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapNextStepsToJson(this);
}

/// Skill dependency edge (V2)
@JsonSerializable()
class SkillDependency {
  final String from;
  final String to;

  SkillDependency({required this.from, required this.to});

  factory SkillDependency.fromJson(Map<String, dynamic> json) =>
      _$SkillDependencyFromJson(json);
  Map<String, dynamic> toJson() => _$SkillDependencyToJson(this);
}

/// Full roadmap response with nested structure (V2)
@JsonSerializable()
class RoadmapResponse {
  final int sessionId;
  final String? roadmapStatus; // ACTIVE, PAUSED, DELETED
  final RoadmapMetadata metadata;
  final List<RoadmapNode> roadmap;
  final RoadmapStatistics statistics;
  final List<String>? learningTips;
  final List<String>? warnings;
  final String createdAt;
  final Map<String, QuestProgress>? progress;

  // V2 enhanced fields
  final RoadmapOverview? overview;
  final List<StructurePhase>? structure;
  final List<String>? thinkingProgression;
  final List<ProjectEvidence>? projectsEvidence;
  final RoadmapNextSteps? nextSteps;
  final List<SkillDependency>? skillDependencies;

  RoadmapResponse({
    required this.sessionId,
    this.roadmapStatus,
    required this.metadata,
    required this.roadmap,
    required this.statistics,
    this.learningTips,
    this.warnings,
    required this.createdAt,
    this.progress,
    this.overview,
    this.structure,
    this.thinkingProgression,
    this.projectsEvidence,
    this.nextSteps,
    this.skillDependencies,
  });

  factory RoadmapResponse.fromJson(Map<String, dynamic> json) =>
      _$RoadmapResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapResponseToJson(this);

  /// Get completed quests count
  int get completedQuestsCount {
    if (progress == null) return 0;
    return progress!.values.where((p) => p.isCompleted).length;
  }

  /// Get progress percentage
  double get progressPercentage {
    if (roadmap.isEmpty) return 0;
    return (completedQuestsCount / roadmap.length) * 100;
  }

  /// Find node by ID
  RoadmapNode? findNode(String nodeId) {
    try {
      return roadmap.firstWhere((node) => node.id == nodeId);
    } catch (_) {
      return null;
    }
  }

  /// Get progress for a specific quest
  QuestProgress? getProgress(String questId) => progress?[questId];

  /// Check if a quest is completed
  bool isQuestCompleted(String questId) {
    return progress?[questId]?.isCompleted ?? false;
  }

  RoadmapResponse copyWith({
    int? sessionId,
    String? roadmapStatus,
    RoadmapMetadata? metadata,
    List<RoadmapNode>? roadmap,
    RoadmapStatistics? statistics,
    List<String>? learningTips,
    List<String>? warnings,
    String? createdAt,
    Map<String, QuestProgress>? progress,
    RoadmapOverview? overview,
    List<StructurePhase>? structure,
    List<String>? thinkingProgression,
    List<ProjectEvidence>? projectsEvidence,
    RoadmapNextSteps? nextSteps,
    List<SkillDependency>? skillDependencies,
  }) {
    return RoadmapResponse(
      sessionId: sessionId ?? this.sessionId,
      roadmapStatus: roadmapStatus ?? this.roadmapStatus,
      metadata: metadata ?? this.metadata,
      roadmap: roadmap ?? this.roadmap,
      statistics: statistics ?? this.statistics,
      learningTips: learningTips ?? this.learningTips,
      warnings: warnings ?? this.warnings,
      createdAt: createdAt ?? this.createdAt,
      progress: progress ?? this.progress,
      overview: overview ?? this.overview,
      structure: structure ?? this.structure,
      thinkingProgression: thinkingProgression ?? this.thinkingProgression,
      projectsEvidence: projectsEvidence ?? this.projectsEvidence,
      nextSteps: nextSteps ?? this.nextSteps,
      skillDependencies: skillDependencies ?? this.skillDependencies,
    );
  }
}

/// Summary of a roadmap session (for list view) - V2 Fields
@JsonSerializable()
class RoadmapSessionSummary {
  final int sessionId;
  final String title;
  final String originalGoal;
  final String? validatedGoal;
  final String duration;
  final String experienceLevel;
  final String learningStyle;
  final int totalQuests;
  final int completedQuests;
  final double progressPercentage;
  final String? difficultyLevel;
  final int? schemaVersion;
  final String? status; // ACTIVE, PAUSED, DELETED
  final String createdAt;

  RoadmapSessionSummary({
    required this.sessionId,
    required this.title,
    required this.originalGoal,
    this.validatedGoal,
    required this.duration,
    required this.experienceLevel,
    required this.learningStyle,
    required this.totalQuests,
    required this.completedQuests,
    required this.progressPercentage,
    this.difficultyLevel,
    this.schemaVersion,
    this.status,
    required this.createdAt,
  });

  factory RoadmapSessionSummary.fromJson(Map<String, dynamic> json) =>
      _$RoadmapSessionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapSessionSummaryToJson(this);

  RoadmapSessionSummary copyWith({
    int? sessionId,
    String? title,
    String? originalGoal,
    String? validatedGoal,
    String? duration,
    String? experienceLevel,
    String? learningStyle,
    int? totalQuests,
    int? completedQuests,
    double? progressPercentage,
    String? difficultyLevel,
    int? schemaVersion,
    String? status,
    String? createdAt,
  }) {
    return RoadmapSessionSummary(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      originalGoal: originalGoal ?? this.originalGoal,
      validatedGoal: validatedGoal ?? this.validatedGoal,
      duration: duration ?? this.duration,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      learningStyle: learningStyle ?? this.learningStyle,
      totalQuests: totalQuests ?? this.totalQuests,
      completedQuests: completedQuests ?? this.completedQuests,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get experience level display text in Vietnamese
  String get experienceLevelDisplay {
    switch (experienceLevel.toLowerCase()) {
      case 'beginner':
      case 'mới bắt đầu':
        return 'Mới bắt đầu';
      case 'intermediate':
      case 'trung cấp':
        return 'Trung cấp';
      case 'advanced':
      case 'nâng cao':
        return 'Nâng cao';
      default:
        return experienceLevel;
    }
  }
}

/// Request to generate a new roadmap
@JsonSerializable()
class GenerateRoadmapRequest {
  final String goal;
  final String duration;
  final String experience;
  final String style;
  final String? industry;
  final String? roadmapType;
  final String? target;
  final String? finalObjective;
  final String? currentLevel;
  final String? desiredDuration;
  final String? background;
  final String? dailyTime;
  final String? learningStyle;
  final String? targetEnvironment;
  final String? location;
  final String? priority;
  final List<String>? toolPreferences;
  final String? difficultyConcern;
  final bool? incomeGoal;

  // Skill-based specific fields
  final String? roadmapMode;
  final String? aiAgentMode;
  final String? skillName;
  final String? skillCategory;
  final String? desiredDepth;
  final String? learnerType;
  final String? currentSkillLevel;
  final String? learningGoal;
  final String? dailyLearningTime;
  final String? assessmentPreference;
  final String? difficultyTolerance;
  final List<String>? toolPreference;

  // Career-based specific fields
  final String? targetRole;
  final String? careerTrack;
  final String? targetSeniority;
  final String? workMode;
  final String? targetMarket;
  final String? companyType;
  final String? timelineToWork;
  final bool? incomeExpectation;
  final String? workExperience;
  final bool? transferableSkills;
  final String? confidenceLevel;

  GenerateRoadmapRequest({
    required this.goal,
    required this.duration,
    required this.experience,
    required this.style,
    this.industry,
    this.roadmapType,
    this.target,
    this.finalObjective,
    this.currentLevel,
    this.desiredDuration,
    this.background,
    this.dailyTime,
    this.learningStyle,
    this.targetEnvironment,
    this.location,
    this.priority,
    this.toolPreferences,
    this.difficultyConcern,
    this.incomeGoal,
    this.roadmapMode,
    this.aiAgentMode,
    this.skillName,
    this.skillCategory,
    this.desiredDepth,
    this.learnerType,
    this.currentSkillLevel,
    this.learningGoal,
    this.dailyLearningTime,
    this.assessmentPreference,
    this.difficultyTolerance,
    this.toolPreference,
    this.targetRole,
    this.careerTrack,
    this.targetSeniority,
    this.workMode,
    this.targetMarket,
    this.companyType,
    this.timelineToWork,
    this.incomeExpectation,
    this.workExperience,
    this.transferableSkills,
    this.confidenceLevel,
  });

  factory GenerateRoadmapRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoadmapRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateRoadmapRequestToJson(this);

  /// Create a simple request
  factory GenerateRoadmapRequest.simple({
    required String goal,
    required String duration,
    required String experience,
    String style = 'Video - Học qua hình ảnh',
  }) {
    return GenerateRoadmapRequest(
      goal: goal,
      duration: duration,
      experience: experience,
      style: style,
    );
  }
}

/// Request to update quest progress
@JsonSerializable()
class UpdateProgressRequest {
  final String questId;
  final bool completed;

  UpdateProgressRequest({required this.questId, required this.completed});

  factory UpdateProgressRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProgressRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProgressRequestToJson(this);
}

/// Response from progress update
@JsonSerializable()
class ProgressResponse {
  final int sessionId;
  final String questId;
  final bool completed;
  final ProgressStats stats;

  ProgressResponse({
    required this.sessionId,
    required this.questId,
    required this.completed,
    required this.stats,
  });

  factory ProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$ProgressResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressResponseToJson(this);
}

/// Progress statistics
@JsonSerializable()
class ProgressStats {
  final int totalQuests;
  final int completedQuests;
  final double completionPercentage;

  ProgressStats({
    required this.totalQuests,
    required this.completedQuests,
    required this.completionPercentage,
  });

  factory ProgressStats.fromJson(Map<String, dynamic> json) =>
      _$ProgressStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressStatsToJson(this);
}

/// Validation result (for pre-validation)
@JsonSerializable()
class ValidationResult {
  final ValidationSeverity severity;
  final String message;
  final String? code;

  ValidationResult({required this.severity, required this.message, this.code});

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      _$ValidationResultFromJson(json);
  Map<String, dynamic> toJson() => _$ValidationResultToJson(this);

  bool get isError => severity == ValidationSeverity.error;
  bool get isWarning => severity == ValidationSeverity.warning;
}

/// Clarification question from AI
@JsonSerializable()
class ClarificationQuestion {
  final String question;
  final String? context;
  final List<String>? suggestedAnswers;

  ClarificationQuestion({
    required this.question,
    this.context,
    this.suggestedAnswers,
  });

  factory ClarificationQuestion.fromJson(Map<String, dynamic> json) =>
      _$ClarificationQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$ClarificationQuestionToJson(this);
}

// ============================================================================
// LEGACY MODELS (for backward compatibility)
// ============================================================================

enum RoadmapDifficulty {
  @JsonValue('Beginner')
  beginner,
  @JsonValue('Intermediate')
  intermediate,
  @JsonValue('Advanced')
  advanced,
}

enum RoadmapCategory {
  @JsonValue('Programming')
  programming,
  @JsonValue('Data Science')
  dataScience,
  @JsonValue('Marketing')
  marketing,
  @JsonValue('Infrastructure')
  infrastructure,
  @JsonValue('Design')
  design,
}

@JsonSerializable()
class RoadmapStep {
  final int id;
  final String title;
  final bool completed;
  final bool? current;
  final String duration;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.completed,
    this.current,
    required this.duration,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) =>
      _$RoadmapStepFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapStepToJson(this);
}

@JsonSerializable()
class Roadmap {
  final int id;
  final String title;
  final String category;
  final int progress;
  final int totalSteps;
  final int completedSteps;
  final String estimatedTime;
  final String difficulty;
  final String color;
  final List<RoadmapStep> steps;

  Roadmap({
    required this.id,
    required this.title,
    required this.category,
    required this.progress,
    required this.totalSteps,
    required this.completedSteps,
    required this.estimatedTime,
    required this.difficulty,
    required this.color,
    required this.steps,
  });

  factory Roadmap.fromJson(Map<String, dynamic> json) =>
      _$RoadmapFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapToJson(this);
}

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool empty;

  PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PageResponseFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}
