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
  @JsonValue('RECRUITER_PRO')
  recruiterPro,
}

extension PlanTypeWeight on PlanType {
  int get weight {
    switch (this) {
      case PlanType.freeTier:
        return 0;
      case PlanType.studentPack:
        return 1;
      case PlanType.premiumBasic:
        return 2;
      case PlanType.premiumPlus:
        return 3;
      case PlanType.recruiterPro:
        return 100;
    }
  }
}

/// Target role for premium plans
enum TargetRole {
  @JsonValue('LEARNER')
  learner,
  @JsonValue('RECRUITER')
  recruiter,
  @JsonValue('PARENT')
  parent,
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
  @JsonValue('SUSPENDED')
  suspended,
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
  final TargetRole? targetRole;
  final double? discountPercent;
  final double? discountedPrice;
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
    this.targetRole,
    this.discountPercent,
    this.discountedPrice,
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
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final PremiumPlanDto plan;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final SubscriptionStatus status;
  final bool? isStudentSubscription;
  final bool? isDiscountedSubscription;
  final bool? autoRenew;
  final double? renewalPrice;
  final DateTime? renewalAttemptDate;
  final DateTime? renewalPriceLockedAt;
  final PremiumPlanDto? scheduledChangePlan;
  final DateTime? scheduledChangeEffectiveDate;
  final bool? scheduledChangeAutoRenew;
  final double? scheduledChangeRenewalPrice;
  final DateTime? scheduledChangeRenewalAttemptDate;
  final int? paymentTransactionId;
  final int? daysRemaining;
  final bool? currentlyActive;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserSubscriptionDto({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
    this.isStudentSubscription,
    this.isDiscountedSubscription,
    this.autoRenew,
    this.renewalPrice,
    this.renewalAttemptDate,
    this.renewalPriceLockedAt,
    this.scheduledChangePlan,
    this.scheduledChangeEffectiveDate,
    this.scheduledChangeAutoRenew,
    this.scheduledChangeRenewalPrice,
    this.scheduledChangeRenewalAttemptDate,
    this.paymentTransactionId,
    this.daysRemaining,
    this.currentlyActive,
    this.cancellationReason,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
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

// ==================== CHECKOUT PREVIEW ====================

/// Pricing mode for checkout preview
enum PricingMode {
  @JsonValue('FULL_PURCHASE')
  fullPurchase,
  @JsonValue('UPGRADE_PRORATED')
  upgradeProrated,
  @JsonValue('UPGRADE_GRACE_WINDOW')
  upgradeGraceWindow,
  @JsonValue('UPGRADE_FULL_PRICE')
  upgradeFullPrice,
  @JsonValue('UPGRADE_NOT_ALLOWED')
  upgradeNotAllowed,
  @JsonValue('CURRENT_PLAN')
  currentPlan,
  @JsonValue('DOWNGRADE_NOT_ALLOWED')
  downgradeNotAllowed,
  @JsonValue('DOWNGRADE_SCHEDULED')
  downgradeScheduled,
}

/// Checkout preview response — pricing info for upgrade/downgrade
@JsonSerializable()
class CheckoutPreviewDto {
  final bool eligible;
  final bool upgrade;
  final bool samePlan;
  final bool downgrade;
  final int? buyerUserId;
  final int? targetUserId;
  final int? currentSubscriptionId;
  final PremiumPlanDto? currentPlan;
  final PremiumPlanDto? targetPlan;
  final double? fullPrice;
  final double? effectivePrice;
  final double? amountDue;
  final double? currentPlanCredit;
  final double? proratedTargetPrice;
  final int? remainingDays;
  final DateTime? nextRenewalDate;
  final String? currency;
  @JsonKey(unknownEnumValue: PricingMode.fullPurchase)
  final PricingMode? pricingMode;
  final String? message;
  final bool? discountApplied;

  const CheckoutPreviewDto({
    required this.eligible,
    this.upgrade = false,
    this.samePlan = false,
    this.downgrade = false,
    this.buyerUserId,
    this.targetUserId,
    this.currentSubscriptionId,
    this.currentPlan,
    this.targetPlan,
    this.fullPrice,
    this.effectivePrice,
    this.amountDue,
    this.currentPlanCredit,
    this.proratedTargetPrice,
    this.remainingDays,
    this.nextRenewalDate,
    this.currency,
    this.pricingMode,
    this.message,
    this.discountApplied,
  });

  factory CheckoutPreviewDto.fromJson(Map<String, dynamic> json) =>
      _$CheckoutPreviewDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CheckoutPreviewDtoToJson(this);
}
