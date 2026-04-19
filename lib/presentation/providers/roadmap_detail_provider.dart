import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../data/services/journey_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

/// Manages state for a single opened roadmap (detail view + quest progress).
/// Use alongside [RoadmapProvider] for list operations.
class RoadmapDetailProvider with ChangeNotifier, LoadingStateProviderMixin {
  final RoadmapService _roadmapService = RoadmapService();
  final JourneyService _journeyService = JourneyService();

  RoadmapResponse? _currentRoadmap;
  Map<String, QuestProgress> _progressMap = {};

  // ============================================================================
  // GETTERS
  // ============================================================================

  RoadmapResponse? get currentRoadmap => _currentRoadmap;
  Map<String, QuestProgress> get progressMap => _progressMap;

  // ============================================================================
  // LOAD
  // ============================================================================

  Future<RoadmapResponse?> loadRoadmapById(int sessionId) async {
    return await executeAsync<RoadmapResponse>(
      () async {
        _currentRoadmap = await _roadmapService.getRoadmapById(sessionId);

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
      errorMessageBuilder: (error) {
        return 'Lỗi cập nhật tiến độ: ${error.toString()}';
      },
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
      return await _journeyService.createStudyPlanForRoadmapNode(
        roadmapSessionId: roadmapSessionId,
        nodeId: nodeId,
      );
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
    }, errorMessageBuilder: (error) {
      return 'Lỗi kích hoạt lộ trình: ${error.toString()}';
    });
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
    }, errorMessageBuilder: (error) {
      return 'Lỗi hoàn thành chặng: ${error.toString()}';
    });
  }

  // ============================================================================
  // RESET
  // ============================================================================

  void clearCurrentRoadmap() {
    _currentRoadmap = null;
    _progressMap = {};
    notifyListeners();
  }
}
