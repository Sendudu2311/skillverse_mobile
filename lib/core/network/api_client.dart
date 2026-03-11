import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/environment.dart';
import '../error/exceptions.dart';
import '../../data/services/auth_service.dart';

/// Callback type for triggering force logout from the interceptor.
/// Set by AuthProvider during app initialization.
typedef ForceLogoutCallback = Future<void> Function();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  String? _authToken;

  /// Callback to force logout when token refresh fails.
  /// This is set by AuthProvider so the interceptor can trigger logout
  /// without a direct dependency on AuthProvider.
  ForceLogoutCallback? onForceLogout;

  /// Lock to prevent concurrent refresh attempts.
  /// When a 401 occurs, the first request starts the refresh.
  /// Subsequent 401s wait for the same refresh to complete.
  Completer<bool>? _refreshLock;

  /// Auth endpoints that should NOT trigger token refresh on 401
  static const _authPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/google',
    '/auth/verify-email',
    '/auth/resend-otp',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.backendUrl,
        connectTimeout: Duration(milliseconds: Environment.apiTimeout),
        receiveTimeout: Duration(milliseconds: Environment.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (Environment.isDebug) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // Add auth + token refresh interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized — attempt token refresh
          if (error.response?.statusCode == 401) {
            final requestPath = error.requestOptions.path;

            // Don't attempt refresh for auth endpoints
            final isAuthEndpoint = _authPaths.any(
              (path) => requestPath.contains(path),
            );

            if (!isAuthEndpoint) {
              final refreshed = await _attemptTokenRefresh();
              if (refreshed) {
                // Retry original request with new token
                try {
                  final retryResponse = await _retryRequest(
                    error.requestOptions,
                  );
                  return handler.resolve(retryResponse);
                } catch (retryError) {
                  // Retry also failed — fall through to normal error handling
                  debugPrint('🔄 Retry after refresh failed: $retryError');
                }
              } else {
                // Refresh failed — force logout
                debugPrint('🚪 Token refresh failed — forcing logout');
                if (onForceLogout != null) {
                  await onForceLogout!();
                }
              }
            }
          }

          // Default error handling
          final appException = _handleError(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: appException,
            ),
          );
        },
      ),
    );
  }

  /// Attempt to refresh the access token.
  /// Uses a lock so concurrent 401s share a single refresh attempt.
  Future<bool> _attemptTokenRefresh() async {
    // If a refresh is already in progress, wait for it
    if (_refreshLock != null) {
      debugPrint('🔄 Refresh already in progress, waiting...');
      return await _refreshLock!.future;
    }

    // Start a new refresh
    _refreshLock = Completer<bool>();
    debugPrint('🔄 Starting token refresh...');

    try {
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();

      if (newToken != null) {
        _authToken = newToken;
        debugPrint('✅ Token refreshed successfully');
        _refreshLock!.complete(true);
        return true;
      } else {
        debugPrint('❌ Token refresh returned null');
        _refreshLock!.complete(false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      _refreshLock!.complete(false);
      return false;
    } finally {
      _refreshLock = null;
    }
  }

  /// Retry a failed request with the updated auth token.
  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    debugPrint('🔄 Retrying request: ${requestOptions.path}');

    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $_authToken',
      },
    );

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Dio get dio => _dio;

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
    debugPrint(
      '🔐 Token set: ${token != null ? "YES (${token.substring(0, 20)}...)" : "NO"}',
    );
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    debugPrint('🔓 Token cleared');
  }

  Future<String?> _getAuthToken() async {
    debugPrint(
      '🔍 Getting token: ${_authToken != null ? "Found" : "Not found"}',
    );
    return _authToken;
  }

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException();
      case DioExceptionType.connectionError:
        return NetworkException('Không thể kết nối đến máy chủ');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String message = 'Lỗi từ máy chủ';

        // Try to extract message from response
        final responseData = error.response?.data;
        if (responseData != null) {
          if (responseData is Map) {
            message = responseData['message'] ?? message;
          } else if (responseData is String) {
            // Try to parse JSON from String
            try {
              final jsonData = jsonDecode(responseData);
              if (jsonData is Map && jsonData['message'] != null) {
                message = jsonData['message'];
              }
            } catch (_) {
              // If not JSON, use the string as is
              message = responseData;
            }
          }
        }

        return ServerException(message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return NetworkException('Yêu cầu đã bị hủy');
      default:
        return UnknownException(error.message);
    }
  }

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw error is AppException ? error : _handleError(e);
    }
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw error is AppException ? error : _handleError(e);
    }
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw error is AppException ? error : _handleError(e);
    }
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw error is AppException ? error : _handleError(e);
    }
  }
}
