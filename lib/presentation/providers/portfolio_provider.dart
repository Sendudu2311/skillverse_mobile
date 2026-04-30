import 'package:flutter/foundation.dart';
import '../../data/models/portfolio_models.dart';
import '../../data/services/portfolio_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class PortfolioProvider with ChangeNotifier, LoadingStateProviderMixin {
  final PortfolioService _portfolioService = PortfolioService();

  // State
  CompletePortfolioDto? _myPortfolio;
  ExtendedProfileDto? _extendedProfile;
  List<ProjectDto> _projects = [];
  List<CertificateDto> _certificates = [];
  List<ReviewDto> _reviews = [];
  List<CVDto> _cvs = [];
  CVDto? _activeCV;
  bool _hasExtendedProfile = false;

  // New: System Certificates, Completed Missions, Verified Skills
  List<SystemCertificateDto> _systemCertificates = [];
  List<CompletedMissionDto> _completedMissions = [];
  List<UserVerifiedSkillDto> _verifiedSkills = [];
  bool _isSyncing = false;

  // CV generation state — separate from the mixin's isLoading so the
  // full-screen AI loading view persists across Back + re-enter.
  bool _isCVGenerating = false;
  CVDto? _lastGeneratedCV;
  String? _cvGenerationError;

  // Getters
  CompletePortfolioDto? get myPortfolio => _myPortfolio;
  ExtendedProfileDto? get extendedProfile => _extendedProfile;
  List<ProjectDto> get projects => _projects;
  List<CertificateDto> get certificates => _certificates;
  List<ReviewDto> get reviews => _reviews;
  List<CVDto> get cvs => _cvs;
  CVDto? get activeCV => _activeCV;
  bool get hasExtendedProfile => _hasExtendedProfile;
  List<SystemCertificateDto> get systemCertificates => _systemCertificates;
  List<CompletedMissionDto> get completedMissions => _completedMissions;
  List<UserVerifiedSkillDto> get verifiedSkills => _verifiedSkills;
  bool get isSyncing => _isSyncing;
  bool get isCVGenerating => _isCVGenerating;
  CVDto? get lastGeneratedCV => _lastGeneratedCV;
  String? get cvGenerationError => _cvGenerationError;

  void clearLastGeneratedCV() {
    _lastGeneratedCV = null;
  }

  void clearCVGenerationError() {
    _cvGenerationError = null;
  }

  // ==================== Extended Profile ====================

  Future<void> checkExtendedProfile() async {
    await executeAsync(() async {
      final response = await _portfolioService.checkExtendedProfile();
      _hasExtendedProfile = response.hasExtendedProfile;
      _extendedProfile = response.profile;
      notifyListeners();
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<bool> createExtendedProfile(
    CreateExtendedProfileRequest request,
  ) async {
    final result = await executeAsync<bool>(() async {
      _extendedProfile = await _portfolioService.createExtendedProfile(
        request: request,
      );
      _hasExtendedProfile = true;
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> updateExtendedProfile(
    CreateExtendedProfileRequest request,
  ) async {
    final result = await executeAsync<bool>(() async {
      _extendedProfile = await _portfolioService.updateExtendedProfile(
        request: request,
      );
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> deleteExtendedProfile() async {
    final result = await executeAsync<bool>(() async {
      await _portfolioService.deleteExtendedProfile();
      _extendedProfile = null;
      _hasExtendedProfile = false;
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<void> loadMyPortfolio() async {
    await executeAsync(() async {
      // getMyProfile now returns ExtendedProfileDto (UserProfileDTO wrapper)
      _extendedProfile = await _portfolioService.getMyProfile();
      _hasExtendedProfile = _extendedProfile != null;
      // Build a CompletePortfolioDto for any code still reading _myPortfolio
      _myPortfolio = CompletePortfolioDto(
        extendedProfile: _extendedProfile,
        projects: _projects,
        certificates: _certificates,
        reviews: _reviews,
        activeCV: _activeCV,
      );
      notifyListeners();
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<ExtendedProfileDto?> getPortfolioBySlug(String slug) async {
    return await executeAsync(() async {
      return await _portfolioService.getProfileBySlug(slug);
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<ExtendedProfileDto?> getPublicPortfolio(int userId) async {
    return await executeAsync(() async {
      return await _portfolioService.getPublicProfile(userId);
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  // ==================== Projects ====================

  Future<void> loadProjects() async {
    await executeAsync(() async {
      _projects = await _portfolioService.getUserProjects();
      notifyListeners();
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<bool> createProject(CreateProjectRequest request) async {
    final result = await executeAsync<bool>(() async {
      final newProject = await _portfolioService.createProject(
        request: request,
      );
      _projects.add(newProject);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> updateProject(
    int projectId,
    UpdateProjectRequest request,
  ) async {
    final result = await executeAsync<bool>(() async {
      final updatedProject = await _portfolioService.updateProject(
        projectId: projectId,
        request: request,
      );
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = updatedProject;
      }
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> deleteProject(int projectId) async {
    final result = await executeAsync<bool>(() async {
      await _portfolioService.deleteProject(projectId);
      _projects.removeWhere((p) => p.id == projectId);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== Certificates ====================

  Future<void> loadCertificates() async {
    await executeAsync(() async {
      _certificates = await _portfolioService.getUserCertificates();
      notifyListeners();
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<bool> createCertificate(CreateCertificateRequest request) async {
    final result = await executeAsync<bool>(() async {
      final newCertificate = await _portfolioService.createCertificate(
        request: request,
      );
      _certificates.add(newCertificate);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> deleteCertificate(int certificateId) async {
    final result = await executeAsync<bool>(() async {
      await _portfolioService.deleteCertificate(certificateId);
      _certificates.removeWhere((c) => c.id == certificateId);
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== Reviews ====================

  Future<void> loadReviews() async {
    await executeAsync(() async {
      _reviews = await _portfolioService.getUserReviews();
      notifyListeners();
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  // ==================== System Certificates ====================

  Future<void> loadSystemCertificates() async {
    try {
      _systemCertificates = await _portfolioService.getSystemCertificates();
      notifyListeners();
    } catch (_) {
      // Endpoint may 500 if no data — safe to ignore
    }
  }

  /// Import system certificates into external certificates.
  /// Returns the count of newly imported items, or -1 on error.
  Future<int> importSystemCertificates({String source = 'ALL'}) async {
    if (_isSyncing) return -1;
    _isSyncing = true;
    notifyListeners();
    try {
      final result = await _portfolioService.importSystemCertificates(
        source: source,
      );
      _systemCertificates = result;
      // Reload external certificates to include newly imported ones
      _certificates = await _portfolioService.getUserCertificates();
      _isSyncing = false;
      notifyListeners();
      return result.where((c) => c.imported).length;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return -1;
    }
  }

  // ==================== Completed Missions ====================

  Future<void> loadCompletedMissions() async {
    try {
      _completedMissions = await _portfolioService.getCompletedMissions();
      notifyListeners();
    } catch (_) {
      // Endpoint may 500 if no data — safe to ignore
    }
  }

  // ==================== Verified Skills ====================

  /// Load verified skills from 3 sources:
  /// 1. Roadmap mentoring (journey-based)
  /// 2. Student self-verification (admin-approved)
  /// 3. Mentor-panel verification
  Future<void> loadVerifiedSkills({int? userId}) async {
    try {
      final results = await Future.wait([
        _portfolioService.getVerifiedSkills().catchError(
          (_) => <UserVerifiedSkillDto>[],
        ),
        userId != null
            ? _portfolioService.getPublicStudentVerifiedSkillDetails(userId)
            : Future.value(<Map<String, dynamic>>[]),
        userId != null
            ? _portfolioService.getPublicMentorVerifiedSkillDetails(userId)
            : Future.value(<Map<String, dynamic>>[]),
      ]);

      final roadmapSkills = results[0] as List<UserVerifiedSkillDto>;
      final studentRaw = results[1] as List<Map<String, dynamic>>;
      final mentorRaw = results[2] as List<Map<String, dynamic>>;

      final studentSkills = _mapManualToVerifiedSkill(
        studentRaw,
        'STUDENT_MANUAL',
      );
      final mentorSkills = _mapManualToVerifiedSkill(
        mentorRaw,
        'MENTOR_MANUAL',
      );

      _verifiedSkills = [...roadmapSkills, ...studentSkills, ...mentorSkills];
      notifyListeners();
    } catch (_) {
      // Non-critical — empty list is acceptable
    }
  }

  /// Convert raw student/mentor verification responses to UserVerifiedSkillDto
  List<UserVerifiedSkillDto> _mapManualToVerifiedSkill(
    List<Map<String, dynamic>> items,
    String source,
  ) {
    return items
        .where(
          (item) =>
              item['status'] == 'APPROVED' || item['status'] == 'VERIFIED',
        )
        .map(
          (item) => UserVerifiedSkillDto(
            id: (item['id'] as num?)?.toInt() ?? 0,
            skillName: item['skillName'] as String? ?? '',
            skillLevel: item['skillLevel'] as String?,
            verifiedByMentorId: (item['reviewedById'] as num?)?.toInt(),
            verifiedByMentorName:
                item['reviewedByName'] as String? ?? 'SkillVerse System',
            verificationNote: item['reviewNote'] as String?,
            verifiedAt: item['reviewedAt'] != null
                ? DateTime.tryParse(item['reviewedAt'].toString())
                : (item['requestedAt'] != null
                      ? DateTime.tryParse(item['requestedAt'].toString())
                      : null),
            source: source,
          ),
        )
        .toList();
  }

  // ==================== CV ====================

  Future<void> loadCVs() async {
    await executeAsync(() async {
      _cvs = await _portfolioService.getAllCVs();
      notifyListeners();
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<void> loadActiveCV() async {
    await executeAsync(() async {
      _activeCV = await _portfolioService.getActiveCV();
      notifyListeners();
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<bool> generateCV({GenerateCVRequest? request}) async {
    if (_isCVGenerating) return false;
    _isCVGenerating = true;
    _lastGeneratedCV = null;
    _cvGenerationError = null;
    notifyListeners();

    try {
      final newCV = await _portfolioService.generateCV(request: request);
      _activeCV = newCV;
      // Reload full list from server to sync isActive flags
      _cvs = await _portfolioService.getAllCVs();
      _lastGeneratedCV = newCV;
      _isCVGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _cvGenerationError = ErrorHandler.getErrorMessage(e);
      _isCVGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCV(int cvId, UpdateCVRequest request) async {
    final result = await executeAsync<bool>(() async {
      final updatedCV = await _portfolioService.updateCV(
        cvId: cvId,
        request: request,
      );
      final index = _cvs.indexWhere((cv) => cv.id == cvId);
      if (index != -1) {
        _cvs[index] = updatedCV;
      }
      if (_activeCV?.id == cvId) {
        _activeCV = updatedCV;
      }
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> setActiveCV(int cvId) async {
    final result = await executeAsync<bool>(() async {
      _activeCV = await _portfolioService.setActiveCV(cvId);
      _cvs = _cvs.map((cv) {
        return cv.copyWith(isActive: cv.id == cvId);
      }).toList();
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  Future<bool> deleteCV(int cvId) async {
    final result = await executeAsync<bool>(() async {
      await _portfolioService.deleteCV(cvId);
      _cvs.removeWhere((cv) => cv.id == cvId);
      if (_activeCV?.id == cvId) {
        _activeCV = null;
      }
      notifyListeners();
      return true;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
    return result ?? false;
  }

  // ==================== Helper Methods ====================

  void clearAll() {
    _myPortfolio = null;
    _extendedProfile = null;
    _projects = [];
    _certificates = [];
    _reviews = [];
    _cvs = [];
    _activeCV = null;
    _hasExtendedProfile = false;
    _systemCertificates = [];
    _completedMissions = [];
    _verifiedSkills = [];
    _isSyncing = false;
    resetState();
  }

  /// Find project by ID
  ProjectDto? findProjectById(int projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() => clearAll();

  /// Find certificate by ID
  CertificateDto? findCertificateById(int certificateId) {
    try {
      return _certificates.firstWhere((c) => c.id == certificateId);
    } catch (e) {
      return null;
    }
  }

  /// Find CV by ID
  CVDto? findCVById(int cvId) {
    try {
      return _cvs.firstWhere((cv) => cv.id == cvId);
    } catch (e) {
      return null;
    }
  }
}
