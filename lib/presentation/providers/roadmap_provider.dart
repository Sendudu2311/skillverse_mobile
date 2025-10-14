import 'package:flutter/material.dart';
import '../../data/models/roadmap_models.dart';
import '../../data/services/roadmap_service.dart';

class RoadmapProvider with ChangeNotifier {
  final RoadmapService _roadmapService = RoadmapService();

  List<Roadmap> _roadmaps = [];
  List<Roadmap> _userRoadmaps = [];
  bool _isLoading = false;
  String? _error;

  List<Roadmap> get roadmaps => _roadmaps;
  List<Roadmap> get userRoadmaps => _userRoadmaps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all available roadmaps
  Future<void> loadRoadmaps() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _roadmaps = await _roadmapService.getRoadmaps();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user's roadmaps
  Future<void> loadUserRoadmaps() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userRoadmaps = await _roadmapService.getUserRoadmaps();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get roadmap by ID
  Future<Roadmap?> getRoadmapById(int roadmapId) async {
    try {
      return await _roadmapService.getRoadmapById(roadmapId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get roadmaps by category
  Future<void> loadRoadmapsByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _roadmaps = await _roadmapService.getRoadmapsByCategory(category);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update roadmap progress
  Future<bool> updateRoadmapProgress(int roadmapId, int completedSteps) async {
    try {
      final updatedRoadmap = await _roadmapService.updateRoadmapProgress(roadmapId, completedSteps);

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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Start a roadmap
  Future<bool> startRoadmap(int roadmapId) async {
    try {
      final startedRoadmap = await _roadmapService.startRoadmap(roadmapId);
      _userRoadmaps.add(startedRoadmap);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadRoadmaps();
    await loadUserRoadmaps();
  }
}