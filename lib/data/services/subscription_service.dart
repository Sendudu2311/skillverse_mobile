import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

      debugPrint('📦 Subscription response: ${response.data}');

      if (response.data == null) {
        debugPrint('📦 Subscription response data is null');
        return null;
      }

      return SubscriptionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      // 404 = no active subscription (normal case for free users)
      if (e.response?.statusCode == 404) {
        debugPrint('📦 No active subscription (404)');
        return null;
      }
      debugPrint('📦 Subscription error: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('📦 Subscription parse error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch subscription: ${e.toString()}');
    }
  }
}
