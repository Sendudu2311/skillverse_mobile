// Student *Skill* Verification models — manual fromJson (no build_runner).
// Mirrors backend StudentSkillVerification DTOs.
// NOTE: This is distinct from student_verification_models.dart which handles
//       email/OTP-based student identity verification.

import '../../core/utils/date_time_helper.dart';

// ── StudentSkillVerificationStatus ─────────────────────────────────────────

enum StudentSkillVerificationStatus {
  pending,
  approved,
  rejected;

  static StudentSkillVerificationStatus fromString(String? value) {
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
        return 'Đang chờ duyệt';
      case approved:
        return 'Đã được duyệt';
      case rejected:
        return 'Bị từ chối';
    }
  }
}

// ── EvidenceItem (request nested) ──────────────────────────────────────────

class SkillEvidenceItem {
  final String evidenceType; // CERTIFICATE, GITHUB, PORTFOLIO_LINK, WORK_EXPERIENCE
  final String? evidenceUrl;
  final String? description;

  const SkillEvidenceItem({
    required this.evidenceType,
    this.evidenceUrl,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'evidenceType': evidenceType,
        if (evidenceUrl != null) 'evidenceUrl': evidenceUrl,
        if (description != null) 'description': description,
      };
}

// ── CreateStudentVerificationRequest ───────────────────────────────────────

class CreateStudentSkillVerificationRequest {
  final String skillName;
  final String? githubUrl;
  final String? portfolioUrl;
  final String? additionalNotes;
  final List<int> certificateIds;
  final List<SkillEvidenceItem> evidences;

  const CreateStudentSkillVerificationRequest({
    required this.skillName,
    this.githubUrl,
    this.portfolioUrl,
    this.additionalNotes,
    this.certificateIds = const [],
    this.evidences = const [],
  });

  Map<String, dynamic> toJson() => {
        'skillName': skillName,
        if (githubUrl != null && githubUrl!.isNotEmpty) 'githubUrl': githubUrl,
        if (portfolioUrl != null && portfolioUrl!.isNotEmpty)
          'portfolioUrl': portfolioUrl,
        if (additionalNotes != null && additionalNotes!.isNotEmpty)
          'additionalNotes': additionalNotes,
        'certificateIds': certificateIds,
        'evidences': evidences.map((e) => e.toJson()).toList(),
      };
}

// ── EvidenceResponse (response nested) ─────────────────────────────────────

class SkillEvidenceResponse {
  final int id;
  final String? evidenceType;
  final String? evidenceUrl;
  final String? description;
  final int? certificateId;
  final String? certificateTitle;
  final String? certificateImageUrl;
  final String? issuingOrganization;

  const SkillEvidenceResponse({
    required this.id,
    this.evidenceType,
    this.evidenceUrl,
    this.description,
    this.certificateId,
    this.certificateTitle,
    this.certificateImageUrl,
    this.issuingOrganization,
  });

  factory SkillEvidenceResponse.fromJson(Map<String, dynamic> json) {
    return SkillEvidenceResponse(
      id: (json['id'] as num).toInt(),
      evidenceType: json['evidenceType'] as String?,
      evidenceUrl: json['evidenceUrl'] as String?,
      description: json['description'] as String?,
      certificateId: (json['certificateId'] as num?)?.toInt(),
      certificateTitle: json['certificateTitle'] as String?,
      certificateImageUrl: json['certificateImageUrl'] as String?,
      issuingOrganization: json['issuingOrganization'] as String?,
    );
  }
}

// ── StudentSkillVerificationResponse ───────────────────────────────────────

class StudentSkillVerificationResponse {
  final int id;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;

  final String skillName;
  final StudentSkillVerificationStatus status;

  final String? githubUrl;
  final String? portfolioUrl;
  final String? additionalNotes;

  final String? reviewNote;
  final int? reviewedById;
  final String? reviewedByName;

  final DateTime? requestedAt;
  final DateTime? reviewedAt;

  final List<SkillEvidenceResponse> evidences;

  const StudentSkillVerificationResponse({
    required this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    required this.skillName,
    required this.status,
    this.githubUrl,
    this.portfolioUrl,
    this.additionalNotes,
    this.reviewNote,
    this.reviewedById,
    this.reviewedByName,
    this.requestedAt,
    this.reviewedAt,
    this.evidences = const [],
  });

  factory StudentSkillVerificationResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentSkillVerificationResponse(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      skillName: json['skillName'] as String? ?? '',
      status: StudentSkillVerificationStatus.fromString(
        json['status'] as String?,
      ),
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
      reviewNote: json['reviewNote'] as String?,
      reviewedById: (json['reviewedById'] as num?)?.toInt(),
      reviewedByName: json['reviewedByName'] as String?,
      requestedAt: DateTimeHelper.tryParseIso8601(
        json['requestedAt'] as String?,
      )?.toLocal(),
      reviewedAt: DateTimeHelper.tryParseIso8601(
        json['reviewedAt'] as String?,
      )?.toLocal(),
      evidences: (json['evidences'] as List<dynamic>?)
              ?.map(
                (e) =>
                    SkillEvidenceResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
