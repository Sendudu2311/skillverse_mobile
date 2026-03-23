import 'package:json_annotation/json_annotation.dart';

part 'user_models.g.dart';

// Base Registration Request
@JsonSerializable()
class BaseRegistrationRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String? phone;
  final String? bio;
  final String? address;
  final String? region;

  BaseRegistrationRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    this.phone,
    this.bio,
    this.address,
    this.region,
  });

  factory BaseRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$BaseRegistrationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BaseRegistrationRequestToJson(this);
}

// User Registration Request
@JsonSerializable()
class UserRegistrationRequest extends BaseRegistrationRequest {
  final String? socialLinks;
  final String? birthday;
  final String? gender;
  final String? provinceCode;
  final String? districtCode;

  UserRegistrationRequest({
    required super.email,
    required super.password,
    required super.confirmPassword,
    required super.fullName,
    super.phone,
    super.bio,
    super.address,
    super.region,
    this.socialLinks,
    this.birthday,
    this.gender,
    this.provinceCode,
    this.districtCode,
  });

  factory UserRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRegistrationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UserRegistrationRequestToJson(this);
}

// Base Registration Response
@JsonSerializable()
class BaseRegistrationResponse {
  final bool success;
  final String message;
  final String email;
  final int userId;
  final bool requiresVerification;
  final int otpExpiryMinutes;
  final String nextStep;

  BaseRegistrationResponse({
    required this.success,
    required this.message,
    required this.email,
    required this.userId,
    required this.requiresVerification,
    required this.otpExpiryMinutes,
    required this.nextStep,
  });

  factory BaseRegistrationResponse.fromJson(Map<String, dynamic> json) =>
      _$BaseRegistrationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BaseRegistrationResponseToJson(this);
}

// User Registration Response (alias for BaseRegistrationResponse)
typedef UserRegistrationResponse = BaseRegistrationResponse;

// User Profile Response
@JsonSerializable()
class UserProfileResponse {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? bio;
  final String? address;
  final String? region;
  final String? socialLinks;
  final String? birthday;
  final String? gender;
  final String? province;
  final String? district;
  final int? avatarMediaId;
  final String? avatarMediaUrl;
  final String? avatarPosition;
  final bool isActive;
  final bool emailVerified;
  final String createdAt;
  final String updatedAt;

