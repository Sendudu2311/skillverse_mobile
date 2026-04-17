import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../error/exceptions.dart';

/// Centralized error handling utility for the application
class ErrorHandler {
  /// Convert exceptions to user-friendly error messages
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return 'Đã xảy ra lỗi không xác định';
    }

    // Handle AppException first (from ApiClient)
    if (error is AppException) {
      if (error is ServerException &&
          _looksLikeHtmlErrorPage(error.message) &&
          error.statusCode != null) {
        return _handleStatusCode(error.statusCode);
      }
      return error.message;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is SocketException) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra lại.';
    }

    if (error is FormatException) {
      return 'Dữ liệu không hợp lệ. Vui lòng thử lại.';
    }

    if (error is TypeError) {
      return 'Dữ liệu không đúng định dạng';
    }

    // Default error message
    return error.toString().replaceFirst('Exception: ', '');
  }

  static bool _looksLikeHtmlErrorPage(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html') ||
        normalized.contains('<body') ||
        normalized.contains('</html>') ||
        normalized.contains('nginx/') ||
        normalized.contains('<title>');
  }

  /// Handle Dio-specific errors (network, API errors)
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối đến máy chủ quá lâu. Vui lòng thử lại.';

      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu quá lâu. Vui lòng thử lại.';

      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu quá lâu. Vui lòng thử lại.';

      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);

      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet.';

      case DioExceptionType.badCertificate:
        return 'Chứng chỉ bảo mật không hợp lệ';

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'Không có kết nối Internet';
        }
        return 'Đã xảy ra lỗi không xác định';
    }
  }

  /// Handle HTTP status codes
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
      case 409:
        return 'Dữ liệu đã tồn tại hoặc xung đột.';
      case 422:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      case 429:
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
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

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626), // Red-600
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // Green-500
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B), // Orange-500
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Handle async operation with error handling
  static Future<T?> handleAsync<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String? successMessage,
    bool showLoading = false,
  }) async {
    try {
      final result = await operation();

      if (successMessage != null && context.mounted) {
        showSuccessSnackBar(context, successMessage);
      }

      return result;
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
      return null;
    }
  }
}
