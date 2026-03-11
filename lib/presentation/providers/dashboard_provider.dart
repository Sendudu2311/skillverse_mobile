import 'package:flutter/material.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/services/dashboard_service.dart';

/// Provider for managing Dashboard state and data
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class DashboardProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final DashboardService _service = DashboardService();

  // State (chỉ giữ domain data — loading/error do mixin quản lý)
  DashboardData? _dashboardData;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
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
    if (isLoading) return;

    await executeAsync(() async {
      _dashboardData = await _service.fetchAllDashboardData();
      notifyListeners();
    }, errorMessageBuilder: (e) {
      debugPrint('Error loading dashboard: $e');
      return e.toString();
    });
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    return loadDashboard();
  }

  /// Clear dashboard data
  void clear() {
    _dashboardData = null;
    resetState(); // Clears isLoading + errorMessage + notifyListeners()
  }
}
