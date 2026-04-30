import '../../../core/error/exceptions.dart';
import '../../../core/exceptions/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_models.dart';
import '../models/enrollment_models.dart';
import 'enrollment_service.dart';
import 'wallet_service.dart';
import 'roadmap_service.dart';

/// Service for fetching Dashboard data from multiple endpoints
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Fetch wallet information (delegates to WalletService)
  Future<WalletResponse> fetchWallet() async {
    try {
      return await WalletService().getMyWallet();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Không thể tải dữ liệu ví');
    }
  }

  /// Fetch usage statistics
  Future<UsageStatsResponse> fetchUsageStats() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/usage/stats',
      );

      if (response.data == null) {
        throw ApiException('No usage stats data received');
      }

      return UsageStatsResponse.fromJson(response.data!);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Không thể tải thống kê sử dụng');
    }
  }

  /// Fetch current subscription
  Future<SubscriptionResponse?> fetchSubscription() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/premium/subscription/current',
      );

      if (response.data == null) {
        return null; // User may not have a subscription
      }

      return SubscriptionResponse.fromJson(response.data!);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Không thể tải thông tin gói Premium');
    }
  }

  /// Fetch AI roadmaps (delegates to RoadmapService)
  /// Uses size=10 to avoid unbounded fetch on every dashboard load.
  Future<List<RoadmapSession>> fetchRoadmaps() async {
    try {
      final summaries = await RoadmapService().getUserRoadmaps(size: 10);
      return summaries
          .map((s) => RoadmapSession.fromSummary(s.toJson()))
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Không thể tải lộ trình học tập');
    }
  }

  /// Fetch the most relevant in-progress enrollment for "Continue Learning"
  Future<EnrollmentDetailDto?> fetchContinueLearning(int userId) async {
    try {
      final page = await EnrollmentService().getUserEnrollments(
        page: 0,
        size: 10,
      );
      final items = page.content ?? [];
      // Prefer courses already started (progress > 0, not completed)
      final inProgress = items
          .where((e) => !e.completed && e.progressPercent > 0)
          .toList();
      if (inProgress.isNotEmpty) return inProgress.first;
      // Fallback: enrolled but not yet started
      final enrolled = items.where((e) => !e.completed).toList();
      return enrolled.isNotEmpty ? enrolled.first : null;
    } catch (_) {
      return null; // non-critical — fail silently
    }
  }

  /// Fetch all dashboard data in parallel
  Future<DashboardData> fetchAllDashboardData({int? userId}) async {
    try {
      final results = await Future.wait([
        fetchWallet()
            .then<WalletResponse?>((v) => v)
            .catchError((_) => null as WalletResponse?),
        fetchUsageStats()
            .then<UsageStatsResponse?>((v) => v)
            .catchError((_) => null as UsageStatsResponse?),
        fetchSubscription().catchError((_) => null as SubscriptionResponse?),
        fetchRoadmaps().catchError((_) => <RoadmapSession>[]),
        if (userId != null)
          fetchContinueLearning(userId)
        else
          Future<EnrollmentDetailDto?>.value(null),
      ]);

      return DashboardData(
        wallet: results[0] as WalletResponse?,
        usageStats: results[1] as UsageStatsResponse?,
        subscription: results[2] as SubscriptionResponse?,
        roadmaps: results[3] as List<RoadmapSession>,
        continueLearning: results[4] as EnrollmentDetailDto?,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiException('Không thể tải dữ liệu tổng quan');
    }
  }
}
