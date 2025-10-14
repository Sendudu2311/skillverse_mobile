import 'package:json_annotation/json_annotation.dart';

part 'roadmap_models.g.dart';

enum RoadmapDifficulty {
  @JsonValue('Beginner')
  beginner,
  @JsonValue('Intermediate')
  intermediate,
  @JsonValue('Advanced')
  advanced,
}

enum RoadmapCategory {
  @JsonValue('Programming')
  programming,
  @JsonValue('Data Science')
  dataScience,
  @JsonValue('Marketing')
  marketing,
  @JsonValue('Infrastructure')
  infrastructure,
  @JsonValue('Design')
  design,
}

@JsonSerializable()
class RoadmapStep {
  final int id;
  final String title;
  final bool completed;
  final bool? current;
  final String duration;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.completed,
    this.current,
    required this.duration,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) => _$RoadmapStepFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapStepToJson(this);
}

@JsonSerializable()
class Roadmap {
  final int id;
  final String title;
  final String category;
  final int progress;
  final int totalSteps;
  final int completedSteps;
  final String estimatedTime;
  final String difficulty;
  final String color;
  final List<RoadmapStep> steps;

  Roadmap({
    required this.id,
    required this.title,
    required this.category,
    required this.progress,
    required this.totalSteps,
    required this.completedSteps,
    required this.estimatedTime,
    required this.difficulty,
    required this.color,
    required this.steps,
  });

  factory Roadmap.fromJson(Map<String, dynamic> json) => _$RoadmapFromJson(json);
  Map<String, dynamic> toJson() => _$RoadmapToJson(this);
}

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool empty;

  PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PageResponseFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => _$PageResponseToJson(this, toJsonT);
}