import 'package:json_annotation/json_annotation.dart';

part 'enrollment_models.g.dart';

/// Request DTO for enrolling in a course
@JsonSerializable()
class EnrollRequestDto {
  final int courseId;

  const EnrollRequestDto({
    required this.courseId,
  });

  factory EnrollRequestDto.fromJson(Map<String, dynamic> json) =>
      _$EnrollRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollRequestDtoToJson(this);
}

/// Detailed enrollment information
@JsonSerializable()
class EnrollmentDetailDto {
  final int? id;
  final int courseId;
  final String courseTitle;
  final String courseSlug;
  final int userId;
  final String status;
  final int progressPercent;
  final String? entitlementSource;
  final String? entitlementRef;
  final DateTime? enrolledAt;
  final DateTime? completedAt;
  final bool completed;

  const EnrollmentDetailDto({
    this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseSlug,
    required this.userId,
    required this.status,
    required this.progressPercent,
    this.entitlementSource,
    this.entitlementRef,
    this.enrolledAt,
    this.completedAt,
    required this.completed,
  });

  factory EnrollmentDetailDto.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentDetailDtoToJson(this);
}

/// Enrollment status response
@JsonSerializable()
class EnrollmentStatusDto {
  final bool enrolled;

  const EnrollmentStatusDto({
    required this.enrolled,
  });

  factory EnrollmentStatusDto.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentStatusDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentStatusDtoToJson(this);
}

/// Enrollment statistics
@JsonSerializable()
class EnrollmentStatsDto {
  final int totalEnrollments;
  final int activeEnrollments;
  final int completedEnrollments;
  final double averageProgress;
  final double completionRate;

  const EnrollmentStatsDto({
    required this.totalEnrollments,
    required this.activeEnrollments,
    required this.completedEnrollments,
    required this.averageProgress,
    required this.completionRate,
  });

  factory EnrollmentStatsDto.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentStatsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentStatsDtoToJson(this);
}

/// Enrollment status enum
enum EnrollmentStatus {
  @JsonValue('ENROLLED')
  enrolled,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('DROPPED')
  dropped,
  @JsonValue('EXPIRED')
  expired,
}

/// Entitlement source enum
enum EntitlementSource {
  @JsonValue('PURCHASE')
  purchase,
  @JsonValue('ADMIN')
  admin,
  @JsonValue('PROMOTION')
  promotion,
  @JsonValue('SCHOLARSHIP')
  scholarship,
}
