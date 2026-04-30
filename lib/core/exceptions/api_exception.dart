import 'package:dio/dio.dart';
import '../error/exceptions.dart';

/// Legacy API exception class — now extends [AppException] so that
/// [ErrorHandler.getErrorMessage] handles it through the standard
/// `AppException` branch (HTML-page detection, Vietnamese messages, etc.).
class ApiException extends AppException {
  final int? statusCode;

  ApiException(super.message, [this.statusCode]);

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException('Kết nối đến máy chủ quá lâu. Vui lòng thử lại.');
      case DioExceptionType.sendTimeout:
        return ApiException('Gửi dữ liệu quá lâu. Vui lòng thử lại.');
      case DioExceptionType.receiveTimeout:
        return ApiException('Nhận dữ liệu quá lâu. Vui lòng thử lại.');
      case DioExceptionType.badResponse:
        return ApiException(
          _handleStatusCode(dioException.response?.statusCode),
          dioException.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException('Yêu cầu đã bị hủy');
      case DioExceptionType.unknown:
        if (dioException.message?.contains('SocketException') == true) {
          return ApiException(
            'Không có kết nối Internet. Vui lòng kiểm tra lại.',
          );
        }
        return ApiException('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
      default:
        return ApiException('Đã xảy ra lỗi không xác định. Vui lòng thử lại.');
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu.';
      case 500:
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      case 502:
        return 'Máy chủ không phản hồi. Vui lòng thử lại sau.';
      case 503:
        return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
      default:
        return 'Đã xảy ra lỗi (Mã: $statusCode)';
    }
  }
}
