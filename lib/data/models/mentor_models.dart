import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/number_formatter.dart';

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
  @JsonValue('MENTORING_ACTIVE')
  mentoringActive,
  @JsonValue('PENDING_COMPLETION')
  pendingCompletion,
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
  final double? roadmapMentoringPrice;
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
    this.roadmapMentoringPrice,
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
    return '${NumberFormatter.formatAmount(hourlyRate!)} VND/giờ';
  }

  String get formattedRoadmapMentoringPrice {
    if (roadmapMentoringPrice == null) return 'Liên hệ';
    return NumberFormatter.formatCurrency(roadmapMentoringPrice!);
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
    double? roadmapMentoringPrice,
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
      roadmapMentoringPrice:
          roadmapMentoringPrice ?? this.roadmapMentoringPrice,
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

  /// Get formatted time range (always in device local timezone)
  String get formattedTimeRange {
    final s = startTime.toLocal();
    final e = endTime.toLocal();
    final start =
        '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
    final end =
        '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
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
  final DateTime? createdAt;
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
  final bool? confirmedByLearner;
  final DateTime? mentorCompletedAt;
  final DateTime? learnerConfirmedAt;
  final DateTime? learnerCompletedAt;
  final DateTime? completionDeadline;
  final int? disputeId;
  final bool? chatAllowed;
  // V3: Context fields from backend BookingResponse
  final String? bookingType;
  final int? journeyId;
  final int? roadmapSessionId;

  MentorBooking({
    required this.id,
    required this.mentorId,
    required this.learnerId,
    this.createdAt,
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
    this.confirmedByLearner,
    this.mentorCompletedAt,
    this.learnerConfirmedAt,
    this.learnerCompletedAt,
    this.completionDeadline,
    this.disputeId,
    this.chatAllowed,
    this.bookingType,
    this.journeyId,
    this.roadmapSessionId,
  });

  /// Get calculated duration
  int get calculatedDuration =>
      durationMinutes ?? endTime.difference(startTime).inMinutes;

  /// Get formatted price
  String get formattedPrice {
    if (priceVnd == null) return 'N/A';
    return NumberFormatter.formatCurrency(priceVnd!);
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
      case BookingStatus.mentoringActive:
        return 'Đang mentoring';
      case BookingStatus.pendingCompletion:
        return 'Chờ xác nhận hoàn thành';
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

  /// Check if learner can confirm session completion.
  /// Backend allows confirm-complete from ONGOING, CONFIRMED, or PENDING_COMPLETION
  /// — for ONGOING/CONFIRMED, the session must have already ended.
  bool get canConfirmComplete {
    if (status == BookingStatus.pendingCompletion) return true;
    if (status == BookingStatus.ongoing || status == BookingStatus.confirmed) {
      return DateTime.now().isAfter(endTime);
    }
    return false;
  }

  /// Check if a dispute can be opened.
  /// PENDING_COMPLETION / MENTORING_ACTIVE: always allowed.
  /// ONGOING/CONFIRMED: only after endTime.
  bool get canOpenDispute {
    if (status == BookingStatus.pendingCompletion) return true;
    if (status == BookingStatus.mentoringActive) return true;
    if (status == BookingStatus.ongoing || status == BookingStatus.confirmed) {
      return DateTime.now().isAfter(endTime);
    }
    return false;
  }

  /// Check if chat is allowed. Prefer backend-provided chatAllowed when present.
  bool get canChat {
    if (chatAllowed != null) return chatAllowed!;
    return status == BookingStatus.pending ||
        status == BookingStatus.confirmed ||
        status == BookingStatus.ongoing ||
        status == BookingStatus.mentoringActive;
  }

  bool get isRoadmapMentoring => bookingType == 'ROADMAP_MENTORING';

  bool get hasRoadmapWorkspace =>
      isRoadmapMentoring &&
      roadmapSessionId != null &&
      journeyId != null &&
      (status == BookingStatus.confirmed ||
          status == BookingStatus.mentoringActive ||
          status == BookingStatus.pendingCompletion ||
          status == BookingStatus.completed ||
          status == BookingStatus.disputed);

  factory MentorBooking.fromJson(Map<String, dynamic> json) =>
      _$MentorBookingFromJson(json);
  Map<String, dynamic> toJson() => _$MentorBookingToJson(this);

  MentorBooking copyWith({
    int? id,
    int? mentorId,
    int? learnerId,
    DateTime? createdAt,
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
    bool? confirmedByLearner,
    DateTime? mentorCompletedAt,
    DateTime? learnerConfirmedAt,
    DateTime? learnerCompletedAt,
    DateTime? completionDeadline,
    int? disputeId,
    bool? chatAllowed,
    String? bookingType,
    int? journeyId,
    int? roadmapSessionId,
  }) {
    return MentorBooking(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      learnerId: learnerId ?? this.learnerId,
      createdAt: createdAt ?? this.createdAt,
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
      confirmedByLearner: confirmedByLearner ?? this.confirmedByLearner,
      mentorCompletedAt: mentorCompletedAt ?? this.mentorCompletedAt,
      learnerConfirmedAt: learnerConfirmedAt ?? this.learnerConfirmedAt,
      learnerCompletedAt: learnerCompletedAt ?? this.learnerCompletedAt,
      completionDeadline: completionDeadline ?? this.completionDeadline,
      disputeId: disputeId ?? this.disputeId,
      chatAllowed: chatAllowed ?? this.chatAllowed,
      bookingType: bookingType ?? this.bookingType,
      journeyId: journeyId ?? this.journeyId,
      roadmapSessionId: roadmapSessionId ?? this.roadmapSessionId,
    );
  }
}

String _dateTimeToUtcIso8601String(DateTime time) =>
    time.toUtc().toIso8601String();

/// Create booking intent request
/// V3 Phase 1: optional context fields for ROADMAP_MENTORING, NODE_MENTORING, etc.
@JsonSerializable()
class CreateBookingRequest {
  final int mentorId;

  @JsonKey(toJson: _dateTimeToUtcIso8601String)
  final DateTime startTime;

  final int durationMinutes;
  final double priceVnd;
  final String paymentMethod; // Only 'WALLET' is supported by backend

  // V3 Phase 1: optional node/journey context — null for legacy bookings
  final int? journeyId;
  final String? nodeId;
  final int? nodeSkillId;
  final String?
  bookingType; // "GENERAL" | "NODE_MENTORING" | "JOURNEY_MENTORING" | "ROADMAP_MENTORING"

  CreateBookingRequest({
    required this.mentorId,
    required this.startTime,
    required this.durationMinutes,
    required this.priceVnd,
    this.paymentMethod = 'WALLET',
    this.journeyId,
    this.nodeId,
    this.nodeSkillId,
    this.bookingType,
  });

  factory CreateBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBookingRequestToJson(this);
}

/// Pre-chat message model
@JsonSerializable()
class PreChatMessage {
  final int id;
  final int? bookingId;
  final int mentorId;
  final int learnerId;
  final int senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final DateTime createdAt;
  @JsonKey(defaultValue: true)
  final bool chatEnabled;

  PreChatMessage({
    required this.id,
    this.bookingId,
    required this.mentorId,
    required this.learnerId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.createdAt,
    this.chatEnabled = true,
  });

  /// Check if message is from current user
  bool isFromUser(int userId) => senderId == userId;

  factory PreChatMessage.fromJson(Map<String, dynamic> json) =>
      _$PreChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$PreChatMessageToJson(this);
}

/// Pre-chat message request — requires bookingId (backend constraint)
@JsonSerializable()
class PreChatMessageRequest {
  final int bookingId;
  final String content;

  PreChatMessageRequest({required this.bookingId, required this.content});

  factory PreChatMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$PreChatMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PreChatMessageRequestToJson(this);
}

/// Pre-chat thread summary — now keyed by bookingId
@JsonSerializable()
class PreChatThread {
  final int? bookingId;
  final int counterpartId;
  final String? counterpartName;
  final String? counterpartAvatar;
  final String? lastContent;
  final DateTime? lastTime;
  final int? unreadCount;
  @JsonKey(defaultValue: false)
  final bool myRoleMentor;
  final DateTime? bookingStartTime;
  final DateTime? bookingEndTime;
  final String? bookingStatus;
  @JsonKey(defaultValue: true)
  final bool chatEnabled;

  PreChatThread({
    this.bookingId,
    required this.counterpartId,
    this.counterpartName,
    this.counterpartAvatar,
    this.lastContent,
    this.lastTime,
    this.unreadCount,
    this.myRoleMentor = false,
    this.bookingStartTime,
    this.bookingEndTime,
    this.bookingStatus,
    this.chatEnabled = true,
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
  final int stars;
  final String? comment;
  final String? skillEndorsed;

  BookingRatingRequest({required this.stars, this.comment, this.skillEndorsed});

  factory BookingRatingRequest.fromJson(Map<String, dynamic> json) =>
      _$BookingRatingRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BookingRatingRequestToJson(this);
}
