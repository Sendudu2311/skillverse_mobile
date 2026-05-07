import 'package:json_annotation/json_annotation.dart';

part 'learning_report_model.g.dart';

/// Report types matching Backend enum
enum ReportType {
  @JsonValue('COMPREHENSIVE')
  comprehensive,
  @JsonValue('WEEKLY_SUMMARY')
  weeklySummary,
  @JsonValue('MONTHLY_SUMMARY')
  monthlySummary,
  @JsonValue('SKILL_ASSESSMENT')
  skillAssessment,
  @JsonValue('GOAL_TRACKING')
  goalTracking,
}

/// AI-generated report sections
@JsonSerializable()
class ReportSections {
  final String? currentSkills;
  final String? learningGoals;
  final String? progressSummary;
  final String? strengths;
  final String? areasToImprove;
  final String? recommendations;
  final String? skillGaps;
  final String? nextSteps;
  final String? motivation;

  ReportSections({
    this.currentSkills,
    this.learningGoals,
    this.progressSummary,
    this.strengths,
    this.areasToImprove,
    this.recommendations,
    this.skillGaps,
    this.nextSteps,
    this.motivation,
  });

  factory ReportSections.fromJson(Map<String, dynamic> json) =>
      _$ReportSectionsFromJson(json);
  Map<String, dynamic> toJson() => _$ReportSectionsToJson(this);

  /// Get all non-null sections as a map for display
  Map<String, String> get displaySections {
    final map = <String, String>{};
    if (currentSkills != null && currentSkills!.isNotEmpty) {
      map['Kỹ năng hiện có'] = currentSkills!;
    }
    if (learningGoals != null && learningGoals!.isNotEmpty) {
      map['Mục tiêu học tập'] = learningGoals!;
    }
    if (progressSummary != null && progressSummary!.isNotEmpty) {
      map['Tổng kết tiến độ'] = progressSummary!;
    }
    if (strengths != null && strengths!.isNotEmpty) {
      map['Điểm mạnh'] = strengths!;
    }
    if (areasToImprove != null && areasToImprove!.isNotEmpty) {
      map['Cần cải thiện'] = areasToImprove!;
    }
    if (recommendations != null && recommendations!.isNotEmpty) {
      map['Khuyến nghị'] = recommendations!;
    }
    if (skillGaps != null && skillGaps!.isNotEmpty) {
      map['Khoảng trống kỹ năng'] = skillGaps!;
    }
    if (nextSteps != null && nextSteps!.isNotEmpty) {
      map['Bước tiếp theo'] = nextSteps!;
    }
    if (motivation != null && motivation!.isNotEmpty) {
      map['Động lực'] = motivation!;
    }
    return map;
  }
}

/// Skill info from Backend
@JsonSerializable()
class SkillInfo {
  final String? skillName;
  final String? level;
  final int? progressPercent;
  final String? source;

  SkillInfo({this.skillName, this.level, this.progressPercent, this.source});

  factory SkillInfo.fromJson(Map<String, dynamic> json) =>
      _$SkillInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SkillInfoToJson(this);
}

/// Roadmap progress from Backend
@JsonSerializable()
class RoadmapProgress {
  final int? roadmapId;
  final String? title;
  final String? goal;
  final int? totalQuests;
  final int? completedQuests;
  final int? progressPercent;
  final double? totalEstimatedHours;
  final String? createdAt;
  final String? lastActivityAt;

  RoadmapProgress({
    this.roadmapId,
    this.title,
    this.goal,
    this.totalQuests,
    this.completedQuests,
    this.progressPercent,
    this.totalEstimatedHours,
    this.createdAt,
    this.lastActivityAt,
  });

  factory RoadmapProgress.fromJson(Map<String, dynamic> json) =>
      _$RoadmapProgressFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapProgressToJson(this);
}

/// Student metrics — raw numbers from Backend
@JsonSerializable()
class StudentMetrics {
  final int? totalRoadmaps;
  final int? completedRoadmaps;
  final int? inProgressRoadmaps;
  final int? averageProgress;
  final int? totalStudyMinutesToday;
  final int? totalStudyMinutesWeek;
  final int? totalStudyMinutesMonth;
  final int? totalStudyHours;
  final int? streakDays;
  final int? currentStreak;
  final int? totalChatSessions;
  final int? totalTasks;
  final int? completedTasks;
  final int? totalTasksCompleted;
  final int? totalEnrolledCourses;
  final int? completedCourses;
  final int? totalTasksPending;
  final int? longestStreak;
  final int? averageSessionDuration;
  final int? totalStudySessions;
  final List<SkillInfo>? topSkills;
  final List<RoadmapProgress>? roadmapDetails;

