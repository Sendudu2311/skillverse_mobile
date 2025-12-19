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

  /// Create subscription
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

  /// Load current subscription
  Future<void> loadCurrentSubscription() async {
    await executeAsync(
      () async {
        _currentSubscription = await _premiumService.getCurrentSubscription();
        _hasPremium = _currentSubscription?.isActive ?? false;
        notifyListeners();
      },
      errorMessageBuilder: (e) {
        // 404 means no active subscription - not an error
        if (e.toString().contains('404')) {
          return ''; // Return empty string to avoid showing error for 404
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

  /// Check premium status
  Future<void> checkPremiumStatus() async {
    await executeAsync(
      () async {
        _hasPremium = await _premiumService.checkPremiumStatus();
        notifyListeners();
      },
      errorMessageBuilder: (e) {
        _hasPremium = false;
        return ''; // Silent fail - premium status check shouldn't show errors
      },
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
