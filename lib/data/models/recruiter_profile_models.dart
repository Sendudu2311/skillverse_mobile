/// Recruiter Profile Response — maps 1:1 with Backend RecruiterProfileResponse.
/// Used for public recruiter profile viewing by Learners.
class RecruiterProfileResponse {
  final int? userId;
  final String? email;
  final String? companyName;
  final String? companyWebsite;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyLogoUrl;
  final String? taxCodeOrBusinessRegistrationNumber;
  final String? companyDocumentsUrl;
  final String? contactPersonPhone;
  final String? contactPersonPosition;
  final String? companySize;
  final String? industry;
  final String? applicationStatus;
  final String? applicationDate;
  final String? approvalDate;
  final String? rejectionReason;
  final String? createdAt;
  final String? updatedAt;

  RecruiterProfileResponse({
    this.userId,
    this.email,
    this.companyName,
    this.companyWebsite,
    this.companyAddress,
    this.companyPhone,
    this.companyLogoUrl,
    this.taxCodeOrBusinessRegistrationNumber,
    this.companyDocumentsUrl,
    this.contactPersonPhone,
    this.contactPersonPosition,
    this.companySize,
    this.industry,
    this.applicationStatus,
    this.applicationDate,
    this.approvalDate,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory RecruiterProfileResponse.fromJson(Map<String, dynamic> json) {
    return RecruiterProfileResponse(
      userId: (json['userId'] as num?)?.toInt(),
      email: json['email'] as String?,
      companyName: json['companyName'] as String?,
      companyWebsite: json['companyWebsite'] as String?,
      companyAddress: json['companyAddress'] as String?,
      companyPhone: json['companyPhone'] as String?,
      companyLogoUrl: json['companyLogoUrl'] as String?,
      taxCodeOrBusinessRegistrationNumber:
          json['taxCodeOrBusinessRegistrationNumber'] as String?,
      companyDocumentsUrl: json['companyDocumentsUrl'] as String?,
      contactPersonPhone: json['contactPersonPhone'] as String?,
      contactPersonPosition: json['contactPersonPosition'] as String?,
      companySize: json['companySize'] as String?,
      industry: json['industry'] as String?,
      applicationStatus: json['applicationStatus'] as String?,
      applicationDate: json['applicationDate'] as String?,
      approvalDate: json['approvalDate'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  /// Whether company has been verified by admin
  bool get isVerified => applicationStatus == 'APPROVED';

  /// Display label for company ID
  String get companyIdDisplay =>
      'BIZ-${(userId ?? 0).toString().padLeft(6, '0')}';
}
