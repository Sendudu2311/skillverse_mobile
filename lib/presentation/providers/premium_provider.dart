import 'package:flutter/foundation.dart';
import '../../data/models/premium_models.dart';
import '../../data/services/premium_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class PremiumProvider with ChangeNotifier, LoadingStateProviderMixin {
  final PremiumService _premiumService = PremiumService();

  List<PremiumPlanDto> _availablePlans = [];
  UserSubscriptionDto? _currentSubscription;
  List<UserSubscriptionDto> _subscriptionHistory = [];
  bool _hasPremium = false;

  List<PremiumPlanDto> get availablePlans => _availablePlans;
  UserSubscriptionDto? get currentSubscription => _currentSubscription;
  List<UserSubscriptionDto> get subscriptionHistory => _subscriptionHistory;
  bool get hasPremium => _hasPremium;

  /// Filtered plans (no FREE_TIER, no recruiter plans for learners)
  List<PremiumPlanDto> get displayPlans =>
      _availablePlans.where((p) => p.planType != PlanType.freeTier).toList();

  // ==================== LOAD ACTIONS ====================

  /// Load available premium plans
  Future<void> loadAvailablePlans() async {
    await executeAsync(
      () async {
        _availablePlans = await _premiumService.getAvailablePlans();
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Get plan by ID
  Future<PremiumPlanDto?> getPlanById(int planId) async {
    PremiumPlanDto? result;
    await executeAsync(
      () async {
        result = await _premiumService.getPlanById(planId: planId);
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result;
  }

  /// Load current subscription
  Future<void> loadCurrentSubscription() async {
    await executeAsync(
      () async {
        _currentSubscription = await _premiumService.getCurrentSubscription();
        _hasPremium = _currentSubscription?.isActive ?? false;
        notifyListeners();
      },
      errorMessageBuilder: (e) {
        if (e.toString().contains('404')) {
          return '';
        }
        return ErrorHandler.getErrorMessage(e);
      },
    );
  }

  /// Load subscription history
  Future<void> loadSubscriptionHistory() async {
    await executeAsync(
      () async {
        _subscriptionHistory = await _premiumService.getSubscriptionHistory();
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Check premium status
  Future<void> checkPremiumStatus() async {
    await executeAsync(
      () async {
        _hasPremium = await _premiumService.checkPremiumStatus();
        notifyListeners();
      },
      errorMessageBuilder: (e) {
        _hasPremium = false;
        return '';
      },
    );
  }

  /// Load all data in parallel
  Future<void> loadAll() async {
    await executeAsync(
      () async {
        final results = await Future.wait([
          _premiumService.getAvailablePlans(),
          _premiumService.getCurrentSubscription().catchError((_) => null),
          _premiumService.checkPremiumStatus().catchError((_) => false),
        ]);

        _availablePlans = results[0] as List<PremiumPlanDto>;
        _currentSubscription = results[1] as UserSubscriptionDto?;
        _hasPremium = (results[2] as bool?) ?? (_currentSubscription?.isActive ?? false);
        notifyListeners();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  // ==================== PURCHASE ACTIONS ====================

  /// Create subscription via PayOS
  Future<UserSubscriptionDto?> createSubscription({
    required int planId,
    required paymentMethod,
    bool applyStudentDiscount = false,
    bool autoRenew = false,
    String? successUrl,
    String? cancelUrl,
    String? couponCode,
  }) async {
    return await executeAsync<UserSubscriptionDto>(
      () async {
        final request = CreateSubscriptionRequestDto(
          planId: planId,
          paymentMethod: paymentMethod,
          applyStudentDiscount: applyStudentDiscount,
          autoRenew: autoRenew,
          successUrl: successUrl,
          cancelUrl: cancelUrl,
          couponCode: couponCode,
        );

        final subscription = await _premiumService.createSubscription(request: request);
        _currentSubscription = subscription;
        _hasPremium = subscription.isActive;
        notifyListeners();
        return subscription;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Purchase subscription with wallet cash (instant)
  Future<UserSubscriptionDto?> purchaseWithWallet({
    required int planId,
    bool applyStudentDiscount = false,
  }) async {
    return await executeAsync<UserSubscriptionDto>(
      () async {
        final subscription = await _premiumService.purchaseWithWallet(
          planId: planId,
          applyStudentDiscount: applyStudentDiscount,
        );
        _currentSubscription = subscription;
        _hasPremium = subscription.isActive;
        notifyListeners();
        return subscription;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  // ==================== SUBSCRIPTION MANAGEMENT ====================

  /// Cancel subscription
  Future<bool> cancelSubscription({String? reason}) async {
    final result = await executeAsync<bool>(
      () async {
        await _premiumService.cancelSubscription(reason: reason);
        _currentSubscription = null;
        _hasPremium = false;
        notifyListeners();
        return true;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
    return result ?? false;
  }

  /// Cancel subscription with refund
  Future<Map<String, dynamic>?> cancelSubscriptionWithRefund({String? reason}) async {
    return await executeAsync<Map<String, dynamic>>(
      () async {
        final result = await _premiumService.cancelSubscriptionWithRefund(reason: reason);
        // Reload subscription after cancel
        await loadCurrentSubscription();
        return result;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Enable auto-renewal
  Future<Map<String, dynamic>?> enableAutoRenewal() async {
    return await executeAsync<Map<String, dynamic>>(
      () async {
        final result = await _premiumService.enableAutoRenewal();
        await loadCurrentSubscription();
        return result;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Cancel auto-renewal
  Future<Map<String, dynamic>?> cancelAutoRenewal() async {
    return await executeAsync<Map<String, dynamic>>(
      () async {
        final result = await _premiumService.cancelAutoRenewal();
        await loadCurrentSubscription();
        return result;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Recover pending subscriptions
  Future<Map<String, dynamic>?> recoverPendingSubscriptions() async {
    return await executeAsync<Map<String, dynamic>>(
      () async {
        final result = await _premiumService.recoverPendingSubscriptions();
        if (result['recovered'] == true) {
          await loadCurrentSubscription();
        }
        return result;
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Check refund eligibility
  Future<Map<String, dynamic>?> checkRefundEligibility() async {
    return await executeAsync<Map<String, dynamic>>(
      () async {
        return await _premiumService.checkRefundEligibility();
      },
      errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e),
    );
  }

  /// Clear all data
  void clearAll() {
    _availablePlans = [];
    _currentSubscription = null;
    _subscriptionHistory = [];
    _hasPremium = false;
    resetState();
  }
}
