// Node Mentoring models — manual fromJson (no build_runner).
// Mirrors backend journey_service/node_mentoring DTOs.

// ── Enums ─────────────────────────────────────────────────────────────────

enum AssignmentSource {
  systemGenerated,
  mentorRefined;

  static AssignmentSource fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MENTOR_REFINED':
        return mentorRefined;
      case 'SYSTEM_GENERATED':
      default:
        return systemGenerated;
    }
  }
}

enum NodeSubmissionStatus {
  draft,
  submitted,
  reworkRequested,
  resubmitted,
  withdrawn;

  static NodeSubmissionStatus? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'DRAFT':
        return draft;
      case 'SUBMITTED':
        return submitted;
      case 'REWORK_REQUESTED':
        return reworkRequested;
      case 'RESUBMITTED':
        return resubmitted;
      case 'WITHDRAWN':
        return withdrawn;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case draft:
        return 'Nháp';
      case submitted:
        return 'Đã nộp';
      case reworkRequested:
        return 'Yêu cầu làm lại';
      case resubmitted:
        return 'Đã nộp lại';
      case withdrawn:
        return 'Đã rút';
    }
  }
}

enum NodeVerificationStatus {
  pending,
  underReview,
  approved,
  rejected,
  verified;

  static NodeVerificationStatus? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return pending;
      case 'UNDER_REVIEW':
        return underReview;
      case 'APPROVED':
        return approved;
      case 'REJECTED':
        return rejected;
      case 'VERIFIED':
        return verified;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case pending:
        return 'Chờ xử lý';
      case underReview:
        return 'Đang xem xét';
      case approved:
        return 'Đã duyệt';
      case rejected:
        return 'Bị từ chối';
      case verified:
        return 'Đã xác thực';
    }
  }
}

enum NodeReviewResult {
  approved,
  reworkRequested,
  rejected;

  static NodeReviewResult? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'APPROVED':
        return approved;
      case 'REWORK_REQUESTED':
        return reworkRequested;
      case 'REJECTED':
        return rejected;
      default:
        return null;
    }
  }
}

// ── NodeAssignmentResponse ─────────────────────────────────────────────────

class NodeAssignmentResponse {
  final int id;
  final int? journeyId;
  final int? roadmapSessionId;
  final String? nodeId;
  final int? nodeSkillId;
  final AssignmentSource? assignmentSource;
  final String? title;
  final String? description;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NodeAssignmentResponse({
    required this.id,
    this.journeyId,
    this.roadmapSessionId,
    this.nodeId,
    this.nodeSkillId,
    this.assignmentSource,
    this.title,
    this.description,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory NodeAssignmentResponse.fromJson(Map<String, dynamic> json) {
    return NodeAssignmentResponse(
      id: (json['id'] as num).toInt(),
      journeyId: (json['journeyId'] as num?)?.toInt(),
      roadmapSessionId: (json['roadmapSessionId'] as num?)?.toInt(),
      nodeId: json['nodeId'] as String?,
      nodeSkillId: (json['nodeSkillId'] as num?)?.toInt(),
      assignmentSource: AssignmentSource.fromString(
        json['assignmentSource'] as String?,
      ),
      title: json['title'] as String?,
      description: json['description'] as String?,
      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
    );
  }
}

// ── NodeReviewResponse ─────────────────────────────────────────────────────

class NodeReviewResponse {
  final int id;
  final int? submissionId;
  final int? mentorId;
  final int? bookingId;
  final int? score;
  final String? feedback;
  final NodeReviewResult? reviewResult;
  final DateTime? reviewedAt;

  const NodeReviewResponse({
    required this.id,
    this.submissionId,
    this.mentorId,
    this.bookingId,
    this.score,
    this.feedback,
    this.reviewResult,
    this.reviewedAt,
  });

  factory NodeReviewResponse.fromJson(Map<String, dynamic> json) {
    return NodeReviewResponse(
      id: (json['id'] as num).toInt(),
      submissionId: (json['submissionId'] as num?)?.toInt(),
      mentorId: (json['mentorId'] as num?)?.toInt(),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
      reviewResult: NodeReviewResult.fromString(
        json['reviewResult'] as String?,
      ),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())?.toLocal()
          : null,
    );
  }
}

// ── NodeVerificationResponse ───────────────────────────────────────────────

class NodeVerificationResponse {
  final int id;
  final int? submissionId;
  final int? mentorId;
  final int? bookingId;
  final NodeVerificationStatus? nodeVerificationStatus;
  final String? verificationNote;
  final DateTime? verifiedAt;

