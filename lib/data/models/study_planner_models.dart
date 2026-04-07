import 'package:json_annotation/json_annotation.dart';

part 'study_planner_models.g.dart';

/// Study method enum
enum StudyMethod {
  @JsonValue('POMODORO')
  pomodoro,
  @JsonValue('TIME_BLOCKING')
  timeBlocking,
  @JsonValue('SPACED_REPETITION')
  spacedRepetition,
}

/// Resources preference enum
enum ResourcesPreference {
  @JsonValue('VIDEO')
  video,
  @JsonValue('READING')
  reading,
  @JsonValue('INTERACTIVE')
  interactive,
  @JsonValue('MIXED')
  mixed,
}

/// Study preference enum
enum StudyPreference {
  @JsonValue('BALANCED')
  balanced,
  @JsonValue('INTENSIVE')
  intensive,
  @JsonValue('RELAXED')
  relaxed,
}

/// Chronotype enum
enum Chronotype {
  @JsonValue('BEAR')
  bear, // Normal schedule (9-5)
  @JsonValue('LION')
  lion, // Early bird
  @JsonValue('WOLF')
  wolf, // Night owl
  @JsonValue('DOLPHIN')
  dolphin, // Light sleeper
}

/// Focus window enum
enum FocusWindow {
  @JsonValue('MORNING')
  morning,
  @JsonValue('AFTERNOON')
  afternoon,
  @JsonValue('EVENING')
  evening,
  @JsonValue('NIGHT')
  night,
}

/// Day of week enum
enum DayOfWeek {
  @JsonValue('MONDAY')
  monday,
  @JsonValue('TUESDAY')
  tuesday,
  @JsonValue('WEDNESDAY')
  wednesday,
  @JsonValue('THURSDAY')
  thursday,
  @JsonValue('FRIDAY')
  friday,
  @JsonValue('SATURDAY')
  saturday,
  @JsonValue('SUNDAY')
  sunday,
}

/// Generate Schedule Request for AI Study Planner
@JsonSerializable()
class GenerateScheduleRequest {
  final String subjectName;
  final List<String> topics;
  final String desiredOutcome;
  final String studyMethod;
  final String resourcesPreference;
  final String startDate;
  final String deadline;
  final String timezone;
  final int durationMinutes;
  final int breakMinutesBetweenSessions;
  final int maxSessionsPerDay;
  final int maxDailyStudyMinutes;
  final List<String> preferredDays;
  final List<String> preferredTimeWindows;
  final String studyPreference;
  final String chronotype;
  final List<String> idealFocusWindows;
  final String earliestStartLocalTime;
  final String latestEndLocalTime;
  final bool avoidLateNight;
  final bool allowLateNight;
  final String? freeTimeDescription;
  final String? intensityLevel;
  final bool? confirmLateNight;
  final List<String>? childBranchTitles;

  GenerateScheduleRequest({
    required this.subjectName,
    this.topics = const [],
    required this.desiredOutcome,
    this.studyMethod = 'POMODORO',
    this.resourcesPreference = 'VIDEO',
    required this.startDate,
    required this.deadline,
    this.timezone = 'Asia/Saigon',
    this.durationMinutes = 600,
    this.breakMinutesBetweenSessions = 15,
    this.maxSessionsPerDay = 4,
    this.maxDailyStudyMinutes = 240,
    this.preferredDays = const [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
    ],
    this.preferredTimeWindows = const ['09:00-17:00'],
    this.studyPreference = 'BALANCED',
    this.chronotype = 'BEAR',
    this.idealFocusWindows = const ['MORNING'],
    this.earliestStartLocalTime = '08:00',
    this.latestEndLocalTime = '22:00',
    this.avoidLateNight = true,
    this.allowLateNight = false,
    this.freeTimeDescription,
    this.intensityLevel,
    this.confirmLateNight,
    this.childBranchTitles,
  });

  factory GenerateScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateScheduleRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateScheduleRequestToJson(this);
}

/// Study Session Response from AI
@JsonSerializable()
class StudySessionResponse {
  final String id;
  final String? subject;
  final String? topic;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String status;
  final String? notes;

  StudySessionResponse({
    required this.id,
    this.subject,
    this.topic,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.status = 'SCHEDULED',
    this.notes,
  });

  factory StudySessionResponse.fromJson(Map<String, dynamic> json) =>
      _$StudySessionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$StudySessionResponseToJson(this);
}

/// Create Study Session Request
@JsonSerializable()
class CreateStudySessionRequest {
  final String? subject;
  final String? topic;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String? notes;

  CreateStudySessionRequest({
    this.subject,
    this.topic,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.notes,
  });

  factory CreateStudySessionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateStudySessionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateStudySessionRequestToJson(this);
}

/// Refine Schedule Request — send current schedule + user feedback
@JsonSerializable()
class RefineScheduleRequest {
  final List<StudySessionResponse> currentSchedule;
  final String userFeedback;
  final String originalGoal;

  RefineScheduleRequest({
    required this.currentSchedule,
    required this.userFeedback,
    required this.originalGoal,
  });

  factory RefineScheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$RefineScheduleRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefineScheduleRequestToJson(this);
}

/// Check Schedule Health Request
@JsonSerializable()
class CheckScheduleHealthRequest {
  final List<StudySessionResponse> sessions;
  final String? timezone;
  final String? earliestStartLocalTime;
  final String? latestEndLocalTime;
  final int? maxDailyStudyMinutes;
  final int? breakMinutesBetweenSessions;
  final String? studyPreference;
  final String? chronotype;
  final List<String>? idealFocusWindows;

  CheckScheduleHealthRequest({
    required this.sessions,
    this.timezone,
    this.earliestStartLocalTime,
    this.latestEndLocalTime,
    this.maxDailyStudyMinutes,
    this.breakMinutesBetweenSessions,
    this.studyPreference,
    this.chronotype,
    this.idealFocusWindows,
  });

  factory CheckScheduleHealthRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckScheduleHealthRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CheckScheduleHealthRequestToJson(this);
}

/// Session Score (used in ScheduleHealthReport)
@JsonSerializable()
class SessionScoreDto {
  final String? id;
  final String? title;
  final int score;

  const SessionScoreDto({this.id, this.title, required this.score});

  factory SessionScoreDto.fromJson(Map<String, dynamic> json) =>
      _$SessionScoreDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SessionScoreDtoToJson(this);
}

/// Schedule Health Report — result of health check
@JsonSerializable()
class ScheduleHealthReport {
  final bool healthy;
  final List<String>? warnings;
  final List<String>? errors;
  final List<String>? suggestions;
  final List<StudySessionResponse>? adjustedSessions;
  final List<SessionScoreDto>? sessionScores;

  const ScheduleHealthReport({
    required this.healthy,
    this.warnings,
    this.errors,
    this.suggestions,
    this.adjustedSessions,
    this.sessionScores,
  });

  factory ScheduleHealthReport.fromJson(Map<String, dynamic> json) =>
      _$ScheduleHealthReportFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleHealthReportToJson(this);
}
