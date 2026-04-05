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
  final String? createdAt;
  final String? lastActivityAt;

  RoadmapProgress({
    this.roadmapId,
    this.title,
    this.goal,
    this.totalQuests,
    this.completedQuests,
    this.progressPercent,
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

/// Full Learning Report response from Backend
@JsonSerializable()
class StudentLearningReportResponse {
  final int? id;
  final String? generatedAt;
  final int? studentId;
  final String? studentName;
  final String? reportContent;
  final ReportSections? sections;
  final StudentMetrics? metrics;
  final String? reportType;

  StudentLearningReportResponse({
    this.id,
    this.generatedAt,
    this.studentId,
    this.studentName,
    this.reportContent,
    this.sections,
    this.metrics,
    this.reportType,
  });

  factory StudentLearningReportResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentLearningReportResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudentLearningReportResponseToJson(this);
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
