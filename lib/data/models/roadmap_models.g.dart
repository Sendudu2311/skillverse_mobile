// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roadmap_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoadmapStep _$RoadmapStepFromJson(Map<String, dynamic> json) => RoadmapStep(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  completed: json['completed'] as bool,
  current: json['current'] as bool?,
  duration: json['duration'] as String,
);

Map<String, dynamic> _$RoadmapStepToJson(RoadmapStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'completed': instance.completed,
      'current': instance.current,
      'duration': instance.duration,
    };

Roadmap _$RoadmapFromJson(Map<String, dynamic> json) => Roadmap(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  category: json['category'] as String,
  progress: (json['progress'] as num).toInt(),
  totalSteps: (json['totalSteps'] as num).toInt(),
  completedSteps: (json['completedSteps'] as num).toInt(),
  estimatedTime: json['estimatedTime'] as String,
  difficulty: json['difficulty'] as String,
  color: json['color'] as String,
  steps: (json['steps'] as List<dynamic>)
      .map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RoadmapToJson(Roadmap instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'category': instance.category,
  'progress': instance.progress,
  'totalSteps': instance.totalSteps,
  'completedSteps': instance.completedSteps,
  'estimatedTime': instance.estimatedTime,
  'difficulty': instance.difficulty,
  'color': instance.color,
  'steps': instance.steps,
};

PageResponse<T> _$PageResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => PageResponse<T>(
  content: (json['content'] as List<dynamic>).map(fromJsonT).toList(),
  page: (json['page'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  totalElements: (json['totalElements'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  first: json['first'] as bool,
  last: json['last'] as bool,
  empty: json['empty'] as bool,
);

Map<String, dynamic> _$PageResponseToJson<T>(
  PageResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'content': instance.content.map(toJsonT).toList(),
  'page': instance.page,
  'size': instance.size,
  'totalElements': instance.totalElements,
  'totalPages': instance.totalPages,
  'first': instance.first,
  'last': instance.last,
  'empty': instance.empty,
};
