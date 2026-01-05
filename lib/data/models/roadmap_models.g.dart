// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roadmap_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoadmapNode _$RoadmapNodeFromJson(Map<String, dynamic> json) => RoadmapNode(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  estimatedTimeMinutes: (json['estimatedTimeMinutes'] as num).toInt(),
  type: $enumDecode(_$NodeTypeEnumMap, json['type']),
  difficulty: $enumDecodeNullable(_$DifficultyLevelEnumMap, json['difficulty']),
  learningObjectives: (json['learningObjectives'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  keyConcepts: (json['keyConcepts'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  practicalExercises: (json['practicalExercises'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  suggestedResources: (json['suggestedResources'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  successCriteria: (json['successCriteria'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  prerequisites: (json['prerequisites'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  children: (json['children'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  estimatedCompletionRate: json['estimatedCompletionRate'] as String?,
);

Map<String, dynamic> _$RoadmapNodeToJson(RoadmapNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'estimatedTimeMinutes': instance.estimatedTimeMinutes,
      'type': _$NodeTypeEnumMap[instance.type]!,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty],
      'learningObjectives': instance.learningObjectives,
      'keyConcepts': instance.keyConcepts,
      'practicalExercises': instance.practicalExercises,
      'suggestedResources': instance.suggestedResources,
      'successCriteria': instance.successCriteria,
      'prerequisites': instance.prerequisites,
      'children': instance.children,
      'estimatedCompletionRate': instance.estimatedCompletionRate,
    };

const _$NodeTypeEnumMap = {NodeType.main: 'MAIN', NodeType.side: 'SIDE'};

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.easy: 'easy',
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.medium: 'medium',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.hard: 'hard',
  DifficultyLevel.advanced: 'advanced',
};

RoadmapMetadata _$RoadmapMetadataFromJson(Map<String, dynamic> json) =>
    RoadmapMetadata(
      title: json['title'] as String,
      originalGoal: json['originalGoal'] as String,
      validatedGoal: json['validatedGoal'] as String?,
      duration: json['duration'] as String,
      experienceLevel: json['experienceLevel'] as String,
      learningStyle: json['learningStyle'] as String,
      detectedIntention: json['detectedIntention'] as String?,
      validationNotes: json['validationNotes'] as String?,
      estimatedCompletion: json['estimatedCompletion'] as String?,
      difficultyLevel: json['difficultyLevel'] as String?,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      careerRelevance: json['careerRelevance'] as String?,
      roadmapType: json['roadmapType'] as String?,
      target: json['target'] as String?,
      finalObjective: json['finalObjective'] as String?,
      currentLevel: json['currentLevel'] as String?,
      desiredDuration: json['desiredDuration'] as String?,
      background: json['background'] as String?,
      dailyTime: json['dailyTime'] as String?,
      targetEnvironment: json['targetEnvironment'] as String?,
      location: json['location'] as String?,
      priority: json['priority'] as String?,
      toolPreferences: (json['toolPreferences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      difficultyConcern: json['difficultyConcern'] as String?,
      incomeGoal: json['incomeGoal'] as bool?,
      roadmapMode: $enumDecodeNullable(
        _$RoadmapModeEnumMap,
        json['roadmapMode'],
      ),
    );

Map<String, dynamic> _$RoadmapMetadataToJson(RoadmapMetadata instance) =>
    <String, dynamic>{
      'title': instance.title,
      'originalGoal': instance.originalGoal,
      'validatedGoal': instance.validatedGoal,
      'duration': instance.duration,
      'experienceLevel': instance.experienceLevel,
      'learningStyle': instance.learningStyle,
      'detectedIntention': instance.detectedIntention,
      'validationNotes': instance.validationNotes,
      'estimatedCompletion': instance.estimatedCompletion,
      'difficultyLevel': instance.difficultyLevel,
      'prerequisites': instance.prerequisites,
      'careerRelevance': instance.careerRelevance,
      'roadmapType': instance.roadmapType,
      'target': instance.target,
      'finalObjective': instance.finalObjective,
      'currentLevel': instance.currentLevel,
      'desiredDuration': instance.desiredDuration,
      'background': instance.background,
      'dailyTime': instance.dailyTime,
      'targetEnvironment': instance.targetEnvironment,
      'location': instance.location,
      'priority': instance.priority,
      'toolPreferences': instance.toolPreferences,
      'difficultyConcern': instance.difficultyConcern,
      'incomeGoal': instance.incomeGoal,
      'roadmapMode': _$RoadmapModeEnumMap[instance.roadmapMode],
    };

const _$RoadmapModeEnumMap = {
  RoadmapMode.skillBased: 'SKILL_BASED',
  RoadmapMode.careerBased: 'CAREER_BASED',
};

RoadmapStatistics _$RoadmapStatisticsFromJson(Map<String, dynamic> json) =>
    RoadmapStatistics(
      totalNodes: (json['totalNodes'] as num).toInt(),
      mainNodes: (json['mainNodes'] as num).toInt(),
      sideNodes: (json['sideNodes'] as num).toInt(),
      totalEstimatedHours: (json['totalEstimatedHours'] as num).toInt(),
      difficultyDistribution:
          (json['difficultyDistribution'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ),
    );

Map<String, dynamic> _$RoadmapStatisticsToJson(RoadmapStatistics instance) =>
    <String, dynamic>{
      'totalNodes': instance.totalNodes,
      'mainNodes': instance.mainNodes,
      'sideNodes': instance.sideNodes,
      'totalEstimatedHours': instance.totalEstimatedHours,
      'difficultyDistribution': instance.difficultyDistribution,
    };

QuestProgress _$QuestProgressFromJson(Map<String, dynamic> json) =>
    QuestProgress(
      questId: json['questId'] as String,
      status: $enumDecode(_$ProgressStatusEnumMap, json['status']),
      progress: (json['progress'] as num).toInt(),
      completedAt: json['completedAt'] as String?,
    );

Map<String, dynamic> _$QuestProgressToJson(QuestProgress instance) =>
    <String, dynamic>{
      'questId': instance.questId,
      'status': _$ProgressStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'completedAt': instance.completedAt,
    };

const _$ProgressStatusEnumMap = {
  ProgressStatus.notStarted: 'NOT_STARTED',
  ProgressStatus.inProgress: 'IN_PROGRESS',
  ProgressStatus.completed: 'COMPLETED',
  ProgressStatus.skipped: 'SKIPPED',
};

RoadmapResponse _$RoadmapResponseFromJson(Map<String, dynamic> json) =>
    RoadmapResponse(
      sessionId: (json['sessionId'] as num).toInt(),
      metadata: RoadmapMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      roadmap: (json['roadmap'] as List<dynamic>)
          .map((e) => RoadmapNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      statistics: RoadmapStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>,
      ),
      learningTips: (json['learningTips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['createdAt'] as String,
      progress: (json['progress'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, QuestProgress.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$RoadmapResponseToJson(RoadmapResponse instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'metadata': instance.metadata,
      'roadmap': instance.roadmap,
      'statistics': instance.statistics,
      'learningTips': instance.learningTips,
      'warnings': instance.warnings,
      'createdAt': instance.createdAt,
      'progress': instance.progress,
    };

RoadmapSessionSummary _$RoadmapSessionSummaryFromJson(
  Map<String, dynamic> json,
) => RoadmapSessionSummary(
  sessionId: (json['sessionId'] as num).toInt(),
  title: json['title'] as String,
  originalGoal: json['originalGoal'] as String,
  validatedGoal: json['validatedGoal'] as String?,
  duration: json['duration'] as String,
  experienceLevel: json['experienceLevel'] as String,
  learningStyle: json['learningStyle'] as String,
  totalQuests: (json['totalQuests'] as num).toInt(),
  completedQuests: (json['completedQuests'] as num).toInt(),
  progressPercentage: (json['progressPercentage'] as num).toDouble(),
  difficultyLevel: json['difficultyLevel'] as String?,
  schemaVersion: (json['schemaVersion'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$RoadmapSessionSummaryToJson(
  RoadmapSessionSummary instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'title': instance.title,
  'originalGoal': instance.originalGoal,
  'validatedGoal': instance.validatedGoal,
  'duration': instance.duration,
  'experienceLevel': instance.experienceLevel,
  'learningStyle': instance.learningStyle,
  'totalQuests': instance.totalQuests,
  'completedQuests': instance.completedQuests,
  'progressPercentage': instance.progressPercentage,
  'difficultyLevel': instance.difficultyLevel,
  'schemaVersion': instance.schemaVersion,
  'createdAt': instance.createdAt,
};

GenerateRoadmapRequest _$GenerateRoadmapRequestFromJson(
  Map<String, dynamic> json,
) => GenerateRoadmapRequest(
  goal: json['goal'] as String,
  duration: json['duration'] as String,
  experience: json['experience'] as String,
  style: json['style'] as String,
  industry: json['industry'] as String?,
  roadmapType: json['roadmapType'] as String?,
  target: json['target'] as String?,
  finalObjective: json['finalObjective'] as String?,
  currentLevel: json['currentLevel'] as String?,
  desiredDuration: json['desiredDuration'] as String?,
  background: json['background'] as String?,
  dailyTime: json['dailyTime'] as String?,
  learningStyle: json['learningStyle'] as String?,
  targetEnvironment: json['targetEnvironment'] as String?,
  location: json['location'] as String?,
  priority: json['priority'] as String?,
  toolPreferences: (json['toolPreferences'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  difficultyConcern: json['difficultyConcern'] as String?,
  incomeGoal: json['incomeGoal'] as bool?,
  roadmapMode: json['roadmapMode'] as String?,
  aiAgentMode: json['aiAgentMode'] as String?,
  skillName: json['skillName'] as String?,
  skillCategory: json['skillCategory'] as String?,
  desiredDepth: json['desiredDepth'] as String?,
  learnerType: json['learnerType'] as String?,
  currentSkillLevel: json['currentSkillLevel'] as String?,
  learningGoal: json['learningGoal'] as String?,
  dailyLearningTime: json['dailyLearningTime'] as String?,
  assessmentPreference: json['assessmentPreference'] as String?,
  difficultyTolerance: json['difficultyTolerance'] as String?,
  toolPreference: (json['toolPreference'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  targetRole: json['targetRole'] as String?,
  careerTrack: json['careerTrack'] as String?,
  targetSeniority: json['targetSeniority'] as String?,
  workMode: json['workMode'] as String?,
  targetMarket: json['targetMarket'] as String?,
  companyType: json['companyType'] as String?,
  timelineToWork: json['timelineToWork'] as String?,
  incomeExpectation: json['incomeExpectation'] as bool?,
  workExperience: json['workExperience'] as String?,
  transferableSkills: json['transferableSkills'] as bool?,
  confidenceLevel: json['confidenceLevel'] as String?,
);

Map<String, dynamic> _$GenerateRoadmapRequestToJson(
  GenerateRoadmapRequest instance,
) => <String, dynamic>{
  'goal': instance.goal,
  'duration': instance.duration,
  'experience': instance.experience,
  'style': instance.style,
  'industry': instance.industry,
  'roadmapType': instance.roadmapType,
  'target': instance.target,
  'finalObjective': instance.finalObjective,
  'currentLevel': instance.currentLevel,
  'desiredDuration': instance.desiredDuration,
  'background': instance.background,
  'dailyTime': instance.dailyTime,
  'learningStyle': instance.learningStyle,
  'targetEnvironment': instance.targetEnvironment,
  'location': instance.location,
  'priority': instance.priority,
  'toolPreferences': instance.toolPreferences,
  'difficultyConcern': instance.difficultyConcern,
  'incomeGoal': instance.incomeGoal,
  'roadmapMode': instance.roadmapMode,
  'aiAgentMode': instance.aiAgentMode,
  'skillName': instance.skillName,
  'skillCategory': instance.skillCategory,
  'desiredDepth': instance.desiredDepth,
  'learnerType': instance.learnerType,
  'currentSkillLevel': instance.currentSkillLevel,
  'learningGoal': instance.learningGoal,
  'dailyLearningTime': instance.dailyLearningTime,
  'assessmentPreference': instance.assessmentPreference,
  'difficultyTolerance': instance.difficultyTolerance,
  'toolPreference': instance.toolPreference,
  'targetRole': instance.targetRole,
  'careerTrack': instance.careerTrack,
  'targetSeniority': instance.targetSeniority,
  'workMode': instance.workMode,
  'targetMarket': instance.targetMarket,
  'companyType': instance.companyType,
  'timelineToWork': instance.timelineToWork,
  'incomeExpectation': instance.incomeExpectation,
  'workExperience': instance.workExperience,
  'transferableSkills': instance.transferableSkills,
  'confidenceLevel': instance.confidenceLevel,
};

UpdateProgressRequest _$UpdateProgressRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProgressRequest(
  questId: json['questId'] as String,
  completed: json['completed'] as bool,
);

Map<String, dynamic> _$UpdateProgressRequestToJson(
  UpdateProgressRequest instance,
) => <String, dynamic>{
  'questId': instance.questId,
  'completed': instance.completed,
};

ProgressResponse _$ProgressResponseFromJson(Map<String, dynamic> json) =>
    ProgressResponse(
      sessionId: (json['sessionId'] as num).toInt(),
      questId: json['questId'] as String,
      completed: json['completed'] as bool,
      stats: ProgressStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProgressResponseToJson(ProgressResponse instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'questId': instance.questId,
      'completed': instance.completed,
      'stats': instance.stats,
    };

ProgressStats _$ProgressStatsFromJson(Map<String, dynamic> json) =>
    ProgressStats(
      totalQuests: (json['totalQuests'] as num).toInt(),
      completedQuests: (json['completedQuests'] as num).toInt(),
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
    );

Map<String, dynamic> _$ProgressStatsToJson(ProgressStats instance) =>
    <String, dynamic>{
      'totalQuests': instance.totalQuests,
      'completedQuests': instance.completedQuests,
      'completionPercentage': instance.completionPercentage,
    };

ValidationResult _$ValidationResultFromJson(Map<String, dynamic> json) =>
    ValidationResult(
      severity: $enumDecode(_$ValidationSeverityEnumMap, json['severity']),
      message: json['message'] as String,
      code: json['code'] as String?,
    );

Map<String, dynamic> _$ValidationResultToJson(ValidationResult instance) =>
    <String, dynamic>{
      'severity': _$ValidationSeverityEnumMap[instance.severity]!,
      'message': instance.message,
      'code': instance.code,
    };

const _$ValidationSeverityEnumMap = {
  ValidationSeverity.info: 'INFO',
  ValidationSeverity.warning: 'WARNING',
  ValidationSeverity.error: 'ERROR',
};

ClarificationQuestion _$ClarificationQuestionFromJson(
  Map<String, dynamic> json,
) => ClarificationQuestion(
  question: json['question'] as String,
  context: json['context'] as String?,
  suggestedAnswers: (json['suggestedAnswers'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ClarificationQuestionToJson(
  ClarificationQuestion instance,
) => <String, dynamic>{
  'question': instance.question,
  'context': instance.context,
  'suggestedAnswers': instance.suggestedAnswers,
};

RoadmapStep _$RoadmapStepFromJson(Map<String, dynamic> json) => RoadmapStep(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  completed: json['completed'] as bool,
  current: json['current'] as bool?,
  duration: json['duration'] as String,
);

Map<String, dynamic> _$RoadmapStepToJson(RoadmapStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'completed': instance.completed,
      'current': instance.current,
      'duration': instance.duration,
    };

Roadmap _$RoadmapFromJson(Map<String, dynamic> json) => Roadmap(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  category: json['category'] as String,
  progress: (json['progress'] as num).toInt(),
  totalSteps: (json['totalSteps'] as num).toInt(),
  completedSteps: (json['completedSteps'] as num).toInt(),
  estimatedTime: json['estimatedTime'] as String,
  difficulty: json['difficulty'] as String,
  color: json['color'] as String,
  steps: (json['steps'] as List<dynamic>)
      .map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RoadmapToJson(Roadmap instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'category': instance.category,
  'progress': instance.progress,
  'totalSteps': instance.totalSteps,
  'completedSteps': instance.completedSteps,
  'estimatedTime': instance.estimatedTime,
  'difficulty': instance.difficulty,
  'color': instance.color,
  'steps': instance.steps,
};

PageResponse<T> _$PageResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PageResponse<T>(
  content: (json['content'] as List<dynamic>).map(fromJsonT).toList(),
  page: (json['page'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  totalElements: (json['totalElements'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  first: json['first'] as bool,
  last: json['last'] as bool,
  empty: json['empty'] as bool,
);

Map<String, dynamic> _$PageResponseToJson<T>(
  PageResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'content': instance.content.map(toJsonT).toList(),
  'page': instance.page,
  'size': instance.size,
  'totalElements': instance.totalElements,
  'totalPages': instance.totalPages,
  'first': instance.first,
  'last': instance.last,
  'empty': instance.empty,
};
