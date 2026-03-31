// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollRequestDto _$EnrollRequestDtoFromJson(Map<String, dynamic> json) =>
    EnrollRequestDto(courseId: (json['courseId'] as num).toInt());

Map<String, dynamic> _$EnrollRequestDtoToJson(EnrollRequestDto instance) =>
    <String, dynamic>{'courseId': instance.courseId};

EnrollmentDetailDto _$EnrollmentDetailDtoFromJson(Map<String, dynamic> json) =>
    EnrollmentDetailDto(
      id: (json['id'] as num?)?.toInt(),
      courseId: (json['courseId'] as num).toInt(),
      courseTitle: json['courseTitle'] as String,
      courseSlug: json['courseSlug'] as String,
      userId: (json['userId'] as num).toInt(),
      status: json['status'] as String,
      progressPercent: (json['progressPercent'] as num).toInt(),
      entitlementSource: json['entitlementSource'] as String?,
      entitlementRef: json['entitlementRef'] as String?,
      learningRevisionId: (json['learningRevisionId'] as num?)?.toInt(),
      upgradePolicySnapshot: json['upgradePolicySnapshot'] as String?,
      enrolledAt: json['enrolledAt'] == null
          ? null
          : DateTime.parse(json['enrolledAt'] as String),
      lastUpgradedAt: json['lastUpgradedAt'] == null
          ? null
          : DateTime.parse(json['lastUpgradedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completed: json['completed'] as bool,
    );

Map<String, dynamic> _$EnrollmentDetailDtoToJson(
  EnrollmentDetailDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'courseTitle': instance.courseTitle,
  'courseSlug': instance.courseSlug,
  'userId': instance.userId,
  'status': instance.status,
  'progressPercent': instance.progressPercent,
  'entitlementSource': instance.entitlementSource,
  'entitlementRef': instance.entitlementRef,
  'learningRevisionId': instance.learningRevisionId,
  'upgradePolicySnapshot': instance.upgradePolicySnapshot,
  'enrolledAt': instance.enrolledAt?.toIso8601String(),
  'lastUpgradedAt': instance.lastUpgradedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'completed': instance.completed,
};

EnrollmentStatusDto _$EnrollmentStatusDtoFromJson(Map<String, dynamic> json) =>
    EnrollmentStatusDto(enrolled: json['enrolled'] as bool);

Map<String, dynamic> _$EnrollmentStatusDtoToJson(
  EnrollmentStatusDto instance,
) => <String, dynamic>{'enrolled': instance.enrolled};

EnrollmentStatsDto _$EnrollmentStatsDtoFromJson(Map<String, dynamic> json) =>
    EnrollmentStatsDto(
      totalEnrollments: (json['totalEnrollments'] as num).toInt(),
      activeEnrollments: (json['activeEnrollments'] as num).toInt(),
      completedEnrollments: (json['completedEnrollments'] as num).toInt(),
      averageProgress: (json['averageProgress'] as num).toDouble(),
      completionRate: (json['completionRate'] as num).toDouble(),
    );

Map<String, dynamic> _$EnrollmentStatsDtoToJson(EnrollmentStatsDto instance) =>
    <String, dynamic>{
      'totalEnrollments': instance.totalEnrollments,
      'activeEnrollments': instance.activeEnrollments,
      'completedEnrollments': instance.completedEnrollments,
      'averageProgress': instance.averageProgress,
      'completionRate': instance.completionRate,
    };
