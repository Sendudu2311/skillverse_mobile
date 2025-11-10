import '../models/premium_models.dart';
import 'api_client.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get available premium plans
  /// GET /api/premium/plans
  Future<List<PremiumPlanDto>> getAvailablePlans() async {
    try {
      final response = await _apiClient.dio.get('/api/premium/plans');

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
  /// GET /api/premium/plans/{planId}
  Future<PremiumPlanDto?> getPlanById({
    required int planId,
  }) async {
    try {
      final response = await _apiClient.dio.get('/api/premium/plans/$planId');
      return PremiumPlanDto.fromJson(response.data);
    } catch (e) {
      // Return null if not found (404)
      return null;
    }
  }

  /// Create premium subscription
  /// POST /api/premium/subscribe
  Future<UserSubscriptionDto> createSubscription({
    required CreateSubscriptionRequestDto request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/premium/subscribe',
        data: request.toJson(),
      );
      return UserSubscriptionDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current subscription for authenticated user
  /// GET /api/premium/subscription/current
  Future<UserSubscriptionDto?> getCurrentSubscription() async {
    try {
      final response =
          await _apiClient.dio.get('/api/premium/subscription/current');
      return UserSubscriptionDto.fromJson(response.data);
    } catch (e) {
      // Return null if no active subscription (404)
      return null;
    }
  }

  /// Get subscription history
  /// GET /api/premium/subscription/history
  Future<List<UserSubscriptionDto>> getSubscriptionHistory() async {
    try {
      final response =
          await _apiClient.dio.get('/api/premium/subscription/history');

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
  /// PUT /api/premium/subscription/cancel
  Future<void> cancelSubscription({
    String? reason,
  }) async {
    try {
      await _apiClient.dio.put(
        '/api/premium/subscription/cancel',
        queryParameters: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has active premium subscription
  /// GET /api/premium/status
  Future<bool> checkPremiumStatus() async {
    try {
      final response = await _apiClient.dio.get('/api/premium/status');
      return response.data as bool;
    } catch (e) {
      rethrow;
    }
  }
}
