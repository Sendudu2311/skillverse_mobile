import 'package:json_annotation/json_annotation.dart';

part 'mentor_models.g.dart';

/// Booking status enum
enum BookingStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('ONGOING')
  ongoing,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('DISPUTED')
  disputed,
  @JsonValue('REFUNDED')
  refunded,
}

/// Recurrence type for availability
enum RecurrenceType {
  @JsonValue('NONE')
  none,
  @JsonValue('DAILY')
  daily,
  @JsonValue('WEEKLY')
  weekly,
  @JsonValue('MONTHLY')
  monthly,
}

/// Social links model
@JsonSerializable()
class SocialLinks {
  final String? linkedin;
  final String? github;
  final String? twitter;
  final String? facebook;
  final String? website;

  SocialLinks({
    this.linkedin,
    this.github,
    this.twitter,
    this.facebook,
    this.website,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) =>
      _$SocialLinksFromJson(json);
  Map<String, dynamic> toJson() => _$SocialLinksToJson(this);
}

/// Mentor profile model from GET /api/mentors
@JsonSerializable()
class MentorProfile {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? bio;
  final String? specialization;
  final int? experience;
  final String? avatar;
  final SocialLinks? socialLinks;
  @JsonKey(defaultValue: [])
  final List<String>? skills;
  @JsonKey(defaultValue: [])
  final List<String>? achievements;
  final double? ratingAverage;
  final int? ratingCount;
  final double? hourlyRate;
  @JsonKey(defaultValue: false)
  final bool preChatEnabled;
  final String? slug;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? skillPoints;
  final int? currentLevel;
  @JsonKey(defaultValue: [])
  final List<String>? badges;

  MentorProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.bio,
    this.specialization,
    this.experience,
    this.avatar,
    this.socialLinks,
    this.skills,
    this.achievements,
    this.ratingAverage,
    this.ratingCount,
    this.hourlyRate,
    this.preChatEnabled = false,
    this.slug,
    this.createdAt,
    this.updatedAt,
    this.skillPoints,
    this.currentLevel,
    this.badges,
  });

  /// Get full name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$first $last'.trim();
  }

  /// Get display name (full name or email)
  String get displayName =>
      fullName.isNotEmpty ? fullName : (email ?? 'Mentor');

  /// Get formatted hourly rate
  String get formattedHourlyRate {
    if (hourlyRate == null) return 'Liên hệ';
    return '${hourlyRate!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VND/giờ';
  }

  factory MentorProfile.fromJson(Map<String, dynamic> json) =>
      _$MentorProfileFromJson(json);
  Map<String, dynamic> toJson() => _$MentorProfileToJson(this);

  MentorProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? bio,
    String? specialization,
    int? experience,
    String? avatar,
    SocialLinks? socialLinks,
    List<String>? skills,
    List<String>? achievements,
    double? ratingAverage,
    int? ratingCount,
    double? hourlyRate,
    bool? preChatEnabled,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? skillPoints,
    int? currentLevel,
    List<String>? badges,
  }) {
    return MentorProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      avatar: avatar ?? this.avatar,
      socialLinks: socialLinks ?? this.socialLinks,
      skills: skills ?? this.skills,
      achievements: achievements ?? this.achievements,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      preChatEnabled: preChatEnabled ?? this.preChatEnabled,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skillPoints: skillPoints ?? this.skillPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      badges: badges ?? this.badges,
    );
  }
}

/// Mentor availability model from GET /api/mentor-availability/{mentorId}
@JsonSerializable()
class MentorAvailability {
  final int id;
  final int mentorId;
  final DateTime startTime;
  final DateTime endTime;
  final RecurrenceType? recurrenceType;
  final DateTime? recurrenceEndDate;
  @JsonKey(defaultValue: false)
  final bool recurring;

  MentorAvailability({
    required this.id,
    required this.mentorId,
    required this.startTime,
    required this.endTime,
    this.recurrenceType,
    this.recurrenceEndDate,
    this.recurring = false,
  });

  /// Get duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Get formatted time range
  String get formattedTimeRange {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  factory MentorAvailability.fromJson(Map<String, dynamic> json) =>
      _$MentorAvailabilityFromJson(json);
  Map<String, dynamic> toJson() => _$MentorAvailabilityToJson(this);
}

/// Booking response model from GET /api/mentor-bookings/me
@JsonSerializable()
class MentorBooking {
  final int id;
  final int mentorId;
  final int learnerId;
  final DateTime startTime;
  final DateTime endTime;
  final int? durationMinutes;
  final BookingStatus status;
  final double? priceVnd;
  final String? meetingLink;
  final String? paymentReference;
  final String? mentorName;
  final String? mentorAvatar;
  final String? learnerName;
  final String? learnerAvatar;

