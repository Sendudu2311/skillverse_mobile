import 'package:flutter/material.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/models/enrollment_models.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/streak_service.dart';

/// Provider for managing Dashboard state and data
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class DashboardProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final DashboardService _service = DashboardService();
  final StreakService _streakService = StreakService();

  // State (chỉ giữ domain data — loading/error do mixin quản lý)
  DashboardData? _dashboardData;
  bool _isCheckingIn = false;

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

  RoadmapSession? get activeRoadmap {
    if (roadmaps.isEmpty) return null;
    // Prefer the explicitly ACTIVE roadmap
    try {
      return roadmaps.firstWhere(
        (r) => (r.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE',
      );
    } catch (_) {
      // Fallback: first non-deleted roadmap (backward compat)
      try {
        return roadmaps.firstWhere(
          (r) => (r.status ?? 'ACTIVE').toUpperCase() != 'DELETED',
        );
      } catch (_) {
        return null;
      }
    }
  }

  EnrollmentDetailDto? get continueCourse => _dashboardData?.continueLearning;

  bool get isCheckingIn => _isCheckingIn;

  /// Today is checked-in if today's weeklyActivity slot is true
  bool get isCheckedInToday {
    final activity = weeklyActivity;
    final todayIndex = DateTime.now().weekday - 1; // Mon=0 ... Sun=6
    return activity.length > todayIndex ? activity[todayIndex] : false;
  }

  /// POST /streak/check-in — điểm danh hàng ngày
  Future<CheckInResult?> checkIn() async {
    if (_isCheckingIn) return null;
    _isCheckingIn = true;
    notifyListeners();
    try {
      final result = await _streakService.checkIn();
      // Update streak state locally so UI reflects immediately
      if (_dashboardData?.usageStats != null) {
        final updated = UsageStatsResponse(
          enrolledCoursesCount:
              _dashboardData!.usageStats!.enrolledCoursesCount,
          completedCoursesCount:
              _dashboardData!.usageStats!.completedCoursesCount,
          completedProjectsCount:
              _dashboardData!.usageStats!.completedProjectsCount,
          certificatesCount: _dashboardData!.usageStats!.certificatesCount,
          totalHoursStudied: _dashboardData!.usageStats!.totalHoursStudied,
          currentStreak: result.currentStreak,
          longestStreak: longestStreak,
          weeklyActivity: result.weeklyActivity,
          cycleStartDate: _dashboardData!.usageStats!.cycleStartDate,
          cycleEndDate: _dashboardData!.usageStats!.cycleEndDate,
        );
        _dashboardData = _dashboardData!.copyWith(usageStats: updated);
      }
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('checkIn error: $e');
      return null;
    } finally {
      _isCheckingIn = false;
      notifyListeners();
    }
  }

  /// Load all dashboard data
  Future<void> loadDashboard({int? userId}) async {
    if (isLoading) return;

    await executeAsync(
      () async {
        _dashboardData = await _service.fetchAllDashboardData(userId: userId);
        notifyListeners();
      },
      errorMessageBuilder: (e) {
        debugPrint('Error loading dashboard: $e');
        return e.toString();
      },
    );
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard({int? userId}) async {
    return loadDashboard(userId: userId);
  }

  /// Clear dashboard data
  void clear() {
    _dashboardData = null;
    resetState(); // Clears isLoading + errorMessage + notifyListeners()
  }
}
