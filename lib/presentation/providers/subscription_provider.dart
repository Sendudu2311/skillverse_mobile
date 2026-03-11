import 'package:flutter/foundation.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/subscription_response.dart';
import '../../data/services/subscription_service.dart';

/// Subscription Provider
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class SubscriptionProvider with ChangeNotifier, LoadingStateProviderMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();

  SubscriptionResponse? _subscription;

  SubscriptionResponse? get subscription => _subscription;
  bool get hasActiveSubscription => _subscription?.currentlyActive ?? false;
  bool get isPremium => _subscription != null && _subscription!.currentlyActive;

  Future<void> loadSubscription() async {
    await executeAsync(() async {
      _subscription = await _subscriptionService.getCurrentSubscription();
      notifyListeners();
    }, errorMessageBuilder: (e) {
      _subscription = null;
      return e.toString();
    });
  }

  void clearSubscription() {
    _subscription = null;
    resetState();
  }
}
