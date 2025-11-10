import 'package:flutter/foundation.dart';
import '../../data/models/premium_models.dart';
import '../../data/services/premium_service.dart';
import 'package:dio/dio.dart';

class PremiumProvider with ChangeNotifier {
  final PremiumService _premiumService = PremiumService();

  List<PremiumPlanDto> _availablePlans = [];
  UserSubscriptionDto? _currentSubscription;
  List<UserSubscriptionDto> _subscriptionHistory = [];
  bool _hasPremium = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<PremiumPlanDto> get availablePlans => _availablePlans;
  UserSubscriptionDto? get currentSubscription => _currentSubscription;
  List<UserSubscriptionDto> get subscriptionHistory => _subscriptionHistory;
  bool get hasPremium => _hasPremium;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load available premium plans
  Future<void> loadAvailablePlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availablePlans = await _premiumService.getAvailablePlans();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = e.response?.data['message'] ?? 'Lỗi tải gói premium';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Get plan by ID
  Future<PremiumPlanDto?> getPlanById(int planId) async {
    try {
      return await _premiumService.getPlanById(planId: planId);
    } catch (e) {
      debugPrint('Error getting plan by ID: $e');
      return null;
    }
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CreateSubscriptionRequestDto(
        planId: planId,
        paymentMethod: paymentMethod,
        applyStudentDiscount: applyStudentDiscount,
        autoRenew: autoRenew,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
        couponCode: couponCode,
      );

      final subscription =
          await _premiumService.createSubscription(request: request);
      _currentSubscription = subscription;
      _hasPremium = subscription.isActive;
      _isLoading = false;
      notifyListeners();
      return subscription;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = e.response?.data['message'] ?? 'Lỗi đăng ký premium';
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Load current subscription
  Future<void> loadCurrentSubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSubscription = await _premiumService.getCurrentSubscription();
      _hasPremium = _currentSubscription?.isActive ?? false;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      // 404 means no active subscription - not an error
      if (e.response?.statusCode != 404) {
        _errorMessage =
            e.response?.data['message'] ?? 'Lỗi tải thông tin subscription';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load subscription history
  Future<void> loadSubscriptionHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscriptionHistory = await _premiumService.getSubscriptionHistory();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage =
          e.response?.data['message'] ?? 'Lỗi tải lịch sử subscription';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription({String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _premiumService.cancelSubscription(reason: reason);
      _currentSubscription = null;
      _hasPremium = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = e.response?.data['message'] ?? 'Lỗi hủy subscription';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Check premium status
  Future<void> checkPremiumStatus() async {
    try {
      _hasPremium = await _premiumService.checkPremiumStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      _hasPremium = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
