import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/core/error/exceptions.dart';
import 'package:skillverse_mobile/core/exceptions/api_exception.dart';
import 'package:dio/dio.dart';

void main() {
  // ============================================================
  // AppException Hierarchy Tests
  // ============================================================
  group('AppException hierarchy', () {
    test('NetworkException has correct message', () {
      final e = NetworkException('No internet');
      expect(e.message, 'No internet');
      expect(e.toString(), contains('No internet'));
    });

    test('AuthException has message and optional code', () {
      final e = AuthException('Unauthorized', code: '401');
      expect(e.message, 'Unauthorized');
      expect(e.code, '401');
    });

    test('ValidationException has correct message', () {
      final e = ValidationException('Invalid input');
      expect(e.message, 'Invalid input');
    });

    test('ServerException has message and statusCode', () {
      final e = ServerException('Internal error', statusCode: 500);
      expect(e.message, 'Internal error');
      expect(e.statusCode, 500);
    });

    test('TimeoutException has default message', () {
      final e = TimeoutException();
      expect(e.message, isNotEmpty);
    });

    test('UnknownException with custom message', () {
      final e = UnknownException('Something happened');
      expect(e.message, 'Something happened');
    });

    test('UnknownException with default message', () {
      final e = UnknownException();
      expect(e.message, isNotEmpty);
    });

    test('all are instances of AppException', () {
      expect(NetworkException('test'), isA<AppException>());
      expect(AuthException('test'), isA<AppException>());
      expect(ValidationException('test'), isA<AppException>());
      expect(ServerException('test'), isA<AppException>());
      expect(TimeoutException(), isA<AppException>());
      expect(UnknownException(), isA<AppException>());
    });
  });

  // ============================================================
  // ApiException Tests
  // ============================================================
  group('ApiException', () {
    test('constructor sets message and statusCode', () {
      final e = ApiException('Bad request', 400);
      expect(e.message, 'Bad request');
      expect(e.statusCode, 400);
    });

    test('toString returns message', () {
      final e = ApiException('Error occurred');
      expect(e.toString(), 'Error occurred');
    });

    test('extends AppException and implements Exception', () {
      final e = ApiException('test');
      expect(e, isA<AppException>());
      expect(e, isA<Exception>());
    });
  });

  group('ApiException.fromDioException()', () {
    test('connectionTimeout returns timeout message', () {
      final dioError = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.message, contains('quá lâu'));
    });

    test('sendTimeout returns timeout message', () {
      final dioError = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.message, contains('quá lâu'));
    });

    test('receiveTimeout returns timeout message', () {
      final dioError = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.message, contains('quá lâu'));
    });

    test('cancel returns cancelled message', () {
      final dioError = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.message, contains('hủy'));
    });

    test('badResponse 400 returns bad request', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 400,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.statusCode, 400);
      expect(e.message, contains('không hợp lệ'));
    });

    test('badResponse 401 returns unauthorized', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.statusCode, 401);
      expect(e.message, contains('đăng nhập'));
    });

    test('badResponse 403 returns forbidden', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 403,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.statusCode, 403);
      expect(e.message, contains('quyền'));
    });

    test('badResponse 404 returns not found', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.statusCode, 404);
      expect(e.message, contains('Không tìm thấy'));
    });

    test('badResponse 500 returns server error', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.statusCode, 500);
      expect(e.message, contains('máy chủ'));
    });

    test('unknown with SocketException returns no internet', () {
      final dioError = DioException(
        type: DioExceptionType.unknown,
        requestOptions: RequestOptions(path: '/test'),
        message: 'SocketException: Connection refused',
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.message, contains('Internet'));
    });

    test('unknown without SocketException returns generic error', () {
      final dioError = DioException(
        type: DioExceptionType.unknown,
        requestOptions: RequestOptions(path: '/test'),
        message: 'Some other error',
      );
      final e = ApiException.fromDioException(dioError);
      expect(e.message, isNotEmpty);
    });
  });
}
