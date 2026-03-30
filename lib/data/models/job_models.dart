import 'package:json_annotation/json_annotation.dart';

part 'job_models.g.dart';

// ==================== ENUMS ====================

enum JobStatus {
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('PENDING_APPROVAL')
  pendingApproval,
  @JsonValue('OPEN')
  open,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('CLOSED')
  closed,
}

enum ShortTermJobStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('PENDING_APPROVAL')
  pendingApproval,
  @JsonValue('PUBLISHED')
  published,
  @JsonValue('APPLIED')
  applied,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('SUBMITTED')
  submitted,
  @JsonValue('UNDER_REVIEW')
  underReview,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('PAID')
  paid,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('DISPUTED')
  disputed,
  @JsonValue('ESCALATED')
  escalated,
  @JsonValue('CLOSED')
  closed,
}

enum JobApplicationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('REVIEWED')
  reviewed,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('REJECTED')
  rejected,
}

enum ShortTermApplicationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('WORKING')
  working,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('SUBMITTED')
  submitted,
  @JsonValue('SUBMITTED_OVERDUE')
  submittedOverdue,
  @JsonValue('REVISION_REQUIRED')
  revisionRequired,
  @JsonValue('REVISION_RESPONSE_OVERDUE')
  revisionResponseOverdue,
  @JsonValue('CANCELLATION_REQUESTED')
  cancellationRequested,
  @JsonValue('AUTO_CANCELLED')
  autoCancelled,
  @JsonValue('DISPUTE_OPENED')
  disputeOpened,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('PAID')
  paid,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('WITHDRAWN')
  withdrawn,
}

enum JobUrgency {
  @JsonValue('NORMAL')
  normal,
  @JsonValue('URGENT')
  urgent,
  @JsonValue('VERY_URGENT')
  veryUrgent,
  @JsonValue('ASAP')
  asap,
}

// ==================== LONG-TERM JOB ====================

@JsonSerializable()
class JobPostingResponse {
  final int? id;
  final String? title;
  final String? description;
  final List<String>? requiredSkills;
  final double? minBudget;
  final double? maxBudget;
  final String? deadline;
  @JsonKey(name: 'isRemote')
  final bool? remote;
  final String? location;
  @JsonKey(unknownEnumValue: JobStatus.open)
  final JobStatus? status;
  final int? applicantCount;

  // Enhanced fields
  final String? experienceLevel;
  final String? jobType;
  final int? hiringQuantity;
  final String? benefits;
  final String? genderRequirement;
  @JsonKey(name: 'isNegotiable')
  final bool? negotiable;
  @JsonKey(name: 'isHighlighted')
  final bool? highlighted;

  // Recruiter info
  final String? recruiterCompanyName;
  final String? recruiterEmail;
  final int? recruiterUserId;

  final String? createdAt;
  final String? updatedAt;

  JobPostingResponse({
    this.id,
    this.title,
    this.description,
    this.requiredSkills,
    this.minBudget,
    this.maxBudget,
    this.deadline,
    this.remote,
    this.location,
    this.status,
    this.applicantCount,
    this.experienceLevel,
    this.jobType,
    this.hiringQuantity,
    this.benefits,
    this.genderRequirement,
    this.negotiable,
    this.highlighted,
    this.recruiterCompanyName,
    this.recruiterEmail,
    this.recruiterUserId,
    this.createdAt,
    this.updatedAt,
  });

  factory JobPostingResponse.fromJson(Map<String, dynamic> json) =>
      _$JobPostingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$JobPostingResponseToJson(this);
}

// ==================== SHORT-TERM JOB ====================

@JsonSerializable()
class ShortTermJobResponse {
  final int? id;
  final String? title;
  final String? description;
  final List<String>? requiredSkills;

  // Pricing
  final double? budget;
  @JsonKey(name: 'isNegotiable')
  final bool? negotiable;
  final String? paymentMethod;

  // Timing
  final String? deadline;
  final String? estimatedDuration;
  @JsonKey(unknownEnumValue: JobUrgency.normal)
  final JobUrgency? urgency;
  final String? startTime;

  // Work settings
  @JsonKey(name: 'isRemote')
  final bool? remote;
  final String? location;
  @JsonKey(name: 'isHighlighted')
  final bool? highlighted;

  // Status
  @JsonKey(unknownEnumValue: ShortTermJobStatus.published)
  final ShortTermJobStatus? status;
  final int? applicantCount;
  final int? selectedApplicantId;

  // Requirements
  final int? maxApplicants;
  final double? minRating;

  // Recruiter info
  final int? recruiterId;
  final RecruiterInfo? recruiterInfo;

  // Milestones
  final List<MilestoneResponse>? milestones;

  // Timestamps
  final String? createdAt;
  final String? updatedAt;
  final String? publishedAt;
  final String? completedAt;
  final String? paidAt;

  // Computed fields
  @JsonKey(name: 'isExpired')
  final bool? expired;
  final bool? canApply;

