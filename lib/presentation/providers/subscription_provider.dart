import 'package:flutter/foundation.dart';
import '../../data/models/subscription_response.dart';
import '../../data/services/subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  SubscriptionResponse? _subscription;
  bool _isLoading = false;
  String? _errorMessage;

  SubscriptionResponse? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSubscription => _subscription?.currentlyActive ?? false;
  bool get isPremium => _subscription != null && _subscription!.currentlyActive;

  Future<void> loadSubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscription = await _subscriptionService.getCurrentSubscription();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _subscription = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSubscription() {
    _subscription = null;
    _errorMessage = null;
    notifyListeners();
  }
}
