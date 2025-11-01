// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonBriefDto _$LessonBriefDtoFromJson(Map<String, dynamic> json) =>
    LessonBriefDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      type: $enumDecode(_$LessonTypeEnumMap, json['type']),
      orderIndex: (json['orderIndex'] as num).toInt(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LessonBriefDtoToJson(LessonBriefDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': _$LessonTypeEnumMap[instance.type]!,
      'orderIndex': instance.orderIndex,
      'durationSec': instance.durationSec,
    };

const _$LessonTypeEnumMap = {
  LessonType.video: 'VIDEO',
  LessonType.reading: 'READING',
  LessonType.quiz: 'QUIZ',
  LessonType.assignment: 'ASSIGNMENT',
  LessonType.codelab: 'CODELAB',
};

LessonDetailDto _$LessonDetailDtoFromJson(Map<String, dynamic> json) =>
    LessonDetailDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      type: json['type'] as String,
      orderIndex: (json['orderIndex'] as num).toInt(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      contentText: json['contentText'] as String?,
      videoUrl: json['videoUrl'] as String?,
      videoMediaId: (json['videoMediaId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LessonDetailDtoToJson(LessonDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'orderIndex': instance.orderIndex,
      'durationSec': instance.durationSec,
      'contentText': instance.contentText,
      'videoUrl': instance.videoUrl,
      'videoMediaId': instance.videoMediaId,
    };

LessonProgressDto _$LessonProgressDtoFromJson(Map<String, dynamic> json) =>
    LessonProgressDto(
      lessonId: (json['lessonId'] as num).toInt(),
      completed: json['completed'] as bool,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      watchedSeconds: (json['watchedSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LessonProgressDtoToJson(LessonProgressDto instance) =>
    <String, dynamic>{
      'lessonId': instance.lessonId,
      'completed': instance.completed,
      'completedAt': instance.completedAt?.toIso8601String(),
      'watchedSeconds': instance.watchedSeconds,
    };
