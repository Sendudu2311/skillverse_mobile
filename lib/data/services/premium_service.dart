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
          .map((json) => PremiumPlanDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get premium plan by ID
  /// GET /premium/plans/{planId}
  Future<PremiumPlanDto?> getPlanById({required int planId}) async {
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
      final response = await _apiClient.dio.get(
        '/premium/subscription/current',
      );
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
      final response = await _apiClient.dio.get(
        '/premium/subscription/history',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) =>
                UserSubscriptionDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel subscription
  /// PUT /premium/subscription/cancel
  Future<void> cancelSubscription({String? reason}) async {
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

  /// Purchase premium with wallet cash
  /// POST /premium/purchase-with-wallet
  Future<UserSubscriptionDto> purchaseWithWallet({
    required int planId,
    bool applyStudentDiscount = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/premium/purchase-with-wallet',
        queryParameters: {
          'planId': planId,
          'applyStudentDiscount': applyStudentDiscount,
        },
      );
      return UserSubscriptionDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Recover pending subscriptions (paid but not activated)
  /// POST /premium/subscription/recover
  Future<Map<String, dynamic>> recoverPendingSubscriptions() async {
    try {
      final response = await _apiClient.dio.post(
        '/premium/subscription/recover',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel subscription with refund
  /// POST /premium/subscription/cancel-with-refund
  Future<Map<String, dynamic>> cancelSubscriptionWithRefund({
    String? reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/premium/subscription/cancel-with-refund',
        queryParameters: reason != null ? {'reason': reason} : null,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Enable auto-renewal
  /// POST /premium/subscription/enable-auto-renewal
  Future<Map<String, dynamic>> enableAutoRenewal() async {
    try {
      final response = await _apiClient.dio.post(
        '/premium/subscription/enable-auto-renewal',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel auto-renewal
  /// POST /premium/subscription/cancel-auto-renewal
  Future<Map<String, dynamic>> cancelAutoRenewal() async {
    try {
      final response = await _apiClient.dio.post(
        '/premium/subscription/cancel-auto-renewal',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get checkout preview (pricing for upgrade/downgrade)
  /// GET /premium/checkout-preview
  Future<CheckoutPreviewDto> getCheckoutPreview({
    required int planId,
    int? targetUserId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'planId': planId};
      if (targetUserId != null) queryParams['targetUserId'] = targetUserId;

      final response = await _apiClient.dio.get(
        '/premium/checkout-preview',
        queryParameters: queryParams,
      );
      return CheckoutPreviewDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Check refund eligibility
  /// GET /premium/subscription/refund-eligibility
  Future<Map<String, dynamic>> checkRefundEligibility() async {
    try {
      final response = await _apiClient.dio.get(
        '/premium/subscription/refund-eligibility',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
