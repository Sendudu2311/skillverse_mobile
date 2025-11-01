// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModuleSummaryDto _$ModuleSummaryDtoFromJson(Map<String, dynamic> json) =>
    ModuleSummaryDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
    );

Map<String, dynamic> _$ModuleSummaryDtoToJson(ModuleSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'orderIndex': instance.orderIndex,
    };

ModuleDetailDto _$ModuleDetailDtoFromJson(Map<String, dynamic> json) =>
    ModuleDetailDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((e) => LessonBriefDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ModuleDetailDtoToJson(ModuleDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'orderIndex': instance.orderIndex,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lessons': instance.lessons,
    };

ModuleProgressDto _$ModuleProgressDtoFromJson(Map<String, dynamic> json) =>
    ModuleProgressDto(
      completedLessons: (json['completedLessons'] as num).toInt(),
      totalLessons: (json['totalLessons'] as num).toInt(),
      percent: (json['percent'] as num).toInt(),
    );

Map<String, dynamic> _$ModuleProgressDtoToJson(ModuleProgressDto instance) =>
    <String, dynamic>{
      'completedLessons': instance.completedLessons,
      'totalLessons': instance.totalLessons,
      'percent': instance.percent,
    };

ModuleProgressDetailDto _$ModuleProgressDetailDtoFromJson(
  Map<String, dynamic> json,
) => ModuleProgressDetailDto(
  moduleId: (json['moduleId'] as num).toInt(),
  moduleTitle: json['moduleTitle'] as String,
  completedLessons: (json['completedLessons'] as num).toInt(),
  totalLessons: (json['totalLessons'] as num).toInt(),
  percent: (json['percent'] as num).toInt(),
);

Map<String, dynamic> _$ModuleProgressDetailDtoToJson(
  ModuleProgressDetailDto instance,
) => <String, dynamic>{
  'moduleId': instance.moduleId,
  'moduleTitle': instance.moduleTitle,
  'completedLessons': instance.completedLessons,
  'totalLessons': instance.totalLessons,
  'percent': instance.percent,
};
