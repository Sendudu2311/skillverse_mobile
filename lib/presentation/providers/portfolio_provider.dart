import 'package:flutter/foundation.dart';
import '../../data/models/portfolio_models.dart';
import '../../data/services/portfolio_service.dart';

class PortfolioProvider with ChangeNotifier {
  final PortfolioService _portfolioService = PortfolioService();

  // State
  CompletePortfolioDto? _myPortfolio;
  ExtendedProfileDto? _extendedProfile;
  List<ProjectDto> _projects = [];
  List<CertificateDto> _certificates = [];
  List<ReviewDto> _reviews = [];
  List<CVDto> _cvs = [];
  CVDto? _activeCV;

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasExtendedProfile = false;

  // Getters
  CompletePortfolioDto? get myPortfolio => _myPortfolio;
  ExtendedProfileDto? get extendedProfile => _extendedProfile;
  List<ProjectDto> get projects => _projects;
  List<CertificateDto> get certificates => _certificates;
  List<ReviewDto> get reviews => _reviews;
  List<CVDto> get cvs => _cvs;
  CVDto? get activeCV => _activeCV;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasExtendedProfile => _hasExtendedProfile;

  // ==================== Extended Profile ====================

  Future<void> checkExtendedProfile() async {
    _setLoading(true);
    try {
      final response = await _portfolioService.checkExtendedProfile();
      _hasExtendedProfile = response.hasExtendedProfile;
      _extendedProfile = response.profile;
      _clearError();
    } catch (e) {
      _setError('Kiểm tra profile thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createExtendedProfile(CreateExtendedProfileRequest request) async {
    _setLoading(true);
    try {
      _extendedProfile = await _portfolioService.createExtendedProfile(request: request);
      _hasExtendedProfile = true;
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Tạo extended profile thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateExtendedProfile(CreateExtendedProfileRequest request) async {
    _setLoading(true);
    try {
      _extendedProfile = await _portfolioService.updateExtendedProfile(request: request);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Cập nhật extended profile thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteExtendedProfile() async {
    _setLoading(true);
    try {
      await _portfolioService.deleteExtendedProfile();
      _extendedProfile = null;
      _hasExtendedProfile = false;
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Xóa extended profile thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyPortfolio() async {
    _setLoading(true);
    try {
      _myPortfolio = await _portfolioService.getMyProfile();
      _extendedProfile = _myPortfolio?.extendedProfile;
      _projects = _myPortfolio?.projects ?? [];
      _certificates = _myPortfolio?.certificates ?? [];
      _reviews = _myPortfolio?.reviews ?? [];
      _activeCV = _myPortfolio?.activeCV;
      _hasExtendedProfile = _extendedProfile != null;
      _clearError();
    } catch (e) {
      _setError('Tải portfolio thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<CompletePortfolioDto?> getPortfolioBySlug(String slug) async {
    _setLoading(true);
    try {
      final portfolio = await _portfolioService.getProfileBySlug(slug);
      _clearError();
      return portfolio;
    } catch (e) {
      _setError('Tải portfolio thất bại: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<CompletePortfolioDto?> getPublicPortfolio(int userId) async {
    _setLoading(true);
    try {
      final portfolio = await _portfolioService.getPublicProfile(userId);
      _clearError();
      return portfolio;
    } catch (e) {
      _setError('Tải portfolio thất bại: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Projects ====================

  Future<void> loadProjects() async {
    _setLoading(true);
    try {
      _projects = await _portfolioService.getUserProjects();
      _clearError();
    } catch (e) {
      _setError('Tải danh sách dự án thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createProject(CreateProjectRequest request) async {
    _setLoading(true);
    try {
      final newProject = await _portfolioService.createProject(request: request);
      _projects.add(newProject);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Tạo dự án thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProject(int projectId, UpdateProjectRequest request) async {
    _setLoading(true);
    try {
      final updatedProject = await _portfolioService.updateProject(
        projectId: projectId,
        request: request,
      );
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = updatedProject;
      }
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Cập nhật dự án thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProject(int projectId) async {
    _setLoading(true);
    try {
      await _portfolioService.deleteProject(projectId);
      _projects.removeWhere((p) => p.id == projectId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Xóa dự án thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Certificates ====================

  Future<void> loadCertificates() async {
    _setLoading(true);
    try {
      _certificates = await _portfolioService.getUserCertificates();
      _clearError();
    } catch (e) {
      _setError('Tải danh sách chứng chỉ thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createCertificate(CreateCertificateRequest request) async {
    _setLoading(true);
    try {
      final newCertificate = await _portfolioService.createCertificate(request: request);
      _certificates.add(newCertificate);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Tạo chứng chỉ thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCertificate(int certificateId) async {
    _setLoading(true);
    try {
      await _portfolioService.deleteCertificate(certificateId);
      _certificates.removeWhere((c) => c.id == certificateId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Xóa chứng chỉ thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Reviews ====================

  Future<void> loadReviews() async {
    _setLoading(true);
    try {
      _reviews = await _portfolioService.getUserReviews();
      _clearError();
    } catch (e) {
      _setError('Tải danh sách đánh giá thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== CV ====================

  Future<void> loadCVs() async {
    _setLoading(true);
    try {
      _cvs = await _portfolioService.getAllCVs();
      _clearError();
    } catch (e) {
      _setError('Tải danh sách CV thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadActiveCV() async {
    _setLoading(true);
    try {
      _activeCV = await _portfolioService.getActiveCV();
      _clearError();
    } catch (e) {
      _setError('Tải CV đang hoạt động thất bại: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> generateCV({GenerateCVRequest? request}) async {
    _setLoading(true);
    try {
      final newCV = await _portfolioService.generateCV(request: request);
      _cvs.add(newCV);
      _activeCV = newCV;
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Tạo CV thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCV(int cvId, UpdateCVRequest request) async {
    _setLoading(true);
    try {
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
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Cập nhật CV thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setActiveCV(int cvId) async {
    _setLoading(true);
    try {
      _activeCV = await _portfolioService.setActiveCV(cvId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Thiết lập CV hoạt động thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCV(int cvId) async {
    _setLoading(true);
    try {
      await _portfolioService.deleteCV(cvId);
      _cvs.removeWhere((cv) => cv.id == cvId);
      if (_activeCV?.id == cvId) {
        _activeCV = null;
      }
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Xóa CV thất bại: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Helper Methods ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearAll() {
    _myPortfolio = null;
    _extendedProfile = null;
    _projects = [];
    _certificates = [];
    _reviews = [];
    _cvs = [];
    _activeCV = null;
    _hasExtendedProfile = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
