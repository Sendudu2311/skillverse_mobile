import '../models/payment_models.dart';
import '../../core/network/api_client.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Create a new payment
  /// POST /payments/create
  Future<CreatePaymentResponseDto> createPayment({
    required CreatePaymentRequestDto request,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/payments/create',
        data: request.toJson(),
      );
      return CreatePaymentResponseDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get payment history for authenticated user
  /// GET /payments/history
  Future<List<PaymentTransactionDto>> getPaymentHistory() async {
    try {
      final response = await _apiClient.dio.get('/payments/history');

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              PaymentTransactionDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get payment by internal reference
  /// GET /payments/transaction/{internalReference}
  Future<PaymentTransactionDto?> getPaymentByReference({
    required String internalReference,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/payments/transaction/$internalReference',
      );
      return PaymentTransactionDto.fromJson(response.data);
    } catch (e) {
      // Return null if not found (404)
      return null;
    }
  }

  /// Get payment by ID
  /// GET /payments/transaction/id/{paymentId}
  Future<PaymentTransactionDto?> getPaymentById({
    required int paymentId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/payments/transaction/id/$paymentId',
      );
      return PaymentTransactionDto.fromJson(response.data);
    } catch (e) {
      // Return null if not found (404)
      return null;
    }
  }

  /// Cancel a pending payment
  /// PUT /payments/cancel/{internalReference}
  Future<void> cancelPayment({
    required String internalReference,
    String? reason,
  }) async {
    try {
      await _apiClient.dio.put(
        '/payments/cancel/$internalReference',
        queryParameters: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update payment status (internal use)
  /// PUT /payments/status/{internalReference}
  Future<PaymentTransactionDto> updatePaymentStatus({
    required String internalReference,
    required PaymentStatus status,
    String? failureReason,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'status': status.toString().split('.').last.toUpperCase(),
      };
      if (failureReason != null) {
        queryParams['failureReason'] = failureReason;
      }

      final response = await _apiClient.dio.put(
        '/payments/status/$internalReference',
        queryParameters: queryParams,
      );
      return PaymentTransactionDto.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
