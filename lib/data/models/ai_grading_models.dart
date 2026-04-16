import 'package:json_annotation/json_annotation.dart';

part 'ai_grading_models.g.dart';

/// AI Grading result for an assignment submission
/// Matches backend AiGradingResultDTO.java
@JsonSerializable()
class AiGradingResult {
  @JsonKey(name: 'criteriaScores')
  final List<CriteriaScoreResult> criteriaScores;
  @JsonKey(name: 'totalScore')
  final double? totalScore;
  @JsonKey(name: 'overallFeedback')
  final String? overallFeedback;
  @JsonKey(name: 'overallConfidence')
  final double? overallConfidence;

  const AiGradingResult({
    this.criteriaScores = const [],
    this.totalScore,
    this.overallFeedback,
    this.overallConfidence,
  });

  factory AiGradingResult.fromJson(Map<String, dynamic> json) =>
      _$AiGradingResultFromJson(json);
  Map<String, dynamic> toJson() => _$AiGradingResultToJson(this);
}

/// Individual criteria score in AI grading
/// Matches backend AiGradingResultDTO.CriteriaScoreResult
@JsonSerializable()
class CriteriaScoreResult {
  @JsonKey(name: 'criteriaId')
  final int? criteriaId;
  @JsonKey(name: 'criteriaName')
  final String? criteriaName;
  final double? score;
  @JsonKey(name: 'maxPoints')
  final double? maxPoints;
  @JsonKey(name: 'passingPoints')
  final double? passingPoints;
  final bool? passed;
  final String? feedback;
  final double? confidence;

  const CriteriaScoreResult({
    this.criteriaId,
    this.criteriaName,
    this.score,
    this.maxPoints,
    this.passingPoints,
    this.passed,
    this.feedback,
    this.confidence,
  });

  factory CriteriaScoreResult.fromJson(Map<String, dynamic> json) =>
      _$CriteriaScoreResultFromJson(json);
  Map<String, dynamic> toJson() => _$CriteriaScoreResultToJson(this);
}