  ShortTermJobResponse({
    this.id,
    this.title,
    this.description,
    this.requiredSkills,
    this.budget,
    this.negotiable,
    this.paymentMethod,
    this.deadline,
    this.estimatedDuration,
    this.urgency,
    this.startTime,
    this.remote,
    this.location,
    this.highlighted,
    this.status,
    this.applicantCount,
    this.selectedApplicantId,
    this.maxApplicants,
    this.minRating,
    this.recruiterId,
    this.recruiterInfo,
    this.milestones,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.completedAt,
    this.paidAt,
    this.expired,
    this.canApply,
  });

  factory ShortTermJobResponse.fromJson(Map<String, dynamic> json) =>
      _$ShortTermJobResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ShortTermJobResponseToJson(this);
}

@JsonSerializable()
class RecruiterInfo {
  final int? id;
  final String? companyName;
  final double? rating;
  final int? totalJobsPosted;
  final double? completionRate;

  RecruiterInfo({
    this.id,
    this.companyName,
    this.rating,
    this.totalJobsPosted,
    this.completionRate,
  });

  factory RecruiterInfo.fromJson(Map<String, dynamic> json) =>
      _$RecruiterInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RecruiterInfoToJson(this);
}

@JsonSerializable()
class MilestoneResponse {
  final int? id;
  final String? title;
  final String? description;
  final double? amount;
  final String? deadline;
  final String? status;
  final int? order;
  final String? completedAt;
  final List<JobDeliverableResponse>? deliverables;

  MilestoneResponse({
    this.id,
    this.title,
    this.description,
    this.amount,
    this.deadline,
    this.status,
    this.order,
    this.completedAt,
    this.deliverables,
  });

  factory MilestoneResponse.fromJson(Map<String, dynamic> json) =>
      _$MilestoneResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MilestoneResponseToJson(this);
}

@JsonSerializable()
class JobDeliverableResponse {
  final int? id;
  final String? type;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String? description;
  final String? uploadedAt;
  final int? uploadedById;
  final String? uploadedByName;

  JobDeliverableResponse({
    this.id,
    this.type,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.description,
    this.uploadedAt,
    this.uploadedById,
    this.uploadedByName,
  });

  factory JobDeliverableResponse.fromJson(Map<String, dynamic> json) =>
      _$JobDeliverableResponseFromJson(json);
  Map<String, dynamic> toJson() => _$JobDeliverableResponseToJson(this);
}

// ==================== LONG-TERM APPLICATION ====================

@JsonSerializable()
class JobApplicationResponse {
  final int? id;
  final int? jobId;
  final String? jobTitle;
  final int? userId;
  final String? userFullName;
  final String? userEmail;
  final String? coverLetter;
  final String? appliedAt;
  @JsonKey(unknownEnumValue: JobApplicationStatus.pending)
  final JobApplicationStatus? status;
  final String? acceptanceMessage;
  final String? rejectionReason;
  final String? reviewedAt;
  final String? processedAt;

  // Job details
  final String? recruiterCompanyName;
  final double? minBudget;
  final double? maxBudget;
  @JsonKey(name: 'isRemote')
  final bool? remote;
  final String? location;
  @JsonKey(name: 'isHighlighted')
  final bool? highlighted;
  final String? portfolioSlug;

  JobApplicationResponse({
    this.id,
    this.jobId,
    this.jobTitle,
    this.userId,
    this.userFullName,
    this.userEmail,
    this.coverLetter,
    this.appliedAt,
    this.status,
    this.acceptanceMessage,
    this.rejectionReason,
    this.reviewedAt,
    this.processedAt,
    this.recruiterCompanyName,
    this.minBudget,
    this.maxBudget,
    this.remote,
    this.location,
    this.highlighted,
    this.portfolioSlug,
  });

  factory JobApplicationResponse.fromJson(Map<String, dynamic> json) =>
      _$JobApplicationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$JobApplicationResponseToJson(this);
}

// ==================== SHORT-TERM APPLICATION ====================

@JsonSerializable()
class ShortTermApplicationResponse {
  final int? id;
  final int? jobId;
  final String? jobTitle;
  final double? jobBudget;

  // User info
  final int? userId;
  final String? userFullName;
  final String? userEmail;
  final String? userAvatar;
  final String? userProfessionalTitle;
  final double? userRating;
  final int? userCompletedJobs;

  // Application details
  final String? coverLetter;
  final double? proposedPrice;
  final String? proposedDuration;
  final List<String>? portfolio;
  final String? portfolioSlug;

  // Status (typed enum)
  @JsonKey(unknownEnumValue: ShortTermApplicationStatus.pending)
  final ShortTermApplicationStatus? status;

  // Timestamps
  final String? appliedAt;
  final String? acceptedAt;
  final String? startedAt;
  final String? submittedAt;
  final String? completedAt;

  // Work submission
  final List<JobDeliverableResponse>? deliverables;
  final String? workNote;

  // Revision
  final int? revisionCount;
  final int? submissionCount;
  final List<RevisionNoteResponse>? revisionNotes;

