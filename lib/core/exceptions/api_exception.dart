import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException('Connection timeout. Please check your internet connection.');
      case DioExceptionType.sendTimeout:
        return const ApiException('Request timeout. Please try again.');
      case DioExceptionType.receiveTimeout:
        return const ApiException('Response timeout. Please try again.');
      case DioExceptionType.badResponse:
        return ApiException(
          _handleStatusCode(dioException.response?.statusCode),
          dioException.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const ApiException('Request cancelled.');
      case DioExceptionType.unknown:
        if (dioException.message?.contains('SocketException') == true) {
          return const ApiException('No internet connection. Please check your network.');
        }
        return const ApiException('Something went wrong. Please try again.');
      default:
        return const ApiException('Something went wrong. Please try again.');
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Forbidden. You don\'t have permission to access this resource.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => message;
}