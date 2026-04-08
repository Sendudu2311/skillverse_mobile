import 'dart:convert';

/// Cấu trúc dữ liệu CV được parse từ `cvJson` trả về bởi Backend AI.
/// Tương đương 1:1 với `CVStructuredData` trong `cvTemplateTypes.ts` (Web).

class CVStructuredData {
  final CVPersonalInfo personalInfo;
  final String summary;
  final List<CVExperience> experience;
  final List<CVEducation> education;
  final List<CVSkillCategory> skills;
  final List<CVProject> projects;
  final List<CVCertificate> certificates;
  final List<CVLanguage> languages;
  final List<CVEndorsement> endorsements;

  CVStructuredData({
    required this.personalInfo,
    this.summary = '',
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    this.projects = const [],
    this.certificates = const [],
    this.languages = const [],
    this.endorsements = const [],
  });

  factory CVStructuredData.fromJson(Map<String, dynamic> json) {
    return CVStructuredData(
      personalInfo: CVPersonalInfo.fromJson(
        json['personalInfo'] as Map<String, dynamic>? ?? {},
      ),
      summary: json['summary'] as String? ?? '',
      experience:
          (json['experience'] as List<dynamic>?)
              ?.map((e) => CVExperience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education:
          (json['education'] as List<dynamic>?)
              ?.map((e) => CVEducation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => CVSkillCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      projects:
          (json['projects'] as List<dynamic>?)
              ?.map((e) => CVProject.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      certificates:
          (json['certificates'] as List<dynamic>?)
              ?.map((e) => CVCertificate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => CVLanguage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      endorsements:
          (json['endorsements'] as List<dynamic>?)
              ?.map((e) => CVEndorsement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Parse JSON string từ Backend `cvJson` field.
  static CVStructuredData? tryParse(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return CVStructuredData.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

class CVPersonalInfo {
  final String fullName;
  final String? professionalTitle;
  final String? email;
  final String? phone;
  final String? location;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final String? avatarUrl;

  CVPersonalInfo({
    this.fullName = '',
    this.professionalTitle,
    this.email,
    this.phone,
    this.location,
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.avatarUrl,
  });

  factory CVPersonalInfo.fromJson(Map<String, dynamic> json) {
    return CVPersonalInfo(
      fullName: json['fullName'] as String? ?? '',
      professionalTitle: json['professionalTitle'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      githubUrl: json['githubUrl'] as String?,
      portfolioUrl: json['portfolioUrl'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class CVExperience {
  final String title;
  final String company;
  final String? location;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;
  final List<String> achievements;
  final List<String> technologies;

  CVExperience({
    this.title = '',
    this.company = '',
    this.location,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
    this.achievements = const [],
    this.technologies = const [],
  });

  factory CVExperience.fromJson(Map<String, dynamic> json) {
    return CVExperience(
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isCurrent: json['isCurrent'] as bool? ?? false,
      description: json['description'] as String?,
      achievements:
          (json['achievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      technologies:
          (json['technologies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class CVEducation {
  final String degree;
  final String institution;
  final String? location;
  final String? startDate;
  final String? endDate;
  final String? gpa;

  CVEducation({
    this.degree = '',
    this.institution = '',
    this.location,
    this.startDate,
    this.endDate,
    this.gpa,
  });

  factory CVEducation.fromJson(Map<String, dynamic> json) {
    return CVEducation(
      degree: json['degree'] as String? ?? '',
      institution: json['institution'] as String? ?? '',
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      gpa: json['gpa'] as String?,
    );
  }
}

class CVSkillCategory {
  final String? category;
  final List<CVSkill> skills;

  CVSkillCategory({this.category, this.skills = const []});

  factory CVSkillCategory.fromJson(Map<String, dynamic> json) {
    return CVSkillCategory(
      category: json['category'] as String?,
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => CVSkill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CVSkill {
  final String name;
  final int level; // 1-5

  CVSkill({this.name = '', this.level = 3});

  factory CVSkill.fromJson(Map<String, dynamic> json) {
    return CVSkill(
      name: json['name'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 3,
    );
  }
}

class CVProject {
  final String title;
  final String? description;
  final String? role;
  final List<String> technologies;
  final List<String> outcomes;
  final String? url;

  CVProject({
    this.title = '',
    this.description,
    this.role,
    this.technologies = const [],
    this.outcomes = const [],
    this.url,
  });

  factory CVProject.fromJson(Map<String, dynamic> json) {
    return CVProject(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      role: json['role'] as String?,
      technologies:
          (json['technologies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      outcomes:
          (json['outcomes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      url: json['url'] as String?,
    );
  }
}

class CVCertificate {
  final String title;
  final String? issuingOrganization;
  final String? issueDate;
  final String? credentialUrl;

  CVCertificate({
    this.title = '',
    this.issuingOrganization,
    this.issueDate,
    this.credentialUrl,
  });

  factory CVCertificate.fromJson(Map<String, dynamic> json) {
    return CVCertificate(
      title: json['title'] as String? ?? '',
      issuingOrganization: json['issuingOrganization'] as String?,
      issueDate: json['issueDate'] as String?,
      credentialUrl: json['credentialUrl'] as String?,
    );
  }
}

class CVLanguage {
  final String name;
  final String proficiency; // Native, Fluent, Advanced, Intermediate, Basic

  CVLanguage({this.name = '', this.proficiency = 'Intermediate'});

  factory CVLanguage.fromJson(Map<String, dynamic> json) {
    return CVLanguage(
      name: json['name'] as String? ?? '',
      proficiency: json['proficiency'] as String? ?? 'Intermediate',
    );
  }

  int get dots {
    switch (proficiency.toLowerCase()) {
      case 'native':
      case 'fluent':
        return 5;
      case 'advanced':
        return 4;
      case 'intermediate':
        return 3;
      case 'basic':
        return 2;
      default:
        return 3;
    }
  }
}

class CVEndorsement {
  final String quote;
  final String authorName;
  final String? authorTitle;

  CVEndorsement({this.quote = '', this.authorName = '', this.authorTitle});

  factory CVEndorsement.fromJson(Map<String, dynamic> json) {
    return CVEndorsement(
      quote: json['quote'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorTitle: json['authorTitle'] as String?,
    );
  }
}
