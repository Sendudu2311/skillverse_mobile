// Notification models — no build_runner needed (manual fromJson).
// NotificationType covers all backend enum values (synced 2026-03-28).
// AppNotification mirrors NotificationResponse DTO.
// NotificationPage mirrors Spring Data Page of NotificationResponse.

import '../../core/utils/date_time_helper.dart';

// ── Notification Type Enum ────────────────────────────────────────────────────

enum NotificationType {
  // Social
  like,
  comment,

  // Premium
  premiumPurchase,
  premiumExpiration,
  premiumCancel,

  // Wallet
  walletDeposit,
  coinPurchase,
  withdrawalApproved,
  withdrawalRejected,
  escrowFunded,
  escrowReleased,
  escrowRefunded,

  // Bookings
  bookingCreated,
  bookingConfirmed,
  bookingRejected,
  bookingReminder,
  bookingCompleted,
  bookingCancelled,
  bookingRefund,
  bookingStarted,
  bookingMentorCompleted,

  // Messaging
  prechatMessage,
  recruitmentMessage,

  // Mentor
  mentorReviewReceived,
  mentorLevelUp,
  mentorBadgeAwarded,

  // Tasks
  taskDeadline,
  taskOverdue,
  taskReview,
  assignmentSubmitted,
  assignmentGraded,
  assignmentLate,

  // Courses
  courseRejected,
  courseSuspended,
  courseRestored,

  // Jobs
  jobApproved,
  jobRejected,
  jobDeleted,
  jobBanned,
  jobUnbanned,

  // Short-term Job Applications
  shortTermApplicationSubmitted,
  shortTermApplicationAccepted,
  shortTermApplicationRejected,
  shortTermWorkSubmitted,
  shortTermWorkApproved,

  // Fulltime Job Applications
  fulltimeApplicationReviewed,
  fulltimeApplicationAccepted,
  fulltimeApplicationRejected,

  // Worker Cancellation
  workerCancellationRequested,
  workerAutoCancelled,
  workerAutoApproved,
  recruiterAutoApprovedWarning,

  // Disputes
  disputeOpened,
  disputeResolved,
  reviewWindowExpiring,
  adminDisputeEscalated,
  disputeEligibilityUnlocked,

  // System
  welcome,
  system,
  warning,
  violationReport,

