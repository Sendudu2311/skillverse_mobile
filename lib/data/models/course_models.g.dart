// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorDto _$AuthorDtoFromJson(Map<String, dynamic> json) => AuthorDto(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String?,
);

Map<String, dynamic> _$AuthorDtoToJson(AuthorDto instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'fullName': instance.fullName,
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
      description: json['description'] as String,
      shortDescription: json['shortDescription'] as String?,
      level: $enumDecode(_$CourseLevelEnumMap, json['level']),
      status: $enumDecode(_$CourseStatusEnumMap, json['status']),
      author: AuthorDto.fromJson(json['author'] as Map<String, dynamic>),
      authorName: json['authorName'] as String?,
      thumbnail: json['thumbnail'] == null
          ? null
          : MediaDto.fromJson(json['thumbnail'] as Map<String, dynamic>),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      enrollmentCount: (json['enrollmentCount'] as num).toInt(),
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$CourseSummaryDtoToJson(CourseSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'shortDescription': instance.shortDescription,
      'level': _$CourseLevelEnumMap[instance.level]!,
      'status': _$CourseStatusEnumMap[instance.status]!,
      'author': instance.author,
      'authorName': instance.authorName,
      'thumbnail': instance.thumbnail,
      'thumbnailUrl': instance.thumbnailUrl,
      'enrollmentCount': instance.enrollmentCount,
      'price': instance.price,
      'currency': instance.currency,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
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
};

PageResponse<T> _$PageResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PageResponse<T>(
  content: (json['items'] as List<dynamic>?)?.map(fromJsonT).toList() ?? [],
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
