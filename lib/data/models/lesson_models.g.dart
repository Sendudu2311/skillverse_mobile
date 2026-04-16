// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonAttachmentDto _$LessonAttachmentDtoFromJson(Map<String, dynamic> json) =>
    LessonAttachmentDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      type: $enumDecodeNullable(_$AttachmentTypeEnumMap, json['type']),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileSizeFormatted: json['fileSizeFormatted'] as String?,
      orderIndex: (json['orderIndex'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$LessonAttachmentDtoToJson(
  LessonAttachmentDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'downloadUrl': instance.downloadUrl,
  'type': _$AttachmentTypeEnumMap[instance.type],
  'fileSize': instance.fileSize,
  'fileSizeFormatted': instance.fileSizeFormatted,
  'orderIndex': instance.orderIndex,
  'createdAt': instance.createdAt,
};

const _$AttachmentTypeEnumMap = {
  AttachmentType.pdf: 'PDF',
  AttachmentType.docx: 'DOCX',
  AttachmentType.pptx: 'PPTX',
  AttachmentType.xlsx: 'XLSX',
  AttachmentType.externalLink: 'EXTERNAL_LINK',
  AttachmentType.googleDrive: 'GOOGLE_DRIVE',
  AttachmentType.github: 'GITHUB',
  AttachmentType.youtube: 'YOUTUBE',
  AttachmentType.website: 'WEBSITE',
};

LessonBriefDto _$LessonBriefDtoFromJson(Map<String, dynamic> json) =>
    LessonBriefDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      type: $enumDecodeNullable(_$LessonTypeEnumMap, json['type']),
      orderIndex: (json['orderIndex'] as num?)?.toInt(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      resourceUrl: json['resourceUrl'] as String?,
    );

Map<String, dynamic> _$LessonBriefDtoToJson(LessonBriefDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': _$LessonTypeEnumMap[instance.type],
      'orderIndex': instance.orderIndex,
      'durationSec': instance.durationSec,
      'resourceUrl': instance.resourceUrl,
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
      resourceUrl: json['resourceUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      videoMediaId: (json['videoMediaId'] as num?)?.toInt(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => LessonAttachmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LessonDetailDtoToJson(LessonDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'orderIndex': instance.orderIndex,
      'durationSec': instance.durationSec,
      'contentText': instance.contentText,
      'resourceUrl': instance.resourceUrl,
      'videoUrl': instance.videoUrl,
      'videoMediaId': instance.videoMediaId,
      'attachments': instance.attachments,
    };

ImpactedLearningItemDto _$ImpactedLearningItemDtoFromJson(
  Map<String, dynamic> json,
) => ImpactedLearningItemDto(
  itemId: (json['itemId'] as num?)?.toInt(),
  itemType: json['itemType'] as String?,
  title: json['title'] as String?,
  isBreakingChanged: json['isBreakingChanged'] as bool?,
  breakingReason: json['breakingReason'] as String?,
  reasonCode: json['reasonCode'] as String?,
  reason: json['reason'] as String?,
  sourceRevisionId: (json['sourceRevisionId'] as num?)?.toInt(),
  targetRevisionId: (json['targetRevisionId'] as num?)?.toInt(),
  requiresRetake: json['requiresRetake'] as bool?,
);

Map<String, dynamic> _$ImpactedLearningItemDtoToJson(
  ImpactedLearningItemDto instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'itemType': instance.itemType,
  'title': instance.title,
  'isBreakingChanged': instance.isBreakingChanged,
  'breakingReason': instance.breakingReason,
  'reasonCode': instance.reasonCode,
  'reason': instance.reason,
  'sourceRevisionId': instance.sourceRevisionId,
  'targetRevisionId': instance.targetRevisionId,
  'requiresRetake': instance.requiresRetake,
};

CourseLearningRevisionInfoDto _$CourseLearningRevisionInfoDtoFromJson(
  Map<String, dynamic> json,
) => CourseLearningRevisionInfoDto(
  courseId: (json['courseId'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  learningRevisionId: (json['learningRevisionId'] as num?)?.toInt(),
  activeRevisionId: (json['activeRevisionId'] as num?)?.toInt(),
  latestRevisionId: (json['latestRevisionId'] as num?)?.toInt(),
  upgradePolicy: json['upgradePolicy'] as String?,
  hasNewerRevision: json['hasNewerRevision'] as bool? ?? false,
  impactedItems: (json['impactedItems'] as List<dynamic>?)
          ?.map(
            (e) =>
                ImpactedLearningItemDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$CourseLearningRevisionInfoDtoToJson(
  CourseLearningRevisionInfoDto instance,
) => <String, dynamic>{
  'courseId': instance.courseId,
  'userId': instance.userId,
  'learningRevisionId': instance.learningRevisionId,
  'activeRevisionId': instance.activeRevisionId,
  'latestRevisionId': instance.latestRevisionId,
  'upgradePolicy': instance.upgradePolicy,
  'hasNewerRevision': instance.hasNewerRevision,
  'impactedItems': instance.impactedItems.map((e) => e.toJson()).toList(),
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
