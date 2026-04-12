/// Data models for Recruitment Chat, mirroring Backend DTOs.

/// Recruitment session status enum
enum RecruitmentSessionStatus {
  CONTACTED,
  INTERESTED,
  INVITED,
  APPLICATION_RECEIVED,
  SCREENING,
  OFFER_SENT,
  HIRED,
  NOT_INTERESTED,
  ARCHIVED;

  String get label {
    switch (this) {
      case CONTACTED:
        return 'Đã liên hệ';
      case INTERESTED:
        return 'Quan tâm';
      case INVITED:
        return 'Đã mời';
      case APPLICATION_RECEIVED:
        return 'Nhận đơn';
      case SCREENING:
        return 'Sàng lọc';
      case OFFER_SENT:
        return 'Đã gửi offer';
      case HIRED:
        return 'Đã tuyển';
      case NOT_INTERESTED:
        return 'Không quan tâm';
      case ARCHIVED:
        return 'Đã lưu trữ';
    }
  }

  static RecruitmentSessionStatus fromString(String? value) {
    if (value == null) return CONTACTED;
    return RecruitmentSessionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CONTACTED,
    );
  }
}

/// Mirrors backend RecruitmentSessionResponse
class RecruitmentSessionResponse {
  final int id;

  // Recruiter info
  final int recruiterId;
  final String? recruiterName;
  final String? recruiterAvatar;
  final String? recruiterCompany;

  // Candidate info
  final int candidateId;
  final String? candidateFullName;
  final String? candidateTitle;
  final String? candidateAvatar;

  // Job info
  final int? jobId;
  final String? jobTitle;
  final String? jobContextType;
  final String? jobStatus;
  final bool? isRemote;
  final String? jobLocation;
  final bool? isChatAvailable;
  final String? chatDisabledReason;

  // Session metadata
  final RecruitmentSessionStatus status;
  final String? sourceType;
  final int? matchScore;
  final int? skillMatchPercent;
  final int? unreadCount;

  // Timestamps
  final String? lastMessageAt;
  final String? createdAt;
  final String? updatedAt;

  // Last message preview
  final String? lastMessagePreview;

  RecruitmentSessionResponse({
    required this.id,
    required this.recruiterId,
    this.recruiterName,
    this.recruiterAvatar,
    this.recruiterCompany,
    required this.candidateId,
    this.candidateFullName,
    this.candidateTitle,
    this.candidateAvatar,
    this.jobId,
    this.jobTitle,
    this.jobContextType,
    this.jobStatus,
    this.isRemote,
    this.jobLocation,
    this.isChatAvailable,
    this.chatDisabledReason,
    this.status = RecruitmentSessionStatus.CONTACTED,
    this.sourceType,
    this.matchScore,
    this.skillMatchPercent,
    this.unreadCount,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
    this.lastMessagePreview,
  });

  factory RecruitmentSessionResponse.fromJson(Map<String, dynamic> json) {
    return RecruitmentSessionResponse(
      id: json['id'] as int,
      recruiterId: json['recruiterId'] as int,
      recruiterName: json['recruiterName'] as String?,
      recruiterAvatar: json['recruiterAvatar'] as String?,
      recruiterCompany: json['recruiterCompany'] as String?,
      candidateId: json['candidateId'] as int,
      candidateFullName: json['candidateFullName'] as String?,
      candidateTitle: json['candidateTitle'] as String?,
      candidateAvatar: json['candidateAvatar'] as String?,
      jobId: json['jobId'] as int?,
      jobTitle: json['jobTitle'] as String?,
      jobContextType: json['jobContextType'] as String?,
      jobStatus: json['jobStatus'] as String?,
      isRemote: json['isRemote'] as bool?,
      jobLocation: json['jobLocation'] as String?,
      isChatAvailable: json['isChatAvailable'] as bool?,
      chatDisabledReason: json['chatDisabledReason'] as String?,
      status: RecruitmentSessionStatus.fromString(json['status'] as String?),
      sourceType: json['sourceType'] as String?,
      matchScore: json['matchScore'] as int?,
      skillMatchPercent: json['skillMatchPercent'] as int?,
      unreadCount: json['unreadCount'] as int?,
      lastMessageAt: json['lastMessageAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }
}

/// Mirrors backend RecruitmentMessageResponse
class RecruitmentMessageResponse {
  final int id;
  final int sessionId;
  final int senderId;
  final String? senderName;
  final String? senderAvatar;
  final String? senderRole; // RECRUITER or CANDIDATE
  final String content;
  final String? messageType;
  final String? actionType;
  final String? actionData;
  final bool? isRead;
  final String? readAt;
  final String? createdAt;

  RecruitmentMessageResponse({
    required this.id,
    required this.sessionId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    this.senderRole,
    required this.content,
    this.messageType,
    this.actionType,
    this.actionData,
    this.isRead,
    this.readAt,
    this.createdAt,
  });

  factory RecruitmentMessageResponse.fromJson(Map<String, dynamic> json) {
    return RecruitmentMessageResponse(
      id: json['id'] as int,
      sessionId: json['sessionId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      senderRole: json['senderRole'] as String?,
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String?,
      actionType: json['actionType'] as String?,
      actionData: json['actionData'] as String?,
      isRead: json['isRead'] as bool?,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  bool isMine(int userId) => senderId == userId;
}
