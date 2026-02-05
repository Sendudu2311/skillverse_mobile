import '../../../core/exceptions/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_models.dart';

/// Service for fetching Dashboard data from multiple endpoints
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Fetch wallet information
  Future<WalletResponse> fetchWallet() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/wallet/my-wallet',
      );

      if (response.data == null) {
        throw ApiException('No wallet data received');
      }

      return WalletResponse.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch wallet: ${e.toString()}');
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
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch usage stats: ${e.toString()}');
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
      // Subscription is optional, return null if not found
      if (e is ApiException && e.message.contains('404')) {
        return null;
      }
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch subscription: ${e.toString()}');
    }
  }

  /// Fetch AI roadmaps
  Future<List<RoadmapSession>> fetchRoadmaps() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/ai/roadmap',
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map((json) => RoadmapSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch roadmaps: ${e.toString()}');
    }
  }

  /// Fetch all dashboard data in parallel
  Future<DashboardData> fetchAllDashboardData() async {
    try {
      final results = await Future.wait([
        fetchWallet().catchError((_) => null as WalletResponse?),
        fetchUsageStats().catchError((_) => null as UsageStatsResponse?),
        fetchSubscription().catchError((_) => null as SubscriptionResponse?),
        fetchRoadmaps().catchError((_) => <RoadmapSession>[]),
      ]);

      return DashboardData(
        wallet: results[0] as WalletResponse?,
        usageStats: results[1] as UsageStatsResponse?,
        subscription: results[2] as SubscriptionResponse?,
        roadmaps: results[3] as List<RoadmapSession>,
      );
    } catch (e) {
      throw ApiException('Failed to fetch dashboard data: ${e.toString()}');
    }
  }
}