  const NodeVerificationResponse({
    required this.id,
    this.submissionId,
    this.mentorId,
    this.bookingId,
    this.nodeVerificationStatus,
    this.verificationNote,
    this.verifiedAt,
  });

  factory NodeVerificationResponse.fromJson(Map<String, dynamic> json) {
    return NodeVerificationResponse(
      id: (json['id'] as num).toInt(),
      submissionId: (json['submissionId'] as num?)?.toInt(),
      mentorId: (json['mentorId'] as num?)?.toInt(),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      nodeVerificationStatus: NodeVerificationStatus.fromString(
        json['nodeVerificationStatus'] as String?,
      ),
      verificationNote: json['verificationNote'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())?.toLocal()
          : null,
    );
  }
}

// ── NodeEvidenceRecordResponse ─────────────────────────────────────────────

class NodeEvidenceRecordResponse {
  final int id;
  final int? journeyId;
  final int? roadmapSessionId;
  final String? nodeId;
  final int? assignmentId;
  final int? learnerId;

  final String? submissionText;
  final String? evidenceUrl;
  final String? attachmentUrl;

  final NodeSubmissionStatus? submissionStatus;
  final NodeVerificationStatus? verificationStatus;
  final String? mentorFeedback;

  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final bool? learnerMarkedComplete;
  final String? roadmapProgressStatus;

  final NodeReviewResponse? latestReview;
  final NodeVerificationResponse? latestVerification;

  const NodeEvidenceRecordResponse({
    required this.id,
    this.journeyId,
    this.roadmapSessionId,
    this.nodeId,
    this.assignmentId,
    this.learnerId,
    this.submissionText,
    this.evidenceUrl,
    this.attachmentUrl,
    this.submissionStatus,
    this.verificationStatus,
    this.mentorFeedback,
    this.submittedAt,
    this.updatedAt,
    this.learnerMarkedComplete,
    this.roadmapProgressStatus,
    this.latestReview,
    this.latestVerification,
  });

  bool get reworkRequested =>
      submissionStatus == NodeSubmissionStatus.reworkRequested;