  StudentMetrics({
    this.totalRoadmaps,
    this.completedRoadmaps,
    this.inProgressRoadmaps,
    this.averageProgress,
    this.totalStudyMinutesToday,
    this.totalStudyMinutesWeek,
    this.totalStudyMinutesMonth,
    this.totalStudyHours,
    this.streakDays,
    this.currentStreak,
    this.totalChatSessions,
    this.totalTasks,
    this.completedTasks,
    this.totalTasksCompleted,
    this.totalEnrolledCourses,
    this.completedCourses,
    this.totalTasksPending,
    this.longestStreak,
    this.averageSessionDuration,
    this.totalStudySessions,
    this.topSkills,
    this.roadmapDetails,
  });

  factory StudentMetrics.fromJson(Map<String, dynamic> json) =>
      _$StudentMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$StudentMetricsToJson(this);

  /// Normalized streak (backend sends either streakDays or currentStreak)
  int get streak => currentStreak ?? streakDays ?? 0;

  /// Normalized study hours
  int get studyHours =>
      totalStudyHours ?? ((totalStudyMinutesWeek ?? 0) / 60).round();

  /// Normalized completed tasks
  int get tasksCompleted => totalTasksCompleted ?? completedTasks ?? 0;
}

// ============================================================================
// V2 STRUCTURED REPORT MODELS
// ============================================================================

/// Structured recommendation from the backend RecommendationEngine
@JsonSerializable()
class ReportRecommendation {
  /// Stable identifier for the rule that produced this recommendation
  final String? id;

  /// Tier: CRITICAL | IMPROVE | NEXT_STEP | STRENGTH
  final String? tier;

  /// Category: STUDY | ROADMAP | TASK | COURSE | JOB | GROWTH
  final String? category;

  /// Short headline for the recommendation card
  final String? title;

  /// Data-driven observation that supports the recommendation
  final String? analysis;

  /// Concrete, measurable action the learner should take
  final String? action;

  /// Optional metric label, e.g. "On-time delivery"
  final String? metricLabel;

  /// Current metric value (number)
  final num? metricValue;

  /// Target metric value (number)
  final num? metricTarget;

  /// Unit shown next to metric, e.g. "%", "phút/tuần"
  final String? metricUnit;

  /// Optional deep-link path on the frontend, e.g. "/roadmap" or "/tasks"
  final String? linkPath;

  /// Label for the deep-link CTA button
  final String? linkLabel;

  ReportRecommendation({
    this.id,
    this.tier,
    this.category,
    this.title,
    this.analysis,
    this.action,
    this.metricLabel,
    this.metricValue,
    this.metricTarget,
    this.metricUnit,
    this.linkPath,
    this.linkLabel,
  });

  factory ReportRecommendation.fromJson(Map<String, dynamic> json) =>
      _$ReportRecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$ReportRecommendationToJson(this);

  /// Whether this has a measurable metric with value and target
  bool get hasMetric => metricValue != null && metricTarget != null;
}

/// Report overview with structured recommendations
@JsonSerializable()
class ReportOverview {
  final int? overallProgress;
  final String? learningTrend;
  final List<ReportRecommendation>? recommendations;

  ReportOverview({
    this.overallProgress,
    this.learningTrend,
    this.recommendations,
  });

  factory ReportOverview.fromJson(Map<String, dynamic> json) =>
      _$ReportOverviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReportOverviewToJson(this);
}

/// Study time statistics
@JsonSerializable()
class StudyStats {
  final int? studyMinutesToday;
  final int? studyMinutesWeek;
  final int? studyMinutesMonth;
  final int? totalStudyHours;
  final int? currentStreak;

  StudyStats({
    this.studyMinutesToday,
    this.studyMinutesWeek,
    this.studyMinutesMonth,
    this.totalStudyHours,
    this.currentStreak,
  });

  factory StudyStats.fromJson(Map<String, dynamic> json) =>
      _$StudyStatsFromJson(json);
  Map<String, dynamic> toJson() => _$StudyStatsToJson(this);
}

