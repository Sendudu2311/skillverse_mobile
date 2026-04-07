import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../data/services/journey_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../core/utils/string_helper.dart';

enum SortOption { newest, oldest, progress, title }

class RoadmapProvider with ChangeNotifier, LoadingStateProviderMixin {
  final RoadmapService _roadmapService = RoadmapService();

  // AI Roadmap V2 state
  List<RoadmapSessionSummary> _roadmaps = [];
  RoadmapResponse? _currentRoadmap;
  Map<String, QuestProgress> _progressMap = {};
  List<ValidationResult> _validationResults = [];
  List<ClarificationQuestion> _clarificationQuestions = [];

  // Filtering and sorting state
  String _searchQuery = '';
  SortOption _sortBy = SortOption.newest;
  String _filterExperience = 'all';

  // Generation state
  bool _isGenerating = false;
  String? _generationError;

  // Roadmap lifecycle counts (HUD sync)
  Map<String, int> _statusCounts = {};

  // Loading state for recycle bin
  bool _isLoadingDeleted = false;
  bool _hasLoadedDeleted = false;

  // Legacy state (for backward compatibility)
  List<Roadmap> _legacyRoadmaps = [];
  List<Roadmap> _legacyUserRoadmaps = [];

  // ============================================================================
  // GETTERS
  // ============================================================================

  List<RoadmapSessionSummary> get roadmaps => _roadmaps;
  RoadmapResponse? get currentRoadmap => _currentRoadmap;
  Map<String, QuestProgress> get progressMap => _progressMap;
  List<ValidationResult> get validationResults => _validationResults;
  List<ClarificationQuestion> get clarificationQuestions =>
      _clarificationQuestions;

  String get searchQuery => _searchQuery;
  SortOption get sortBy => _sortBy;
  String get filterExperience => _filterExperience;
  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;
  Map<String, int> get statusCounts => _statusCounts;
  List<RoadmapSessionSummary> get deletedRoadmaps => filteredDeletedRoadmaps;
  bool get isLoadingDeleted => _isLoadingDeleted;
  bool get hasLoadedDeleted => _hasLoadedDeleted;

  // Legacy getters
  @Deprecated('Use roadmaps instead')
  List<Roadmap> get legacyRoadmaps => _legacyRoadmaps;
  @Deprecated('Use roadmaps instead')
  List<Roadmap> get userRoadmaps => _legacyUserRoadmaps;

  /// Get filtered and sorted roadmaps (excludes DELETED)
  List<RoadmapSessionSummary> get filteredRoadmaps {
    var filtered = _roadmaps.where((r) {
      final s = (r.status ?? 'ACTIVE').toUpperCase();
      return s != 'DELETED' && s != 'SOFT_DELETED';
    }).toList();

    // Apply filters and sorting
    return _applyFiltersAndSorting(filtered);
  }

