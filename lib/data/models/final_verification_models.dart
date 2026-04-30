// Models mapping 1:1 with journey_service/node_mentoring DTOs.

// ============================================================
// Enums
// ============================================================

enum FinalGateStatus {
  notRequired,
  blocked,
  passed,
}

enum AssessmentStatus {
  pending,
  approved,
  rejected,
}

enum GateDecision {
  pass,
  fail,
  pending,
}

// ============================================================
// Response DTOs
// ============================================================

/// Maps JourneyCompletionGateResponse
class JourneyCompletionGateResponse {
  final int journeyId;
  final FinalGateStatus finalGateStatus;
  final bool? finalVerificationRequired;
  final bool? journeyOutputVerificationRequired;
  final bool? hasPassCompletionReport;
  final bool? outputAssessmentApproved;
  final List<String>? blockingReasons;

  JourneyCompletionGateResponse({
    required this.journeyId,
    required this.finalGateStatus,
    this.finalVerificationRequired,
    this.journeyOutputVerificationRequired,
    this.hasPassCompletionReport,
    this.outputAssessmentApproved,
    this.blockingReasons,
  });

  factory JourneyCompletionGateResponse.fromJson(Map<String, dynamic> json) {
    return JourneyCompletionGateResponse(
      journeyId: (json['journeyId'] as num).toInt(),
      finalGateStatus: _parseGateStatus(json['finalGateStatus'] as String?),
      finalVerificationRequired: json['finalVerificationRequired'] as bool?,
      journeyOutputVerificationRequired:
          json['journeyOutputVerificationRequired'] as bool?,
      hasPassCompletionReport: json['hasPassCompletionReport'] as bool?,
      outputAssessmentApproved: json['outputAssessmentApproved'] as bool?,
      blockingReasons: (json['blockingReasons'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  static FinalGateStatus _parseGateStatus(String? value) {
    switch (value) {
      case 'NOT_REQUIRED':
        return FinalGateStatus.notRequired;
      case 'PASSED':
        return FinalGateStatus.passed;
      default:
        return FinalGateStatus.blocked;
    }
  }
}

/// Maps JourneyOutputAssessmentResponse
class JourneyOutputAssessmentResponse {
  final int id;
  final int journeyId;
  final int? learnerId;
  final int? mentorId;
  final String? submissionText;
  final String? evidenceUrl;
  final String? attachmentUrl;
  final int? score;
  final String? feedback;
  final AssessmentStatus? assessmentStatus;
  final DateTime? submittedAt;
  final DateTime? assessedAt;

  JourneyOutputAssessmentResponse({
    required this.id,
    required this.journeyId,
    this.learnerId,
    this.mentorId,
    this.submissionText,
    this.evidenceUrl,
    this.attachmentUrl,
    this.score,
    this.feedback,
    this.assessmentStatus,
    this.submittedAt,
    this.assessedAt,
  });

  factory JourneyOutputAssessmentResponse.fromJson(Map<String, dynamic> json) {
    return JourneyOutputAssessmentResponse(
      id: (json['id'] as num).toInt(),
      journeyId: (json['journeyId'] as num).toInt(),
      learnerId: (json['learnerId'] as num?)?.toInt(),
      mentorId: (json['mentorId'] as num?)?.toInt(),
      submissionText: json['submissionText'] as String?,
      evidenceUrl: json['evidenceUrl'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      score: (json['score'] as num?)?.toInt(),
      feedback: json['feedback'] as String?,
      assessmentStatus: _parseAssessmentStatus(json['assessmentStatus']),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      assessedAt: json['assessedAt'] != null
          ? DateTime.tryParse(json['assessedAt'].toString())
          : null,
    );
  }

  static AssessmentStatus? _parseAssessmentStatus(dynamic value) {
    switch (value?.toString()) {
      case 'PENDING':
        return AssessmentStatus.pending;
      case 'APPROVED':
        return AssessmentStatus.approved;
      case 'REJECTED':
        return AssessmentStatus.rejected;
      default:
        return null;
    }
  }
}

/// Maps VerificationEvidenceReportResponse
class VerificationEvidenceReportResponse {
  final int id;
  final int journeyId;
  final int? bookingId;
  final int? mentorId;
  final String? meetingJitsiLink;
  final int? meetingDurationMinutes;
  final String? summaryReport;
  final List<String>? assignmentsGiven;
  final List<String>? weakNodeIds;
  final String? failReason;
  final GateDecision? gateDecision;
  final int? attemptNumber;
  final DateTime? submittedAt;

  VerificationEvidenceReportResponse({
    required this.id,
    required this.journeyId,
    this.bookingId,
    this.mentorId,
    this.meetingJitsiLink,
    this.meetingDurationMinutes,
    this.summaryReport,
    this.assignmentsGiven,
    this.weakNodeIds,
    this.failReason,
    this.gateDecision,
    this.attemptNumber,
    this.submittedAt,
  });

  factory VerificationEvidenceReportResponse.fromJson(
      Map<String, dynamic> json) {
    return VerificationEvidenceReportResponse(
      id: (json['id'] as num).toInt(),
      journeyId: (json['journeyId'] as num).toInt(),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      mentorId: (json['mentorId'] as num?)?.toInt(),
      meetingJitsiLink: json['meetingJitsiLink'] as String?,
      meetingDurationMinutes: (json['meetingDurationMinutes'] as num?)?.toInt(),
      summaryReport: json['summaryReport'] as String?,
      assignmentsGiven: (json['assignmentsGiven'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      weakNodeIds: (json['weakNodeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      failReason: json['failReason'] as String?,
      gateDecision: _parseGateDecision(json['gateDecision']),
      attemptNumber: (json['attemptNumber'] as num?)?.toInt(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }

  static GateDecision? _parseGateDecision(dynamic value) {
    switch (value?.toString()) {
      case 'PASS':
        return GateDecision.pass;
      case 'FAIL':
        return GateDecision.fail;
      case 'PENDING':
        return GateDecision.pending;
      default:
        return null;
    }
  }
}

// ============================================================
// Request DTOs
// ============================================================

class SubmitJourneyOutputRequest {
  final String submissionText;
  final String? evidenceUrl;
  final String? attachmentUrl;

  SubmitJourneyOutputRequest({
    required this.submissionText,
    this.evidenceUrl,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() => {
        'submissionText': submissionText,
        if (evidenceUrl != null) 'evidenceUrl': evidenceUrl,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      };
}

class AssessJourneyOutputRequest {
  final String assessmentStatus;
  final String? feedback;
  final int? score;

  AssessJourneyOutputRequest({
    required this.assessmentStatus,
    this.feedback,
    this.score,
  });

  Map<String, dynamic> toJson() => {
        'assessmentStatus': assessmentStatus,
        if (feedback != null) 'feedback': feedback,
        if (score != null) 'score': score,
      };
}
