import 'package:json_annotation/json_annotation.dart';

part 'payment_models.g.dart';

/// Payment type enum
enum PaymentType {
  @JsonValue('PREMIUM_SUBSCRIPTION')
  premiumSubscription,
  @JsonValue('COURSE_PURCHASE')
  coursePurchase,
  @JsonValue('WALLET_TOPUP')
  walletTopup,
  @JsonValue('REFUND')
  refund,
}

/// Payment status enum
enum PaymentStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('FAILED')
  failed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('REFUNDED')
  refunded,
}

/// Payment method enum
enum PaymentMethod {
  @JsonValue('PAYOS')
  payos,
  @JsonValue('MOMO')
  momo,
  @JsonValue('VNPAY')
  vnpay,
  @JsonValue('BANK_TRANSFER')
  bankTransfer,
  @JsonValue('CREDIT_CARD')
  creditCard,
}

/// Create payment request
@JsonSerializable()
class CreatePaymentRequestDto {
  final double amount;
  final String? currency;
  final PaymentType type;
  final PaymentMethod paymentMethod;
  final String? description;
  final int? planId;
  final int? courseId;
  final String? metadata;
  final String? successUrl;
  final String? cancelUrl;

  const CreatePaymentRequestDto({
    required this.amount,
    this.currency = 'VND',
    required this.type,
    required this.paymentMethod,
    this.description,
    this.planId,
    this.courseId,
    this.metadata,
    this.successUrl,
    this.cancelUrl,
  });

  factory CreatePaymentRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentRequestDtoToJson(this);
}

/// Create payment response
@JsonSerializable()
class CreatePaymentResponseDto {
  final String transactionReference;
  final String checkoutUrl;
  final String? gatewayReferenceId;
  final String? qrCodeUrl;
  final String? deepLinkUrl;
  final String? expiresAt;
  final String? message;

  const CreatePaymentResponseDto({
    required this.transactionReference,
    required this.checkoutUrl,
    this.gatewayReferenceId,
    this.qrCodeUrl,
    this.deepLinkUrl,
    this.expiresAt,
    this.message,
  });

  factory CreatePaymentResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentResponseDtoToJson(this);
}

/// Payment transaction response
@JsonSerializable()
class PaymentTransactionDto {
  final int id;
  final int userId;
  final double amount;
  final String currency;
  final PaymentType type;
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final String? referenceId;
  final String? internalReference;
  final String? description;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentTransactionDto({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.paymentMethod,
    this.referenceId,
    this.internalReference,
    this.description,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentTransactionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentTransactionDtoToJson(this);
}
