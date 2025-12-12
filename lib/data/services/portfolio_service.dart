import '../models/portfolio_models.dart';
import 'api_client.dart';

class PortfolioService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== Extended Profile ====================

  /// Create extended profile
  /// POST /api/portfolio/profile
  Future<ExtendedProfileDto> createExtendedProfile({
    required CreateExtendedProfileRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/portfolio/profile',
        data: request.toJson(),
      );
      return ExtendedProfileDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update extended profile
  /// PUT /api/portfolio/profile
  Future<ExtendedProfileDto> updateExtendedProfile({
    required CreateExtendedProfileRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/portfolio/profile',
        data: request.toJson(),
      );
      return ExtendedProfileDto.fromJson(response.data);
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

  /// Get my portfolio
  /// GET /api/portfolio/profile
  Future<CompletePortfolioDto> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/profile');
      return CompletePortfolioDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if extended profile exists
  /// GET /api/portfolio/profile/check
  Future<CheckExtendedProfileResponse> checkExtendedProfile() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/profile/check');
      return CheckExtendedProfileResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile by slug
  /// GET /api/portfolio/profile/slug/{slug}
  Future<CompletePortfolioDto> getProfileBySlug(String slug) async {
    try {
      final response = await _apiClient.dio.get('/portfolio/profile/slug/$slug');
      return CompletePortfolioDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get public profile by user ID
  /// GET /api/portfolio/profile/{userId}
  Future<CompletePortfolioDto> getPublicProfile(int userId) async {
    try {
      final response = await _apiClient.dio.get('/portfolio/profile/$userId');
      return CompletePortfolioDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Projects ====================

  /// Create project
  /// POST /api/portfolio/projects
  Future<ProjectDto> createProject({
    required CreateProjectRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/portfolio/projects',
        data: request.toJson(),
      );
      return ProjectDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update project
  /// PUT /api/portfolio/projects/{projectId}
  Future<ProjectDto> updateProject({
    required int projectId,
    required UpdateProjectRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/portfolio/projects/$projectId',
        data: request.toJson(),
      );
      return ProjectDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user projects
  /// GET /api/portfolio/projects
  Future<List<ProjectDto>> getUserProjects() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/projects');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ProjectDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete project
  /// DELETE /api/portfolio/projects/{projectId}
  Future<void> deleteProject(int projectId) async {
    try {
      await _apiClient.dio.delete('/portfolio/projects/$projectId');
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Certificates ====================

  /// Create certificate
  /// POST /api/portfolio/certificates
  Future<CertificateDto> createCertificate({
    required CreateCertificateRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/portfolio/certificates',
        data: request.toJson(),
      );
      return CertificateDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user certificates
  /// GET /api/portfolio/certificates
  Future<List<CertificateDto>> getUserCertificates() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/certificates');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => CertificateDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete certificate
  /// DELETE /api/portfolio/certificates/{certificateId}
  Future<void> deleteCertificate(int certificateId) async {
    try {
      await _apiClient.dio.delete('/portfolio/certificates/$certificateId');
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Reviews ====================

  /// Get user reviews
  /// GET /api/portfolio/reviews
  Future<List<ReviewDto>> getUserReviews() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/reviews');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ReviewDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== CV ====================

  /// Generate CV
  /// POST /api/portfolio/cv/generate
  Future<CVDto> generateCV({
    GenerateCVRequest? request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/portfolio/cv/generate',
        data: request?.toJson() ?? {},
      );
      return CVDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update CV
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
      return CVDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get active CV
  /// GET /api/portfolio/cv/active
  Future<CVDto?> getActiveCV() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/cv/active');
      return CVDto.fromJson(response.data);
    } catch (e) {
      // Return null if no active CV (404)
      return null;
    }
  }

  /// Get all CVs
  /// GET /api/portfolio/cv/all
  Future<List<CVDto>> getAllCVs() async {
    try {
      final response = await _apiClient.dio.get('/portfolio/cv/all');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => CVDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Set active CV
  /// PUT /api/portfolio/cv/{cvId}/set-active
  Future<CVDto> setActiveCV(int cvId) async {
    try {
      final response = await _apiClient.dio.put(
        '/portfolio/cv/$cvId/set-active',
      );
      return CVDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete CV
  /// DELETE /api/portfolio/cv/{cvId}
  Future<void> deleteCV(int cvId) async {
    try {
      await _apiClient.dio.delete('/portfolio/cv/$cvId');
    } catch (e) {
      rethrow;
    }
  }
}
