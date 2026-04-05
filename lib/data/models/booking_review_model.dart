import 'package:json_annotation/json_annotation.dart';

part 'booking_review_model.g.dart';

/// Review response matching Backend's BookingReviewDTO
@JsonSerializable()
class BookingReview {
  final int id;
  final int bookingId;
  final int? studentId;
  final String? studentName;
  final String? studentAvatar;
  final int? mentorId;
  final int rating;
  final String? comment;
  final String? reply;
  @JsonKey(name: 'anonymous')
  final bool? isAnonymous;
  final String? createdAt;
  final String? updatedAt;

  BookingReview({
    required this.id,
    required this.bookingId,
    this.studentId,
    this.studentName,
    this.studentAvatar,
    this.mentorId,
    required this.rating,
    this.comment,
    this.reply,
    this.isAnonymous,
    this.createdAt,
    this.updatedAt,
  });

  factory BookingReview.fromJson(Map<String, dynamic> json) =>
      _$BookingReviewFromJson(json);
  Map<String, dynamic> toJson() => _$BookingReviewToJson(this);

  /// Whether mentor has replied
  bool get hasReply => reply != null && reply!.isNotEmpty;
}

/// Request body for POST /api/reviews/booking/{bookingId}
@JsonSerializable()
class CreateBookingReviewRequest {
  final int rating;
  final String comment;
  final bool isAnonymous;

  CreateBookingReviewRequest({
    required this.rating,
    required this.comment,
    this.isAnonymous = false,
  });

  factory CreateBookingReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingReviewRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBookingReviewRequestToJson(this);
}
