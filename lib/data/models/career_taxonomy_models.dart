import 'package:json_annotation/json_annotation.dart';

part 'career_taxonomy_models.g.dart';

// ============================================================
// Enums
// ============================================================

/// Taxonomy entity status managed by admin.
enum TaxonomyStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('INACTIVE')
  inactive,
}

/// Skill requirement type within a track.
enum RequirementType {
  @JsonValue('REQUIRED')
  required,
  @JsonValue('IMPORTANT')
  important,
  @JsonValue('NICE_TO_HAVE')
  niceToHave,
}

// ============================================================
// DTOs — match backend TaxonomyController responses
// ============================================================

/// Active domain returned by GET /api/domains
@JsonSerializable()
class DomainDto {
  final int id;
  final String code;
  final String? name;
  final String? description;
  @JsonKey(unknownEnumValue: TaxonomyStatus.active)
  final TaxonomyStatus status;

  const DomainDto({
    required this.id,
    required this.code,
    this.name,
    this.description,
    required this.status,
  });

  factory DomainDto.fromJson(Map<String, dynamic> json) =>
      _$DomainDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DomainDtoToJson(this);

  /// Human-readable label with Vietnamese fallback.
  String get displayLabel {
    const overrides = <String, String>{
      'it': 'Công nghệ thông tin',
      'technology': 'Công nghệ',
      'software_engineering': 'Công nghệ phần mềm',
      'software engineering': 'Công nghệ phần mềm',
      'design': 'Thiết kế',
      'business': 'Kinh doanh',
      'service': 'Dịch vụ',
      'education': 'Giáo dục',
      'healthcare': 'Y tế',
      'finance': 'Tài chính',
      'marketing': 'Marketing',
    };
    final key = (code).trim().toLowerCase();
    final nameKey = (name ?? '').trim().toLowerCase();
    return overrides[key] ??
        overrides[nameKey] ??
        _humanize(name ?? code);
  }
}

/// Active job position returned by GET /api/job-positions
@JsonSerializable()
class JobPositionDto {
  final int id;
  final String code;
  final String? name;
  final String? description;
  final int? domainId;
  @JsonKey(unknownEnumValue: TaxonomyStatus.active)
  final TaxonomyStatus status;

  const JobPositionDto({
    required this.id,
    required this.code,
    this.name,
    this.description,
    this.domainId,
    required this.status,
  });

  factory JobPositionDto.fromJson(Map<String, dynamic> json) =>
      _$JobPositionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$JobPositionDtoToJson(this);

  /// Human-readable label with Vietnamese fallback.
  String get displayLabel {
    const overrides = <String, String>{
      'backend_developer': 'Lập trình viên Backend',
      'backend developer': 'Lập trình viên Backend',
      'frontend_developer': 'Lập trình viên Frontend',
      'frontend developer': 'Lập trình viên Frontend',
      'fullstack_developer': 'Lập trình viên Full-stack',
      'fullstack developer': 'Lập trình viên Full-stack',
      'mobile_developer': 'Lập trình viên Mobile',
      'mobile developer': 'Lập trình viên Mobile',
      'data_analyst': 'Chuyên viên phân tích dữ liệu',
      'data analyst': 'Chuyên viên phân tích dữ liệu',
      'data_engineer': 'Kỹ sư dữ liệu',
      'data engineer': 'Kỹ sư dữ liệu',
      'qa_tester': 'Kiểm thử phần mềm',
      'qa tester': 'Kiểm thử phần mềm',
      'devops_engineer': 'Kỹ sư DevOps',
      'devops engineer': 'Kỹ sư DevOps',
      'ui_ux_designer': 'Nhà thiết kế UI/UX',
      'ui/ux designer': 'Nhà thiết kế UI/UX',
    };
    final key = (code).trim().toLowerCase();
    final nameKey = (name ?? '').trim().toLowerCase();
    return overrides[key] ??
        overrides[nameKey] ??
        _humanize(name ?? code);
  }
}

/// Track within a job position returned by GET /api/job-positions/{id}/tracks
@JsonSerializable()
class JobPositionTrackDto {
  final int id;
  final String? code;
  final String? name;
  final String? description;
  final int? jobPositionId;
  @JsonKey(unknownEnumValue: TaxonomyStatus.active)
  final TaxonomyStatus status;

  const JobPositionTrackDto({
    required this.id,
    this.code,
    this.name,
    this.description,
    this.jobPositionId,
    required this.status,
  });

  factory JobPositionTrackDto.fromJson(Map<String, dynamic> json) =>
      _$JobPositionTrackDtoFromJson(json);
  Map<String, dynamic> toJson() => _$JobPositionTrackDtoToJson(this);

  String get displayLabel => _humanize(name ?? code ?? 'Track #$id');
}

/// Skill mapped to a track returned by GET /api/job-position-tracks/{trackId}/skills
@JsonSerializable()
class JobPositionTrackSkillDto {
  final int? id;
  final int? trackId;
  final int? skillId;
  final String? skillName;
  final String? canonicalKey;
  @JsonKey(unknownEnumValue: RequirementType.required)
  final RequirementType? requirementType;
  final double? weight;
  final int? sortOrder;

  const JobPositionTrackSkillDto({
    this.id,
    this.trackId,
    this.skillId,
    this.skillName,
    this.canonicalKey,
    this.requirementType,
    this.weight,
    this.sortOrder,
  });

  factory JobPositionTrackSkillDto.fromJson(Map<String, dynamic> json) =>
      _$JobPositionTrackSkillDtoFromJson(json);
  Map<String, dynamic> toJson() => _$JobPositionTrackSkillDtoToJson(this);

  String get displayName =>
      _humanize(skillName ?? canonicalKey ?? 'Kỹ năng #${skillId ?? id}');
}

// ============================================================
// Helpers
// ============================================================

String _humanize(String value) =>
    value.replaceAll(RegExp(r'[_-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