  factory NodeEvidenceRecordResponse.fromJson(Map<String, dynamic> json) {
    return NodeEvidenceRecordResponse(
      id: (json['id'] as num).toInt(),
      journeyId: (json['journeyId'] as num?)?.toInt(),
      roadmapSessionId: (json['roadmapSessionId'] as num?)?.toInt(),
      nodeId: json['nodeId'] as String?,
      assignmentId: (json['assignmentId'] as num?)?.toInt(),
      learnerId: (json['learnerId'] as num?)?.toInt(),
      submissionText: json['submissionText'] as String?,
      evidenceUrl: json['evidenceUrl'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      submissionStatus: NodeSubmissionStatus.fromString(
        json['submissionStatus'] as String?,
      ),
      verificationStatus: NodeVerificationStatus.fromString(
        json['verificationStatus'] as String?,
      ),
      mentorFeedback: json['mentorFeedback'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
      learnerMarkedComplete: json['learnerMarkedComplete'] as bool?,
      roadmapProgressStatus: json['roadmapProgressStatus'] as String?,
      latestReview: json['latestReview'] != null
          ? NodeReviewResponse.fromJson(
              json['latestReview'] as Map<String, dynamic>,
            )
          : null,
      latestVerification: json['latestVerification'] != null
          ? NodeVerificationResponse.fromJson(
              json['latestVerification'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

// ── SubmitNodeEvidenceRequest ──────────────────────────────────────────────

class SubmitNodeEvidenceRequest {
  final String submissionText;
  final String? evidenceUrl;
  final String? attachmentUrl;

  const SubmitNodeEvidenceRequest({
    required this.submissionText,
    this.evidenceUrl,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() => {
    'submissionText': submissionText,
    if (evidenceUrl != null && evidenceUrl!.isNotEmpty)
      'evidenceUrl': evidenceUrl,
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty)
      'attachmentUrl': attachmentUrl,
  };
}

// ── SubmitJourneyOutputAssessmentRequest ────────────────────────────────────

class SubmitJourneyOutputAssessmentRequest {
  final String submissionText;
  final String? evidenceUrl;
  final String? attachmentUrl;

  const SubmitJourneyOutputAssessmentRequest({
    required this.submissionText,
    this.evidenceUrl,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() => {
    'submissionText': submissionText,
    if (evidenceUrl != null && evidenceUrl!.isNotEmpty)
      'evidenceUrl': evidenceUrl,
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty)
      'attachmentUrl': attachmentUrl,
  };
}

// ── RoadmapFollowUpMeetingDTO ──────────────────────────────────────────────

class RoadmapFollowUpMeetingDTO {
  final int? id;
  final int? bookingId;
  final int? journeyId;
  final int? mentorId;
  final int? learnerId;
  final String? title;
  final String? agenda;
  final String? purpose;
  final String? scheduledAt;
  final int? durationMinutes;
  final String? meetingLink;
  final String? status;
  final String? notes;
  final String? createdByRole;
  final int? createdByUserId;
  final String? acceptedAt;
  final String? rejectedAt;
  final String? rejectReason;
  final bool? canJoin;

  const RoadmapFollowUpMeetingDTO({
    this.id,
    this.bookingId,
    this.journeyId,
    this.mentorId,
    this.learnerId,
    this.title,
    this.agenda,
    this.purpose,
    this.scheduledAt,
    this.durationMinutes,
    this.meetingLink,
    this.status,
    this.notes,
    this.createdByRole,
    this.createdByUserId,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectReason,
    this.canJoin,
  });

  factory RoadmapFollowUpMeetingDTO.fromJson(Map<String, dynamic> json) {
    return RoadmapFollowUpMeetingDTO(
      id: (json['id'] as num?)?.toInt(),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      journeyId: (json['journeyId'] as num?)?.toInt(),
      mentorId: (json['mentorId'] as num?)?.toInt(),
      learnerId: (json['learnerId'] as num?)?.toInt(),
      title: json['title'] as String?,
      agenda: json['agenda'] as String?,
      purpose: json['purpose'] as String?,
      scheduledAt: json['scheduledAt'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      meetingLink: json['meetingLink'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
      createdByRole: json['createdByRole'] as String?,
      createdByUserId: (json['createdByUserId'] as num?)?.toInt(),
      acceptedAt: json['acceptedAt'] as String?,
      rejectedAt: json['rejectedAt'] as String?,
      rejectReason: json['rejectReason'] as String?,
      canJoin: json['canJoin'] as bool?,
    );
  }

  /// User-friendly status label
  String get statusLabel {
    switch (status?.toUpperCase()) {
      case 'PENDING_MENTOR':
        return 'Chờ mentor chấp nhận';
      case 'PENDING_LEARNER':
        return 'Mentor đề xuất — cần bạn chấp nhận';
      case 'ACCEPTED':
        return 'Đã kích hoạt';
      case 'REJECTED':
        return 'Đã từ chối';
      case 'CANCELLED':
        return 'Đã huỷ';
      case 'COMPLETED':
        return 'Đã hoàn tất';
      default:
        return 'Đã lên lịch';
    }
  }

  DateTime? get scheduledAtLocal =>
      scheduledAt != null ? DateTime.tryParse(scheduledAt!)?.toLocal() : null;
}

// ── CreateFollowUpMeetingRequest ────────────────────────────────────────────

class CreateFollowUpMeetingRequest {
  final String title;
  final String? purpose;
  final String? agenda;
  final String scheduledAt;
  final int? durationMinutes;

  const CreateFollowUpMeetingRequest({
    required this.title,
    this.purpose,
    this.agenda,
    required this.scheduledAt,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (purpose != null) 'purpose': purpose,
    if (agenda != null) 'agenda': agenda,
    'scheduledAt': scheduledAt,
    if (durationMinutes != null) 'durationMinutes': durationMinutes,
  };
}

// ── OutputAssessmentStatus Enum ────────────────────────────────────────────

enum OutputAssessmentStatus {
  pending,
  approved,
  rejected;

  static OutputAssessmentStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'APPROVED':
        return approved;
      case 'REJECTED':
        return rejected;
      case 'PENDING':
      default:
        return pending;
    }
  }

  String get displayName {
    switch (this) {
      case pending:
        return 'Chờ xử lý';
      case approved:
        return 'Đã duyệt';
      case rejected:
        return 'Bị từ chối';
    }
  }
}

// ── JourneyOutputAssessmentResponse ────────────────────────────────────────

class JourneyOutputAssessmentResponse {
  final int? id;
  final int? journeyId;
  final int? learnerId;
  final int? mentorId;
  final String? submissionText;
  final String? evidenceUrl;
  final String? attachmentUrl;
  final int? score;
  final String? feedback;
  final OutputAssessmentStatus assessmentStatus;
  final DateTime? submittedAt;
  final DateTime? assessedAt;

  const JourneyOutputAssessmentResponse({
    this.id,
    this.journeyId,
    this.learnerId,
    this.mentorId,
    this.submissionText,
    this.evidenceUrl,
    this.attachmentUrl,
    this.score,
    this.feedback,
    this.assessmentStatus = OutputAssessmentStatus.pending,
    this.submittedAt,
    this.assessedAt,
  });

  factory JourneyOutputAssessmentResponse.fromJson(Map<String, dynamic> json) {
    return JourneyOutputAssessmentResponse(
      id: (json['id'] as num?)?.toInt(),
      journeyId: (json['journeyId'] as num?)?.toInt(),
      learnerId: (json['learnerId'] as num?)?.toInt(),
      mentorId: (json['mentorId'] as num?)?.toInt(),
      submissionText: json['submissionText'] as String?,
      evidenceUrl: json['evidenceUrl'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      score: (json['score'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
      assessmentStatus: OutputAssessmentStatus.fromString(
        json['assessmentStatus'] as String?,
      ),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())?.toLocal()
          : null,
      assessedAt: json['assessedAt'] != null
          ? DateTime.tryParse(json['assessedAt'].toString())?.toLocal()
          : null,
    );
  }

  String get statusLabel => assessmentStatus.displayName;
}

// ── FinalGateStatus Enum ───────────────────────────────────────────────────

enum FinalGateStatus {
  notRequired,
  blocked,
  passed;

  static FinalGateStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PASSED':
        return passed;
      case 'BLOCKED':
        return blocked;
      case 'NOT_REQUIRED':
      default:
        return notRequired;
    }
  }

  String get displayName {
    switch (this) {
      case notRequired:
        return 'Không yêu cầu';
      case blocked:
        return 'Đang chặn';
      case passed:
        return 'Đã vượt qua';
    }
  }
}

// ── GateDecision Enum ──────────────────────────────────────────────────────

enum GateDecision {
  pass,
  fail,
  pending;

  static GateDecision fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PASS':
        return pass;
      case 'FAIL':
        return fail;
      case 'PENDING':
      default:
        return pending;
    }
  }

  String get displayName {
    switch (this) {
      case pass:
        return 'Đạt';
      case fail:
        return 'Không đạt';
      case pending:
        return 'Chờ xử lý';
    }
  }
}

// ── JourneyCompletionGateResponse ──────────────────────────────────────────

class JourneyCompletionGateResponse {
  final int journeyId;
  final FinalGateStatus finalGateStatus;
  final bool finalVerificationRequired;
  final bool journeyOutputVerificationRequired;
  final bool hasPassCompletionReport;
  final bool outputAssessmentApproved;
  final List<String> blockingReasons;

  const JourneyCompletionGateResponse({
    required this.journeyId,
    required this.finalGateStatus,
    this.finalVerificationRequired = false,
    this.journeyOutputVerificationRequired = false,
    this.hasPassCompletionReport = false,
    this.outputAssessmentApproved = false,
    this.blockingReasons = const [],
  });

  factory JourneyCompletionGateResponse.fromJson(Map<String, dynamic> json) {
    return JourneyCompletionGateResponse(
      journeyId: (json['journeyId'] as num).toInt(),
      finalGateStatus: FinalGateStatus.fromString(
        json['finalGateStatus'] as String?,
      ),
      finalVerificationRequired:
          json['finalVerificationRequired'] as bool? ?? false,
      journeyOutputVerificationRequired:
          json['journeyOutputVerificationRequired'] as bool? ?? false,
      hasPassCompletionReport:
          json['hasPassCompletionReport'] as bool? ?? false,
      outputAssessmentApproved:
          json['outputAssessmentApproved'] as bool? ?? false,
      blockingReasons:
          (json['blockingReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

// ── VerificationEvidenceReportResponse ─────────────────────────────────────

class VerificationEvidenceReportResponse {
  final int id;
  final int journeyId;
  final int bookingId;
  final int mentorId;
  final String? meetingJitsiLink;
  final int? meetingDurationMinutes;
  final String summaryReport;
  final List<String>? assignmentsGiven;
  final List<String>? weakNodeIds;
  final String? failReason;
  final GateDecision gateDecision;
  final int attemptNumber;
  final DateTime submittedAt;

  const VerificationEvidenceReportResponse({
    required this.id,
    required this.journeyId,
    required this.bookingId,
    required this.mentorId,
    this.meetingJitsiLink,
    this.meetingDurationMinutes,
    required this.summaryReport,
    this.assignmentsGiven,
    this.weakNodeIds,
    this.failReason,
    required this.gateDecision,
    required this.attemptNumber,
    required this.submittedAt,
  });

  factory VerificationEvidenceReportResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerificationEvidenceReportResponse(
      id: (json['id'] as num).toInt(),
      journeyId: (json['journeyId'] as num).toInt(),
      bookingId: (json['bookingId'] as num).toInt(),
      mentorId: (json['mentorId'] as num).toInt(),
      meetingJitsiLink: json['meetingJitsiLink'] as String?,
      meetingDurationMinutes: (json['meetingDurationMinutes'] as num?)?.toInt(),
      summaryReport: json['summaryReport'] as String? ?? '',
      assignmentsGiven: (json['assignmentsGiven'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      weakNodeIds: (json['weakNodeIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      failReason: json['failReason'] as String?,
      gateDecision: GateDecision.fromString(json['gateDecision'] as String?),
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
      submittedAt:
          DateTime.tryParse(json['submittedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

// ── UserVerifiedSkillDTO ───────────────────────────────────────────────────

class UserVerifiedSkillDTO {
  final int id;
  final String skillName;
  final String? skillLevel;
  final int verifiedByMentorId;
  final String? verifiedByMentorName;
  final int? journeyId;
  final int? bookingId;
  final String? verificationNote;
  final DateTime verifiedAt;

  const UserVerifiedSkillDTO({
    required this.id,
    required this.skillName,
    this.skillLevel,
    required this.verifiedByMentorId,
    this.verifiedByMentorName,
    this.journeyId,
    this.bookingId,
    this.verificationNote,
    required this.verifiedAt,
  });

  factory UserVerifiedSkillDTO.fromJson(Map<String, dynamic> json) {
    return UserVerifiedSkillDTO(
      id: (json['id'] as num).toInt(),
      skillName: json['skillName'] as String? ?? '',
      skillLevel: json['skillLevel'] as String?,
      verifiedByMentorId: (json['verifiedByMentorId'] as num).toInt(),
      verifiedByMentorName: json['verifiedByMentorName'] as String?,
      journeyId: (json['journeyId'] as num?)?.toInt(),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      verificationNote: json['verificationNote'] as String?,
      verifiedAt:
          DateTime.tryParse(json['verifiedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Display-friendly skill name (replace underscores with spaces)
  String get displayName => skillName.replaceAll('_', ' ');
}
