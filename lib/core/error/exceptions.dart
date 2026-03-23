abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException(super.message, {this.statusCode, super.code});
}

class TimeoutException extends AppException {
  TimeoutException() : super('Kết nối quá thời gian');
}

class UnknownException extends AppException {
  UnknownException([String? message]) : super(message ?? 'Đã có lỗi xảy ra');
}