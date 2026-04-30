import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/environment.dart';
import '../error/exceptions.dart';
import '../../data/services/auth_service.dart';

/// Callback type for triggering force logout from the interceptor.
/// Set by AuthProvider during app initialization.
typedef ForceLogoutCallback = Future<void> Function([String? reason]);

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
  /// Lock to prevent concurrent refresh attempts.
  /// Returns `null` on success, or an error message string on failure.
  Completer<String?>? _refreshLock;

  /// Auth endpoints that should NOT trigger token refresh on 401
  static const _authPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/logout',
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
          final token = _getAuthToken();
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
              final failureReason = await _attemptTokenRefresh();
              if (failureReason == null) {
                // Refresh succeeded — retry original request with new token
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
                // Refresh failed — force logout with reason
                debugPrint(
                  '🚪 Token refresh failed — forcing logout: $failureReason',
                );
                if (onForceLogout != null) {
                  await onForceLogout!(failureReason);
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
  /// Returns `null` on success, or a user-facing error message on failure.
  Future<String?> _attemptTokenRefresh() async {
    // If a refresh is already in progress, wait for it
    if (_refreshLock != null) {
      debugPrint('🔄 Refresh already in progress, waiting...');
      return await _refreshLock!.future;
    }

    // Start a new refresh
    _refreshLock = Completer<String?>();
    debugPrint('🔄 Starting token refresh...');

    try {
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();

      if (newToken != null) {
        _authToken = newToken;
        debugPrint('✅ Token refreshed successfully');
        _refreshLock!.complete(null); // null = success
        return null;
      } else {
        debugPrint('❌ Token refresh returned null');
        const reason = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        _refreshLock!.complete(reason);
        return reason;
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      // Preserve the user-facing message from AuthService/ApiException
      final reason = (e is AppException)
          ? e.message
          : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      _refreshLock!.complete(reason);
      return reason;
    } finally {
      _refreshLock = null;
    }
  }

  /// Retry a failed request with the updated auth token.
  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    debugPrint('🔄 Retrying request: ${requestOptions.path}');

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {'Authorization': 'Bearer $_authToken'},
      ),
    );
  }

  Dio get dio => _dio;

  /// Get current authentication token (e.g. for WebSocket headers)
  String? get authToken => _authToken;

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

  String? _getAuthToken() {
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
              // If not JSON, check if it looks like HTML (e.g. Nginx error page)
              if (responseData.contains('<html') ||
                  responseData.contains('<!DOCTYPE')) {
                message = _statusCodeMessage(statusCode);
              } else {
                message = responseData;
              }
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

  /// Clean status-code message when response body is HTML (e.g. Nginx error page)
  static String _statusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dữ liệu không hợp lệ';
      case 401:
        return 'Phiên đăng nhập đã hết hạn';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu';
      case 500:
        return 'Lỗi máy chủ. Vui lòng thử lại sau';
      case 502:
        return 'Máy chủ không phản hồi. Vui lòng thử lại sau';
      case 503:
        return 'Dịch vụ tạm thời không khả dụng';
      case 504:
        return 'Máy chủ phản hồi quá lâu. Vui lòng thử lại sau';
      default:
        return 'Lỗi từ máy chủ (Mã: $statusCode)';
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