/// Roadmap-specific statistics
@JsonSerializable()
class ReportRoadmapStats {
  final int? totalRoadmaps;
  final int? completedRoadmaps;
  final int? inProgressRoadmaps;
  final int? totalMissions;
  final int? completedMissions;
  final int? pendingMissions;
  final int? roadmapProgress;

  ReportRoadmapStats({
    this.totalRoadmaps,
    this.completedRoadmaps,
    this.inProgressRoadmaps,
    this.totalMissions,
    this.completedMissions,
    this.pendingMissions,
    this.roadmapProgress,
  });

  factory ReportRoadmapStats.fromJson(Map<String, dynamic> json) =>
      _$ReportRoadmapStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ReportRoadmapStatsToJson(this);
}

/// Task statistics
@JsonSerializable()
class TaskStats {
  final int? totalTasks;
  final int? completedTasks;
  final int? pendingTasks;
  final int? overdueTasks;
  final int? taskProgress;

  TaskStats({
    this.totalTasks,
    this.completedTasks,
    this.pendingTasks,
    this.overdueTasks,
    this.taskProgress,
  });

  factory TaskStats.fromJson(Map<String, dynamic> json) =>
      _$TaskStatsFromJson(json);
  Map<String, dynamic> toJson() => _$TaskStatsToJson(this);
}

/// Course statistics
@JsonSerializable()
class CourseStats {
  final int? activeCourses;
  final int? completedCourses;
  final int? averageActiveCourseProgress;

  CourseStats({
    this.activeCourses,
    this.completedCourses,
    this.averageActiveCourseProgress,
  });

  factory CourseStats.fromJson(Map<String, dynamic> json) =>
      _$CourseStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CourseStatsToJson(this);
}

/// Short-term job statistics
@JsonSerializable()
class ShortTermJobStats {
  final int? totalJobsApplied;
  final int? completedJobs;
  final int? inProgressJobs;
  final int? pendingApplications;
  final int? rejectedApplications;
  final double? totalEarnings;
  final double? averageRating;
  final int? totalMilestonesDelivered;
  final int? onTimeDeliveryRate;

  ShortTermJobStats({
    this.totalJobsApplied,
    this.completedJobs,
    this.inProgressJobs,
    this.pendingApplications,
    this.rejectedApplications,
    this.totalEarnings,
    this.averageRating,
    this.totalMilestonesDelivered,
    this.onTimeDeliveryRate,
  });

  factory ShortTermJobStats.fromJson(Map<String, dynamic> json) =>
      _$ShortTermJobStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ShortTermJobStatsToJson(this);
}

/// Roadmap breakdown item for detailed per-roadmap data
@JsonSerializable()
class RoadmapBreakdownItem {
  final int? roadmapId;
  final String? title;
  final String? goal;
  final String? status;
  final int? totalMissions;
  final int? completedMissions;
  final int? pendingMissions;
  final int? progressPercent;
  final String? nextMissionTitle;
  final String? lastCompletedAt;

  RoadmapBreakdownItem({
    this.roadmapId,
    this.title,
    this.goal,
    this.status,
    this.totalMissions,
    this.completedMissions,
    this.pendingMissions,
    this.progressPercent,
    this.nextMissionTitle,
    this.lastCompletedAt,
  });

  factory RoadmapBreakdownItem.fromJson(Map<String, dynamic> json) =>
      _$RoadmapBreakdownItemFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapBreakdownItemToJson(this);
}

/// Course breakdown item
@JsonSerializable()
class CourseBreakdownItem {
  final int? courseId;
  final String? courseTitle;
  final String? status;
  final int? progressPercent;
  final String? completedAt;
  final String? enrolledAt;

  CourseBreakdownItem({
    this.courseId,
    this.courseTitle,
    this.status,
    this.progressPercent,
    this.completedAt,
    this.enrolledAt,
  });

  factory CourseBreakdownItem.fromJson(Map<String, dynamic> json) =>
      _$CourseBreakdownItemFromJson(json);
  Map<String, dynamic> toJson() => _$CourseBreakdownItemToJson(this);
}

