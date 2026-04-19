// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorDto _$AuthorDtoFromJson(Map<String, dynamic> json) => AuthorDto(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  email: json['email'] as String,
  fullName: json['fullName'] as String?,
  roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  authProvider: json['authProvider'] as String?,
  googleLinked: json['googleLinked'] as bool?,
);

Map<String, dynamic> _$AuthorDtoToJson(AuthorDto instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'fullName': instance.fullName,
  'roles': instance.roles,
  'authProvider': instance.authProvider,
  'googleLinked': instance.googleLinked,
};

MediaDto _$MediaDtoFromJson(Map<String, dynamic> json) => MediaDto(
  id: (json['id'] as num).toInt(),
  url: json['url'] as String,
  type: json['type'] as String,
  fileName: json['fileName'] as String,
  fileSize: (json['fileSize'] as num?)?.toInt(),
  uploadedBy: (json['uploadedBy'] as num?)?.toInt(),
  uploadedByName: json['uploadedByName'] as String?,
  uploadedAt: json['uploadedAt'] as String?,
);

Map<String, dynamic> _$MediaDtoToJson(MediaDto instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'type': instance.type,
  'fileName': instance.fileName,
  'fileSize': instance.fileSize,
  'uploadedBy': instance.uploadedBy,
  'uploadedByName': instance.uploadedByName,
  'uploadedAt': instance.uploadedAt,
};

CourseSummaryDto _$CourseSummaryDtoFromJson(Map<String, dynamic> json) =>
    CourseSummaryDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      shortDescription: json['shortDescription'] as String?,
      category: json['category'] as String?,
      level: $enumDecode(
        _$CourseLevelEnumMap,
        json['level'],
        unknownValue: CourseLevel.beginner,
      ),
      status: $enumDecode(
        _$CourseStatusEnumMap,
        json['status'],
        unknownValue: CourseStatus.public,
      ),
      author: AuthorDto.fromJson(json['author'] as Map<String, dynamic>),
      authorName: json['authorName'] as String?,
      thumbnail: json['thumbnail'] == null
          ? null
          : MediaDto.fromJson(json['thumbnail'] as Map<String, dynamic>),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      enrollmentCount: (json['enrollmentCount'] as num).toInt(),
      moduleCount: (json['moduleCount'] as num?)?.toInt(),
      lessonCount: (json['lessonCount'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      estimatedDurationHours: (json['estimatedDurationHours'] as num?)?.toInt(),
      language: json['language'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      submittedDate: json['submittedDate'] as String?,
      publishedDate: json['publishedDate'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$CourseSummaryDtoToJson(CourseSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'shortDescription': instance.shortDescription,
      'category': instance.category,
      'level': _$CourseLevelEnumMap[instance.level]!,
      'status': _$CourseStatusEnumMap[instance.status]!,
      'author': instance.author,
      'authorName': instance.authorName,
      'thumbnail': instance.thumbnail,
      'thumbnailUrl': instance.thumbnailUrl,
      'enrollmentCount': instance.enrollmentCount,
      'moduleCount': instance.moduleCount,
      'lessonCount': instance.lessonCount,
      'price': instance.price,
      'currency': instance.currency,
      'estimatedDurationHours': instance.estimatedDurationHours,
      'language': instance.language,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'submittedDate': instance.submittedDate,
      'publishedDate': instance.publishedDate,
      'rejectionReason': instance.rejectionReason,
    };

const _$CourseLevelEnumMap = {
  CourseLevel.beginner: 'BEGINNER',
  CourseLevel.intermediate: 'INTERMEDIATE',
  CourseLevel.advanced: 'ADVANCED',
};

const _$CourseStatusEnumMap = {
  CourseStatus.draft: 'DRAFT',
  CourseStatus.pending: 'PENDING',
  CourseStatus.public: 'PUBLIC',
  CourseStatus.archived: 'ARCHIVED',
  CourseStatus.rejected: 'REJECTED',
  CourseStatus.suspended: 'SUSPENDED',
};

PageResponse<T> _$PageResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PageResponse<T>(
  content: (json['items'] as List<dynamic>?)?.map(fromJsonT).toList(),
  page: (json['page'] as num?)?.toInt() ?? 0,
  size: (json['size'] as num?)?.toInt() ?? 10,
  totalElements: (json['total'] as num?)?.toInt() ?? 0,
  totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
  first: json['first'] as bool? ?? true,
  last: json['last'] as bool? ?? true,
  empty: json['empty'] as bool? ?? true,
);

Map<String, dynamic> _$PageResponseToJson<T>(
  PageResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'items': instance.content?.map(toJsonT).toList(),
  'page': instance.page,
  'size': instance.size,
  'total': instance.totalElements,
  'totalPages': instance.totalPages,
  'first': instance.first,
  'last': instance.last,
  'empty': instance.empty,
};

CourseDetailDto _$CourseDetailDtoFromJson(Map<String, dynamic> json) =>
    CourseDetailDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      shortDescription: json['shortDescription'] as String?,
      category: json['category'] as String?,
      level: json['level'] as String?,
      status: json['status'] as String?,
      author: AuthorDto.fromJson(json['author'] as Map<String, dynamic>),
      thumbnail: json['thumbnail'] == null
          ? null
          : MediaDto.fromJson(json['thumbnail'] as Map<String, dynamic>),
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      authorName: json['authorName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      enrollmentCount: (json['enrollmentCount'] as num).toInt(),
      moduleCount: (json['moduleCount'] as num?)?.toInt(),
      lessonCount: (json['lessonCount'] as num?)?.toInt(),
      estimatedDurationHours: (json['estimatedDurationHours'] as num?)?.toInt(),
      language: json['language'] as String?,
      learningObjectives: (json['learningObjectives'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      requirements: (json['requirements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      courseSkills: (json['courseSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      submittedDate: json['submittedDate'] as String?,
      publishedDate: json['publishedDate'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      rejectedAt: json['rejectedAt'] as String?,
      suspensionReason: json['suspensionReason'] as String?,
      suspendedAt: json['suspendedAt'] as String?,
      upgradePolicy: json['upgradePolicy'] as String?,
      upgradePolicyStatusMessage: json['upgradePolicyStatusMessage'] as String?,
      modules: (json['modules'] as List<dynamic>?)
          ?.map((e) => ModuleSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseDetailDtoToJson(CourseDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'shortDescription': instance.shortDescription,
      'category': instance.category,
      'level': instance.level,
      'status': instance.status,
      'author': instance.author,
      'thumbnail': instance.thumbnail,
      'price': instance.price,
      'currency': instance.currency,
      'authorName': instance.authorName,
      'thumbnailUrl': instance.thumbnailUrl,
      'enrollmentCount': instance.enrollmentCount,
      'moduleCount': instance.moduleCount,
      'lessonCount': instance.lessonCount,
      'estimatedDurationHours': instance.estimatedDurationHours,
      'language': instance.language,
      'learningObjectives': instance.learningObjectives,
      'requirements': instance.requirements,
      'courseSkills': instance.courseSkills,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'submittedDate': instance.submittedDate,
      'publishedDate': instance.publishedDate,
      'rejectionReason': instance.rejectionReason,
      'rejectedAt': instance.rejectedAt,
      'suspensionReason': instance.suspensionReason,
      'suspendedAt': instance.suspendedAt,
      'upgradePolicy': instance.upgradePolicy,
      'upgradePolicyStatusMessage': instance.upgradePolicyStatusMessage,
      'modules': instance.modules,
    };
