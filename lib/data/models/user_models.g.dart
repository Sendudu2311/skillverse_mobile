// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseRegistrationRequest _$BaseRegistrationRequestFromJson(
  Map<String, dynamic> json,
) => BaseRegistrationRequest(
  email: json['email'] as String,
  password: json['password'] as String,
  confirmPassword: json['confirmPassword'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  bio: json['bio'] as String?,
  address: json['address'] as String?,
  region: json['region'] as String?,
);

Map<String, dynamic> _$BaseRegistrationRequestToJson(
  BaseRegistrationRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'confirmPassword': instance.confirmPassword,
  'fullName': instance.fullName,
  'phone': instance.phone,
  'bio': instance.bio,
  'address': instance.address,
  'region': instance.region,
};

UserRegistrationRequest _$UserRegistrationRequestFromJson(
  Map<String, dynamic> json,
) => UserRegistrationRequest(
  email: json['email'] as String,
  password: json['password'] as String,
  confirmPassword: json['confirmPassword'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  bio: json['bio'] as String?,
  address: json['address'] as String?,
  region: json['region'] as String?,
  socialLinks: json['socialLinks'] as String?,
  birthday: json['birthday'] as String?,
  gender: json['gender'] as String?,
  provinceCode: json['provinceCode'] as String?,
  districtCode: json['districtCode'] as String?,
);

Map<String, dynamic> _$UserRegistrationRequestToJson(
  UserRegistrationRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'confirmPassword': instance.confirmPassword,
  'fullName': instance.fullName,
  'phone': instance.phone,
  'bio': instance.bio,
  'address': instance.address,
  'region': instance.region,
  'socialLinks': instance.socialLinks,
  'birthday': instance.birthday,
  'gender': instance.gender,
  'provinceCode': instance.provinceCode,
  'districtCode': instance.districtCode,
};

BaseRegistrationResponse _$BaseRegistrationResponseFromJson(
  Map<String, dynamic> json,
) => BaseRegistrationResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  email: json['email'] as String,
  userId: (json['userId'] as num).toInt(),
  requiresVerification: json['requiresVerification'] as bool,
  otpExpiryMinutes: (json['otpExpiryMinutes'] as num).toInt(),
  nextStep: json['nextStep'] as String,
);

Map<String, dynamic> _$BaseRegistrationResponseToJson(
  BaseRegistrationResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'email': instance.email,
  'userId': instance.userId,
  'requiresVerification': instance.requiresVerification,
  'otpExpiryMinutes': instance.otpExpiryMinutes,
  'nextStep': instance.nextStep,
};

UserProfileResponse _$UserProfileResponseFromJson(Map<String, dynamic> json) =>
    UserProfileResponse(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      address: json['address'] as String?,
      region: json['region'] as String?,
      socialLinks: json['socialLinks'] as String?,
      birthday: json['birthday'] as String?,
      gender: json['gender'] as String?,
      province: json['province'] as String?,
      district: json['district'] as String?,
      isActive: json['isActive'] as bool,
      emailVerified: json['emailVerified'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$UserProfileResponseToJson(
  UserProfileResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'phone': instance.phone,
  'bio': instance.bio,
  'address': instance.address,
  'region': instance.region,
  'socialLinks': instance.socialLinks,
  'birthday': instance.birthday,
  'gender': instance.gender,
  'province': instance.province,
  'district': instance.district,
  'isActive': instance.isActive,
  'emailVerified': instance.emailVerified,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

UserSkillResponse _$UserSkillResponseFromJson(Map<String, dynamic> json) =>
    UserSkillResponse(
      id: (json['id'] as num).toInt(),
      skillName: json['skillName'] as String,
      proficiencyLevel: json['proficiencyLevel'] as String,
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
      description: json['description'] as String?,
      certifications: (json['certifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserSkillResponseToJson(UserSkillResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'skillName': instance.skillName,
      'proficiencyLevel': instance.proficiencyLevel,
      'yearsOfExperience': instance.yearsOfExperience,
      'description': instance.description,
      'certifications': instance.certifications,
    };

Province _$ProvinceFromJson(Map<String, dynamic> json) => Province(
  code: json['code'] as String,
  name: json['name'] as String,
  codename: json['codename'] as String,
  divisionType: json['divisionType'] as String,
  phoneCode: (json['phoneCode'] as num).toInt(),
);

Map<String, dynamic> _$ProvinceToJson(Province instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'codename': instance.codename,
  'divisionType': instance.divisionType,
  'phoneCode': instance.phoneCode,
};

District _$DistrictFromJson(Map<String, dynamic> json) => District(
  code: json['code'] as String,
  name: json['name'] as String,
  codename: json['codename'] as String,
  divisionType: json['divisionType'] as String,
  shortCodename: json['shortCodename'] as String,
  provinceCode: json['provinceCode'] as String,
);

Map<String, dynamic> _$DistrictToJson(District instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'codename': instance.codename,
  'divisionType': instance.divisionType,
  'shortCodename': instance.shortCodename,
  'provinceCode': instance.provinceCode,
};

MentorRegistrationRequest _$MentorRegistrationRequestFromJson(
  Map<String, dynamic> json,
) => MentorRegistrationRequest(
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  linkedinProfile: json['linkedinProfile'] as String,
  mainExpertise: json['mainExpertise'] as String,
  yearsOfExperience: (json['yearsOfExperience'] as num).toInt(),
  personalBio: json['personalBio'] as String,
  password: json['password'] as String,
  confirmPassword: json['confirmPassword'] as String,
);

Map<String, dynamic> _$MentorRegistrationRequestToJson(
  MentorRegistrationRequest instance,
) => <String, dynamic>{
  'fullName': instance.fullName,
  'email': instance.email,
  'linkedinProfile': instance.linkedinProfile,
  'mainExpertise': instance.mainExpertise,
  'yearsOfExperience': instance.yearsOfExperience,
  'personalBio': instance.personalBio,
  'password': instance.password,
  'confirmPassword': instance.confirmPassword,
};

MentorRegistrationResponse _$MentorRegistrationResponseFromJson(
  Map<String, dynamic> json,
) => MentorRegistrationResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  email: json['email'] as String,
  userId: (json['userId'] as num).toInt(),
  requiresVerification: json['requiresVerification'] as bool,
  otpExpiryMinutes: (json['otpExpiryMinutes'] as num).toInt(),
  nextStep: json['nextStep'] as String,
  mentorId: (json['mentorId'] as num).toInt(),
  applicationStatus: json['applicationStatus'] as String,
);

Map<String, dynamic> _$MentorRegistrationResponseToJson(
  MentorRegistrationResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'email': instance.email,
  'userId': instance.userId,
  'requiresVerification': instance.requiresVerification,
  'otpExpiryMinutes': instance.otpExpiryMinutes,
  'nextStep': instance.nextStep,
  'mentorId': instance.mentorId,
  'applicationStatus': instance.applicationStatus,
};

BusinessRegistrationRequest _$BusinessRegistrationRequestFromJson(
  Map<String, dynamic> json,
) => BusinessRegistrationRequest(
  companyName: json['companyName'] as String,
  businessEmail: json['businessEmail'] as String,
  companyWebsite: json['companyWebsite'] as String,
  businessAddress: json['businessAddress'] as String,
  taxId: json['taxId'] as String,
  password: json['password'] as String,
  confirmPassword: json['confirmPassword'] as String,
);

Map<String, dynamic> _$BusinessRegistrationRequestToJson(
  BusinessRegistrationRequest instance,
) => <String, dynamic>{
  'companyName': instance.companyName,
  'businessEmail': instance.businessEmail,
  'companyWebsite': instance.companyWebsite,
  'businessAddress': instance.businessAddress,
  'taxId': instance.taxId,
  'password': instance.password,
  'confirmPassword': instance.confirmPassword,
};

BusinessRegistrationResponse _$BusinessRegistrationResponseFromJson(
  Map<String, dynamic> json,
) => BusinessRegistrationResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  email: json['email'] as String,
  userId: (json['userId'] as num).toInt(),
  requiresVerification: json['requiresVerification'] as bool,
  otpExpiryMinutes: (json['otpExpiryMinutes'] as num).toInt(),
  nextStep: json['nextStep'] as String,
  businessId: (json['businessId'] as num).toInt(),
  applicationStatus: json['applicationStatus'] as String,
);

Map<String, dynamic> _$BusinessRegistrationResponseToJson(
  BusinessRegistrationResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'email': instance.email,
  'userId': instance.userId,
  'requiresVerification': instance.requiresVerification,
  'otpExpiryMinutes': instance.otpExpiryMinutes,
  'nextStep': instance.nextStep,
  'businessId': instance.businessId,
  'applicationStatus': instance.applicationStatus,
};

MentorProfileResponse _$MentorProfileResponseFromJson(
  Map<String, dynamic> json,
) => MentorProfileResponse(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  linkedinProfile: json['linkedinProfile'] as String,
  mainExpertise: json['mainExpertise'] as String,
  yearsOfExperience: (json['yearsOfExperience'] as num).toInt(),
  personalBio: json['personalBio'] as String,
  applicationStatus: json['applicationStatus'] as String,
  isActive: json['isActive'] as bool,
  emailVerified: json['emailVerified'] as bool,
  cvFileUrl: json['cvFileUrl'] as String?,
  certificationFileUrls: (json['certificationFileUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$MentorProfileResponseToJson(
  MentorProfileResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'linkedinProfile': instance.linkedinProfile,
  'mainExpertise': instance.mainExpertise,
  'yearsOfExperience': instance.yearsOfExperience,
  'personalBio': instance.personalBio,
  'applicationStatus': instance.applicationStatus,
  'isActive': instance.isActive,
  'emailVerified': instance.emailVerified,
  'cvFileUrl': instance.cvFileUrl,
  'certificationFileUrls': instance.certificationFileUrls,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

BusinessProfileResponse _$BusinessProfileResponseFromJson(
  Map<String, dynamic> json,
) => BusinessProfileResponse(
  id: (json['id'] as num).toInt(),
  companyName: json['companyName'] as String,
  businessEmail: json['businessEmail'] as String,
  companyWebsite: json['companyWebsite'] as String,
  businessAddress: json['businessAddress'] as String,
  taxId: json['taxId'] as String,
  applicationStatus: json['applicationStatus'] as String,
  isActive: json['isActive'] as bool,
  emailVerified: json['emailVerified'] as bool,
  documentFileUrls: (json['documentFileUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$BusinessProfileResponseToJson(
  BusinessProfileResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'companyName': instance.companyName,
  'businessEmail': instance.businessEmail,
  'companyWebsite': instance.companyWebsite,
  'businessAddress': instance.businessAddress,
  'taxId': instance.taxId,
  'applicationStatus': instance.applicationStatus,
  'isActive': instance.isActive,
  'emailVerified': instance.emailVerified,
  'documentFileUrls': instance.documentFileUrls,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

ApplicationStatusResponse _$ApplicationStatusResponseFromJson(
  Map<String, dynamic> json,
) => ApplicationStatusResponse(
  applicationStatus: json['applicationStatus'] as String,
  statusMessage: json['statusMessage'] as String,
  submittedAt: json['submittedAt'] as String,
  reviewedAt: json['reviewedAt'] as String?,
  reviewerComments: json['reviewerComments'] as String?,
);

Map<String, dynamic> _$ApplicationStatusResponseToJson(
  ApplicationStatusResponse instance,
) => <String, dynamic>{
  'applicationStatus': instance.applicationStatus,
  'statusMessage': instance.statusMessage,
  'submittedAt': instance.submittedAt,
  'reviewedAt': instance.reviewedAt,
  'reviewerComments': instance.reviewerComments,
};