  MentorBooking({
    required this.id,
    required this.mentorId,
    required this.learnerId,
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    required this.status,
    this.priceVnd,
    this.meetingLink,
    this.paymentReference,
    this.mentorName,
    this.mentorAvatar,
    this.learnerName,
    this.learnerAvatar,
  });

  /// Get calculated duration
  int get calculatedDuration =>
      durationMinutes ?? endTime.difference(startTime).inMinutes;

  /// Get formatted price
  String get formattedPrice {
    if (priceVnd == null) return 'N/A';
    return '${priceVnd!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VND';
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.rejected:
        return 'Đã từ chối';
      case BookingStatus.ongoing:
        return 'Đang diễn ra';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.disputed:
        return 'Tranh chấp';
      case BookingStatus.refunded:
        return 'Đã hoàn tiền';
    }
  }

  /// Check if booking can be cancelled
  bool get canCancel =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  /// Check if booking can be rated
  bool get canRate => status == BookingStatus.completed;

  factory MentorBooking.fromJson(Map<String, dynamic> json) =>
      _$MentorBookingFromJson(json);
  Map<String, dynamic> toJson() => _$MentorBookingToJson(this);

  MentorBooking copyWith({
    int? id,
    int? mentorId,
    int? learnerId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    BookingStatus? status,
    double? priceVnd,
    String? meetingLink,
    String? paymentReference,
    String? mentorName,
    String? mentorAvatar,
    String? learnerName,
    String? learnerAvatar,
  }) {
    return MentorBooking(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      learnerId: learnerId ?? this.learnerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      priceVnd: priceVnd ?? this.priceVnd,
      meetingLink: meetingLink ?? this.meetingLink,
      paymentReference: paymentReference ?? this.paymentReference,
      mentorName: mentorName ?? this.mentorName,
      mentorAvatar: mentorAvatar ?? this.mentorAvatar,
      learnerName: learnerName ?? this.learnerName,
      learnerAvatar: learnerAvatar ?? this.learnerAvatar,
    );
  }
}

/// Create booking intent request
@JsonSerializable()
class CreateBookingRequest {
  final int mentorId;
  final DateTime startTime;
  final int durationMinutes;
  final double priceVnd;
  final String paymentMethod; // 'PAYOS' or 'WALLET'
  final String? successUrl;
  final String? cancelUrl;

  CreateBookingRequest({
    required this.mentorId,
    required this.startTime,
    required this.durationMinutes,
    required this.priceVnd,
    required this.paymentMethod,
    this.successUrl,
    this.cancelUrl,
  });

  factory CreateBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBookingRequestToJson(this);
}

/// Pre-chat message model
@JsonSerializable()
class PreChatMessage {
  final int id;
  final int mentorId;
  final int learnerId;
  final int senderId;
  final String content;
  final DateTime createdAt;

  PreChatMessage({
    required this.id,
    required this.mentorId,
    required this.learnerId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  /// Check if message is from current user
  bool isFromUser(int userId) => senderId == userId;

  factory PreChatMessage.fromJson(Map<String, dynamic> json) =>
      _$PreChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$PreChatMessageToJson(this);
}

/// Pre-chat message request
@JsonSerializable()
class PreChatMessageRequest {
  final int mentorId;
  final String content;

  PreChatMessageRequest({required this.mentorId, required this.content});

  factory PreChatMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$PreChatMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PreChatMessageRequestToJson(this);
}

/// Pre-chat thread summary
@JsonSerializable()
class PreChatThread {
  final int counterpartId;
  final String? counterpartName;
  final String? counterpartAvatar;
  final String? lastContent;
  final DateTime? lastTime;
  final int? unreadCount;
  @JsonKey(defaultValue: false)
  final bool myRoleMentor;

  PreChatThread({
    required this.counterpartId,
    this.counterpartName,
    this.counterpartAvatar,
    this.lastContent,
    this.lastTime,
    this.unreadCount,
    this.myRoleMentor = false,
  });

  /// Get display name
  String get displayName => counterpartName ?? 'Người dùng';

  /// Check if has unread messages
  bool get hasUnread => (unreadCount ?? 0) > 0;

  factory PreChatThread.fromJson(Map<String, dynamic> json) =>
      _$PreChatThreadFromJson(json);
  Map<String, dynamic> toJson() => _$PreChatThreadToJson(this);
}

/// Paginated response for bookings
@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  final List<T> content;
  @JsonKey(name: 'number')
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;

  PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PageResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$PageResponseToJson(this, toJsonT);
}

/// Rating request for booking
@JsonSerializable()
class BookingRatingRequest {
  final int rating;
  final String? review;

  BookingRatingRequest({required this.rating, this.review});

  factory BookingRatingRequest.fromJson(Map<String, dynamic> json) =>
      _$BookingRatingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BookingRatingRequestToJson(this);
}
