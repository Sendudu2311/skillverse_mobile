import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../data/services/task_board_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../core/utils/string_helper.dart';

enum SortOption { newest, oldest, progress, title }

/// Manages the roadmap list, filtering/sorting, and lifecycle operations
/// (activate, pause, delete, restore).
///
/// For single-roadmap detail and progress use [RoadmapDetailProvider].
/// For AI generation flow use [RoadmapGenerateProvider].
class RoadmapProvider with ChangeNotifier, LoadingStateProviderMixin {
  final RoadmapService _roadmapService = RoadmapService();

  // List state
  List<RoadmapSessionSummary> _roadmaps = [];
  Map<String, int> _statusCounts = {};

  // Filtering and sorting state
  String _searchQuery = '';
  SortOption _sortBy = SortOption.newest;
  String _filterExperience = 'all';

  // Loading state for recycle bin
  bool _isLoadingDeleted = false;
  bool _hasLoadedDeleted = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<RoadmapSessionSummary> get roadmaps => _roadmaps;
  Map<String, int> get statusCounts => _statusCounts;

  String get searchQuery => _searchQuery;
  SortOption get sortBy => _sortBy;
  String get filterExperience => _filterExperience;
  List<RoadmapSessionSummary> get deletedRoadmaps => filteredDeletedRoadmaps;
  bool get isLoadingDeleted => _isLoadingDeleted;
  bool get hasLoadedDeleted => _hasLoadedDeleted;

  /// Get filtered and sorted roadmaps (excludes DELETED)
  List<RoadmapSessionSummary> get filteredRoadmaps {
    var filtered = _roadmaps.where((r) {
      final s = (r.status ?? 'ACTIVE').toUpperCase();
      return s != 'DELETED' && s != 'SOFT_DELETED';
    }).toList();

    return _applyFiltersAndSorting(filtered);
  }

