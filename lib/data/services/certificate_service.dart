import '../../core/network/api_client.dart';

class CertificateService {
  static final CertificateService _instance = CertificateService._internal();
  factory CertificateService() => _instance;
  CertificateService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get a certificate by ID (owned by current user)
  /// GET /api/certificates/{certificateId}
  Future<CertificateDto> getCertificate({required int certificateId}) async {
    final response = await _apiClient.dio.get(
      '/certificates/$certificateId',
    );
    return CertificateDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify a certificate by serial (public endpoint)
  /// GET /api/certificates/verify/{serial}
  Future<CertificateVerificationDto> verifyCertificate({
    required String serial,
  }) async {
    final response = await _apiClient.dio.get(
      '/certificates/verify/$serial',
    );
    return CertificateVerificationDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Look up the certificate ID for a completed course
  /// Uses system-certificates endpoint and filters by courseTitle
  Future<int?> getCertificateIdByCourse({
    required int courseId,
    required String courseTitle,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/portfolio/system-certificates',
      );
      final data = response.data;
      List<dynamic> items = [];
      if (data is Map<String, dynamic>) {
        items = (data['data'] as List<dynamic>?) ?? [];
      } else if (data is List) {
        items = data;
      }
      // Filter: source == COURSE and title matches
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        if (map['source'] == 'COURSE' && map['title'] == courseTitle) {
          return map['id'] as int?;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Maps to backend CertificateDTO
class CertificateDto {
  final int id;
  final int courseId;
  final int userId;
  final String courseTitle;
  final String recipientName;
  final String instructorName;
  final String? instructorSignatureUrl;
  final String issuerName;
  final String type;
  final String serial;
  final String? issuedAt;
  final String? revokedAt;
  final String? criteria;
  final String? platformProof;
  final bool proofVerified;

  const CertificateDto({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.courseTitle,
    required this.recipientName,
    required this.instructorName,
    this.instructorSignatureUrl,
    required this.issuerName,
    required this.type,
    required this.serial,
    this.issuedAt,
    this.revokedAt,
    this.criteria,
    this.platformProof,
    this.proofVerified = false,
  });

  factory CertificateDto.fromJson(Map<String, dynamic> json) {
    return CertificateDto(
      id: (json['id'] as num).toInt(),
      courseId: (json['courseId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      courseTitle: json['courseTitle'] as String? ?? '',
      recipientName: json['recipientName'] as String? ?? '',
      instructorName: json['instructorName'] as String? ?? '',
      instructorSignatureUrl: json['instructorSignatureUrl'] as String?,
      issuerName: json['issuerName'] as String? ?? 'SkillVerse',
      type: json['type'] as String? ?? 'COURSE_COMPLETION',
      serial: json['serial'] as String? ?? '',
      issuedAt: json['issuedAt'] as String?,
      revokedAt: json['revokedAt'] as String?,
      criteria: json['criteria'] as String?,
      platformProof: json['platformProof'] as String?,
      proofVerified: json['proofVerified'] == true,
    );
  }
}

/// Maps to backend CertificateVerificationDTO
class CertificateVerificationDto {
  final String serial;
  final String recipientName;
  final String courseTitle;
  final String issuerName;
  final String? issuedAt;
  final bool valid;

  const CertificateVerificationDto({
    required this.serial,
    required this.recipientName,
    required this.courseTitle,
    required this.issuerName,
    this.issuedAt,
    this.valid = false,
  });

  factory CertificateVerificationDto.fromJson(Map<String, dynamic> json) {
    return CertificateVerificationDto(
      serial: json['serial'] as String? ?? '',
      recipientName: json['recipientName'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      issuerName: json['issuerName'] as String? ?? '',
      issuedAt: json['issuedAt'] as String?,
      valid: json['valid'] == true,
    );
  }
}
