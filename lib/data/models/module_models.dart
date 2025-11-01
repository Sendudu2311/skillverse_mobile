import 'package:json_annotation/json_annotation.dart';
import 'lesson_models.dart';

part 'module_models.g.dart';

/// Module summary (basic info)
@JsonSerializable()
class ModuleSummaryDto {
  final int id;
  final String title;
  final String? description;
  final int orderIndex;

  const ModuleSummaryDto({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
  });

  factory ModuleSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ModuleSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleSummaryDtoToJson(this);
}

/// Module detail (with lessons)
@JsonSerializable()
class ModuleDetailDto {
  final int id;
  final String title;
  final String? description;
  final int orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<LessonBriefDto>? lessons;

  const ModuleDetailDto({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    this.createdAt,
    this.updatedAt,
    this.lessons,
  });

  factory ModuleDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ModuleDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleDetailDtoToJson(this);
}

/// Module progress
@JsonSerializable()
class ModuleProgressDto {
  final int completedLessons;
  final int totalLessons;
  final int percent; // 0-100

  const ModuleProgressDto({
    required this.completedLessons,
    required this.totalLessons,
    required this.percent,
  });

  factory ModuleProgressDto.fromJson(Map<String, dynamic> json) =>
      _$ModuleProgressDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleProgressDtoToJson(this);
}

/// Module progress detail (with module info)
@JsonSerializable()
class ModuleProgressDetailDto {
  final int moduleId;
  final String moduleTitle;
  final int completedLessons;
  final int totalLessons;
  final int percent;

  const ModuleProgressDetailDto({
    required this.moduleId,
    required this.moduleTitle,
    required this.completedLessons,
    required this.totalLessons,
    required this.percent,
  });

  factory ModuleProgressDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ModuleProgressDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleProgressDetailDtoToJson(this);
}