  UserProfileResponse({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.bio,
    this.address,
    this.region,
    this.socialLinks,
    this.birthday,
    this.gender,
    this.province,
    this.district,
    this.avatarMediaId,
    this.avatarMediaUrl,
    this.avatarPosition,
    required this.isActive,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$UserProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileResponseToJson(this);
}

// User Skill Response
@JsonSerializable()
class UserSkillResponse {
  final int id;
  final String skillName;
  final String proficiencyLevel;
  final int? yearsOfExperience;
  final String? description;
  final List<String>? certifications;

  UserSkillResponse({
    required this.id,
    required this.skillName,
    required this.proficiencyLevel,
    this.yearsOfExperience,
    this.description,
    this.certifications,
  });

  factory UserSkillResponse.fromJson(Map<String, dynamic> json) =>
      _$UserSkillResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserSkillResponseToJson(this);
}

// Location DTOs
@JsonSerializable()
class Province {
  final String code;
  final String name;
  final String codename;
  final String divisionType;
  final int phoneCode;

  Province({
    required this.code,
    required this.name,
    required this.codename,
    required this.divisionType,
    required this.phoneCode,
  });

  factory Province.fromJson(Map<String, dynamic> json) =>
      _$ProvinceFromJson(json);
  Map<String, dynamic> toJson() => _$ProvinceToJson(this);
}

@JsonSerializable()
class District {
  final String code;
  final String name;
  final String codename;
  final String divisionType;
  final String shortCodename;
  final String provinceCode;

  District({
    required this.code,
    required this.name,
    required this.codename,
    required this.divisionType,
    required this.shortCodename,
    required this.provinceCode,
  });

  factory District.fromJson(Map<String, dynamic> json) =>
      _$DistrictFromJson(json);
  Map<String, dynamic> toJson() => _$DistrictToJson(this);
}

// Mentor Registration Request
@JsonSerializable()
class MentorRegistrationRequest {
  final String fullName;
  final String email;
  final String linkedinProfile;
  final String mainExpertise;
  final int yearsOfExperience;
  final String personalBio;
  final String password;
  final String confirmPassword;

  MentorRegistrationRequest({
    required this.fullName,
    required this.email,
    required this.linkedinProfile,
    required this.mainExpertise,
    required this.yearsOfExperience,
    required this.personalBio,
    required this.password,
    required this.confirmPassword,
  });

  factory MentorRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$MentorRegistrationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MentorRegistrationRequestToJson(this);
}

// Mentor Registration Response
@JsonSerializable()
class MentorRegistrationResponse extends BaseRegistrationResponse {
  final int mentorId;
  final String applicationStatus;

  MentorRegistrationResponse({
    required super.success,
    required super.message,
    required super.email,
    required super.userId,
    required super.requiresVerification,
    required super.otpExpiryMinutes,
    required super.nextStep,
    required this.mentorId,
    required this.applicationStatus,
  });

  factory MentorRegistrationResponse.fromJson(Map<String, dynamic> json) =>
      _$MentorRegistrationResponseFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$MentorRegistrationResponseToJson(this);
}

// Business Registration Request
@JsonSerializable()
class BusinessRegistrationRequest {
  final String companyName;
  final String businessEmail;
  final String companyWebsite;
  final String businessAddress;
  final String taxId;
  final String password;
  final String confirmPassword;

  BusinessRegistrationRequest({
    required this.companyName,
    required this.businessEmail,
    required this.companyWebsite,
    required this.businessAddress,
    required this.taxId,
    required this.password,
    required this.confirmPassword,
  });

  factory BusinessRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$BusinessRegistrationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessRegistrationRequestToJson(this);
}

// Business Registration Response
@JsonSerializable()
class BusinessRegistrationResponse extends BaseRegistrationResponse {
  final int businessId;
  final String applicationStatus;

  BusinessRegistrationResponse({
    required super.success,
    required super.message,
    required super.email,
    required super.userId,
    required super.requiresVerification,
    required super.otpExpiryMinutes,
    required super.nextStep,
    required this.businessId,
    required this.applicationStatus,
  });

  factory BusinessRegistrationResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessRegistrationResponseFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$BusinessRegistrationResponseToJson(this);
}

// Mentor Profile Response
@JsonSerializable()
class MentorProfileResponse {
  final int id;
  final String email;
  final String fullName;
  final String linkedinProfile;
  final String mainExpertise;
  final int yearsOfExperience;
  final String personalBio;
  final String applicationStatus;
  final bool isActive;
  final bool emailVerified;
  final String? cvFileUrl;
  final List<String>? certificationFileUrls;
  final String createdAt;
  final String updatedAt;

  MentorProfileResponse({
    required this.id,
    required this.email,
    required this.fullName,
    required this.linkedinProfile,
    required this.mainExpertise,
    required this.yearsOfExperience,
    required this.personalBio,
    required this.applicationStatus,
    required this.isActive,
    required this.emailVerified,
    this.cvFileUrl,
    this.certificationFileUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MentorProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$MentorProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MentorProfileResponseToJson(this);
}

// Business Profile Response
@JsonSerializable()
class BusinessProfileResponse {
  final int id;
  final String companyName;
  final String businessEmail;
  final String companyWebsite;
  final String businessAddress;
  final String taxId;
  final String applicationStatus;
  final bool isActive;
  final bool emailVerified;
  final List<String>? documentFileUrls;
  final String createdAt;
  final String updatedAt;

  BusinessProfileResponse({
    required this.id,
    required this.companyName,
    required this.businessEmail,
    required this.companyWebsite,
    required this.businessAddress,
    required this.taxId,
    required this.applicationStatus,
    required this.isActive,
    required this.emailVerified,
    this.documentFileUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessProfileResponseToJson(this);
}

// Application Status Response
@JsonSerializable()
class ApplicationStatusResponse {
  final String applicationStatus;
  final String statusMessage;
  final String submittedAt;
  final String? reviewedAt;
  final String? reviewerComments;

  ApplicationStatusResponse({
    required this.applicationStatus,
    required this.statusMessage,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerComments,
  });

  factory ApplicationStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$ApplicationStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationStatusResponseToJson(this);
}

// Public User Profile
@JsonSerializable()
class PublicUserProfile {
  final int userId;
  final String? email;
  final String? fullName;
  final int? avatarMediaId;
  final String? avatarMediaUrl;
  final String? avatarPosition;
  final String? bio;
  final String? phone;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PublicUserProfile({
    required this.userId,
    this.email,
    this.fullName,
    this.avatarMediaId,
    this.avatarMediaUrl,
    this.avatarPosition,
    this.bio,
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicUserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PublicUserProfileToJson(this);
}
