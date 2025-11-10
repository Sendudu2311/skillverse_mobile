import 'package:flutter/foundation.dart';
import '../../data/models/payment_models.dart';
import '../../data/services/payment_service.dart';
import 'package:dio/dio.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<PaymentTransactionDto> _paymentHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  CreatePaymentResponseDto? _lastPaymentResponse;

  List<PaymentTransactionDto> get paymentHistory => _paymentHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
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
      _isLoading = false;
      notifyListeners();
      return response;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = e.response?.data['message'] ?? 'Lỗi tạo thanh toán';
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Load payment history
  Future<void> loadPaymentHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _paymentHistory = await _paymentService.getPaymentHistory();
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage =
          e.response?.data['message'] ?? 'Lỗi tải lịch sử thanh toán';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Get payment by reference
  Future<PaymentTransactionDto?> getPaymentByReference(
      String internalReference) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payment = await _paymentService.getPaymentByReference(
        internalReference: internalReference,
      );
      _isLoading = false;
      notifyListeners();
      return payment;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage =
          e.response?.data['message'] ?? 'Lỗi tải thông tin thanh toán';
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Cancel payment
  Future<bool> cancelPayment(String internalReference,
      {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _paymentService.cancelPayment(
        internalReference: internalReference,
        reason: reason,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = e.response?.data['message'] ?? 'Lỗi hủy thanh toán';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear last payment response
  void clearLastPaymentResponse() {
    _lastPaymentResponse = null;
    notifyListeners();
  }
}
