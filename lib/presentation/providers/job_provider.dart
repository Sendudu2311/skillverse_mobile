import 'package:flutter/material.dart';
import '../../data/models/job_models.dart';
import '../../data/services/job_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class JobProvider with ChangeNotifier, LoadingStateProviderMixin {
  final JobService _jobService = JobService();

  // ==================== STATE ====================

  // Long-term jobs
  List<JobPostingResponse> _longTermJobs = [];
  List<JobApplicationResponse> _myLongTermApplications = [];

  // Short-term jobs
  List<ShortTermJobResponse> _shortTermJobs = [];
  List<ShortTermApplicationResponse> _myShortTermApplications = [];

  // Job detail
  JobPostingResponse? _selectedJob;
  ShortTermJobResponse? _selectedShortTermJob;

  // UI state
  int _selectedTab = 0; // 0 = long-term, 1 = short-term
  String _searchQuery = '';
  bool _isLoadingJobs = false;
  bool _isLoadingApplications = false;
  bool _isApplying = false;
  bool _isSubmittingDeliverable = false;

  // ==================== GETTERS ====================

  List<JobPostingResponse> get longTermJobs => _longTermJobs;
  List<ShortTermJobResponse> get shortTermJobs => _shortTermJobs;
  List<JobApplicationResponse> get myLongTermApplications =>
      _myLongTermApplications;
  List<ShortTermApplicationResponse> get myShortTermApplications =>
      _myShortTermApplications;
  JobPostingResponse? get selectedJob => _selectedJob;
  ShortTermJobResponse? get selectedShortTermJob => _selectedShortTermJob;
  int get selectedTab => _selectedTab;
  String get searchQuery => _searchQuery;
  bool get isLoadingJobs => _isLoadingJobs;
  bool get isLoadingApplications => _isLoadingApplications;
  bool get isApplying => _isApplying;
  bool get isSubmittingDeliverable => _isSubmittingDeliverable;

  /// Check if user has already applied to a long-term job
  bool hasAppliedToJob(int jobId) {
    return _myLongTermApplications.any((app) => app.jobId == jobId);
  }

  /// Check if user has already applied to a short-term job
  bool hasAppliedToShortTermJob(int jobId) {
    return _myShortTermApplications.any((app) => app.jobId == jobId);
  }

  // ==================== TAB CONTROL ====================

  void setSelectedTab(int tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  // ==================== LONG-TERM JOBS ====================

  /// Load all public long-term jobs
  Future<void> loadPublicJobs() async {
    _isLoadingJobs = true;
    notifyListeners();

    try {
      _longTermJobs = await _jobService.getPublicJobs();
      setError(null);
    } catch (e) {
      setError('Lỗi tải việc làm: ${e.toString()}');
    } finally {
      _isLoadingJobs = false;
      notifyListeners();
    }
  }

  /// Load long-term job details
  Future<void> loadJobDetails(int jobId) async {
    await executeAsync(() async {
      _selectedJob = await _jobService.getJobDetails(jobId);
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi tải chi tiết: ${e.toString()}');
  }

  /// Apply to a long-term job
  Future<bool> applyToJob(int jobId, {String? coverLetter}) async {
    _isApplying = true;
    notifyListeners();

    try {
      final request = ApplyJobRequest(coverLetter: coverLetter);
      await _jobService.applyToJob(jobId, request);
      setError(null);
      // Reload applications after applying
      await loadMyApplications();
      return true;
    } catch (e) {
      setError('Ứng tuyển thất bại: ${e.toString()}');
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// Load current user's long-term applications
  Future<void> loadMyApplications() async {
    _isLoadingApplications = true;
    notifyListeners();

    try {
      _myLongTermApplications = await _jobService.getMyApplications();
      setError(null);
    } catch (e) {
      setError('Lỗi tải đơn ứng tuyển: ${e.toString()}');
    } finally {
      _isLoadingApplications = false;
      notifyListeners();
    }
  }

  // ==================== SHORT-TERM JOBS ====================

  /// Load all published short-term jobs
  Future<void> loadShortTermJobs() async {
    _isLoadingJobs = true;
    notifyListeners();

    try {
      _shortTermJobs = await _jobService.getPublicShortTermJobs();
      setError(null);
    } catch (e) {
      setError('Lỗi tải việc ngắn hạn: ${e.toString()}');
    } finally {
      _isLoadingJobs = false;
      notifyListeners();
    }
  }

  /// Search short-term jobs with filters
  Future<void> searchShortTermJobs({
    String? search,
    double? minBudget,
    double? maxBudget,
    bool? isRemote,
    String? urgency,
  }) async {
    _searchQuery = search ?? '';
    _isLoadingJobs = true;
    notifyListeners();

    try {
      final result = await _jobService.searchShortTermJobs(
        search: search,
        minBudget: minBudget,
        maxBudget: maxBudget,
        isRemote: isRemote,
        urgency: urgency,
      );
      _shortTermJobs = result.content ?? [];
      setError(null);
    } catch (e) {
      setError('Lỗi tìm kiếm: ${e.toString()}');
    } finally {
      _isLoadingJobs = false;
      notifyListeners();
    }
  }

  /// Load short-term job details
  Future<void> loadShortTermJobDetails(int jobId) async {
    await executeAsync(() async {
      _selectedShortTermJob = await _jobService.getShortTermJobDetails(jobId);
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi tải chi tiết: ${e.toString()}');
  }

  /// Apply to a short-term job
  Future<bool> applyToShortTermJob(
    int jobId, {
    String? coverLetter,
    double? proposedPrice,
    String? proposedDuration,
    List<String>? portfolio,
  }) async {
    _isApplying = true;
    notifyListeners();

    try {
      final request = ApplyShortTermJobRequest(
        coverLetter: coverLetter,
        proposedPrice: proposedPrice,
        proposedDuration: proposedDuration,
        portfolio: portfolio,
      );
      await _jobService.applyToShortTermJob(jobId, request);
      setError(null);
      await loadMyShortTermApplications();
      return true;
    } catch (e) {
      setError('Ứng tuyển thất bại: ${e.toString()}');
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// Load current user's short-term applications
  Future<void> loadMyShortTermApplications() async {
    _isLoadingApplications = true;
    notifyListeners();

    try {
      _myShortTermApplications =
          await _jobService.getMyShortTermApplications();
      setError(null);
    } catch (e) {
      setError('Lỗi tải đơn ứng tuyển: ${e.toString()}');
    } finally {
      _isLoadingApplications = false;
      notifyListeners();
    }
  }

  /// Submit deliverables for a short-term job (worker bàn giao công việc)
  Future<bool> submitDeliverables(SubmitDeliverableRequest request) async {
    _isSubmittingDeliverable = true;
    notifyListeners();

    try {
      final updated = await _jobService.submitDeliverables(request);
      final idx = _myShortTermApplications.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        _myShortTermApplications[idx] = updated;
      }
      setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      setError('Nộp bài thất bại: ${e.toString()}');
      return false;
    } finally {
      _isSubmittingDeliverable = false;
      notifyListeners();
    }
  }

  /// Withdraw a short-term application
  Future<bool> withdrawApplication(int applicationId) async {
    try {
      await _jobService.withdrawShortTermApplication(applicationId);
      _myShortTermApplications
          .removeWhere((app) => app.id == applicationId);
      setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      setError('Rút đơn thất bại: ${e.toString()}');
      return false;
    }
  }

  // ==================== SEARCH ====================

  /// Search jobs based on current tab
  Future<void> searchJobs(String query) async {
    _searchQuery = query;
    if (_selectedTab == 0) {
      // Filter long-term locally (no search endpoint)
      notifyListeners();
    } else {
      await searchShortTermJobs(search: query);
    }
  }

  /// Get filtered long-term jobs (client-side search)
  List<JobPostingResponse> get filteredLongTermJobs {
    if (_searchQuery.isEmpty) return _longTermJobs;
    final q = _searchQuery.toLowerCase();
    return _longTermJobs.where((job) {
      return (job.title?.toLowerCase().contains(q) ?? false) ||
          (job.description?.toLowerCase().contains(q) ?? false) ||
          (job.recruiterCompanyName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ==================== REFRESH ====================

  /// Refresh all data
  Future<void> refresh() async {
    if (_selectedTab == 0) {
      await loadPublicJobs();
    } else {
      if (_searchQuery.isNotEmpty) {
        await searchShortTermJobs(search: _searchQuery);
      } else {
        await loadShortTermJobs();
      }
    }
  }

  /// Clear selected job
  void clearSelectedJob() {
    _selectedJob = null;
    _selectedShortTermJob = null;
    notifyListeners();
  }
}