/// Job breakdown item
@JsonSerializable()
class JobBreakdownItem {
  final int? jobId;
  final String? jobTitle;
  final String? recruiterName;
  final String? status;
  final double? budget;
  final double? earnedAmount;
  final int? milestonesTotal;
  final int? milestonesCompleted;
  final String? appliedAt;
  final String? completedAt;
  final double? rating;
  final String? primarySkill;
  final List<String>? skillsDemonstrated;

  JobBreakdownItem({
    this.jobId,
    this.jobTitle,
    this.recruiterName,
    this.status,
    this.budget,
    this.earnedAmount,
    this.milestonesTotal,
    this.milestonesCompleted,
    this.appliedAt,
    this.completedAt,
    this.rating,
    this.primarySkill,
    this.skillsDemonstrated,
  });

  factory JobBreakdownItem.fromJson(Map<String, dynamic> json) =>
      _$JobBreakdownItemFromJson(json);
  Map<String, dynamic> toJson() => _$JobBreakdownItemToJson(this);
}

/// Timeline data point for charts
@JsonSerializable()
class TimelinePoint {
  final String? bucketLabel;
  final String? bucketStart;
  final int? studyMinutes;
  final int? missionsCompleted;
  final int? tasksCompleted;
  final int? jobsCompleted;
  final double? earnings;

  TimelinePoint({
    this.bucketLabel,
    this.bucketStart,
    this.studyMinutes,
    this.missionsCompleted,
    this.tasksCompleted,
    this.jobsCompleted,
    this.earnings,
  });

  factory TimelinePoint.fromJson(Map<String, dynamic> json) =>
      _$TimelinePointFromJson(json);
  Map<String, dynamic> toJson() => _$TimelinePointToJson(this);
}

// ============================================================================
// MAIN RESPONSE (expanded with V2 structured fields)
// ============================================================================

/// Full Learning Report response from Backend
@JsonSerializable()
class StudentLearningReportResponse {
  final int? id;
  final int? reportId;
  final String? reportName;
  final String? generatedAt;
  final int? studentId;
  final String? studentName;
  final String? reportType;
  final String? range;
  final bool? snapshot;

  // --- V2 structured data ---
  final ReportOverview? overview;
  final StudyStats? studyStats;
  final ReportRoadmapStats? roadmapStats;
  final TaskStats? taskStats;
  final CourseStats? courseStats;
  final ShortTermJobStats? jobStats;
  final List<RoadmapBreakdownItem>? roadmapBreakdown;
  final List<CourseBreakdownItem>? courseBreakdown;
  final List<JobBreakdownItem>? jobBreakdown;
  final List<TimelinePoint>? timeline;
  final Map<String, List<TimelinePoint>>? timelineByRange;

  // --- Compatibility fields (kept for backward compat with old backend) ---
  final String? reportContent;
  final ReportSections? sections;
  final StudentMetrics? metrics;

  /// Tiến độ tổng thể (0-100)
  final int? overallProgress;

  /// Xu hướng học tập: improving / stable / declining
  final String? learningTrend;

  /// Đề xuất tập trung
  final String? recommendedFocus;

  StudentLearningReportResponse({
    this.id,
    this.reportId,
    this.reportName,
    this.generatedAt,
    this.studentId,
    this.studentName,
    this.reportType,
    this.range,
    this.snapshot,
    this.overview,
    this.studyStats,
    this.roadmapStats,
    this.taskStats,
    this.courseStats,
    this.jobStats,
    this.roadmapBreakdown,
    this.courseBreakdown,
    this.jobBreakdown,
    this.timeline,
    this.timelineByRange,
    this.reportContent,
    this.sections,
    this.metrics,
    this.overallProgress,
    this.learningTrend,
    this.recommendedFocus,
  });

  factory StudentLearningReportResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentLearningReportResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentLearningReportResponseToJson(this);

  /// Get structured recommendations if available, otherwise empty
  List<ReportRecommendation> get structuredRecommendations =>
      overview?.recommendations ?? [];

  /// Check if this report has the new structured format
  bool get hasStructuredData => overview != null || studyStats != null;
}

/// Request to generate a new report
@JsonSerializable()
class GenerateReportRequest {
  final String? reportType;
  final bool? includeChatHistory;
  final bool? includeDetailedSkills;
  final String? customPrompt;

  GenerateReportRequest({
    this.reportType,
    this.includeChatHistory,
    this.includeDetailedSkills,
    this.customPrompt,
  });

  factory GenerateReportRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateReportRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateReportRequestToJson(this);
}
