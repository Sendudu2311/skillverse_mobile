import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/portfolio_models.dart';
import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';

class PortfolioService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== Helpers ====================

  /// Unwrap backend's {success, data, message} envelope.
  /// Throws ApiException if success == false or data is missing.
  T _unwrap<T>(dynamic responseData, T Function(dynamic data) parse) {
    if (responseData is Map<String, dynamic>) {
      final success = responseData['success'] as bool? ?? true;
      if (!success) {
        throw ApiException(
          responseData['message'] as String? ?? 'Có lỗi xảy ra',
        );
      }
      final inner = responseData['data'];
      if (inner == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return parse(inner);
    }
    // Some endpoints may return the object directly (no wrapper)
    return parse(responseData);
  }

  List<T> _unwrapList<T>(
    dynamic responseData,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (responseData is Map<String, dynamic>) {
      final success = responseData['success'] as bool? ?? true;
      if (!success) {
        throw ApiException(
          responseData['message'] as String? ?? 'Có lỗi xảy ra',
        );
      }
      final inner = responseData['data'];
      if (inner == null) return [];
      if (inner is List) {
        return inner.map((e) => parse(e as Map<String, dynamic>)).toList();
      }
    }
    if (responseData is List) {
      return responseData.map((e) => parse(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ==================== Extended Profile ====================

  /// Check if user has extended profile
  /// GET /api/portfolio/profile/check
  Future<CheckExtendedProfileResponse> checkExtendedProfile() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/profile/check');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return CheckExtendedProfileResponse(
          hasExtendedProfile: data['hasExtendedProfile'] as bool? ?? false,
        );
      }
      return CheckExtendedProfileResponse(hasExtendedProfile: false);
    } catch (e) {
      rethrow;
    }
  }

  /// Get my combined profile (basic + extended)
  /// GET /api/portfolio/profile
  /// Returns {success, data: UserProfileDTO}
  Future<ExtendedProfileDto> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/profile');
      return _unwrap(
        response.data,
        (d) => ExtendedProfileDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create extended profile (multipart: profile JSON part)
  /// POST /api/portfolio/profile
  Future<ExtendedProfileDto> createExtendedProfile({
    required CreateExtendedProfileRequest request,
  }) async {
    try {
      final profileJson = jsonEncode(request.toJson());
      final formData = FormData.fromMap({
        'profile': MultipartFile.fromString(
          profileJson,
          filename: 'profile.json',
          contentType: DioMediaType('application', 'json'),
        ),
      });
      final response = await _apiClient.dio.post(
        '/portfolio/profile',
        data: formData,
      );
      return _unwrap(
        response.data,
        (d) => ExtendedProfileDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update extended profile (multipart)
  /// PUT /api/portfolio/profile
  Future<ExtendedProfileDto> updateExtendedProfile({
    required CreateExtendedProfileRequest request,
  }) async {
    try {
      final profileJson = jsonEncode(request.toJson());
      final formData = FormData.fromMap({
        'profile': MultipartFile.fromString(
          profileJson,
          filename: 'profile.json',
          contentType: DioMediaType('application', 'json'),
        ),
      });
      final response = await _apiClient.dio.put(
        '/portfolio/profile',
        data: formData,
      );
      return _unwrap(
        response.data,
        (d) => ExtendedProfileDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete extended profile
  /// DELETE /api/portfolio/profile
  Future<void> deleteExtendedProfile() async {
    try {
      await _apiClient.dio.delete('/portfolio/profile');
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile by slug (public)
  /// GET /api/portfolio/profile/slug/{slug}
  Future<ExtendedProfileDto> getProfileBySlug(String slug) async {
    try {
      final response = await _apiClient.dio.get(
        '/portfolio/profile/slug/$slug',
      );
      return _unwrap(
        response.data,
        (d) => ExtendedProfileDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get public profile by userId
  /// GET /api/portfolio/profile/{userId}
  Future<ExtendedProfileDto> getPublicProfile(int userId) async {
    try {
      final response = await _apiClient.dio.get('/portfolio/profile/$userId');
      return _unwrap(
        response.data,
        (d) => ExtendedProfileDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Projects ====================

  /// GET /api/portfolio/projects
  Future<List<ProjectDto>> getUserProjects() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/projects');
      return _unwrapList(response.data, ProjectDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/portfolio/projects (multipart)
  Future<ProjectDto> createProject({
    required CreateProjectRequest request,
  }) async {
    try {
      final projectJson = jsonEncode(request.toJson());
      final formData = FormData.fromMap({
        'project': MultipartFile.fromString(
          projectJson,
          filename: 'project.json',
          contentType: DioMediaType('application', 'json'),
        ),
      });
      final response = await _apiClient.dio.post(
        '/portfolio/projects',
        data: formData,
      );
      return _unwrap(
        response.data,
        (d) => ProjectDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/portfolio/projects/{projectId} (multipart)
  Future<ProjectDto> updateProject({
    required int projectId,
    required UpdateProjectRequest request,
  }) async {
    try {
      final projectJson = jsonEncode(request.toJson());
      final formData = FormData.fromMap({
        'project': MultipartFile.fromString(
          projectJson,
          filename: 'project.json',
          contentType: DioMediaType('application', 'json'),
        ),
      });
      final response = await _apiClient.dio.put(
        '/portfolio/projects/$projectId',
        data: formData,
      );
      return _unwrap(
        response.data,
        (d) => ProjectDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /api/portfolio/projects/{projectId}
  Future<void> deleteProject(int projectId) async {
    try {
      await _apiClient.dio.delete('/portfolio/projects/$projectId');
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Certificates ====================

  /// GET /api/portfolio/certificates
  Future<List<CertificateDto>> getUserCertificates() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/certificates');
      return _unwrapList(response.data, CertificateDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/portfolio/certificates (multipart)
  Future<CertificateDto> createCertificate({
    required CreateCertificateRequest request,
  }) async {
    try {
      final certJson = jsonEncode(request.toJson());
      final formData = FormData.fromMap({
        'certificate': MultipartFile.fromString(
          certJson,
          filename: 'certificate.json',
          contentType: DioMediaType('application', 'json'),
        ),
      });
      final response = await _apiClient.dio.post(
        '/portfolio/certificates',
        data: formData,
      );
      return _unwrap(
        response.data,
        (d) => CertificateDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /api/portfolio/certificates/{certificateId}
  Future<void> deleteCertificate(int certificateId) async {
    try {
      await _apiClient.dio.delete('/portfolio/certificates/$certificateId');
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Reviews ====================

  /// GET /api/portfolio/reviews
  Future<List<ReviewDto>> getUserReviews() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/reviews');
      return _unwrapList(response.data, ReviewDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== CV ====================

  /// POST /api/portfolio/cv/generate
  Future<CVDto> generateCV({GenerateCVRequest? request}) async {
    try {
      final response = await _apiClient.dio.post(
        '/portfolio/cv/generate',
        data: request?.toJson() ?? {},
      );
      return _unwrap(
        response.data,
        (d) => CVDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/portfolio/cv/{cvId}
  Future<CVDto> updateCV({
    required int cvId,
    required UpdateCVRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/portfolio/cv/$cvId',
        data: request.toJson(),
      );
      return _unwrap(
        response.data,
        (d) => CVDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/portfolio/cv/active — returns null if 404 or no active CV
  Future<CVDto?> getActiveCV() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/cv/active');
      return _unwrap(
        response.data,
        (d) => CVDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (_) {
      // 404 "No active CV" is a normal state — not an error
      return null;
    }
  }

  /// GET /api/portfolio/cv/all
  Future<List<CVDto>> getAllCVs() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/cv/all');
      return _unwrapList(response.data, CVDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/portfolio/cv/{cvId}/set-active
  Future<CVDto> setActiveCV(int cvId) async {
    try {
      final response = await _apiClient.dio.put(
        '/portfolio/cv/$cvId/set-active',
      );
      return _unwrap(
        response.data,
        (d) => CVDto.fromJson(d as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /api/portfolio/cv/{cvId}
  Future<void> deleteCV(int cvId) async {
    try {
      await _apiClient.dio.delete('/portfolio/cv/$cvId');
    } catch (e) {
      rethrow;
    }
  }

  // ==================== System Certificates (Auto-Import) ====================

  /// GET /api/portfolio/system-certificates
  Future<List<SystemCertificateDto>> getSystemCertificates() async {
    try {
      final response = await _apiClient.dio.get(
        '/portfolio/system-certificates',
      );
      return _unwrapList(response.data, SystemCertificateDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/portfolio/certificates/import/system?source={source}
  /// source: "COURSE" | "BADGE" | "ALL"
  Future<List<SystemCertificateDto>> importSystemCertificates({
    String source = 'ALL',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/portfolio/certificates/import/system',
        queryParameters: {'source': source},
      );
      return _unwrapList(response.data, SystemCertificateDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Completed Missions (Short-Term Jobs) ====================

  /// GET /api/portfolio/completed-missions
  Future<List<CompletedMissionDto>> getCompletedMissions() async {
    try {
      final response = await _apiClient.dio.get(
        '/portfolio/completed-missions',
      );
      return _unwrapList(response.data, CompletedMissionDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/portfolio/public/{userId}/completed-missions
  Future<List<CompletedMissionDto>> getPublicCompletedMissions(
    int userId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/portfolio/public/$userId/completed-missions',
      );
      return _unwrapList(response.data, CompletedMissionDto.fromJson);
    } catch (e) {
      rethrow;
    }
  }
}
