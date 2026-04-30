// Roadmap Follow-Up Meeting models — manual fromJson (no build_runner).
// Mirrors backend RoadmapFollowUpMeetingDTO.

import '../../core/utils/date_time_helper.dart';

// ── RoadmapFollowUpMeetingDto ──────────────────────────────────────────────

class RoadmapFollowUpMeetingDto {
  final int id;
  final int? bookingId;
  final int? journeyId;
  final int? mentorId;
  final int? learnerId;

  final String? title;
  final String? purpose;
  final String? agenda;

  final DateTime? scheduledAt;
  final int? durationMinutes;
  final String? meetingLink;
  final String? status; // PENDING, ACCEPTED, REJECTED

  final String? notes;
  final int? createdByUserId;
  final String? createdByRole; // MENTOR or LEARNER

  final bool? canJoin;
  final String? rejectReason;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;

  const RoadmapFollowUpMeetingDto({
    required this.id,
    this.bookingId,
    this.journeyId,
    this.mentorId,
    this.learnerId,
    this.title,
    this.purpose,
    this.agenda,
    this.scheduledAt,
    this.durationMinutes,
    this.meetingLink,
    this.status,
    this.notes,
    this.createdByUserId,
    this.createdByRole,
    this.canJoin,
    this.rejectReason,
    this.acceptedAt,
    this.rejectedAt,
  });

  bool get isPending => status?.toUpperCase() == 'PENDING';
  bool get isAccepted => status?.toUpperCase() == 'ACCEPTED';
  bool get isRejected => status?.toUpperCase() == 'REJECTED';

  factory RoadmapFollowUpMeetingDto.fromJson(Map<String, dynamic> json) {
    return RoadmapFollowUpMeetingDto(
      id: (json['id'] as num).toInt(),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      journeyId: (json['journeyId'] as num?)?.toInt(),
      mentorId: (json['mentorId'] as num?)?.toInt(),
      learnerId: (json['learnerId'] as num?)?.toInt(),
      title: json['title'] as String?,
      purpose: json['purpose'] as String?,
      agenda: json['agenda'] as String?,
      scheduledAt: DateTimeHelper.tryParseIso8601(
        json['scheduledAt'] as String?,
      )?.toLocal(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      meetingLink: json['meetingLink'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
      createdByUserId: (json['createdByUserId'] as num?)?.toInt(),
      createdByRole: json['createdByRole'] as String?,
      canJoin: json['canJoin'] as bool?,
      rejectReason: json['rejectReason'] as String?,
      acceptedAt: DateTimeHelper.tryParseIso8601(
        json['acceptedAt'] as String?,
      )?.toLocal(),
      rejectedAt: DateTimeHelper.tryParseIso8601(
        json['rejectedAt'] as String?,
      )?.toLocal(),
    );
  }
}
