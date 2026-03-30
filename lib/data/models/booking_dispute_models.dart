// Booking Dispute models — no build_runner needed (manual fromJson).
// Mirrors backend BookingDispute, BookingDisputeEvidence, BookingDisputeResponse.

// ── Dispute Status ──────────────────────────────────────────────────────────

enum DisputeStatus {
  open,
  underInvestigation,
  awaitingResponse,
  resolved,
  dismissed,
  escalated,
  unknown;

  static DisputeStatus fromString(String? value) {
    switch (value) {
      case 'OPEN':
        return open;
      case 'UNDER_INVESTIGATION':
        return underInvestigation;
      case 'AWAITING_RESPONSE':
        return awaitingResponse;
      case 'RESOLVED':
        return resolved;
      case 'DISMISSED':
        return dismissed;
      case 'ESCALATED':
        return escalated;
      default:
        return unknown;
    }
  }

  String get displayName {
    switch (this) {
      case open:
        return 'Đang mở';
      case underInvestigation:
        return 'Đang điều tra';
      case awaitingResponse:
        return 'Chờ phản hồi';
      case resolved:
        return 'Đã giải quyết';
      case dismissed:
        return 'Đã bác bỏ';
      case escalated:
        return 'Đã chuyển cấp';
      case unknown:
        return 'Không xác định';
    }
  }
}

// ── Dispute Resolution ──────────────────────────────────────────────────────

enum DisputeResolution {
  fullRefund,
  fullRelease,
  partialRefund,
  partialRelease;

  static DisputeResolution? fromString(String? value) {
    switch (value) {
      case 'FULL_REFUND':
        return fullRefund;
      case 'FULL_RELEASE':
        return fullRelease;
      case 'PARTIAL_REFUND':
        return partialRefund;
      case 'PARTIAL_RELEASE':
        return partialRelease;
      default:
        return null;
    }
  }
}

// ── Evidence Type ───────────────────────────────────────────────────────────

enum EvidenceType {
  text,
  file,
  link,
  screenshot,
  chatLog,
  image;

  static EvidenceType fromString(String? value) {
    switch (value) {
      case 'TEXT':
        return text;
      case 'FILE':
        return file;
      case 'LINK':
        return link;
      case 'SCREENSHOT':
        return screenshot;
      case 'CHAT_LOG':
        return chatLog;
      case 'IMAGE':
        return image;
      default:
        return text;
    }
  }

  String toValue() {
    switch (this) {
      case text:
        return 'TEXT';
      case file:
        return 'FILE';
      case link:
        return 'LINK';
      case screenshot:
        return 'SCREENSHOT';
      case chatLog:
        return 'CHAT_LOG';
      case image:
        return 'IMAGE';
    }
  }
}

// ── Evidence Review Status ──────────────────────────────────────────────────

enum EvidenceReviewStatus {
  pending,
  underReview,
  accepted,
  rejected;

  static EvidenceReviewStatus fromString(String? value) {
    switch (value) {
      case 'PENDING':
        return pending;
      case 'UNDER_REVIEW':
        return underReview;
      case 'ACCEPTED':
        return accepted;
      case 'REJECTED':
        return rejected;
      default:
        return pending;
    }
  }
}

// ── BookingDispute ──────────────────────────────────────────────────────────

class BookingDisputeDto {
  final int id;
  final int bookingId;
  final int initiatorId;
  final int respondentId;
  final String reason;
  final DisputeStatus status;
  final DisputeResolution? resolution;
  final String? resolutionNotes;
  final double? refundAmount;
  final double? releasedAmount;
  final double? mentorPayoutAmount;
  final double? adminCommissionAmount;
  final int? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const BookingDisputeDto({
    required this.id,
    required this.bookingId,
    required this.initiatorId,
    required this.respondentId,
    required this.reason,
    required this.status,
    this.resolution,
    this.resolutionNotes,
    this.refundAmount,
    this.releasedAmount,
    this.mentorPayoutAmount,
    this.adminCommissionAmount,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  factory BookingDisputeDto.fromJson(Map<String, dynamic> json) {
    return BookingDisputeDto(
      id: json['id'] as int,
      bookingId: json['bookingId'] as int,
      initiatorId: json['initiatorId'] as int,
      respondentId: json['respondentId'] as int,
      reason: json['reason'] as String? ?? '',
      status: DisputeStatus.fromString(json['status'] as String?),
      resolution: DisputeResolution.fromString(json['resolution'] as String?),
      resolutionNotes: json['resolutionNotes'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      releasedAmount: (json['releasedAmount'] as num?)?.toDouble(),
      mentorPayoutAmount: (json['mentorPayoutAmount'] as num?)?.toDouble(),
      adminCommissionAmount: (json['adminCommissionAmount'] as num?)
          ?.toDouble(),
      resolvedBy: json['resolvedBy'] as int?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// ── BookingDisputeEvidence ──────────────────────────────────────────────────

class BookingDisputeEvidenceDto {
  final int id;
  final int? disputeId;
  final int submittedBy;
  final EvidenceType evidenceType;
  final String? content;
  final String? fileUrl;
  final String? fileName;
  final String? description;
  final bool isOfficial;
  final EvidenceReviewStatus? reviewStatus;
  final String? reviewNotes;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final List<BookingDisputeResponseDto> responses;

  const BookingDisputeEvidenceDto({
    required this.id,
    this.disputeId,
    required this.submittedBy,
    required this.evidenceType,
    this.content,
    this.fileUrl,
    this.fileName,
    this.description,
    this.isOfficial = false,
    this.reviewStatus,
    this.reviewNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.responses = const [],
  });

  factory BookingDisputeEvidenceDto.fromJson(Map<String, dynamic> json) {
    final rawResponses = json['responses'] as List<dynamic>? ?? [];
    return BookingDisputeEvidenceDto(
      id: json['id'] as int,
      disputeId: json['disputeId'] as int?,
      submittedBy: json['submittedBy'] as int,
      evidenceType: EvidenceType.fromString(json['evidenceType'] as String?),
      content: json['content'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      description: json['description'] as String?,
      isOfficial: json['isOfficial'] as bool? ?? false,
      reviewStatus: EvidenceReviewStatus.fromString(
        json['reviewStatus'] as String?,
      ),
      reviewNotes: json['reviewNotes'] as String?,
      reviewedBy: json['reviewedBy'] as int?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      responses: rawResponses
          .map(
            (e) =>
                BookingDisputeResponseDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

// ── BookingDisputeResponse ──────────────────────────────────────────────────

class BookingDisputeResponseDto {
  final int id;
  final int? evidenceId;
  final int respondedBy;
  final String respondedByName;
  final String content;
  final bool isAdminResponse;
  final DateTime createdAt;

  const BookingDisputeResponseDto({
    required this.id,
    this.evidenceId,
    required this.respondedBy,
    required this.respondedByName,
    required this.content,
    this.isAdminResponse = false,
    required this.createdAt,
  });

  factory BookingDisputeResponseDto.fromJson(Map<String, dynamic> json) {
    return BookingDisputeResponseDto(
      id: json['id'] as int,
      evidenceId: json['evidenceId'] as int?,
      respondedBy: json['respondedBy'] as int,
      respondedByName: json['respondedByName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isAdminResponse: json['isAdminResponse'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
