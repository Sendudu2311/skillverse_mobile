// Student Verification models — manual fromJson (no build_runner).
// Mirrors backend StudentVerification DTOs.

import '../../core/utils/date_time_helper.dart';

// ── StudentVerificationStatus ───────────────────────────────────────────────

enum StudentVerificationStatus {
  emailOtpPending,
  pendingReview,
  approved,
  rejected,
  expired;

  static StudentVerificationStatus fromString(String? value) {
    switch (value) {
      case 'EMAIL_OTP_PENDING':
        return emailOtpPending;
      case 'PENDING_REVIEW':
        return pendingReview;
      case 'APPROVED':
        return approved;
      case 'REJECTED':
        return rejected;
      case 'EXPIRED':
        return expired;
      default:
        return emailOtpPending;
    }
  }

  String get displayName {
    switch (this) {
      case emailOtpPending:
        return 'Đang chờ OTP';
      case pendingReview:
        return 'Đang chờ duyệt';
      case approved:
        return 'Đã duyệt';
      case rejected:
        return 'Từ chối';
      case expired:
        return 'Hết hạn';
    }
  }
}

// ── StartVerificationRequest ────────────────────────────────────────────────
// Note: The backend uses multipart/form-data with schoolEmail + file,
// so this class is only used for the text field.

class StartVerificationRequest {
  final String schoolEmail;

  StartVerificationRequest({required this.schoolEmail});

  Map<String, dynamic> toJson() => {'schoolEmail': schoolEmail};
}

// ── VerifyOtpRequest ────────────────────────────────────────────────────────

class VerifyOtpRequest {
  final String otp;

  VerifyOtpRequest({required this.otp});

  Map<String, dynamic> toJson() => {'otp': otp};
}

// ── StudentVerificationStartResponse ────────────────────────────────────────

class StudentVerificationStartResponse {
  final int requestId;
  final StudentVerificationStatus status;
  final String? otpExpiresAt;
  final String? message;

  const StudentVerificationStartResponse({
    required this.requestId,
    required this.status,
    this.otpExpiresAt,
    this.message,
  });

  factory StudentVerificationStartResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentVerificationStartResponse(
      requestId: json['requestId'] as int,
      status: StudentVerificationStatus.fromString(json['status'] as String?),
      otpExpiresAt: json['otpExpiresAt'] as String?,
      message: json['message'] as String?,
    );
  }
}

// ── StudentVerificationDetailResponse ───────────────────────────────────────

class StudentVerificationDetailResponse {
  final int id;
  final int userId;
  final String? userEmail;
  final String? userFullName;
  final String? schoolEmail;
  final String? schoolDomain;
  final bool emailDomainValid;
  final StudentVerificationStatus status;
  final DateTime? otpExpiresAt;
  final DateTime? otpVerifiedAt;
  final String? imageUrl;
  final String? uploadedFileName;
  final String? uploadedContentType;
  final int? uploadedFileSize;
  final String? reviewNote;
  final String? rejectionReason;
  final int? reviewedById;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentVerificationDetailResponse({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userFullName,
    this.schoolEmail,
    this.schoolDomain,
    this.emailDomainValid = false,
    required this.status,
    this.otpExpiresAt,
    this.otpVerifiedAt,
    this.imageUrl,
    this.uploadedFileName,
    this.uploadedContentType,
    this.uploadedFileSize,
    this.reviewNote,
    this.rejectionReason,
    this.reviewedById,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentVerificationDetailResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentVerificationDetailResponse(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String?,
      userFullName: json['userFullName'] as String?,
      schoolEmail: json['schoolEmail'] as String?,
      schoolDomain: json['schoolDomain'] as String?,
      emailDomainValid: json['emailDomainValid'] as bool? ?? false,
      status: StudentVerificationStatus.fromString(json['status'] as String?),
      otpExpiresAt: DateTimeHelper.tryParseIso8601(
        json['otpExpiresAt'] as String?,
      )?.toLocal(),
      otpVerifiedAt: DateTimeHelper.tryParseIso8601(
        json['otpVerifiedAt'] as String?,
      )?.toLocal(),
      imageUrl: json['imageUrl'] as String?,
      uploadedFileName: json['uploadedFileName'] as String?,
      uploadedContentType: json['uploadedContentType'] as String?,
      uploadedFileSize: json['uploadedFileSize'] as int?,
      reviewNote: json['reviewNote'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      reviewedById: json['reviewedById'] as int?,
      reviewedAt: DateTimeHelper.tryParseIso8601(
        json['reviewedAt'] as String?,
      )?.toLocal(),
      createdAt:
          (DateTimeHelper.tryParseIso8601(json['createdAt'] as String?) ??
                  DateTime.now())
              .toLocal(),
      updatedAt:
          (DateTimeHelper.tryParseIso8601(json['updatedAt'] as String?) ??
                  DateTime.now())
              .toLocal(),
    );
  }
}

// ── StudentVerificationListItemResponse ─────────────────────────────────────

class StudentVerificationListItemResponse {
  final int id;
  final int userId;
  final String? userEmail;
  final String? userFullName;
  final String? schoolEmail;
  final StudentVerificationStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const StudentVerificationListItemResponse({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userFullName,
    this.schoolEmail,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
  });

  factory StudentVerificationListItemResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentVerificationListItemResponse(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String?,
      userFullName: json['userFullName'] as String?,
      schoolEmail: json['schoolEmail'] as String?,
      status: StudentVerificationStatus.fromString(json['status'] as String?),
      createdAt:
          (DateTimeHelper.tryParseIso8601(json['createdAt'] as String?) ??
                  DateTime.now())
              .toLocal(),
      reviewedAt: DateTimeHelper.tryParseIso8601(
        json['reviewedAt'] as String?,
      )?.toLocal(),
    );
  }
}

// ── StudentVerificationEligibilityResponse ──────────────────────────────────

class StudentVerificationEligibilityResponse {
  final bool approved;
  final bool canBuyStudentPremium;
  final String? message;
  final DateTime? lastApprovedAt;

  const StudentVerificationEligibilityResponse({
    this.approved = false,
    this.canBuyStudentPremium = false,
    this.message,
    this.lastApprovedAt,
  });

  factory StudentVerificationEligibilityResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudentVerificationEligibilityResponse(
      approved: json['approved'] as bool? ?? false,
      canBuyStudentPremium: json['canBuyStudentPremium'] as bool? ?? false,
      message: json['message'] as String?,
      lastApprovedAt: DateTimeHelper.tryParseIso8601(
        json['lastApprovedAt'] as String?,
      )?.toLocal(),
    );
  }
}
