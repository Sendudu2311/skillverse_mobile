import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../data/services/journey_service.dart';
import '../../data/services/task_board_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

/// Manages state for a single opened roadmap (detail view + quest progress).
/// Use alongside [RoadmapProvider] for list operations.
class RoadmapDetailProvider with ChangeNotifier, LoadingStateProviderMixin {
  final RoadmapService _roadmapService = RoadmapService();
  final JourneyService _journeyService = JourneyService();
  final TaskBoardService _taskBoardService = TaskBoardService();

  RoadmapResponse? _currentRoadmap;
  Map<String, QuestProgress> _progressMap = {};

  /// Node IDs that have linked study-plan tasks on the Task Board.
  /// Mirrors prototype's `studyTaskNodeIds` state.
  Set<String> _studyPlanNodeIds = {};

  /// Canonical regex matching [ROADMAP_NODE_LINK] markers in task.userNotes.
  /// Pattern: [ROADMAP_NODE_LINK] (optional journey=N) roadmap={id} node={id}
  static final _nodeLinkPattern = RegExp(
    r'\[ROADMAP_NODE_LINK\](?:\s+journey=\d+)?\s+roadmap=(\d+)\s+node=(\S+)',
    caseSensitive: false,
  );

  // ============================================================================
  // GETTERS
  // ============================================================================

  RoadmapResponse? get currentRoadmap => _currentRoadmap;
  Map<String, QuestProgress> get progressMap => _progressMap;

  /// Whether the given node has at least one linked study-plan task.
  bool hasStudyPlan(String nodeId) => _studyPlanNodeIds.contains(nodeId);

  // ============================================================================
  // LOAD
  // ============================================================================

  Future<RoadmapResponse?> loadRoadmapById(int sessionId) async {
    return await executeAsync<RoadmapResponse>(
      () async {
        // Sync with Prototype: auto-activate PAUSED roadmaps on 403
        try {
          _currentRoadmap = await _roadmapService.getRoadmapById(sessionId);
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('403') ||
              errorStr.contains('tạm dừng') ||
              errorStr.contains('forbidden')) {
            await _roadmapService.activateRoadmap(sessionId);
            _currentRoadmap =
                await _roadmapService.getRoadmapById(sessionId);
          } else {
            rethrow;
          }
        }

        if (_currentRoadmap?.progress != null) {
          _progressMap = Map<String, QuestProgress>.from(
            _currentRoadmap!.progress!,
          );
        } else {
          _progressMap = {};
        }

        // Load linked study-plan tasks (non-blocking — failures are silent)
        _loadStudyPlanNodeIds(_currentRoadmap!.sessionId);

        notifyListeners();
        return _currentRoadmap!;
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('404')) {
          return 'Không tìm thấy lộ trình';
        }
        return ErrorHandler.getErrorMessage(error);
      },
    );
  }


  // ============================================================================
  // QUEST PROGRESS
  // ============================================================================

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

        if (_currentRoadmap != null) {
          _currentRoadmap = _currentRoadmap!.copyWith(
            progress: Map.from(_progressMap),
          );
        }

        notifyListeners();
        return response;
      },
      errorMessageBuilder: (error) => ErrorHandler.getErrorMessage(error),
    );
  }

  bool isQuestCompleted(String questId) =>
      _progressMap[questId]?.isCompleted ?? false;

  QuestProgress? getQuestProgress(String questId) => _progressMap[questId];

  // ============================================================================
  // STUDY PLAN FROM NODE
  // ============================================================================

  Future<Map<String, dynamic>?> createStudyPlanForNode({
    required int roadmapSessionId,
    required String nodeId,
  }) async {
    try {
      final result = await _journeyService.createStudyPlanForRoadmapNode(
        roadmapSessionId: roadmapSessionId,
        nodeId: nodeId,
      );
      // Optimistically mark this node as having a study plan
      _studyPlanNodeIds.add(nodeId);
      notifyListeners();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // LIFECYCLE — Activate paused roadmap
  // ============================================================================

  /// Whether the current error is a "paused roadmap" error.
  bool get isPausedError =>
      errorMessage != null &&
      errorMessage!.contains('tạm dừng');

  /// Activate a paused roadmap, then reload it.
  Future<void> activateAndReload(int sessionId) async {
    await executeAsync(() async {
      await _roadmapService.activateRoadmap(sessionId);
      // Now reload the roadmap data
      _currentRoadmap = await _roadmapService.getRoadmapById(sessionId);
      if (_currentRoadmap?.progress != null) {
        _progressMap = Map<String, QuestProgress>.from(
          _currentRoadmap!.progress!,
        );
      } else {
        _progressMap = {};
      }
      notifyListeners();
    }, errorMessageBuilder: (error) => ErrorHandler.getErrorMessage(error));
  }

  // ============================================================================
  // COMPLETE NODE
  // ============================================================================

  Future<void> completeNode(int sessionId, String nodeId) async {
    await executeAsync(() async {
      await _roadmapService.completeNode(sessionId, nodeId);
      // Reload roadmap data to reflect the completed node status
      _currentRoadmap = await _roadmapService.getRoadmapById(sessionId);
      notifyListeners();
    }, errorMessageBuilder: (error) => ErrorHandler.getErrorMessage(error));
  }

  // ============================================================================
  // RESET
  // ============================================================================

  void clearCurrentRoadmap() {
    _currentRoadmap = null;
    _progressMap = {};
    _studyPlanNodeIds = {};
    notifyListeners();
  }

  // ============================================================================
  // PRIVATE — Study Plan Node Link Detection
  // ============================================================================

  /// Loads the task board for [sessionId] and parses `userNotes` to find
  /// nodes that have linked study-plan tasks (via [ROADMAP_NODE_LINK] marker).
  Future<void> _loadStudyPlanNodeIds(int sessionId) async {
    try {
      final board = await _taskBoardService.getBoard(
        roadmapSessionId: sessionId,
      );
      final nodeIds = <String>{};
      for (final column in board) {
        for (final task in column.tasks) {
          final notes = task.userNotes?.trim();
          if (notes == null || notes.isEmpty) continue;
          final match = _nodeLinkPattern.firstMatch(notes);
          if (match == null) continue;
          final matchedRoadmapId = int.tryParse(match.group(1) ?? '');
          final matchedNodeId = match.group(2)?.trim();
          if (matchedRoadmapId == sessionId &&
              matchedNodeId != null &&
              matchedNodeId.isNotEmpty) {
            nodeIds.add(matchedNodeId);
          }
        }
      }
      _studyPlanNodeIds = nodeIds;
      notifyListeners();
    } catch (e) {
      // Non-critical: badge simply won't show if board loading fails
      debugPrint('⚠️ Failed to load study plan node IDs: $e');
    }
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() => clearCurrentRoadmap();
}
