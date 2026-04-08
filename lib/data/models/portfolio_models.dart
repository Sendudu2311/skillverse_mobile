import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'portfolio_models.g.dart';

// ==================== ENUMS ====================

enum ProjectType {
  @JsonValue('MICRO_JOB')
  microJob,
  @JsonValue('FREELANCE')
  freelance,
  @JsonValue('PERSONAL')
  personal,
  @JsonValue('ACADEMIC')
  academic,
  @JsonValue('OPEN_SOURCE')
  openSource,
  @JsonValue('INTERNSHIP')
  internship,
  @JsonValue('FULL_TIME')
  fullTime,
}

enum CertificateCategory {
  @JsonValue('TECHNICAL')
  technical,
  @JsonValue('DESIGN')
  design,
  @JsonValue('BUSINESS')
  business,
  @JsonValue('SOFT_SKILLS')
  softSkills,
  @JsonValue('LANGUAGE')
  language,
  @JsonValue('OTHER')
  other,
}

// ==================== EXTENDED PROFILE ====================
// Maps to backend UserProfileDTO
// Backward-compat getters allow old UI code to still compile.

@JsonSerializable()
class ExtendedProfileDto {
  final int? userId;

  // Basic profile fields
  final String? fullName;
  final String? basicBio;
  final String? phone;
  final String? address;
  final String? region;
  final String? basicAvatarUrl;

  // Extended portfolio info
  final String? professionalTitle;
  final String? careerGoals;
  final int? yearsOfExperience;

  // Portfolio media
  final String? portfolioAvatarUrl;
  final String? videoIntroUrl;
  final String? coverImageUrl;

  // Professional links
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioWebsiteUrl;
  final String? behanceUrl;
  final String? dribbbleUrl;

  // Additional info
  final String? tagline;
  final String? location;
  final String? availabilityStatus;
  final double? hourlyRate;
  final String? preferredCurrency;

  // topSkills is a JSON array string e.g. '["Java","React"]'
  final String? topSkills;
  final String? languagesSpoken;

  @JsonKey(name: 'isPublic')
  final bool? isPublic;
  final bool? showContactInfo;
  final bool? allowJobOffers;

  // Stats
  final int? portfolioViews;
  final int? totalProjects;
  final int? totalCertificates;

  // SEO
  final String? customUrlSlug;
  final String? metaDescription;

  final String? createdAt;
  final String? updatedAt;

  ExtendedProfileDto({
    this.userId,
    this.fullName,
    this.basicBio,
    this.phone,
    this.address,
    this.region,
    this.basicAvatarUrl,
    this.professionalTitle,
    this.careerGoals,
    this.yearsOfExperience,
    this.portfolioAvatarUrl,
    this.videoIntroUrl,
    this.coverImageUrl,
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioWebsiteUrl,
    this.behanceUrl,
    this.dribbbleUrl,
    this.tagline,
    this.location,
    this.availabilityStatus,
    this.hourlyRate,
    this.preferredCurrency,
    this.topSkills,
    this.languagesSpoken,
    this.isPublic,
    this.showContactInfo,
    this.allowJobOffers,
    this.portfolioViews,
    this.totalProjects,
    this.totalCertificates,
    this.customUrlSlug,
    this.metaDescription,
    this.createdAt,
    this.updatedAt,
  });

  factory ExtendedProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ExtendedProfileDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ExtendedProfileDtoToJson(this);

  // ---- Backward-compatible getters for existing UI pages ----
  /// professionalTitle → headline
  String? get headline => professionalTitle;

  /// customUrlSlug → slug
  String? get slug => customUrlSlug;

  /// basicBio ?? careerGoals → bio
  String? get bio => basicBio ?? careerGoals;

  /// portfolioWebsiteUrl → website
  String? get website => portfolioWebsiteUrl;

  /// twitter: not in new backend, returns null
  String? get twitterUrl => null;

