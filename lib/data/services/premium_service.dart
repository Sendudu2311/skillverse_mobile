import '../models/premium_models.dart';
import '../../core/network/api_client.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get available premium plans
  /// GET /premium/plans
  Future<List<PremiumPlanDto>> getAvailablePlans() async {
    try {
      final response = await _apiClient.dio.get('/premium/plans');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              PremiumPlanDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get premium plan by ID
  /// GET /premium/plans/{planId}
  Future<PremiumPlanDto?> getPlanById({
    required int planId,
  }) async {
    try {
      final response = await _apiClient.dio.get('/premium/plans/$planId');
      return PremiumPlanDto.fromJson(response.data);
    } catch (e) {
      // Return null if not found (404)
      return null;
    }
  }

  /// Create premium subscription
  /// POST /premium/subscribe
  Future<UserSubscriptionDto> createSubscription({
    required CreateSubscriptionRequestDto request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/premium/subscribe',
        data: request.toJson(),
      );
      return UserSubscriptionDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current subscription for authenticated user
  /// GET /premium/subscription/current
  Future<UserSubscriptionDto?> getCurrentSubscription() async {
    try {
      final response =
          await _apiClient.dio.get('/premium/subscription/current');
      return UserSubscriptionDto.fromJson(response.data);
    } catch (e) {
      // Return null if no active subscription (404)
      return null;
    }
  }

  /// Get subscription history
  /// GET /premium/subscription/history
  Future<List<UserSubscriptionDto>> getSubscriptionHistory() async {
    try {
      final response =
          await _apiClient.dio.get('/premium/subscription/history');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              UserSubscriptionDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel subscription
  /// PUT /premium/subscription/cancel
  Future<void> cancelSubscription({
    String? reason,
  }) async {
    try {
      await _apiClient.dio.put(
        '/premium/subscription/cancel',
        queryParameters: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has active premium subscription
  /// GET /premium/status
  Future<bool> checkPremiumStatus() async {
    try {
      final response = await _apiClient.dio.get('/premium/status');
      return response.data as bool;
    } catch (e) {
      rethrow;
    }
  }
}