  /// Get filtered and sorted deleted roadmaps
  List<RoadmapSessionSummary> get filteredDeletedRoadmaps {
    var filtered = _roadmaps.where((r) {
      final s = (r.status ?? '').toUpperCase();
      return s == 'DELETED' || s == 'SOFT_DELETED';
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = StringHelper.removeDiacritics(_searchQuery);
      filtered = filtered
          .where(
            (r) =>
                StringHelper.removeDiacritics(r.title).contains(query) ||
                StringHelper.removeDiacritics(r.originalGoal).contains(query),
          )
          .toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  List<RoadmapSessionSummary> _applyFiltersAndSorting(
    List<RoadmapSessionSummary> input,
  ) {
    var list = List<RoadmapSessionSummary>.from(input);

    if (_searchQuery.isNotEmpty) {
      final query = StringHelper.removeDiacritics(_searchQuery);
      list = list
          .where(
            (r) =>
                StringHelper.removeDiacritics(r.title).contains(query) ||
                StringHelper.removeDiacritics(r.originalGoal).contains(query),
          )
          .toList();
    }

    if (_filterExperience != 'all') {
      list = list.where((r) {
        final exp = r.experienceLevel.toLowerCase();
        final normalizedExp = (exp == 'mới bắt đầu')
            ? 'beginner'
            : (exp == 'trung cấp')
            ? 'intermediate'
            : (exp == 'nâng cao')
            ? 'advanced'
            : exp;
        return normalizedExp == _filterExperience.toLowerCase();
      }).toList();
    }

    list.sort((a, b) {
      final aActive = (a.status ?? '').toUpperCase() == 'ACTIVE' ? 0 : 1;
      final bActive = (b.status ?? '').toUpperCase() == 'ACTIVE' ? 0 : 1;
      if (aActive != bActive) return aActive.compareTo(bActive);

      switch (_sortBy) {
        case SortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
        case SortOption.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case SortOption.progress:
          return b.progressPercentage.compareTo(a.progressPercentage);
        case SortOption.title:
          return a.title.compareTo(b.title);
      }
    });

    return list;
  }

  // ============================================================================
  // SETTERS
  // ============================================================================

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(SortOption option) {
    _sortBy = option;
    notifyListeners();
  }

  void setFilterExperience(String filter) {
    _filterExperience = filter;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _sortBy = SortOption.newest;
    _filterExperience = 'all';
    notifyListeners();
  }

  // ============================================================================
  // LOAD
  // ============================================================================

  Future<void> loadUserRoadmaps({bool force = false}) async {
    if (!force && _roadmaps.isNotEmpty) return;

    await executeAsync(
      () async {
        final data = await _roadmapService.getUserRoadmaps(
          includeDeleted: true,
        );
        _roadmaps = data;
        notifyListeners();
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('timeout')) {
          return 'Không có kết nối Internet';
        }
        return 'Lỗi tải danh sách lộ trình: ${error.toString()}';
      },
    );
  }

  Future<void> loadDeletedRoadmaps({bool force = false}) async {
    if (!force && _hasLoadedDeleted) return;

    _isLoadingDeleted = true;
    notifyListeners();

    try {
      await loadUserRoadmaps(force: true);
      _hasLoadedDeleted = true;
    } catch (e) {
      debugPrint('🚨 Error loading deleted roadmaps: $e');
    } finally {
      _isLoadingDeleted = false;
      notifyListeners();
    }
  }

  Future<void> loadStatusCounts() async {
    try {
      _statusCounts = await _roadmapService.getRoadmapStatusCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading status counts: $e');
    }
  }

  Future<void> refresh() async {
    await loadUserRoadmaps(force: true);
  }

  // ============================================================================
  // LIFECYCLE MANAGEMENT
  // ============================================================================

  Future<bool> activateRoadmap(int sessionId) async {
    try {
      await _roadmapService.activateRoadmap(sessionId);
      await loadUserRoadmaps(force: true);
      return true;
    } catch (e) {
      debugPrint('Error activating roadmap: $e');
      return false;
    }
  }

  Future<bool> pauseRoadmap(int sessionId) async {
    try {
      await _roadmapService.pauseRoadmap(sessionId);
      await loadUserRoadmaps(force: true);
      try {
        await TaskBoardService().archiveRoadmapTasks(sessionId);
      } catch (e) {
        debugPrint('Auto-archive failed: $e');
      }
      return true;
    } catch (e) {
      debugPrint('Error pausing roadmap: $e');
      return false;
    }
  }

  Future<bool> softDeleteRoadmap(int sessionId) async {
    try {
      debugPrint(
        '🗑️ [RoadmapProvider] Starting soft-delete for session: $sessionId',
      );

      final index = _roadmaps.indexWhere((r) => r.sessionId == sessionId);
      if (index != -1) {
        _roadmaps[index] = _roadmaps[index].copyWith(status: 'DELETED');
        notifyListeners();
      }

      await _roadmapService.softDeleteRoadmap(sessionId);
      await loadStatusCounts();
      try {
        await TaskBoardService().archiveRoadmapTasks(sessionId);
      } catch (e) {
        debugPrint('Auto-archive failed: $e');
      }
      return true;
    } catch (e) {
      debugPrint('❌ [RoadmapProvider] Error deleting roadmap $sessionId: $e');
      await loadUserRoadmaps(force: true);
      return false;
    }
  }

  Future<bool> permanentDeleteRoadmap(int sessionId) async {
    try {
      await _roadmapService.permanentDeleteRoadmap(sessionId);
      _roadmaps.removeWhere((r) => r.sessionId == sessionId);
      await loadStatusCounts();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error permanently deleting roadmap: $e');
      return false;
    }
  }

  Future<bool> restoreRoadmap(int sessionId) async {
    try {
      debugPrint(
        '🔄 [RoadmapProvider] Starting restore for session: $sessionId',
      );

      final index = _roadmaps.indexWhere((r) => r.sessionId == sessionId);
      if (index != -1) {
        _roadmaps[index] = _roadmaps[index].copyWith(status: 'ACTIVE');
        notifyListeners();
      }

      await _roadmapService.restoreRoadmap(sessionId);
      await loadUserRoadmaps(force: true);
      await loadStatusCounts();
      return true;
    } catch (e) {
      debugPrint('❌ [RoadmapProvider] Error restoring roadmap $sessionId: $e');
      await loadUserRoadmaps(force: true);
      return false;
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void removeUserRoadmap(int sessionId) {
    _roadmaps.removeWhere((r) => r.sessionId == sessionId);
    notifyListeners();
  }

  RoadmapSessionSummary? findRoadmapBySessionId(int sessionId) {
    try {
      return _roadmaps.firstWhere((r) => r.sessionId == sessionId);
    } catch (e) {
      return null;
    }
  }

}
