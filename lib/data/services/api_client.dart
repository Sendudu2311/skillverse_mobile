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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('*** API Log ***\n$obj'),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        // Log successful responses
        print('*** Response ***');
        print('uri: ${response.requestOptions.uri}');
        print('statusCode: ${response.statusCode}');
        print('headers:');
        response.headers.forEach((name, values) {
          print(' $name: ${values.join(", ")}');
        });
        print('Response Text:');
        print(response.data);
        handler.next(response);
      },
      onError: (DioException e, ErrorInterceptorHandler handler) {
        // Log detailed error information
        print('*** DioException ***:');
        print('uri: ${e.requestOptions.uri}');
        print(e);
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