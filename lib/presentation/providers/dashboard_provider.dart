import 'package:flutter/material.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/services/dashboard_service.dart';

/// Provider for managing Dashboard state and data
class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  // State
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _dashboardData != null;

  // Convenience getters
  WalletResponse? get wallet => _dashboardData?.wallet;
  UsageStatsResponse? get usageStats => _dashboardData?.usageStats;
  SubscriptionResponse? get subscription => _dashboardData?.subscription;
  List<RoadmapSession> get roadmaps => _dashboardData?.roadmaps ?? [];

  // Computed getters for UI
  int get coinBalance => wallet?.coinBalance ?? 0;
  int get cashBalance => wallet?.cashBalance ?? 0;

  int get currentStreak => usageStats?.currentStreak ?? 0;
  int get longestStreak => usageStats?.longestStreak ?? 0;
  List<bool> get weeklyActivity =>
      usageStats?.weeklyActivity ??
      [false, false, false, false, false, false, false];

  int get enrolledCoursesCount => usageStats?.enrolledCoursesCount ?? 0;
  int get completedCoursesCount => usageStats?.completedCoursesCount ?? 0;
  int get completedProjectsCount => usageStats?.completedProjectsCount ?? 0;
  int get certificatesCount => usageStats?.certificatesCount ?? 0;
  int get totalHoursStudied => usageStats?.totalHoursStudied ?? 0;

  bool get hasPremium => subscription?.currentlyActive ?? false;
  String get premiumPlanName => subscription?.plan.displayName ?? 'Free';
  int get premiumDaysRemaining => subscription?.daysRemaining ?? 0;

  RoadmapSession? get activeRoadmap =>
      roadmaps.isNotEmpty ? roadmaps.first : null;

  /// Load all dashboard data
  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardData = await _service.fetchAllDashboardData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    return loadDashboard();
  }

  /// Clear dashboard data
  void clear() {
    _dashboardData = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
