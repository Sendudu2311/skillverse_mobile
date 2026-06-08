enum TeachingEligibilityStatus {
  eligible,
  partiallyEligible,
  needsReview,
  notEligible;

  static TeachingEligibilityStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ELIGIBLE':
        return eligible;
      case 'PARTIALLY_ELIGIBLE':
        return partiallyEligible;
      case 'NOT_ELIGIBLE':
        return notEligible;
      case 'NEEDS_REVIEW':
      default:
        return needsReview;
    }
  }

  int get sortWeight {
    switch (this) {
      case eligible:
        return 3;
      case partiallyEligible:
        return 2;
      case needsReview:
        return 1;
      case notEligible:
        return 0;
    }
  }

  String get displayLabel {
    switch (this) {
      case eligible:
        return 'Phù hợp';
      case partiallyEligible:
        return 'Khá phù hợp';
      case needsReview:
        return 'Cần xem xét';
      case notEligible:
        return 'Không phù hợp';
    }
  }
}

class MentorEligibilitySkillRequirement {
  final String? skillName;
  final String? requiredLevel;
  final String? mentorLevel;

  const MentorEligibilitySkillRequirement({
    this.skillName,
    this.requiredLevel,
    this.mentorLevel,
  });

  factory MentorEligibilitySkillRequirement.fromJson(
    Map<String, dynamic> json,
  ) {
    return MentorEligibilitySkillRequirement(
      skillName: json['skillName']?.toString() ?? json['name']?.toString(),
      requiredLevel: json['requiredLevel']?.toString(),
      mentorLevel: json['mentorLevel']?.toString(),
    );
  }
}

class MentorNodeEligibility {
  final String? nodeId;
  final String? title;
  final TeachingEligibilityStatus status;
  final int matchPercent;
  final List<MentorEligibilitySkillRequirement> missingRequiredSkills;
  final List<MentorEligibilitySkillRequirement> missingImportantSkills;
  final List<MentorEligibilitySkillRequirement> missingNiceToHaveSkills;

  const MentorNodeEligibility({
    this.nodeId,
    this.title,
    required this.status,
    this.matchPercent = 0,
    this.missingRequiredSkills = const [],
    this.missingImportantSkills = const [],
    this.missingNiceToHaveSkills = const [],
  });

  factory MentorNodeEligibility.fromJson(Map<String, dynamic> json) {
    return MentorNodeEligibility(
      nodeId: json['nodeId']?.toString(),
      title: json['title']?.toString() ?? json['nodeTitle']?.toString(),
      status: TeachingEligibilityStatus.fromString(json['status']?.toString()),
      matchPercent: (json['matchPercent'] as num?)?.toInt() ?? 0,
      missingRequiredSkills: _parseSkillList(json['missingRequiredSkills']),
      missingImportantSkills: _parseSkillList(json['missingImportantSkills']),
      missingNiceToHaveSkills: _parseSkillList(json['missingNiceToHaveSkills']),
    );
  }

  static List<MentorEligibilitySkillRequirement> _parseSkillList(
    dynamic value,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => MentorEligibilitySkillRequirement.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  String get missingSkillsText {
    final allMissing = [...missingRequiredSkills, ...missingImportantSkills];
    return allMissing
        .map((skill) => skill.skillName)
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .take(3)
        .join(', ');
  }
}

class MentorTeachingEligibilityResponse {
  final int? mentorId;
  final int? journeyId;
  final int? roadmapSessionId;
  final TeachingEligibilityStatus summaryStatus;
  final int overallMatchPercent;
  final List<MentorNodeEligibility> nodes;

  const MentorTeachingEligibilityResponse({
    this.mentorId,
    this.journeyId,
    this.roadmapSessionId,
    required this.summaryStatus,
    this.overallMatchPercent = 0,
    this.nodes = const [],
  });

  factory MentorTeachingEligibilityResponse.needsReview(int mentorId) {
    return MentorTeachingEligibilityResponse(
      mentorId: mentorId,
      summaryStatus: TeachingEligibilityStatus.needsReview,
    );
  }

  factory MentorTeachingEligibilityResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return MentorTeachingEligibilityResponse(
      mentorId: (json['mentorId'] as num?)?.toInt(),
      journeyId: (json['journeyId'] as num?)?.toInt(),
      roadmapSessionId: (json['roadmapSessionId'] as num?)?.toInt(),
      summaryStatus: TeachingEligibilityStatus.fromString(
        json['summaryStatus']?.toString(),
      ),
      overallMatchPercent: (json['overallMatchPercent'] as num?)?.toInt() ?? 0,
      nodes:
          (json['nodes'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (item) => MentorNodeEligibility.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          const [],
    );
  }
}
