class SkillResolveAlternative {
  final String domain;
  final String industry;
  final String jobRole;
  final double confidence;

  SkillResolveAlternative({
    required this.domain,
    required this.industry,
    required this.jobRole,
    required this.confidence,
  });

  factory SkillResolveAlternative.fromJson(Map<String, dynamic> json) {
    return SkillResolveAlternative(
      domain: json['domain'] ?? '',
      industry: json['industry'] ?? '',
      jobRole: json['jobRole'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'industry': industry,
      'jobRole': jobRole,
      'confidence': confidence,
    };
  }
}

class SkillResolveResponse {
  final String skillName;
  final String domain;
  final String industry;
  final String jobRole;
  final double confidence;
  final String reasoning;
  final bool questionBankExists;
  final int? existingQuestionBankId;
  final String? existingQuestionBankTitle;
  final int? createdQuestionBankId;
  final String? createdQuestionBankTitle;
  final List<SkillResolveAlternative>? alternatives;

  SkillResolveResponse({
    required this.skillName,
    required this.domain,
    required this.industry,
    required this.jobRole,
    required this.confidence,
    required this.reasoning,
    required this.questionBankExists,
    this.existingQuestionBankId,
    this.existingQuestionBankTitle,
    this.createdQuestionBankId,
    this.createdQuestionBankTitle,
    this.alternatives,
  });

  factory SkillResolveResponse.fromJson(Map<String, dynamic> json) {
    return SkillResolveResponse(
      skillName: json['skillName'] ?? '',
      domain: json['domain'] ?? '',
      industry: json['industry'] ?? '',
      jobRole: json['jobRole'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] ?? '',
      questionBankExists: json['questionBankExists'] ?? false,
      existingQuestionBankId: json['existingQuestionBankId'],
      existingQuestionBankTitle: json['existingQuestionBankTitle'],
      createdQuestionBankId: json['createdQuestionBankId'],
      createdQuestionBankTitle: json['createdQuestionBankTitle'],
      alternatives: json['alternatives'] != null
          ? (json['alternatives'] as List)
              .map((e) => SkillResolveAlternative.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillName': skillName,
      'domain': domain,
      'industry': industry,
      'jobRole': jobRole,
      'confidence': confidence,
      'reasoning': reasoning,
      'questionBankExists': questionBankExists,
      'existingQuestionBankId': existingQuestionBankId,
      'existingQuestionBankTitle': existingQuestionBankTitle,
      'createdQuestionBankId': createdQuestionBankId,
      'createdQuestionBankTitle': createdQuestionBankTitle,
      'alternatives': alternatives?.map((e) => e.toJson()).toList(),
    };
  }
}

class SkillResolveResult {
  final String domain;
  final String industry;
  final String jobRole;
  final double score;

  SkillResolveResult({
    required this.domain,
    required this.industry,
    required this.jobRole,
    required this.score,
  });
}
