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
  isCore: json['isCore'] as bool?,
  parentId: json['parentId'] as String?,
  suggestedCourseIds: (json['suggestedCourseIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  nodeStatus: json['nodeStatus'] as String?,
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
      'isCore': instance.isCore,
      'parentId': instance.parentId,
      'suggestedCourseIds': instance.suggestedCourseIds,
      'nodeStatus': instance.nodeStatus,
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
      skillMode: json['skillMode'] == null
          ? null
          : SkillModeMeta.fromJson(json['skillMode'] as Map<String, dynamic>),
      careerMode: json['careerMode'] == null
          ? null
          : CareerModeMeta.fromJson(json['careerMode'] as Map<String, dynamic>),
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
      'skillMode': instance.skillMode,
      'careerMode': instance.careerMode,
    };

const _$RoadmapModeEnumMap = {
  RoadmapMode.skillBased: 'SKILL_BASED',
  RoadmapMode.careerBased: 'CAREER_BASED',
};

SkillModeMeta _$SkillModeMetaFromJson(Map<String, dynamic> json) =>
    SkillModeMeta(
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
    );

Map<String, dynamic> _$SkillModeMetaToJson(SkillModeMeta instance) =>
    <String, dynamic>{
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
    };

CareerModeMeta _$CareerModeMetaFromJson(Map<String, dynamic> json) =>
    CareerModeMeta(
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

Map<String, dynamic> _$CareerModeMetaToJson(CareerModeMeta instance) =>
    <String, dynamic>{
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

RoadmapOverview _$RoadmapOverviewFromJson(Map<String, dynamic> json) =>
    RoadmapOverview(
      purpose: json['purpose'] as String?,
      audience: json['audience'] as String?,
      postRoadmapState: json['postRoadmapState'] as String?,
    );

Map<String, dynamic> _$RoadmapOverviewToJson(RoadmapOverview instance) =>
    <String, dynamic>{
      'purpose': instance.purpose,
      'audience': instance.audience,
      'postRoadmapState': instance.postRoadmapState,
    };

StructurePhase _$StructurePhaseFromJson(Map<String, dynamic> json) =>
    StructurePhase(
      phaseId: json['phaseId'] as String?,
      title: json['title'] as String?,
      timeframe: json['timeframe'] as String?,
      goal: json['goal'] as String?,
      skillFocus: (json['skillFocus'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mindsetGoal: json['mindsetGoal'] as String?,
      expectedOutput: json['expectedOutput'] as String?,
    );

Map<String, dynamic> _$StructurePhaseToJson(StructurePhase instance) =>
    <String, dynamic>{
      'phaseId': instance.phaseId,
      'title': instance.title,
      'timeframe': instance.timeframe,
      'goal': instance.goal,
      'skillFocus': instance.skillFocus,
      'mindsetGoal': instance.mindsetGoal,
      'expectedOutput': instance.expectedOutput,
    };

ProjectEvidence _$ProjectEvidenceFromJson(Map<String, dynamic> json) =>
    ProjectEvidence(
      phaseId: json['phaseId'] as String?,
      project: json['project'] as String?,
      objective: json['objective'] as String?,
      skillsProven: (json['skillsProven'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      kpi: (json['kpi'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ProjectEvidenceToJson(ProjectEvidence instance) =>
    <String, dynamic>{
      'phaseId': instance.phaseId,
      'project': instance.project,
      'objective': instance.objective,
      'skillsProven': instance.skillsProven,
      'kpi': instance.kpi,
    };

RoadmapNextSteps _$RoadmapNextStepsFromJson(Map<String, dynamic> json) =>
    RoadmapNextSteps(
      jobs: (json['jobs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      nextSkills: (json['nextSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mentorsMicroJobs: (json['mentorsMicroJobs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RoadmapNextStepsToJson(RoadmapNextSteps instance) =>
    <String, dynamic>{
      'jobs': instance.jobs,
      'nextSkills': instance.nextSkills,
      'mentorsMicroJobs': instance.mentorsMicroJobs,
    };

SkillDependency _$SkillDependencyFromJson(Map<String, dynamic> json) =>
    SkillDependency(from: json['from'] as String, to: json['to'] as String);

Map<String, dynamic> _$SkillDependencyToJson(SkillDependency instance) =>
    <String, dynamic>{'from': instance.from, 'to': instance.to};

RoadmapResponse _$RoadmapResponseFromJson(
  Map<String, dynamic> json,
) => RoadmapResponse(
  sessionId: (json['sessionId'] as num).toInt(),
  roadmapStatus: json['roadmapStatus'] as String?,
  metadata: RoadmapMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
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
    (k, e) => MapEntry(k, QuestProgress.fromJson(e as Map<String, dynamic>)),
  ),
  overview: json['overview'] == null
      ? null
      : RoadmapOverview.fromJson(json['overview'] as Map<String, dynamic>),
  structure: (json['structure'] as List<dynamic>?)
      ?.map((e) => StructurePhase.fromJson(e as Map<String, dynamic>))
      .toList(),
  thinkingProgression: (json['thinkingProgression'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  projectsEvidence: (json['projectsEvidence'] as List<dynamic>?)
      ?.map((e) => ProjectEvidence.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextSteps: json['nextSteps'] == null
      ? null
      : RoadmapNextSteps.fromJson(json['nextSteps'] as Map<String, dynamic>),
  skillDependencies: (json['skillDependencies'] as List<dynamic>?)
      ?.map((e) => SkillDependency.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RoadmapResponseToJson(RoadmapResponse instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'roadmapStatus': instance.roadmapStatus,
      'metadata': instance.metadata,
      'roadmap': instance.roadmap,
      'statistics': instance.statistics,
      'learningTips': instance.learningTips,
      'warnings': instance.warnings,
      'createdAt': instance.createdAt,
      'progress': instance.progress,
      'overview': instance.overview,
      'structure': instance.structure,
      'thinkingProgression': instance.thinkingProgression,
      'projectsEvidence': instance.projectsEvidence,
      'nextSteps': instance.nextSteps,
      'skillDependencies': instance.skillDependencies,
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
  status: json['status'] as String?,
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
  'status': instance.status,
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
