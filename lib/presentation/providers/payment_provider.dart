import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/payment_models.dart';
import '../../data/services/payment_service.dart';

/// Payment Provider
///
/// Uses [LoadingStateProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
class PaymentProvider with ChangeNotifier, LoadingStateProviderMixin {
  final PaymentService _paymentService = PaymentService();

  List<PaymentTransactionDto> _paymentHistory = [];
  CreatePaymentResponseDto? _lastPaymentResponse;

  List<PaymentTransactionDto> get paymentHistory => _paymentHistory;
  CreatePaymentResponseDto? get lastPaymentResponse => _lastPaymentResponse;

  /// Create a payment (for course purchase or subscription)
  Future<CreatePaymentResponseDto?> createPayment({
    required double amount,
    required PaymentType type,
    required PaymentMethod paymentMethod,
    String? description,
    int? planId,
    int? courseId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    return await executeAsync(() async {
      final request = CreatePaymentRequestDto(
        amount: amount,
        currency: 'VND',
        type: type,
        paymentMethod: paymentMethod,
        description: description,
        planId: planId,
        courseId: courseId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      final response = await _paymentService.createPayment(request: request);
      _lastPaymentResponse = response;
      notifyListeners();
      return response;
    }, errorMessageBuilder: (e) => _extractErrorMessage(e, 'Lỗi tạo thanh toán'));
  }

  /// Load payment history
  Future<void> loadPaymentHistory() async {
    await executeAsync(() async {
      _paymentHistory = await _paymentService.getPaymentHistory();
      notifyListeners();
    }, errorMessageBuilder: (e) => _extractErrorMessage(e, 'Lỗi tải lịch sử thanh toán'));
  }

  /// Get payment by reference
  Future<PaymentTransactionDto?> getPaymentByReference(
      String internalReference) async {
    final result = await executeAsync<PaymentTransactionDto?>(() async {
      return await _paymentService.getPaymentByReference(
        internalReference: internalReference,
      );
    }, errorMessageBuilder: (e) => _extractErrorMessage(e, 'Lỗi tải thông tin thanh toán'));
    return result;
  }

  /// Cancel payment
  Future<bool> cancelPayment(String internalReference,
      {String? reason}) async {
    final result = await executeAsync(() async {
      await _paymentService.cancelPayment(
        internalReference: internalReference,
        reason: reason,
      );
      return true;
    }, errorMessageBuilder: (e) => _extractErrorMessage(e, 'Lỗi hủy thanh toán'));
    return result ?? false;
  }

  /// Clear error message
  @override
  void clearError() => super.clearError();

  /// Clear last payment response
  void clearLastPaymentResponse() {
    _lastPaymentResponse = null;
    notifyListeners();
  }

  // Helper: extract error message from DioException or generic error
  String _extractErrorMessage(dynamic e, String fallback) {
    if (e is DioException && e.response?.data is Map) {
      return (e.response!.data as Map)['message']?.toString() ?? fallback;
    }
    return 'Lỗi không xác định: ${e.toString()}';
  }
}
