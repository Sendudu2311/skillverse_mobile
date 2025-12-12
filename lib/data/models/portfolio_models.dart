import 'package:json_annotation/json_annotation.dart';

part 'portfolio_models.g.dart';

// ==================== Extended Profile ====================

@JsonSerializable()
class ExtendedProfileDto {
  final int? id;
  final int? userId;
  final String? slug;
  final String? bio;
  final String? headline;
  final String? location;
  final String? website;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? twitterUrl;
  final List<String>? expertiseAreas;
  final bool? isPublic;
  final String? createdAt;
  final String? updatedAt;

  ExtendedProfileDto({
    this.id,
    this.userId,
    this.slug,
    this.bio,
    this.headline,
    this.location,
    this.website,
    this.githubUrl,
    this.linkedinUrl,
    this.twitterUrl,
    this.expertiseAreas,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
  });

  factory ExtendedProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ExtendedProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ExtendedProfileDtoToJson(this);
}

@JsonSerializable()
class CreateExtendedProfileRequest {
  final String? slug;
  final String? bio;
  final String? headline;
  final String? location;
  final String? website;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? twitterUrl;
  final List<String>? expertiseAreas;
  final bool? isPublic;

  CreateExtendedProfileRequest({
    this.slug,
    this.bio,
    this.headline,
    this.location,
    this.website,
    this.githubUrl,
    this.linkedinUrl,
    this.twitterUrl,
    this.expertiseAreas,
    this.isPublic,
  });

  factory CreateExtendedProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateExtendedProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateExtendedProfileRequestToJson(this);
}

// ==================== Project ====================

@JsonSerializable()
class ProjectDto {
  final int? id;
  final int? userId;
  final String? title;
  final String? description;
  final String? technologies;
  final String? imageUrl;
  final String? projectUrl;
  final String? githubUrl;
  final String? startDate;
  final String? endDate;
  final bool? isFeatured;
  final int? displayOrder;
  final String? createdAt;
  final String? updatedAt;

  ProjectDto({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.technologies,
    this.imageUrl,
    this.projectUrl,
    this.githubUrl,
    this.startDate,
    this.endDate,
    this.isFeatured,
    this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectDtoToJson(this);
}

@JsonSerializable()
class CreateProjectRequest {
  final String title;
  final String description;
  final String? technologies;
  final String? imageUrl;
  final String? projectUrl;
  final String? githubUrl;
  final String? startDate;
  final String? endDate;
  final bool? isFeatured;

  CreateProjectRequest({
    required this.title,
    required this.description,
    this.technologies,
    this.imageUrl,
    this.projectUrl,
    this.githubUrl,
    this.startDate,
    this.endDate,
    this.isFeatured,
  });

  factory CreateProjectRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateProjectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateProjectRequestToJson(this);
}

@JsonSerializable()
class UpdateProjectRequest {
  final String? title;
  final String? description;
  final String? technologies;
  final String? imageUrl;
  final String? projectUrl;
  final String? githubUrl;
  final String? startDate;
  final String? endDate;
  final bool? isFeatured;

  UpdateProjectRequest({
    this.title,
    this.description,
    this.technologies,
    this.imageUrl,
    this.projectUrl,
    this.githubUrl,
    this.startDate,
    this.endDate,
    this.isFeatured,
  });

  factory UpdateProjectRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProjectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProjectRequestToJson(this);
}

// ==================== Certificate ====================

@JsonSerializable()
class CertificateDto {
  final int? id;
  final int? userId;
  final String? title;
  final String? issuer;
  final String? issueDate;
  final String? expiryDate;
  final String? credentialId;
  final String? credentialUrl;
  final String? imageUrl;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  CertificateDto({
    this.id,
    this.userId,
    this.title,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
    this.imageUrl,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory CertificateDto.fromJson(Map<String, dynamic> json) =>
      _$CertificateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CertificateDtoToJson(this);
}

@JsonSerializable()
class CreateCertificateRequest {
  final String title;
  final String issuer;
  final String? issueDate;
  final String? expiryDate;
  final String? credentialId;
  final String? credentialUrl;
  final String? imageUrl;
  final String? description;

  CreateCertificateRequest({
    required this.title,
    required this.issuer,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
    this.imageUrl,
    this.description,
  });

  factory CreateCertificateRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCertificateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCertificateRequestToJson(this);
}

// ==================== CV ====================

@JsonSerializable()
class CVDto {
  final int? id;
  final int? userId;
  final String? templateName;
  final String? cvData;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  CVDto({
    this.id,
    this.userId,
    this.templateName,
    this.cvData,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory CVDto.fromJson(Map<String, dynamic> json) => _$CVDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CVDtoToJson(this);
}

@JsonSerializable()
class GenerateCVRequest {
  final String? templateName;
  final Map<String, dynamic>? customData;

  GenerateCVRequest({
    this.templateName,
    this.customData,
  });

  factory GenerateCVRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateCVRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateCVRequestToJson(this);
}

@JsonSerializable()
class UpdateCVRequest {
  final String? templateName;
  final Map<String, dynamic>? cvData;

  UpdateCVRequest({
    this.templateName,
    this.cvData,
  });

  factory UpdateCVRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateCVRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCVRequestToJson(this);
}

// ==================== Review ====================

@JsonSerializable()
class ReviewDto {
  final int? id;
  final int? reviewerId;
  final int? revieweeId;
  final int? rating;
  final String? comment;
  final String? reviewerName;
  final String? reviewerAvatarUrl;
  final String? createdAt;

  ReviewDto({
    this.id,
    this.reviewerId,
    this.revieweeId,
    this.rating,
    this.comment,
    this.reviewerName,
    this.reviewerAvatarUrl,
    this.createdAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewDtoToJson(this);
}

// ==================== Complete Portfolio ====================

@JsonSerializable()
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

  factory CompletePortfolioDto.fromJson(Map<String, dynamic> json) =>
      _$CompletePortfolioDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CompletePortfolioDtoToJson(this);
}

// ==================== Check Extended Profile Response ====================

@JsonSerializable()
class CheckExtendedProfileResponse {
  final bool hasExtendedProfile;
  final ExtendedProfileDto? profile;

  CheckExtendedProfileResponse({
    required this.hasExtendedProfile,
    this.profile,
  });

  factory CheckExtendedProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckExtendedProfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckExtendedProfileResponseToJson(this);
}
