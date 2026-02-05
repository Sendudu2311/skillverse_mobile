class SubscriptionResponse {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final PremiumPlan plan;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String status;
  final bool isStudentSubscription;
  final bool autoRenew;
  final int daysRemaining;
  final bool currentlyActive;
  final DateTime createdAt;

  SubscriptionResponse({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
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

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponse(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      plan: PremiumPlan.fromJson(json['plan'] as Map<String, dynamic>),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
      status: json['status'] as String,
      isStudentSubscription: json['isStudentSubscription'] as bool,
      autoRenew: json['autoRenew'] as bool,
      daysRemaining: json['daysRemaining'] as int,
      currentlyActive: json['currentlyActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatarUrl': userAvatarUrl,
      'plan': plan.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'status': status,
      'isStudentSubscription': isStudentSubscription,
      'autoRenew': autoRenew,
      'daysRemaining': daysRemaining,
      'currentlyActive': currentlyActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PremiumPlan {
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

  PremiumPlan({
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

  factory PremiumPlan.fromJson(Map<String, dynamic> json) {
    // Parse features - handle both string array and nested JSON string
    List<String> parseFeatures(dynamic featuresData) {
      if (featuresData is List) {
        return featuresData.map((e) => e.toString()).toList();
      }
      return [];
    }

    return PremiumPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      durationMonths: json['durationMonths'] as int,
      price: json['price'] as int,
      currency: json['currency'] as String,
      planType: json['planType'] as String,
      studentDiscountPercent: json['studentDiscountPercent'] as int,
      studentPrice: json['studentPrice'] as int,
      features: parseFeatures(json['features']),
      isActive: json['isActive'] as bool,
      currentSubscribers: json['currentSubscribers'] as int,
      availableForSubscription: json['availableForSubscription'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'description': description,
      'durationMonths': durationMonths,
      'price': price,
      'currency': currency,
      'planType': planType,
      'studentDiscountPercent': studentDiscountPercent,
      'studentPrice': studentPrice,
      'features': features,
      'isActive': isActive,
      'currentSubscribers': currentSubscribers,
      'availableForSubscription': availableForSubscription,
    };
  }
}
