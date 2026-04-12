import 'package:json_annotation/json_annotation.dart';

part 'contract_models.g.dart';

// ==================== ENUMS ====================

enum ContractStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('PENDING_SIGNER')
  pendingSigner,
  @JsonValue('PENDING_EMPLOYER')
  pendingEmployer,
  @JsonValue('SIGNED')
  signed,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('CANCELLED')
  cancelled;

  String get label => switch (this) {
    ContractStatus.draft => 'Bản nháp',
    ContractStatus.pendingSigner => 'Chờ ứng viên ký',
    ContractStatus.pendingEmployer => 'Chờ NTD ký',
    ContractStatus.signed => 'Đã ký',
    ContractStatus.rejected => 'Bị từ chối',
    ContractStatus.cancelled => 'Đã hủy',
  };

  String get jsonValue => switch (this) {
    ContractStatus.draft => 'DRAFT',
    ContractStatus.pendingSigner => 'PENDING_SIGNER',
    ContractStatus.pendingEmployer => 'PENDING_EMPLOYER',
    ContractStatus.signed => 'SIGNED',
    ContractStatus.rejected => 'REJECTED',
    ContractStatus.cancelled => 'CANCELLED',
  };
}

enum ContractType {
  @JsonValue('PROBATION')
  probation,
  @JsonValue('FULL_TIME')
  fullTime,
  @JsonValue('PART_TIME')
  partTime;

  String get label => switch (this) {
    ContractType.probation => 'Hợp đồng thử việc',
    ContractType.fullTime => 'Hợp đồng lao động',
    ContractType.partTime => 'Hợp đồng thời vụ',
  };
}

// ==================== RESPONSE DTOs ====================

@JsonSerializable()
class ContractSignatureResponse {
  final int? id;
  final int? signedBy;
  final String? signedByName;
  final String? signedByRole;
  final String? status; // NOT_SIGNED, SIGNED, REJECTED
  final String? signatureImageUrl;
  final String? signedAt;

  ContractSignatureResponse({
    this.id,
    this.signedBy,
    this.signedByName,
    this.signedByRole,
    this.status,
    this.signatureImageUrl,
    this.signedAt,
  });

  factory ContractSignatureResponse.fromJson(Map<String, dynamic> json) =>
      _$ContractSignatureResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ContractSignatureResponseToJson(this);
}

@JsonSerializable()
class ContractResponse {
  // Contract info
  final int id;
  final int? applicationId;
  final int? jobId;
  final ContractStatus? status;
  final ContractType? contractType;
  final String? contractNumber;

  // Job content
  final String? jobTitle;
  final String? workingLocation;
  final String? candidatePosition;
  final String? jobDescription;

  // Probation
  final int? probationMonths;
  final double? probationSalary;
  final String? probationSalaryText;
  final String? probationEvaluationCriteria;
  final String? probationObjectives;

  // Compensation
  final double? salary;
  final String? salaryText;
  final int? salaryPaymentDate;
  final String? paymentMethod;
  final double? mealAllowance;
  final double? transportAllowance;
  final double? housingAllowance;
  final String? otherAllowances;
  final String? bonusPolicy;

  // Working hours & leave
  final int? workingHoursPerDay;
  final int? workingHoursPerWeek;
  final String? workingSchedule;
  final String? remoteWorkPolicy;
  final int? annualLeaveDays;
  final String? leavePolicy;

  // Benefits & insurance
  final String? insurancePolicy;
  final bool? healthCheckupAnnual;
  final String? trainingPolicy;
  final String? otherBenefits;

  // Legal clauses
  final String? legalText;
  final String? confidentialityClause;
  final String? ipClause;
  final String? nonCompeteClause;
  final int? nonCompeteDurationMonths;
  final int? terminationNoticeDays;
  final String? terminationClause;

  // Dates
  final String? startDate;
  final String? endDate;

  // Employer info
  final int? employerId;
  final String? employerName;
  final String? employerCompanyName;
  final String? employerAddress;
  final String? employerTaxId;
  final String? employerEmail;

  // Candidate info
  final int? candidateId;
  final String? candidateName;
  final String? candidateEmail;
  final String? candidatePhone;
  final String? candidateAddress;
  final String? candidateDateOfBirth;
  final String? candidateIdCardNumber;
  final String? candidateIdCardPlace;

  // Signatures
  final ContractSignatureResponse? employerSignature;
  final ContractSignatureResponse? candidateSignature;

  // PDF & signed
  final String? signedPdfUrl;
  final String? signedAt;

  // Application snapshot
  final String? applicationJobTitle;
  final int? userId;
  final String? userFullName;

  // Audit
  final int? version;
  final String? createdAt;
  final String? updatedAt;

  ContractResponse({
    required this.id,
    this.applicationId,
    this.jobId,
    this.status,
    this.contractType,
    this.contractNumber,
    this.jobTitle,
    this.workingLocation,
    this.candidatePosition,
    this.jobDescription,
    this.probationMonths,
    this.probationSalary,
    this.probationSalaryText,
    this.probationEvaluationCriteria,
    this.probationObjectives,
    this.salary,
    this.salaryText,
    this.salaryPaymentDate,
    this.paymentMethod,
    this.mealAllowance,
    this.transportAllowance,
    this.housingAllowance,
    this.otherAllowances,
    this.bonusPolicy,
    this.workingHoursPerDay,
    this.workingHoursPerWeek,
    this.workingSchedule,
    this.remoteWorkPolicy,
    this.annualLeaveDays,
    this.leavePolicy,
    this.insurancePolicy,
    this.healthCheckupAnnual,
    this.trainingPolicy,
    this.otherBenefits,
    this.legalText,
    this.confidentialityClause,
    this.ipClause,
    this.nonCompeteClause,
    this.nonCompeteDurationMonths,
    this.terminationNoticeDays,
    this.terminationClause,
    this.startDate,
    this.endDate,
    this.employerId,
    this.employerName,
    this.employerCompanyName,
    this.employerAddress,
    this.employerTaxId,
    this.employerEmail,
    this.candidateId,
    this.candidateName,
    this.candidateEmail,
    this.candidatePhone,
    this.candidateAddress,
    this.candidateDateOfBirth,
    this.candidateIdCardNumber,
    this.candidateIdCardPlace,
    this.employerSignature,
    this.candidateSignature,
    this.signedPdfUrl,
    this.signedAt,
    this.applicationJobTitle,
    this.userId,
    this.userFullName,
    this.version,
    this.createdAt,
    this.updatedAt,
  });

  factory ContractResponse.fromJson(Map<String, dynamic> json) =>
      _$ContractResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ContractResponseToJson(this);
}

// ==================== REQUEST DTOs ====================

@JsonSerializable()
class SignContractRequest {
  final String action; // "SIGN" or "REJECT"
  final String? signatureImageUrl;
  final String? rejectionReason;

  SignContractRequest({
    required this.action,
    this.signatureImageUrl,
    this.rejectionReason,
  });

  factory SignContractRequest.fromJson(Map<String, dynamic> json) =>
      _$SignContractRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SignContractRequestToJson(this);
}