  // SLA / Cancellation / Dispute fields
  final String? reviewDeadlineAt;
  final String? responseDeadlineAt;
  final bool? disputeEligibilityUnlocked;

  // Job info
  final ShortTermAppJobInfo? jobDetails;

  ShortTermApplicationResponse({
    this.id,
    this.jobId,
    this.jobTitle,
    this.jobBudget,
    this.userId,
    this.userFullName,
    this.userEmail,
    this.userAvatar,
    this.userProfessionalTitle,
    this.userRating,
    this.userCompletedJobs,
    this.coverLetter,
    this.proposedPrice,
    this.proposedDuration,
    this.portfolio,
    this.portfolioSlug,
    this.status,
    this.appliedAt,
    this.acceptedAt,
    this.startedAt,
    this.submittedAt,
    this.completedAt,
    this.deliverables,
    this.workNote,
    this.revisionCount,
    this.submissionCount,
    this.revisionNotes,
    this.reviewDeadlineAt,
    this.responseDeadlineAt,
    this.disputeEligibilityUnlocked,
    this.jobDetails,
  });

  factory ShortTermApplicationResponse.fromJson(Map<String, dynamic> json) =>
      _$ShortTermApplicationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ShortTermApplicationResponseToJson(this);
}

@JsonSerializable()
class RevisionNoteResponse {
  final int? id;
  final String? note;
  final List<String>? specificIssues;
  final int? requestedById;
  final String? requestedByName;
  final String? requestedAt;
  final String? resolvedAt;

  RevisionNoteResponse({
    this.id,
    this.note,
    this.specificIssues,
    this.requestedById,
    this.requestedByName,
    this.requestedAt,
    this.resolvedAt,
  });

  factory RevisionNoteResponse.fromJson(Map<String, dynamic> json) =>
      _$RevisionNoteResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RevisionNoteResponseToJson(this);
}

@JsonSerializable()
class ShortTermAppJobInfo {
  final String? title;
  final double? budget;
  final String? deadline;
  final String? recruiterCompanyName;

  ShortTermAppJobInfo({
    this.title,
    this.budget,
    this.deadline,
    this.recruiterCompanyName,
  });

  factory ShortTermAppJobInfo.fromJson(Map<String, dynamic> json) =>
      _$ShortTermAppJobInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ShortTermAppJobInfoToJson(this);
}

// ==================== REQUEST DTOs ====================

@JsonSerializable()
class ApplyJobRequest {
  final String? coverLetter;

  ApplyJobRequest({this.coverLetter});

  factory ApplyJobRequest.fromJson(Map<String, dynamic> json) =>
      _$ApplyJobRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ApplyJobRequestToJson(this);
}

@JsonSerializable()
class ApplyShortTermJobRequest {
  final String? coverLetter;
  final double? proposedPrice;
  final String? proposedDuration;
  final List<String>? portfolio;

  ApplyShortTermJobRequest({
    this.coverLetter,
    this.proposedPrice,
    this.proposedDuration,
    this.portfolio,
  });

  factory ApplyShortTermJobRequest.fromJson(Map<String, dynamic> json) =>
      _$ApplyShortTermJobRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ApplyShortTermJobRequestToJson(this);
}

@JsonSerializable()
class SubmitDeliverableRequest {
  final int applicationId;
  final int? milestoneId;
  final String? workNote;
  final List<DeliverablePayload>? deliverables;
  @JsonKey(name: 'isFinalSubmission')
  final bool? finalSubmission;

  SubmitDeliverableRequest({
    required this.applicationId,
    this.milestoneId,
    this.workNote,
    this.deliverables,
    this.finalSubmission,
  });

  factory SubmitDeliverableRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitDeliverableRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SubmitDeliverableRequestToJson(this);
}

@JsonSerializable()
class DeliverablePayload {
  final String type;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String? description;

  DeliverablePayload({
    required this.type,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.description,
  });

  factory DeliverablePayload.fromJson(Map<String, dynamic> json) =>
      _$DeliverablePayloadFromJson(json);
  Map<String, dynamic> toJson() => _$DeliverablePayloadToJson(this);
}

// ==================== PAGE RESPONSE ====================

@JsonSerializable(genericArgumentFactories: true)
class JobPageResponse<T> {
  @JsonKey(name: 'content')
  final List<T>? content;
  @JsonKey(defaultValue: 0)
  final int page;
  @JsonKey(defaultValue: 10)
  final int size;
  @JsonKey(name: 'totalElements', defaultValue: 0)
  final int totalElements;
  @JsonKey(defaultValue: 1)
  final int totalPages;
  @JsonKey(defaultValue: true)
  final bool first;
  @JsonKey(defaultValue: true)
  final bool last;
  @JsonKey(defaultValue: true)
  final bool empty;

  JobPageResponse({
    this.content,
    this.page = 0,
    this.size = 10,
    this.totalElements = 0,
    this.totalPages = 1,
    this.first = true,
    this.last = true,
    this.empty = true,
  });

  factory JobPageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$JobPageResponseFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$JobPageResponseToJson(this, toJsonT);
}
