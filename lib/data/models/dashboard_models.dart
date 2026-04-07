import 'package:json_annotation/json_annotation.dart';
import 'enrollment_models.dart';

part 'dashboard_models.g.dart';

/// Wallet response from /wallet/my-wallet
@JsonSerializable()
class WalletResponse {
  final int walletId;
  final int userId;
  final int cashBalance;
  final int coinBalance;
  final int frozenCashBalance;
  final int availableCashBalance;
  final int totalDeposited;
  final int totalWithdrawn;
  final int totalCoinsEarned;
  final int totalCoinsSpent;
  final String status;
  final bool hasBankAccount;
  final bool hasTransactionPin;
  final bool require2FA;
  final String createdAt;
  final String? lastTransactionAt;

  WalletResponse({
    required this.walletId,
    required this.userId,
    required this.cashBalance,
    required this.coinBalance,
    required this.frozenCashBalance,
    required this.availableCashBalance,
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.totalCoinsEarned,
    required this.totalCoinsSpent,
    required this.status,
    required this.hasBankAccount,
    required this.hasTransactionPin,
    required this.require2FA,
    required this.createdAt,
    this.lastTransactionAt,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletResponseToJson(this);
}

/// Usage stats response from /usage/stats
@JsonSerializable()
class UsageStatsResponse {
  final int enrolledCoursesCount;
  final int completedCoursesCount;
  final int completedProjectsCount;
  final int certificatesCount;
  final int totalHoursStudied;
  final int currentStreak;
  final int longestStreak;
  final List<bool> weeklyActivity;
  final String cycleStartDate;
  final String cycleEndDate;

  UsageStatsResponse({
    required this.enrolledCoursesCount,
    required this.completedCoursesCount,
    required this.completedProjectsCount,
    required this.certificatesCount,
    required this.totalHoursStudied,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyActivity,
    required this.cycleStartDate,
    required this.cycleEndDate,
  });

  factory UsageStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$UsageStatsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UsageStatsResponseToJson(this);
}

/// Subscription plan info
@JsonSerializable()
class PlanInfo {
  final int id;
  final String name;
  final String displayName;
  final String description;
  final int durationMonths;
  final int price;
  final String currency;
  final String planType;
  final int studentDiscountPercent;
  final int studentPrice;
  final List<String> features;
  final bool isActive;
  final int currentSubscribers;
  final bool availableForSubscription;

  PlanInfo({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.durationMonths,
    required this.price,
    required this.currency,
    required this.planType,
    required this.studentDiscountPercent,
    required this.studentPrice,
    required this.features,
    required this.isActive,
    required this.currentSubscribers,
    required this.availableForSubscription,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) =>
      _$PlanInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PlanInfoToJson(this);
}

/// Subscription response from /premium/subscription/current
@JsonSerializable()
class SubscriptionResponse {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String userAvatarUrl;
  final PlanInfo plan;
  final String startDate;
  final String endDate;
  final bool isActive;
  final String status;
  final bool isStudentSubscription;
  final bool autoRenew;
  final int daysRemaining;
  final bool currentlyActive;
  final String createdAt;

  SubscriptionResponse({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userAvatarUrl,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.status,
    required this.isStudentSubscription,
    required this.autoRenew,
    required this.daysRemaining,
    required this.currentlyActive,
    required this.createdAt,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionResponseToJson(this);
}

/// Roadmap session summary from /v1/ai/roadmap
@JsonSerializable()
class RoadmapSession {
  final int sessionId;
  final String title;
  final String originalGoal;
  final String validatedGoal;
  final String duration;
  final String experienceLevel;
  final String learningStyle;
  final int totalQuests;
  final int completedQuests;
  final int progressPercentage;
  final String difficultyLevel;
  final int schemaVersion;
  final String? status; // ACTIVE, PAUSED, DELETED
  final String createdAt;

  RoadmapSession({
    required this.sessionId,
    required this.title,
    required this.originalGoal,
    required this.validatedGoal,
    required this.duration,
    required this.experienceLevel,
    required this.learningStyle,
    required this.totalQuests,
    required this.completedQuests,
    required this.progressPercentage,
    required this.difficultyLevel,
    required this.schemaVersion,
    this.status,
    required this.createdAt,
  });

  factory RoadmapSession.fromJson(Map<String, dynamic> json) =>
      _$RoadmapSessionFromJson(json);

  Map<String, dynamic> toJson() => _$RoadmapSessionToJson(this);
}

/// Aggregate dashboard data combining all API responses
class DashboardData {
  final WalletResponse? wallet;
  final UsageStatsResponse? usageStats;
  final SubscriptionResponse? subscription;
  final List<RoadmapSession> roadmaps;
  final EnrollmentDetailDto? continueLearning;

  DashboardData({
    this.wallet,
    this.usageStats,
    this.subscription,
    this.roadmaps = const [],
    this.continueLearning,
  });

  DashboardData copyWith({
    WalletResponse? wallet,
    UsageStatsResponse? usageStats,
    SubscriptionResponse? subscription,
    List<RoadmapSession>? roadmaps,
    EnrollmentDetailDto? continueLearning,
  }) {
    return DashboardData(
      wallet: wallet ?? this.wallet,
      usageStats: usageStats ?? this.usageStats,
      subscription: subscription ?? this.subscription,
      roadmaps: roadmaps ?? this.roadmaps,
      continueLearning: continueLearning ?? this.continueLearning,
    );
  }
}
