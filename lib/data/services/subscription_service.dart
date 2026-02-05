import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/subscription_response.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<SubscriptionResponse?> getCurrentSubscription() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/premium/subscription/current',
      );

      if (response.data == null) {
        return null;
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
}