  /// Fallback for new types added on the backend.
  unknown;

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'LIKE':
        return like;
      case 'COMMENT':
        return comment;
      case 'PREMIUM_PURCHASE':
        return premiumPurchase;
      case 'PREMIUM_EXPIRATION':
        return premiumExpiration;
      case 'PREMIUM_CANCEL':
        return premiumCancel;
      case 'WALLET_DEPOSIT':
        return walletDeposit;
      case 'COIN_PURCHASE':
        return coinPurchase;
      case 'WITHDRAWAL_APPROVED':
        return withdrawalApproved;
      case 'WITHDRAWAL_REJECTED':
        return withdrawalRejected;
      case 'ESCROW_FUNDED':
        return escrowFunded;
      case 'ESCROW_RELEASED':
        return escrowReleased;
      case 'ESCROW_REFUNDED':
        return escrowRefunded;
      case 'BOOKING_CREATED':
        return bookingCreated;
      case 'BOOKING_CONFIRMED':
        return bookingConfirmed;
      case 'BOOKING_REJECTED':
        return bookingRejected;
      case 'BOOKING_REMINDER':
        return bookingReminder;
      case 'BOOKING_COMPLETED':
        return bookingCompleted;
      case 'BOOKING_CANCELLED':
        return bookingCancelled;
      case 'BOOKING_REFUND':
        return bookingRefund;
      case 'BOOKING_STARTED':
        return bookingStarted;
      case 'BOOKING_MENTOR_COMPLETED':
        return bookingMentorCompleted;
      case 'PRECHAT_MESSAGE':
        return prechatMessage;
      case 'RECRUITMENT_MESSAGE':
        return recruitmentMessage;
      case 'MENTOR_REVIEW_RECEIVED':
        return mentorReviewReceived;
      case 'MENTOR_LEVEL_UP':
        return mentorLevelUp;
      case 'MENTOR_BADGE_AWARDED':
        return mentorBadgeAwarded;
      case 'TASK_DEADLINE':
        return taskDeadline;
      case 'TASK_OVERDUE':
        return taskOverdue;
      case 'TASK_REVIEW':
        return taskReview;
      case 'ASSIGNMENT_SUBMITTED':
        return assignmentSubmitted;
      case 'ASSIGNMENT_GRADED':
        return assignmentGraded;
      case 'ASSIGNMENT_LATE':
        return assignmentLate;
      case 'COURSE_REJECTED':
        return courseRejected;
      case 'COURSE_SUSPENDED':
        return courseSuspended;
      case 'COURSE_RESTORED':
        return courseRestored;
      case 'JOB_APPROVED':
        return jobApproved;
      case 'JOB_REJECTED':
        return jobRejected;
      case 'JOB_DELETED':
        return jobDeleted;
      case 'JOB_BANNED':
        return jobBanned;
      case 'JOB_UNBANNED':
        return jobUnbanned;
      case 'SHORT_TERM_APPLICATION_SUBMITTED':
        return shortTermApplicationSubmitted;
      case 'SHORT_TERM_APPLICATION_ACCEPTED':
        return shortTermApplicationAccepted;
      case 'SHORT_TERM_APPLICATION_REJECTED':
        return shortTermApplicationRejected;
      case 'SHORT_TERM_WORK_SUBMITTED':
        return shortTermWorkSubmitted;
      case 'SHORT_TERM_WORK_APPROVED':
        return shortTermWorkApproved;
      case 'FULLTIME_APPLICATION_REVIEWED':
        return fulltimeApplicationReviewed;
      case 'FULLTIME_APPLICATION_ACCEPTED':
        return fulltimeApplicationAccepted;
      case 'FULLTIME_APPLICATION_REJECTED':
        return fulltimeApplicationRejected;
      case 'WORKER_CANCELLATION_REQUESTED':
        return workerCancellationRequested;
      case 'WORKER_AUTO_CANCELLED':
        return workerAutoCancelled;
      case 'WORKER_AUTO_APPROVED':
        return workerAutoApproved;
      case 'RECRUITER_AUTO_APPROVED_WARNING':
        return recruiterAutoApprovedWarning;
      case 'DISPUTE_OPENED':
        return disputeOpened;
      case 'DISPUTE_RESOLVED':
        return disputeResolved;
      case 'REVIEW_WINDOW_EXPIRING':
        return reviewWindowExpiring;
      case 'ADMIN_DISPUTE_ESCALATED':
        return adminDisputeEscalated;
      case 'DISPUTE_ELIGIBILITY_UNLOCKED':
        return disputeEligibilityUnlocked;
      case 'WELCOME':
        return welcome;
      case 'SYSTEM':
        return system;
      case 'WARNING':
        return warning;
      case 'VIOLATION_REPORT':
        return violationReport;
      default:
        return unknown;
    }
  }
}

// ── AppNotification ───────────────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String? relatedId;
  final int? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String? postTitle;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.relatedId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.postTitle,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      // Spring Boot may serialize 'boolean isRead' as 'read' or 'isRead'
      isRead: (json['isRead'] ?? json['read']) as bool? ?? false,
      relatedId: json['relatedId'] as String?,
      senderId: json['senderId'] as int?,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      postTitle: json['postTitle'] as String?,
      createdAt: DateTimeHelper.tryParseIso8601(json['createdAt'] as String?) ?? DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      postTitle: postTitle,
      createdAt: createdAt,
    );
  }
}

// ── NotificationPage (Spring Data Page wrapper) ───────────────────────────────

class NotificationPage {
  final List<AppNotification> content;
  final int totalPages;
  final int totalElements;
  final bool last;

  const NotificationPage({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.last,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final rawList = json['content'] as List<dynamic>? ?? [];
    return NotificationPage(
      content: rawList
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      last: json['last'] as bool? ?? true,
    );
  }
}