  /// topSkills JSON string parsed to List<String> → expertiseAreas
  List<String>? get expertiseAreas {
    if (topSkills == null || topSkills!.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(topSkills!);
      if (decoded is List) {
        final result = decoded.map((e) => e.toString()).toList();
        return result.isEmpty ? null : result;
      }
    } catch (_) {}
    return null;
  }

  String get displayName => fullName ?? 'Người dùng';
  String get avatarUrl => portfolioAvatarUrl ?? basicAvatarUrl ?? '';
}

// Request DTO for create/update extended profile.
// Field names here match backend UserProfileDTO (sent as JSON part of multipart).
@JsonSerializable()
class CreateExtendedProfileRequest {
  // Backend field: customUrlSlug
  final String? customUrlSlug;
  // Backend field: professionalTitle
  final String? professionalTitle;
  // Backend field: basicBio
  final String? basicBio;
  // Backend field: careerGoals
  final String? careerGoals;
  // Backend field: location
  final String? location;
  // Backend field: portfolioWebsiteUrl
  final String? portfolioWebsiteUrl;
  // Backend field: githubUrl
  final String? githubUrl;
  // Backend field: linkedinUrl
  final String? linkedinUrl;
  // Backend field: behanceUrl
  final String? behanceUrl;
  // Backend field: dribbbleUrl
  final String? dribbbleUrl;
  // Backend field: topSkills (JSON string)
  final String? topSkills;
  @JsonKey(name: 'isPublic')
  final bool? isPublic;
  final bool? allowJobOffers;

  CreateExtendedProfileRequest({
    this.customUrlSlug,
    this.professionalTitle,
    this.basicBio,
    this.careerGoals,
    this.location,
    this.portfolioWebsiteUrl,
    this.githubUrl,
    this.linkedinUrl,
    this.behanceUrl,
    this.dribbbleUrl,
    this.topSkills,
    this.isPublic,
    this.allowJobOffers,
  });

  /// Factory that accepts OLD field names from existing UI pages.
  factory CreateExtendedProfileRequest.fromOldFields({
    String? slug,
    String? headline,
    String? bio,
    String? location,
    String? website,
    String? githubUrl,
    String? linkedinUrl,
    String? behanceUrl,
    String? dribbbleUrl,
    List<String>? expertiseAreas,
    bool? isPublic,
  }) {
    final topSkillsJson = expertiseAreas != null && expertiseAreas.isNotEmpty
        ? jsonEncode(expertiseAreas)
        : null;
    return CreateExtendedProfileRequest(
      customUrlSlug: slug,
      professionalTitle: headline,
      basicBio: bio,
      location: location,
      portfolioWebsiteUrl: website,
      githubUrl: githubUrl,
      linkedinUrl: linkedinUrl,
      behanceUrl: behanceUrl,
      dribbbleUrl: dribbbleUrl,
      topSkills: topSkillsJson,
      isPublic: isPublic,
    );
  }

  factory CreateExtendedProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateExtendedProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateExtendedProfileRequestToJson(this);
}

// ==================== PROJECT ====================
// Maps to backend PortfolioProjectDTO

@JsonSerializable()
class ProjectDto {
  final int? id;
  final int? userId;
  final String? title;
  final String? description;
  final String? clientName;
  @JsonKey(unknownEnumValue: ProjectType.personal)
  final ProjectType? projectType;
  final String? duration;
  final String? completionDate;
  final List<String>? tools;
  final List<String>? outcomes;
  final double? rating;
  final String? clientFeedback;
  final String? projectUrl;
  final String? githubUrl;
  final String? thumbnailUrl;
  @JsonKey(name: 'isFeatured')
  final bool? isFeatured;
  final String? createdAt;
  final String? updatedAt;

