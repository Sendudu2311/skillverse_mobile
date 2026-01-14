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
