import 'package:flutter/material.dart';
import '../../data/models/job_models.dart';
import '../../data/services/job_service.dart';
import '../../core/utils/pagination_helper.dart';
import '../../core/utils/string_helper.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class JobProvider with ChangeNotifier, LoadingStateProviderMixin {
  final JobService _jobService = JobService();

  // ==================== STATE ====================

  // Job detail
  JobPostingResponse? _selectedJob;
  ShortTermJobResponse? _selectedShortTermJob;

  // UI state
  int _selectedTab = 0; // 0 = long-term, 1 = short-term
  String _searchQuery = '';

  // Loading flags
  bool _isApplying = false;
  bool _isSubmittingDeliverable = false;
  bool _isRespondingToOffer = false;
  bool _isLoadingLongTermApps = false;
  String? _longTermApplicationsError;

  // Lazy PaginationHelpers
  PaginationHelper<JobPostingResponse>? _longTermPagination;
  PaginationHelper<ShortTermJobResponse>? _shortTermPagination;
  PaginationHelper<ShortTermApplicationResponse>? _shortTermAppPagination;

  // ==================== PAGINATION HELPERS ====================

  PaginationHelper<JobPostingResponse> get _longTerm {
    _longTermPagination ??= PaginationHelper<JobPostingResponse>(
      fetchPage: (page) async {
        final result = await _jobService.getPublicJobsPaged(
          page: page - 1, // PaginationHelper uses 1-based
          size: 10,
        );
        return PaginatedResponse<JobPostingResponse>(
          data: result.content ?? [],
          currentPage: page,
          totalPages: result.totalPages,
          totalItems: result.totalElements,
          hasMore: !result.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
    return _longTermPagination!;
  }

  PaginationHelper<ShortTermJobResponse> get _shortTerm {
    _shortTermPagination ??= PaginationHelper<ShortTermJobResponse>(
      fetchPage: (page) async {
        final result = await _jobService.getPublicShortTermJobsPaged(
          page: page - 1,
          size: 10,
        );
        return PaginatedResponse<ShortTermJobResponse>(
          data: result.content ?? [],
          currentPage: page,
          totalPages: result.totalPages,
          totalItems: result.totalElements,
          hasMore: !result.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
    return _shortTermPagination!;
  }

  PaginationHelper<ShortTermApplicationResponse> get _shortTermApp {
    _shortTermAppPagination ??= PaginationHelper<ShortTermApplicationResponse>(
      fetchPage: (page) async {
        final result = await _jobService.getMyShortTermApplicationsPaged(
          page: page - 1,
          size: 10,
        );
        return PaginatedResponse<ShortTermApplicationResponse>(
          data: result.content ?? [],
          currentPage: page,
          totalPages: result.totalPages,
          totalItems: result.totalElements,
          hasMore: !result.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
    return _shortTermAppPagination!;
  }

  // ==================== GETTERS ====================

  // Long-term jobs (paginated)
  List<JobPostingResponse> get longTermJobs => _longTerm.items;
  bool get isLoadingLongTermJobs => _longTerm.isInitialLoading;
  bool get isLoadingMoreLongTermJobs => _longTerm.isLoadingMore;
  bool get hasMoreLongTermJobs => _longTerm.hasMore;
  bool get hasErrorLongTermJobs => _longTerm.hasError;
  String? get longTermJobsError => _longTerm.error;

  // Short-term jobs (paginated)
  List<ShortTermJobResponse> get shortTermJobs => _shortTerm.items;
  bool get isLoadingShortTermJobs => _shortTerm.isInitialLoading;
  bool get isLoadingMoreShortTermJobs => _shortTerm.isLoadingMore;
  bool get hasMoreShortTermJobs => _shortTerm.hasMore;
  bool get hasErrorShortTermJobs => _shortTerm.hasError;
  String? get shortTermJobsError => _shortTerm.error;

  // Short-term applications (paginated)
  List<ShortTermApplicationResponse> get myShortTermApplications =>
      _shortTermApp.items;
  bool get isLoadingShortTermApps => _shortTermApp.isInitialLoading;
  bool get isLoadingMoreShortTermApps => _shortTermApp.isLoadingMore;
  bool get hasMoreShortTermApps => _shortTermApp.hasMore;
  bool get hasErrorShortTermApps => _shortTermApp.hasError;
  String? get shortTermAppsError => _shortTermApp.error;

  // Long-term applications (simple list — no server-side pagination)
  List<JobApplicationResponse> _longTermApplications = [];
  List<JobApplicationResponse> get myLongTermApplications =>
      _longTermApplications;
  bool get hasErrorLongTermApps => _longTermApplicationsError != null;
  String? get longTermApplicationsError => _longTermApplicationsError;
  bool get isRespondingToOffer => _isRespondingToOffer;

  // Job detail
  JobPostingResponse? get selectedJob => _selectedJob;
  ShortTermJobResponse? get selectedShortTermJob => _selectedShortTermJob;

  // UI state
  int get selectedTab => _selectedTab;
  String get searchQuery => _searchQuery;

  // Loading flags
  bool get isApplying => _isApplying;
  bool get isSubmittingDeliverable => _isSubmittingDeliverable;

  // Aliases for existing code compatibility
  bool get isLoadingJobs => isLoadingLongTermJobs || isLoadingShortTermJobs;
  bool get isLoadingApplications =>
      _isLoadingLongTermApps || isLoadingShortTermApps;

  /// Check if user has already applied to a long-term job
  bool hasAppliedToJob(int jobId) {
    return myLongTermApplications.any((app) => app.jobId == jobId);
  }

  /// Check if user has already applied to a short-term job
  bool hasAppliedToShortTermJob(int jobId) {
    return myShortTermApplications.any((app) => app.jobId == jobId);
  }

  // ==================== TAB CONTROL ====================

  void setSelectedTab(int tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  // ==================== LONG-TERM JOBS (PAGINATED) ====================

  /// Load first page of public long-term jobs
  Future<void> loadPublicJobs({bool refresh = false}) async {
    if (refresh) {
      await _longTerm.refresh();
    } else {
      await _longTerm.loadFirstPage();
    }
  }

  /// Load next page of long-term jobs
  Future<void> loadMoreLongTermJobs() async {
    await _longTerm.loadNextPage();
  }

  // ==================== SHORT-TERM JOBS (PAGINATED) ====================

  /// Load first page of published short-term jobs
  Future<void> loadShortTermJobs({bool refresh = false}) async {
    if (refresh) {
      await _shortTerm.refresh();
    } else {
      await _shortTerm.loadFirstPage();
    }
  }

  /// Load next page of short-term jobs
  Future<void> loadMoreShortTermJobs() async {
    await _shortTerm.loadNextPage();
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
    _shortTermPagination?.dispose();
    _shortTermPagination = PaginationHelper<ShortTermJobResponse>(
      fetchPage: (page) async {
        final r = await _jobService.searchShortTermJobs(
          search: search,
          minBudget: minBudget,
          maxBudget: maxBudget,
          isRemote: isRemote,
          urgency: urgency,
          page: page - 1,
          size: 10,
        );
        return PaginatedResponse<ShortTermJobResponse>(
          data: r.content ?? [],
          currentPage: page,
          totalPages: r.totalPages,
          totalItems: r.totalElements,
          hasMore: !r.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
    await _shortTermPagination!.loadFirstPage();
  }

  // ==================== JOB DETAIL ====================

  /// Load long-term job details
  Future<void> loadJobDetails(int jobId) async {
    await executeAsync(() async {
      _selectedJob = await _jobService.getJobDetails(jobId);
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi tải chi tiết: ${e.toString()}');
  }

  /// Load short-term job details
  Future<void> loadShortTermJobDetails(int jobId) async {
    await executeAsync(() async {
      _selectedShortTermJob = await _jobService.getShortTermJobDetails(jobId);
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi tải chi tiết: ${e.toString()}');
  }

  // ==================== APPLICATIONS ====================

  /// Apply to a long-term job
  Future<bool> applyToJob(int jobId, {String? coverLetter}) async {
    _isApplying = true;
    notifyListeners();

    try {
      final request = ApplyJobRequest(coverLetter: coverLetter);
      await _jobService.applyToJob(jobId, request);
      setError(null);
      await loadMyLongTermApplications();
      return true;
    } catch (e) {
      setError('Ứng tuyển thất bại: ${e.toString()}');
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
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

  /// Load current user's long-term applications (non-paginated)
  Future<void> loadMyLongTermApplications({bool refresh = false}) async {
    if (_isLoadingLongTermApps) return;
    _isLoadingLongTermApps = true;
    _longTermApplicationsError = null;
    notifyListeners();

    try {
      if (refresh) _longTermApplications = [];
      final apps = await _jobService.getMyApplications();
      _longTermApplications = apps;
    } catch (e) {
      _longTermApplicationsError = 'Lỗi tải đơn ứng tuyển: ${e.toString()}';
    } finally {
      _isLoadingLongTermApps = false;
      notifyListeners();
    }
  }

  /// Load first page of short-term applications (paginated)
  Future<void> loadMyShortTermApplications({bool refresh = false}) async {
    if (refresh) {
      await _shortTermApp.refresh();
    } else {
      await _shortTermApp.loadFirstPage();
    }
  }

  /// Load next page of short-term applications
  Future<void> loadMoreShortTermApplications() async {
    await _shortTermApp.loadNextPage();
  }

  /// Submit deliverables for a short-term job
  Future<bool> submitDeliverables(SubmitDeliverableRequest request) async {
    _isSubmittingDeliverable = true;
    notifyListeners();

    try {
      final updated = await _jobService.submitDeliverables(request);
      final idx = myShortTermApplications.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        _shortTermApp.updateItem(idx, updated);
      }
      setError(null);
      return true;
    } catch (e) {
      setError('Nộp bài thất bại: ${e.toString()}');
      return false;
    } finally {
      _isSubmittingDeliverable = false;
      notifyListeners();
    }
  }

  /// Candidate responds to a long-term job offer (OFFER_ACCEPTED or OFFER_REJECTED)
  Future<bool> respondToOffer({
    required int applicationId,
    required bool accept,
    String? candidateOfferResponse,
    int? counterSalaryAmount,
    String? counterAdditionalRequirements,
  }) async {
    _isRespondingToOffer = true;
    notifyListeners();
    try {
      final updated = await _jobService.respondToOffer(
        applicationId: applicationId,
        accept: accept,
        candidateOfferResponse: candidateOfferResponse,
        counterSalaryAmount: counterSalaryAmount,
        counterAdditionalRequirements: counterAdditionalRequirements,
      );
      final idx = _longTermApplications.indexWhere((a) => a.id == updated.id);
      if (idx != -1) _longTermApplications[idx] = updated;
      setError(null);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      _isRespondingToOffer = false;
      notifyListeners();
    }
  }

  /// Withdraw a short-term application
  Future<bool> withdrawApplication(int applicationId) async {
    try {
      await _jobService.withdrawShortTermApplication(applicationId);
      _shortTermApp.removeWhere((app) => app.id == applicationId);
      setError(null);
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
    if (_searchQuery.isEmpty) return longTermJobs;
    final q = StringHelper.removeDiacritics(_searchQuery.toLowerCase());
    return longTermJobs.where((job) {
      normalize(String? s) =>
          StringHelper.removeDiacritics(s?.toLowerCase() ?? '');
      return normalize(job.title).contains(q) ||
          normalize(job.description).contains(q) ||
          normalize(job.recruiterCompanyName).contains(q);
    }).toList();
  }

  // ==================== REFRESH ====================

  /// Refresh all data
  Future<void> refresh() async {
    if (_selectedTab == 0) {
      await loadPublicJobs(refresh: true);
    } else {
      if (_searchQuery.isNotEmpty) {
        await searchShortTermJobs(search: _searchQuery);
      } else {
        await loadShortTermJobs(refresh: true);
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
