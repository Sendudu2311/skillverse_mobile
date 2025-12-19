import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class RoadmapProvider with ChangeNotifier, LoadingStateProviderMixin {
  final RoadmapService _roadmapService = RoadmapService();

  List<Roadmap> _roadmaps = [];
  List<Roadmap> _userRoadmaps = [];

  List<Roadmap> get roadmaps => _roadmaps;
  List<Roadmap> get userRoadmaps => _userRoadmaps;

  /// Load all available roadmaps with error handling
  Future<void> loadRoadmaps() async {
    await executeAsync(
      () async {
        _roadmaps = await _roadmapService.getRoadmaps();
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

  /// Load user's roadmaps with error handling
  Future<void> loadUserRoadmaps() async {
    await executeAsync(
      () async {
        _userRoadmaps = await _roadmapService.getUserRoadmaps();
        notifyListeners();
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('timeout')) {
          return 'Không có kết nối Internet';
        }
        return 'Lỗi tải roadmap của bạn: ${error.toString()}';
      },
    );
  }

  /// Get roadmap by ID with error handling
  Future<Roadmap?> getRoadmapById(int roadmapId) async {
    return await executeAsync(
      () async {
        return await _roadmapService.getRoadmapById(roadmapId);
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('404')) {
          return 'Không tìm thấy roadmap';
        }
        return 'Lỗi tải roadmap: ${error.toString()}';
      },
    );
  }

  /// Get roadmaps by category with error handling
  Future<void> loadRoadmapsByCategory(String category) async {
    await executeAsync(
      () async {
        _roadmaps = await _roadmapService.getRoadmapsByCategory(category);
        notifyListeners();
      },
      errorMessageBuilder: (error) {
        return 'Lỗi tải roadmap theo danh mục: ${error.toString()}';
      },
    );
  }

  /// Update roadmap progress with error handling
  Future<bool> updateRoadmapProgress(int roadmapId, int completedSteps) async {
    final result = await executeAsync<bool>(
      () async {
        final updatedRoadmap = await _roadmapService.updateRoadmapProgress(
          roadmapId,
          completedSteps,
        );

        // Update in local lists
        final index = _roadmaps.indexWhere((r) => r.id == roadmapId);
        if (index != -1) {
          _roadmaps[index] = updatedRoadmap;
        }

        final userIndex = _userRoadmaps.indexWhere((r) => r.id == roadmapId);
        if (userIndex != -1) {
          _userRoadmaps[userIndex] = updatedRoadmap;
        }

        notifyListeners();
        return true;
      },
      errorMessageBuilder: (error) {
        return 'Lỗi cập nhật tiến độ: ${error.toString()}';
      },
    );

    return result ?? false;
  }

  /// Start a roadmap with error handling
  Future<bool> startRoadmap(int roadmapId) async {
    final result = await executeAsync<bool>(
      () async {
        final startedRoadmap = await _roadmapService.startRoadmap(roadmapId);
        _userRoadmaps.add(startedRoadmap);
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (error) {
        if (error.toString().contains('401') || error.toString().contains('403')) {
          return 'Vui lòng đăng nhập để bắt đầu roadmap';
        }
        return 'Lỗi bắt đầu roadmap: ${error.toString()}';
      },
    );

    return result ?? false;
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadRoadmaps(),
      loadUserRoadmaps(),
    ]);
  }

  /// Remove roadmap from user list
  void removeUserRoadmap(int roadmapId) {
    _userRoadmaps.removeWhere((r) => r.id == roadmapId);
    notifyListeners();
  }

  /// Find roadmap in list
  Roadmap? findRoadmapById(int roadmapId) {
    try {
      return _roadmaps.firstWhere((r) => r.id == roadmapId);
    } catch (e) {
      return null;
    }
  }
}
