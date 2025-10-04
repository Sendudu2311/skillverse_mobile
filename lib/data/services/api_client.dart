import 'package:dio/dio.dart';
import '../../core/constants/environment.dart';
import '../../core/exceptions/api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  Dio? _dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  Dio get dio {
    _dio ??= _initializeDio();
    return _dio!;
  }

  Dio _initializeDio() {
    final dio = Dio(BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, ErrorInterceptorHandler handler) {
        throw ApiException.fromDioException(e);
      },
    ));

    return dio;
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}