import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../data/services/journey_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

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

  // Legacy getters
  @Deprecated('Use roadmaps instead')
  List<Roadmap> get legacyRoadmaps => _legacyRoadmaps;
  @Deprecated('Use roadmaps instead')
  List<Roadmap> get userRoadmaps => _legacyUserRoadmaps;

  /// Get filtered and sorted roadmaps
  List<RoadmapSessionSummary> get filteredRoadmaps {
    var filtered = List<RoadmapSessionSummary>.from(_roadmaps);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (r) =>
                r.title.toLowerCase().contains(query) ||
                r.originalGoal.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply experience filter
    if (_filterExperience != 'all') {
      filtered = filtered
          .where(
            (r) =>
                r.experienceLevel.toLowerCase() ==
                _filterExperience.toLowerCase(),
          )
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
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

    return filtered;
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

  /// Load all roadmap sessions for current user
  Future<void> loadUserRoadmaps() async {
    await executeAsync(
      () async {
        _roadmaps = await _roadmapService.getUserRoadmaps();
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