  ProjectDto({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.clientName,
    this.projectType,
    this.duration,
    this.completionDate,
    this.tools,
    this.outcomes,
    this.rating,
    this.clientFeedback,
    this.projectUrl,
    this.githubUrl,
    this.thumbnailUrl,
    this.isFeatured,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectDtoToJson(this);

  // ---- Backward-compat getters ----
  /// thumbnailUrl → imageUrl
  String? get imageUrl => thumbnailUrl;

  /// tools list → technologies string
  String? get technologies => tools?.join(', ');

  /// No startDate in backend — returns null for compat
  String? get startDate => null;

  /// completionDate → endDate
  String? get endDate => completionDate;
}

@JsonSerializable()
class CreateProjectRequest {
  final String title;
  final String description;
  final String? clientName;
  final ProjectType? projectType;
  final String? duration;
  final String? completionDate;
  final List<String>? tools;
  final List<String>? outcomes;
  final String? projectUrl;
  final String? githubUrl;
  @JsonKey(name: 'isFeatured')
  final bool? isFeatured;

  CreateProjectRequest({
    required this.title,
    required this.description,
    this.clientName,
    this.projectType,
    this.duration,
    this.completionDate,
    this.tools,
    this.outcomes,
    this.projectUrl,
    this.githubUrl,
    this.isFeatured,
  });

  /// Factory that accepts OLD field names from existing UI pages.
  factory CreateProjectRequest.fromOldFields({
    required String title,
    required String description,
    String? technologies,
    String? imageUrl,
    String? projectUrl,
    String? githubUrl,
    String? startDate,
    String? endDate,
    bool? isFeatured,
  }) {
    final toolsList = technologies != null && technologies.trim().isNotEmpty
        ? technologies
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList()
        : null;
    return CreateProjectRequest(
      title: title,
      description: description,
      tools: toolsList,
      projectUrl: projectUrl,
      githubUrl: githubUrl,
      completionDate: endDate,
      isFeatured: isFeatured,
    );
  }

  factory CreateProjectRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateProjectRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateProjectRequestToJson(this);
}

@JsonSerializable()
class UpdateProjectRequest {
  final String? title;
  final String? description;
  final String? clientName;
  final ProjectType? projectType;
  final String? duration;
  final String? completionDate;
  final List<String>? tools;
  final List<String>? outcomes;
  final String? projectUrl;
  final String? githubUrl;
  @JsonKey(name: 'isFeatured')
  final bool? isFeatured;

  UpdateProjectRequest({
    this.title,
    this.description,
    this.clientName,
    this.projectType,
    this.duration,
    this.completionDate,
    this.tools,
    this.outcomes,
    this.projectUrl,
    this.githubUrl,
    this.isFeatured,
  });

  /// Factory that accepts OLD field names from existing UI pages.
  factory UpdateProjectRequest.fromOldFields({
    String? title,
    String? description,
    String? technologies,
    String? imageUrl,
    String? projectUrl,
    String? githubUrl,
    String? startDate,
    String? endDate,
    bool? isFeatured,
  }) {
    final toolsList = technologies != null && technologies.trim().isNotEmpty
        ? technologies
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList()
        : null;
    return UpdateProjectRequest(
      title: title,
      description: description,
      tools: toolsList,
      projectUrl: projectUrl,
      githubUrl: githubUrl,
      completionDate: endDate,
      isFeatured: isFeatured,
    );
  }

  factory UpdateProjectRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProjectRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProjectRequestToJson(this);
}

// ==================== CERTIFICATE ====================
// Maps to backend ExternalCertificateDTO

@JsonSerializable()
class CertificateDto {
  final int? id;
  final int? userId;
  final String? title;
  final String? issuingOrganization;
  final String? issueDate;
  final String? expiryDate;
  final String? credentialId;
  final String? credentialUrl;
  final String? description;
  final String? certificateImageUrl;
  final List<String>? skills;
  @JsonKey(unknownEnumValue: CertificateCategory.other)
  final CertificateCategory? category;
  final bool? isVerified;
  final String? createdAt;
  final String? updatedAt;

  CertificateDto({
    this.id,
    this.userId,
    this.title,
    this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
    this.description,
    this.certificateImageUrl,
    this.skills,
    this.category,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory CertificateDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CertificateDtoToJson(this);

  // ---- Backward-compat getters ----
  /// issuingOrganization → issuer
  String? get issuer => issuingOrganization;

  /// certificateImageUrl → imageUrl
  String? get imageUrl => certificateImageUrl;
}

@JsonSerializable()
class CreateCertificateRequest {
  final String title;
  final String issuingOrganization;
  final String? issueDate;
  final String? expiryDate;
  final String? credentialId;
  final String? credentialUrl;
  final String? description;
  final List<String>? skills;
  final CertificateCategory? category;

  CreateCertificateRequest({
    required this.title,
    required this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
    this.description,
    this.skills,
    this.category,
  });

  /// Factory that accepts OLD field names from existing UI pages.
  factory CreateCertificateRequest.fromOldFields({
    required String title,
    required String issuer,
    String? issueDate,
    String? expiryDate,
    String? credentialId,
    String? credentialUrl,
    String? imageUrl,
    String? description,
  }) {
    return CreateCertificateRequest(
      title: title,
      issuingOrganization: issuer,
      issueDate: issueDate,
      expiryDate: expiryDate,
      credentialId: credentialId,
      credentialUrl: credentialUrl,
      description: description,
    );
  }

  factory CreateCertificateRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCertificateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCertificateRequestToJson(this);
}

// ==================== REVIEW ====================
// Maps to backend MentorReviewDTO

@JsonSerializable()
class ReviewDto {
  final int? id;
  final int? userId;
  final int? mentorId;
  final String? mentorName;
  final String? mentorTitle;
  final String? mentorAvatarUrl;
  final String? feedback;
  final String? skillEndorsed;
  final double? rating;
  final bool? isVerified;
  @JsonKey(name: 'isPublic')
  final bool? isPublic;
  final String? createdAt;
  final String? updatedAt;

  ReviewDto({
    this.id,
    this.userId,
    this.mentorId,
    this.mentorName,
    this.mentorTitle,
    this.mentorAvatarUrl,
    this.feedback,
    this.skillEndorsed,
    this.rating,
    this.isVerified,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewDtoToJson(this);

  // ---- Backward-compat getters ----
  String? get reviewerAvatarUrl => mentorAvatarUrl;
  String? get reviewerName => mentorName;
  String? get comment => feedback;
}

// ==================== CV ====================
// Maps to backend GeneratedCVDTO

@JsonSerializable()
class CVDto {
  final int? id;
  final int? userId;
  final String? cvContent;
  final String? cvJson;
  final String? templateName;
  @JsonKey(name: 'isActive')
  final bool? isActive;
  final int? version;
  final bool? generatedByAi;
  final String? pdfUrl;
  final String? createdAt;
  final String? updatedAt;

  CVDto({
    this.id,
    this.userId,
    this.cvContent,
    this.cvJson,
    this.templateName,
    this.isActive,
    this.version,
    this.generatedByAi,
    this.pdfUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory CVDto.fromJson(Map<String, dynamic> json) => _$CVDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CVDtoToJson(this);

  CVDto copyWith({
    int? id,
    int? userId,
    String? cvContent,
    String? cvJson,
    String? templateName,
    bool? isActive,
    int? version,
    bool? generatedByAi,
    String? pdfUrl,
    String? createdAt,
    String? updatedAt,
  }) {
    return CVDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cvContent: cvContent ?? this.cvContent,
      cvJson: cvJson ?? this.cvJson,
      templateName: templateName ?? this.templateName,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      generatedByAi: generatedByAi ?? this.generatedByAi,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Backward-compat
  String? get cvData => cvContent;
}

@JsonSerializable()
class GenerateCVRequest {
  final String? templateName;
  final String? targetRole;
  final String? targetIndustry;
  final String? additionalInstructions;
  final bool? includeProjects;
  final bool? includeCertificates;
  final bool? includeReviews;

  GenerateCVRequest({
    this.templateName,
    this.targetRole,
    this.targetIndustry,
    this.additionalInstructions,
    this.includeProjects,
    this.includeCertificates,
    this.includeReviews,
  });

  factory GenerateCVRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateCVRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateCVRequestToJson(this);
}

@JsonSerializable()
class UpdateCVRequest {
  final String? cvContent;
  final String? cvJson;

  UpdateCVRequest({this.cvContent, this.cvJson});

  factory UpdateCVRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateCVRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateCVRequestToJson(this);
}

// ==================== COMPOSITE / PROVIDER STATE ====================
// Not from backend — used internally by PortfolioProvider.

class CompletePortfolioDto {
  final ExtendedProfileDto? extendedProfile;
  final List<ProjectDto>? projects;
  final List<CertificateDto>? certificates;
  final List<ReviewDto>? reviews;
  final CVDto? activeCV;

  CompletePortfolioDto({
    this.extendedProfile,
    this.projects,
    this.certificates,
    this.reviews,
    this.activeCV,
  });
}

// ==================== CHECK PROFILE RESPONSE ====================

class CheckExtendedProfileResponse {
  final bool hasExtendedProfile;
  final ExtendedProfileDto? profile;

  CheckExtendedProfileResponse({
    required this.hasExtendedProfile,
    this.profile,
  });

  factory CheckExtendedProfileResponse.fromJson(Map<String, dynamic> json) {
    return CheckExtendedProfileResponse(
      hasExtendedProfile: json['hasExtendedProfile'] as bool? ?? false,
    );
  }
}

// ==================== SYSTEM CERTIFICATE (Auto-Import) ====================
// Maps to backend SystemCertificateDTO

class SystemCertificateDto {
  final int? id;

  /// "COURSE" | "BADGE"
  final String? source;
  final String? title;
  final String? issuer;
  final String? issueDate;
  final String? credentialId;
  final String? credentialUrl;
  final String? category;
  final List<String>? skills;
  final String? imageUrl;

  /// Only for BADGE source
  final String? badgeKey;

  /// Only for BADGE source: common/rare/epic/legendary
  final String? badgeRarity;

  /// Whether this has been imported into external_certificates
  final bool imported;

  SystemCertificateDto({
    this.id,
    this.source,
    this.title,
    this.issuer,
    this.issueDate,
    this.credentialId,
    this.credentialUrl,
    this.category,
    this.skills,
    this.imageUrl,
    this.badgeKey,
    this.badgeRarity,
    this.imported = false,
  });

  factory SystemCertificateDto.fromJson(Map<String, dynamic> json) {
    return SystemCertificateDto(
      id: json['id'] as int?,
      source: json['source'] as String?,
      title: json['title'] as String?,
      issuer: json['issuer'] as String?,
      issueDate: json['issueDate'] as String?,
      credentialId: json['credentialId'] as String?,
      credentialUrl: json['credentialUrl'] as String?,
      category: json['category'] as String?,
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      badgeKey: json['badgeKey'] as String?,
      badgeRarity: json['badgeRarity'] as String?,
      imported: json['imported'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'title': title,
    'issuer': issuer,
    'issueDate': issueDate,
    'credentialId': credentialId,
    'credentialUrl': credentialUrl,
    'category': category,
    'skills': skills,
    'imageUrl': imageUrl,
    'badgeKey': badgeKey,
    'badgeRarity': badgeRarity,
    'imported': imported,
  };

  /// Backward-compat: issuer → issuingOrganization
  String? get issuingOrganization => issuer;
}

// ==================== COMPLETED MISSION (Short-Term Jobs) ====================
// Maps to backend CompletedMissionDTO

class DeliverableInfoDto {
  final String? fileName;
  final String? fileUrl;
  final String? type;

  DeliverableInfoDto({this.fileName, this.fileUrl, this.type});

  factory DeliverableInfoDto.fromJson(Map<String, dynamic> json) {
    return DeliverableInfoDto(
      fileName: json['fileName'] as String?,
      fileUrl: json['fileUrl'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileUrl': fileUrl,
    'type': type,
  };
}

class CompletedMissionDto {
  final int? applicationId;
  final int? jobId;
  final String? jobTitle;
  final String? jobDescription;
  final String? recruiterName;
  final String? recruiterAvatar;
  final String? recruiterCompanyName;
  final double? budget;
  final String? currency;
  final String? deadline;
  final String? estimatedDuration;
  final bool? isRemote;
  final String? location;
  final List<String>? requiredSkills;
  final String? paymentMethod;
  final String? completedAt;
  final double? rating;
  final String? reviewComment;
  final int? communicationRating;
  final int? qualityRating;
  final int? timelinessRating;
  final int? professionalismRating;
  final List<DeliverableInfoDto>? deliverables;

  /// "COMPLETED" | "PAID"
  final String? status;
  final String? workNote;

  CompletedMissionDto({
    this.applicationId,
    this.jobId,
    this.jobTitle,
    this.jobDescription,
    this.recruiterName,
    this.recruiterAvatar,
    this.recruiterCompanyName,
    this.budget,
    this.currency,
    this.deadline,
    this.estimatedDuration,
    this.isRemote,
    this.location,
    this.requiredSkills,
    this.paymentMethod,
    this.completedAt,
    this.rating,
    this.reviewComment,
    this.communicationRating,
    this.qualityRating,
    this.timelinessRating,
    this.professionalismRating,
    this.deliverables,
    this.status,
    this.workNote,
  });

  factory CompletedMissionDto.fromJson(Map<String, dynamic> json) {
    return CompletedMissionDto(
      applicationId: json['applicationId'] as int?,
      jobId: json['jobId'] as int?,
      jobTitle: json['jobTitle'] as String?,
      jobDescription: json['jobDescription'] as String?,
      recruiterName: json['recruiterName'] as String?,
      recruiterAvatar: json['recruiterAvatar'] as String?,
      recruiterCompanyName: json['recruiterCompanyName'] as String?,
      budget: (json['budget'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      deadline: json['deadline'] as String?,
      estimatedDuration: json['estimatedDuration'] as String?,
      isRemote: json['isRemote'] as bool?,
      location: json['location'] as String?,
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      paymentMethod: json['paymentMethod'] as String?,
      completedAt: json['completedAt'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewComment: json['reviewComment'] as String?,
      communicationRating: json['communicationRating'] as int?,
      qualityRating: json['qualityRating'] as int?,
      timelinessRating: json['timelinessRating'] as int?,
      professionalismRating: json['professionalismRating'] as int?,
      deliverables: (json['deliverables'] as List<dynamic>?)
          ?.map((e) => DeliverableInfoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      workNote: json['workNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'applicationId': applicationId,
    'jobId': jobId,
    'jobTitle': jobTitle,
    'jobDescription': jobDescription,
    'recruiterName': recruiterName,
    'recruiterAvatar': recruiterAvatar,
    'recruiterCompanyName': recruiterCompanyName,
    'budget': budget,
    'currency': currency,
    'deadline': deadline,
    'estimatedDuration': estimatedDuration,
    'isRemote': isRemote,
    'location': location,
    'requiredSkills': requiredSkills,
    'paymentMethod': paymentMethod,
    'completedAt': completedAt,
    'rating': rating,
    'reviewComment': reviewComment,
    'communicationRating': communicationRating,
    'qualityRating': qualityRating,
    'timelinessRating': timelinessRating,
    'professionalismRating': professionalismRating,
    'deliverables': deliverables?.map((e) => e.toJson()).toList(),
    'status': status,
    'workNote': workNote,
  };

  /// Display-friendly budget string
  String get budgetDisplay {
    if (budget == null) return '';
    final cur = currency ?? 'VND';
    return '${budget!.toStringAsFixed(0)} $cur';
  }
}
