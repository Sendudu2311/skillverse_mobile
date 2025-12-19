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

  // Getters
  CompletePortfolioDto? get myPortfolio => _myPortfolio;
  ExtendedProfileDto? get extendedProfile => _extendedProfile;
  List<ProjectDto> get projects => _projects;
  List<CertificateDto> get certificates => _certificates;
  List<ReviewDto> get reviews => _reviews;
  List<CVDto> get cvs => _cvs;
  CVDto? get activeCV => _activeCV;
  bool get hasExtendedProfile => _hasExtendedProfile;

  // ==================== Extended Profile ====================

  Future<void> checkExtendedProfile() async {
    await executeAsync(
      () async {
        final response = await _portfolioService.checkExtendedProfile();
        _hasExtendedProfile = response.hasExtendedProfile;
        _extendedProfile = response.profile;
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  Future<bool> createExtendedProfile(CreateExtendedProfileRequest request) async {
    final result = await executeAsync<bool>(
      () async {
        _extendedProfile = await _portfolioService.createExtendedProfile(request: request);
        _hasExtendedProfile = true;
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> updateExtendedProfile(CreateExtendedProfileRequest request) async {
    final result = await executeAsync<bool>(
      () async {
        _extendedProfile = await _portfolioService.updateExtendedProfile(request: request);
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> deleteExtendedProfile() async {
    final result = await executeAsync<bool>(
      () async {
        await _portfolioService.deleteExtendedProfile();
        _extendedProfile = null;
        _hasExtendedProfile = false;
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<void> loadMyPortfolio() async {
    await executeAsync(
      () async {
        _myPortfolio = await _portfolioService.getMyProfile();
        _extendedProfile = _myPortfolio?.extendedProfile;
        _projects = _myPortfolio?.projects ?? [];
        _certificates = _myPortfolio?.certificates ?? [];
        _reviews = _myPortfolio?.reviews ?? [];
        _activeCV = _myPortfolio?.activeCV;
        _hasExtendedProfile = _extendedProfile != null;
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  Future<CompletePortfolioDto?> getPortfolioBySlug(String slug) async {
    return await executeAsync(
      () async {
        return await _portfolioService.getProfileBySlug(slug);
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  Future<CompletePortfolioDto?> getPublicPortfolio(int userId) async {
    return await executeAsync(
      () async {
        return await _portfolioService.getPublicProfile(userId);
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  // ==================== Projects ====================

  Future<void> loadProjects() async {
    await executeAsync(
      () async {
        _projects = await _portfolioService.getUserProjects();
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  Future<bool> createProject(CreateProjectRequest request) async {
    final result = await executeAsync<bool>(
      () async {
        final newProject = await _portfolioService.createProject(request: request);
        _projects.add(newProject);
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> updateProject(int projectId, UpdateProjectRequest request) async {
    final result = await executeAsync<bool>(
      () async {
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
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> deleteProject(int projectId) async {
    final result = await executeAsync<bool>(
      () async {
        await _portfolioService.deleteProject(projectId);
        _projects.removeWhere((p) => p.id == projectId);
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  // ==================== Certificates ====================

  Future<void> loadCertificates() async {
    await executeAsync(
      () async {
        _certificates = await _portfolioService.getUserCertificates();
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  Future<bool> createCertificate(CreateCertificateRequest request) async {
    final result = await executeAsync<bool>(
      () async {
        final newCertificate = await _portfolioService.createCertificate(request: request);
        _certificates.add(newCertificate);
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> deleteCertificate(int certificateId) async {
    final result = await executeAsync<bool>(
      () async {
        await _portfolioService.deleteCertificate(certificateId);
        _certificates.removeWhere((c) => c.id == certificateId);
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  // ==================== Reviews ====================

  Future<void> loadReviews() async {
    await executeAsync(
      () async {
        _reviews = await _portfolioService.getUserReviews();
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  // ==================== CV ====================

  Future<void> loadCVs() async {
    await executeAsync(
      () async {
        _cvs = await _portfolioService.getAllCVs();
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  Future<void> loadActiveCV() async {
    await executeAsync(
      () async {
        _activeCV = await _portfolioService.getActiveCV();
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  Future<bool> generateCV({GenerateCVRequest? request}) async {
    final result = await executeAsync<bool>(
      () async {
        final newCV = await _portfolioService.generateCV(request: request);
        _cvs.add(newCV);
        _activeCV = newCV;
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> updateCV(int cvId, UpdateCVRequest request) async {
    final result = await executeAsync<bool>(
      () async {
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
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> setActiveCV(int cvId) async {
    final result = await executeAsync<bool>(
      () async {
        _activeCV = await _portfolioService.setActiveCV(cvId);
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  Future<bool> deleteCV(int cvId) async {
    final result = await executeAsync<bool>(
      () async {
        await _portfolioService.deleteCV(cvId);
        _cvs.removeWhere((cv) => cv.id == cvId);
        if (_activeCV?.id == cvId) {
          _activeCV = null;
        }
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
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
