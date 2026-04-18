import 'package:json_annotation/json_annotation.dart';

part 'interview_models.g.dart';

/// Who cancelled the interview
/// Matches backend InterviewSchedule.CancelledBy enum
enum CancelledBy {
  @JsonValue('RECRUITER')
  recruiter,
  @JsonValue('CANDIDATE')
  candidate,
  @JsonValue('AUTO')
  auto,
}

/// Meeting type for interview
/// Matches backend InterviewSchedule.MeetingType enum
enum MeetingType {
  @JsonValue('GOOGLE_MEET')
  googleMeet,
  @JsonValue('SKILLVERSE_ROOM')
  skillverseRoom,
  @JsonValue('ZOOM')
  zoom,
  @JsonValue('MICROSOFT_TEAMS')
  microsoftTeams,
  @JsonValue('PHONE_CALL')
  phoneCall,
  @JsonValue('ONSITE')
  onsite,
}

/// Interview status
/// Matches backend InterviewSchedule.InterviewStatus enum
enum InterviewStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('NO_SHOW')
  noShow,
}

/// Response DTO for interview schedule
/// Matches backend InterviewScheduleResponse.java
@JsonSerializable()
class InterviewScheduleResponse {
  final int? id;
  @JsonKey(name: 'applicationId')
  final int? applicationId;
  @JsonKey(name: 'candidateName')
  final String? candidateName;
  @JsonKey(name: 'candidateEmail')
  final String? candidateEmail;
  @JsonKey(name: 'candidateAvatarUrl')
  final String? candidateAvatarUrl;
  @JsonKey(name: 'jobTitle')
  final String? jobTitle;
  @JsonKey(name: 'scheduledAt')
  final String? scheduledAt;
  @JsonKey(name: 'durationMinutes')
  final int? durationMinutes;
  @JsonKey(name: 'meetingType')
  final MeetingType? meetingType;
  @JsonKey(name: 'meetingLink')
  final String? meetingLink;
  @JsonKey(name: 'skillverseRoomId')
  final String? skillverseRoomId;
  final String? location;
  @JsonKey(name: 'interviewerName')
  final String? interviewerName;
  @JsonKey(name: 'interviewNotes')
  final String? interviewNotes;
  final InterviewStatus? status;
  @JsonKey(name: 'createdAt')
  final String? createdAt;
  @JsonKey(name: 'updatedAt')
  final String? updatedAt;
  @JsonKey(name: 'responseDeadlineAt')
  final String? responseDeadlineAt;
  @JsonKey(name: 'respondedAt')
  final String? respondedAt;
  @JsonKey(name: 'cancelledBy', unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final CancelledBy? cancelledBy;
  @JsonKey(name: 'cancelReason')
  final String? cancelReason;
  @JsonKey(name: 'completedAt')
  final String? completedAt;

  const InterviewScheduleResponse({
    this.id,
    this.applicationId,
    this.candidateName,
    this.candidateEmail,
    this.candidateAvatarUrl,
    this.jobTitle,
    this.scheduledAt,
    this.durationMinutes,
    this.meetingType,
    this.meetingLink,
    this.skillverseRoomId,
    this.location,
    this.interviewerName,
    this.interviewNotes,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.responseDeadlineAt,
    this.respondedAt,
    this.cancelledBy,
    this.cancelReason,
    this.completedAt,
  });

  factory InterviewScheduleResponse.fromJson(Map<String, dynamic> json) =>
      _$InterviewScheduleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InterviewScheduleResponseToJson(this);
}

/// Request DTO for creating an interview
/// Matches backend CreateInterviewRequest.java
@JsonSerializable()
class CreateInterviewRequest {
  @JsonKey(name: 'applicationId')
  final int applicationId;
  @JsonKey(name: 'scheduledAt')
  final String scheduledAt;
  @JsonKey(name: 'durationMinutes')
  final int durationMinutes;
  @JsonKey(name: 'meetingType')
  final MeetingType meetingType;
  @JsonKey(name: 'meetingLink')
  final String? meetingLink;
  @JsonKey(name: 'skillverseRoomId')
  final String? skillverseRoomId;
  final String? location;
  @JsonKey(name: 'interviewerName')
  final String? interviewerName;
  @JsonKey(name: 'interviewNotes')
  final String? interviewNotes;

  const CreateInterviewRequest({
    required this.applicationId,
    required this.scheduledAt,
    this.durationMinutes = 60,
    required this.meetingType,
    this.meetingLink,
    this.skillverseRoomId,
    this.location,
    this.interviewerName,
    this.interviewNotes,
  });

  factory CreateInterviewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateInterviewRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateInterviewRequestToJson(this);
}

/// Request body for declining an interview (candidate)
/// Matches backend DeclineInterviewRequest.java
@JsonSerializable()
class DeclineInterviewRequest {
  final String? reason;

  const DeclineInterviewRequest({this.reason});

  factory DeclineInterviewRequest.fromJson(Map<String, dynamic> json) =>
      _$DeclineInterviewRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeclineInterviewRequestToJson(this);
}