  /// Get filtered and sorted deleted roadmaps
  List<RoadmapSessionSummary> get filteredDeletedRoadmaps {
    var filtered = _roadmaps.where((r) {
      final s = (r.status ?? '').toUpperCase();
      return s == 'DELETED' || s == 'SOFT_DELETED';
    }).toList();

    // Apply filters and sorting (pinned ACTIVE doesn't apply here)
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

  /// Shared filtering and sorting logic for non-deleted roadmaps
  List<RoadmapSessionSummary> _applyFiltersAndSorting(
    List<RoadmapSessionSummary> input,
  ) {
    var list = List<RoadmapSessionSummary>.from(input);

    // Apply search filter
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

    // Apply experience filter
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

    // Apply sorting — ACTIVE items always pinned to top
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
  // AI ROADMAP V2 METHODS
  // ============================================================================

  /// Load all roadmap sessions for current user (including deleted)
  Future<void> loadUserRoadmaps({bool force = false}) async {
    if (!force && _roadmaps.isNotEmpty) return;

    await executeAsync(
      () async {
        // ALWAYS include deleted so we have a unified list for both tabs
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

  /// Ensure all roadmaps (including deleted) are loaded
  Future<void> loadDeletedRoadmaps({bool force = false}) async {
    if (!force && _hasLoadedDeleted) return;

    _isLoadingDeleted = true;
    notifyListeners();

    try {
      // With the unified list strategy, this just ensures the main list is loaded with deleted items
      await loadUserRoadmaps(force: true);
      _hasLoadedDeleted = true;
    } catch (e) {
      debugPrint('🚨 Error loading deleted roadmaps: $e');
    } finally {
      _isLoadingDeleted = false;
      notifyListeners();
    }
  }

  /// Load a specific roadmap by ID
  Future<RoadmapResponse?> loadRoadmapById(int sessionId) async {
    return await executeAsync<RoadmapResponse>(
      () async {
        _currentRoadmap = await _roadmapService.getRoadmapById(sessionId);

        // Update progress map from response
        if (_currentRoadmap?.progress != null) {
          _progressMap = Map<String, QuestProgress>.from(
            _currentRoadmap!.progress!,
          );
        } else {
          _progressMap = {};
        }

        notifyListeners();
        return _currentRoadmap!;
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('404')) {
          return 'Không tìm thấy lộ trình';
        }
        return 'Lỗi tải lộ trình: ${error.toString()}';
      },
    );
  }

  /// Pre-validate roadmap generation request
  Future<List<ValidationResult>> preValidate(
    GenerateRoadmapRequest request,
  ) async {
    final result = await executeAsync(
      () async {
        _validationResults = await _roadmapService.preValidate(request);
        notifyListeners();
        return _validationResults;
      },
      errorMessageBuilder: (error) {
        return 'Lỗi xác thực: ${error.toString()}';
      },
    );
    return result ?? [];
  }

  /// Generate a new AI roadmap
  Future<RoadmapResponse?> generateRoadmap(
    GenerateRoadmapRequest request,
  ) async {
    _isGenerating = true;
    _generationError = null;
    notifyListeners();

    try {
      final roadmap = await _roadmapService.generateRoadmap(request);
      _currentRoadmap = roadmap;

      // Reload user roadmaps to include the new one
      await loadUserRoadmaps();

      _isGenerating = false;
      notifyListeners();
      return roadmap;
    } catch (e) {
      debugPrint('🚨 RoadmapProvider Generation Error: $e');
      _generationError = e.toString();
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  /// Get clarification questions for a roadmap request
  Future<List<ClarificationQuestion>> getClarificationQuestions(
    GenerateRoadmapRequest request,
  ) async {
    final result = await executeAsync(
      () async {
        _clarificationQuestions = await _roadmapService.clarify(request);
        notifyListeners();
        return _clarificationQuestions;
      },
      errorMessageBuilder: (error) {
        return 'Lỗi lấy câu hỏi làm rõ: ${error.toString()}';
      },
    );
    return result ?? [];
  }

  /// Update quest progress
  Future<ProgressResponse?> updateQuestProgress({
    required int sessionId,
    required String questId,
    required bool completed,
  }) async {
    return await executeAsync(
      () async {
        final response = await _roadmapService.updateQuestProgress(
          sessionId: sessionId,
          questId: questId,
          completed: completed,
        );

        // Update local progress map
        if (completed) {
          _progressMap[questId] = QuestProgress(
            questId: questId,
            status: ProgressStatus.completed,
            progress: 100,
            completedAt: DateTime.now().toIso8601String(),
          );
        } else {
          _progressMap.remove(questId);
        }

        // Update current roadmap object with new progress
        if (_currentRoadmap != null) {
          _currentRoadmap = _currentRoadmap!.copyWith(
            progress: Map.from(_progressMap),
          );
        }

        // Update roadmap list item progress
        final index = _roadmaps.indexWhere((r) => r.sessionId == sessionId);
        if (index != -1) {
          // Reload the roadmap session summary to get updated progress
          await loadUserRoadmaps();
        }

        notifyListeners();
        return response;
      },
      errorMessageBuilder: (error) {
        return 'Lỗi cập nhật tiến độ: ${error.toString()}';
      },
    );
  }

  /// Check if a quest is completed
  bool isQuestCompleted(String questId) {
    return _progressMap[questId]?.isCompleted ?? false;
  }

  /// Get progress for a specific quest
  QuestProgress? getQuestProgress(String questId) {
    return _progressMap[questId];
  }

  /// Clear current roadmap
  void clearCurrentRoadmap() {
    _currentRoadmap = null;
    _progressMap = {};
    notifyListeners();
  }

  /// Clear validation results
  void clearValidationResults() {
    _validationResults = [];
    notifyListeners();
  }

  /// Clear generation error
  void clearGenerationError() {
    _generationError = null;
    notifyListeners();
  }

  // ============================================================================
  // LEGACY METHODS (for backward compatibility)
  // ============================================================================

  /// Load all available roadmaps with error handling
  @Deprecated('Use loadUserRoadmaps() instead')
  Future<void> loadRoadmaps() async {
    await executeAsync(
      () async {
        // ignore: deprecated_member_use_from_same_package
        _legacyRoadmaps = await _roadmapService.getRoadmaps();
        notifyListeners();
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('timeout')) {
          return 'Không có kết nối Internet';
        } else if (error.toString().contains('404')) {
          return 'Không tìm thấy roadmap';
        }
        return 'Lỗi tải roadmap: ${error.toString()}';
      },
    );
  }

  /// Get roadmap by ID with error handling
  @Deprecated('Use loadRoadmapById() instead')
  Future<Roadmap?> getRoadmapById(int roadmapId) async {
    return await executeAsync(
      () async {
        // ignore: deprecated_member_use_from_same_package
        return await _roadmapService.getRoadmapById(roadmapId) as dynamic;
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('404')) {
          return 'Không tìm thấy roadmap';
        }
        return 'Lỗi tải roadmap: ${error.toString()}';
      },
    );
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadUserRoadmaps();
  }

  /// Remove roadmap from user list
  void removeUserRoadmap(int sessionId) {
    _roadmaps.removeWhere((r) => r.sessionId == sessionId);
    notifyListeners();
  }

  /// Find roadmap in list
  RoadmapSessionSummary? findRoadmapBySessionId(int sessionId) {
    try {
      return _roadmaps.firstWhere((r) => r.sessionId == sessionId);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // ROADMAP LIFECYCLE MANAGEMENT
  // ============================================================================

  /// Load roadmap status counts
  Future<void> loadStatusCounts() async {
    try {
      _statusCounts = await _roadmapService.getRoadmapStatusCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading status counts: $e');
    }
  }

  /// Activate a roadmap (auto-pauses others)
  Future<bool> activateRoadmap(int sessionId) async {
    try {
      await _roadmapService.activateRoadmap(sessionId);
      await loadUserRoadmaps(); // refresh to reflect status changes on all items
      return true;
    } catch (e) {
      debugPrint('Error activating roadmap: $e');
      return false;
    }
  }

  /// Pause a roadmap
  Future<bool> pauseRoadmap(int sessionId) async {
    try {
      await _roadmapService.pauseRoadmap(sessionId);
      await loadUserRoadmaps();
      return true;
    } catch (e) {
      debugPrint('Error pausing roadmap: $e');
      return false;
    }
  }

  /// Soft-delete a roadmap (hidden from list)
  Future<bool> softDeleteRoadmap(int sessionId) async {
    try {
      debugPrint(
        '🗑️ [RoadmapProvider] Starting soft-delete for session: $sessionId',
      );

      // Find item and update locally FIRST (Optimistic UI)
      final index = _roadmaps.indexWhere((r) => r.sessionId == sessionId);
      if (index != -1) {
        _roadmaps[index] = _roadmaps[index].copyWith(status: 'DELETED');
        debugPrint('   ✅ Local status updated to DELETED');
        notifyListeners();
      }

      await _roadmapService.softDeleteRoadmap(sessionId);
      debugPrint('   ✅ API Delete call success');

      await loadStatusCounts();
      return true;
    } catch (e) {
      debugPrint('❌ [RoadmapProvider] Error deleting roadmap $sessionId: $e');
      // On error, reload from server to fix local state
      await loadUserRoadmaps(force: true);
      return false;
    }
  }

  /// Permanently delete a roadmap
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

  /// Restore a soft-deleted roadmap (re-activate it)
  Future<bool> restoreRoadmap(int sessionId) async {
    try {
      debugPrint(
        '🔄 [RoadmapProvider] Starting restore for session: $sessionId',
      );

      // Update locally FIRST (Optimistic UI)
      final index = _roadmaps.indexWhere((r) => r.sessionId == sessionId);
      if (index != -1) {
        // When restoring, we auto-pause others if the backend does so.
        // For simplicity on mobile, we just update this one to ACTIVE.
        // The subsequent loadUserRoadmaps() call will sync all other items' statuses.
        _roadmaps[index] = _roadmaps[index].copyWith(status: 'ACTIVE');
        debugPrint('   ✅ Local status updated to ACTIVE');
        notifyListeners();
      }

      await _roadmapService.activateRoadmap(sessionId);
      debugPrint('   ✅ API Activate success');

      // Refresh to ensure all active/paused statuses are synced from server
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
  // STUDY PLAN FROM NODE
  // ============================================================================

  final JourneyService _journeyService = JourneyService();

  /// Create study plan for a specific roadmap node
  Future<Map<String, dynamic>?> createStudyPlanForNode({
    required int roadmapSessionId,
    required String nodeId,
  }) async {
    try {
      final result = await _journeyService.createStudyPlanForRoadmapNode(
        roadmapSessionId: roadmapSessionId,
        nodeId: nodeId,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
