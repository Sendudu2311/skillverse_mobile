import 'package:json_annotation/json_annotation.dart';
import 'payment_models.dart';

part 'premium_models.g.dart';

/// Plan type enum
enum PlanType {
  @JsonValue('FREE_TIER')
  freeTier,
  @JsonValue('PREMIUM_BASIC')
  premiumBasic,
  @JsonValue('PREMIUM_PLUS')
  premiumPlus,
  @JsonValue('STUDENT_PACK')
  studentPack,
}

/// Subscription status enum
enum SubscriptionStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('PENDING')
  pending,
}

/// Premium plan response
@JsonSerializable()
class PremiumPlanDto {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final int durationMonths;
  final double price;
  final String currency;
  final PlanType planType;
  final double? studentDiscountPercent;
  final double? studentPrice;
  final List<String>? features;
  final bool isActive;
  final int? maxSubscribers;
  final int? currentSubscribers;
  final bool? availableForSubscription;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PremiumPlanDto({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.durationMonths,
    required this.price,
    required this.currency,
    required this.planType,
    this.studentDiscountPercent,
    this.studentPrice,
    this.features,
    required this.isActive,
    this.maxSubscribers,
    this.currentSubscribers,
    this.availableForSubscription,
    this.createdAt,
    this.updatedAt,
  });

  factory PremiumPlanDto.fromJson(Map<String, dynamic> json) =>
      _$PremiumPlanDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PremiumPlanDtoToJson(this);
}

/// User subscription response
@JsonSerializable()
class UserSubscriptionDto {
  final int id;
  final int userId;
  final PremiumPlanDto plan;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final SubscriptionStatus status;
  final bool? isStudentSubscription;
  final bool? autoRenew;
  final int? paymentTransactionId;
  final int? daysRemaining;
  final bool? currentlyActive;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSubscriptionDto({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
    this.isStudentSubscription,
    this.autoRenew,
    this.paymentTransactionId,
    this.daysRemaining,
    this.currentlyActive,
    this.cancellationReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscriptionDto.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserSubscriptionDtoToJson(this);
}

/// Create subscription request
@JsonSerializable()
class CreateSubscriptionRequestDto {
  final int planId;
  final PaymentMethod paymentMethod;
  final bool? applyStudentDiscount;
  final bool? autoRenew;
  final String? successUrl;
  final String? cancelUrl;
  final String? couponCode;

  const CreateSubscriptionRequestDto({
    required this.planId,
    required this.paymentMethod,
    this.applyStudentDiscount,
    this.autoRenew,
    this.successUrl,
    this.cancelUrl,
    this.couponCode,
  });

  factory CreateSubscriptionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateSubscriptionRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSubscriptionRequestDtoToJson(this);
}
