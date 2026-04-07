import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';

/// Service to register/unregister FCM device tokens with the Backend.
///
/// Maps to:
///   POST   /api/notifications/device-token
///   DELETE /api/notifications/device-token?deviceToken=xxx
///   DELETE /api/notifications/device-tokens/all
///   GET    /api/notifications/device-tokens/status
class FcmApiService {
  final Dio _dio = ApiClient().dio;

  /// Register device token with backend.
  Future<void> registerDeviceToken({
    required String deviceToken,
    String deviceType = 'ANDROID',
    String? deviceName,
  }) async {
    try {
      await _dio.post(
        '/notifications/device-token',
        data: {
          'deviceToken': deviceToken,
          'deviceType': deviceType,
          if (deviceName != null) 'deviceName': deviceName,
        },
      );
    } on DioException catch (e) {
      // Non-critical: don't crash the app if token registration fails
      _log('Failed to register device token: ${e.message}');
    }
  }

  /// Unregister a specific device token.
  Future<void> unregisterDeviceToken(String deviceToken) async {
    try {
      await _dio.delete(
        '/notifications/device-token',
        queryParameters: {'deviceToken': deviceToken},
      );
    } on DioException catch (e) {
      _log('Failed to unregister device token: ${e.message}');
    }
  }

  /// Unregister all device tokens for the current user.
  Future<void> unregisterAllTokens() async {
    try {
      await _dio.delete('/notifications/device-tokens/all');
    } on DioException catch (e) {
      _log('Failed to unregister all tokens: ${e.message}');
    }
  }

  /// Check Firebase status and active token count.
  Future<Map<String, dynamic>?> getDeviceTokenStatus() async {
    try {
      final response = await _dio.get('/notifications/device-tokens/status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _log('Failed to get token status: ${e.message}');
      return null;
    }
  }

  void _log(String message) {
    debugPrint('🔔 FcmApiService: $message');
  }
}
