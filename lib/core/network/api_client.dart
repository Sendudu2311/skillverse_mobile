import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/environment.dart';
import '../error/exceptions.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  String? _authToken;

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

    // Add auth interceptor
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
        onError: (error, handler) {
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
        final message = error.response?.data?['message'] ?? 'Lỗi từ máy chủ';
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
