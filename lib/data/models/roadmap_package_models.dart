// Roadmap Package models — manual fromJson (no build_runner).
// Mirrors backend roadmap-template / offering / purchase DTOs.

// ── Enums ─────────────────────────────────────────────────────────────────

enum RoadmapTemplateStatus {
  draft,
  submitted,
  approved,
  rejected,
  archived;

  static RoadmapTemplateStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUBMITTED':
        return submitted;
      case 'APPROVED':
        return approved;
      case 'REJECTED':
        return rejected;
      case 'ARCHIVED':
        return archived;
      case 'DRAFT':
      default:
        return draft;
    }
  }

  String get displayName {
    switch (this) {
      case draft:
        return 'Nháp';
      case submitted:
        return 'Đã gửi';
      case approved:
        return 'Đã duyệt';
      case rejected:
        return 'Bị từ chối';
      case archived:
        return 'Lưu trữ';
    }
  }
}

enum RoadmapOfferingStatus {
  draft,
  active,
  paused,
  archived;

  static RoadmapOfferingStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return active;
      case 'PAUSED':
        return paused;
      case 'ARCHIVED':
        return archived;
      case 'DRAFT':
      default:
        return draft;
    }
  }

  String get displayName {
    switch (this) {
      case draft:
        return 'Nháp';
      case active:
        return 'Đang mở';
      case paused:
        return 'Tạm dừng';
      case archived:
        return 'Lưu trữ';
    }
  }
}

enum RoadmapPurchaseStatus {
  pendingPayment,
  active,
  completed,
  cancelled,
  refunded;

  static RoadmapPurchaseStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return active;
      case 'COMPLETED':
        return completed;
      case 'CANCELLED':
        return cancelled;
      case 'REFUNDED':
        return refunded;
      case 'PENDING_PAYMENT':
      default:
        return pendingPayment;
    }
  }

  String get displayName {
    switch (this) {
      case pendingPayment:
        return 'Chờ thanh toán';
      case active:
        return 'Đang hoạt động';
      case completed:
        return 'Hoàn thành';
      case cancelled:
        return 'Đã huỷ';
      case refunded:
        return 'Đã hoàn tiền';
    }
  }
}

// ── RoadmapTemplateNodeResponse ───────────────────────────────────────────

class RoadmapTemplateNodeResponse {
  final int id;
  final int templateId;
  final int? parentNodeId;
  final String? nodeKey;
  final String title;
  final String? description;
  final int orderIndex;
  final int? skillId;
  final String? skillNameSnapshot;
  final String? skillCanonicalKeySnapshot;
  final String? requirementType;
  final String? importanceLevel;
  final String? difficulty;
  final int? estimatedHours;
  final String? expectedOutput;
  final String? rubric;
  final String? nodeType;
  final String? parentNodeKey;

  const RoadmapTemplateNodeResponse({
    required this.id,
    required this.templateId,
    this.parentNodeId,
    this.nodeKey,
    required this.title,
    this.description,
    required this.orderIndex,
    this.skillId,
    this.skillNameSnapshot,
    this.skillCanonicalKeySnapshot,
    this.requirementType,
    this.importanceLevel,
    this.difficulty,
    this.estimatedHours,
    this.expectedOutput,
    this.rubric,
    this.nodeType,
    this.parentNodeKey,
  });

  factory RoadmapTemplateNodeResponse.fromJson(Map<String, dynamic> json) {
    return RoadmapTemplateNodeResponse(
      id: (json['id'] as num).toInt(),
      templateId: (json['templateId'] as num).toInt(),
      parentNodeId: (json['parentNodeId'] as num?)?.toInt(),
      nodeKey: json['nodeKey'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      skillId: (json['skillId'] as num?)?.toInt(),
      skillNameSnapshot: json['skillNameSnapshot'] as String?,
      skillCanonicalKeySnapshot:
          json['skillCanonicalKeySnapshot'] as String?,
      requirementType: json['requirementType'] as String?,
      importanceLevel: json['importanceLevel'] as String?,
      difficulty: json['difficulty'] as String?,
      estimatedHours: (json['estimatedHours'] as num?)?.toInt(),
      expectedOutput: json['expectedOutput'] as String?,
      rubric: json['rubric'] as String?,
      nodeType: json['nodeType'] as String?,
      parentNodeKey: json['parentNodeKey'] as String?,
    );
  }
}

// ── RoadmapTemplateCourseResponse ─────────────────────────────────────────

class RoadmapTemplateCourseResponse {
  final int id;
  final int templateId;
  final int? templateNodeId;
  final int courseId;
  final int? displayOrder;
  final bool? required;

  const RoadmapTemplateCourseResponse({
    required this.id,
    required this.templateId,
    this.templateNodeId,
    required this.courseId,
    this.displayOrder,
    this.required,
  });

  factory RoadmapTemplateCourseResponse.fromJson(Map<String, dynamic> json) {
    return RoadmapTemplateCourseResponse(
      id: (json['id'] as num).toInt(),
      templateId: (json['templateId'] as num).toInt(),
      templateNodeId: (json['templateNodeId'] as num?)?.toInt(),
      courseId: (json['courseId'] as num).toInt(),
      displayOrder: (json['displayOrder'] as num?)?.toInt(),
      required: json['required'] as bool?,
    );
  }
}

// ── RoadmapTemplateResponse ───────────────────────────────────────────────

class RoadmapTemplateResponse {
  final int id;
  final int mentorId;
  final String? mentorName;
  final int? domainId;
  final int? jobPositionId;
  final int? jobPositionTrackId;
  final String title;
  final String? description;
  final String? targetRole;
  final String? targetLevel;
  final String? targetRoleSnapshot;
  final String? targetLevelSnapshot;
  final RoadmapTemplateStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<RoadmapTemplateNodeResponse> nodes;
  final List<RoadmapTemplateCourseResponse> courses;

  const RoadmapTemplateResponse({
    required this.id,
    required this.mentorId,
    this.mentorName,
    this.domainId,
    this.jobPositionId,
    this.jobPositionTrackId,
    required this.title,
    this.description,
    this.targetRole,
    this.targetLevel,
    this.targetRoleSnapshot,
    this.targetLevelSnapshot,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.nodes = const [],
    this.courses = const [],
  });

  factory RoadmapTemplateResponse.fromJson(Map<String, dynamic> json) {
    return RoadmapTemplateResponse(
      id: (json['id'] as num).toInt(),
      mentorId: (json['mentorId'] as num).toInt(),
      mentorName: json['mentorName'] as String?,
      domainId: (json['domainId'] as num?)?.toInt(),
      jobPositionId: (json['jobPositionId'] as num?)?.toInt(),
      jobPositionTrackId: (json['jobPositionTrackId'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      targetRole: json['targetRole'] as String?,
      targetLevel: json['targetLevel'] as String?,
      targetRoleSnapshot: json['targetRoleSnapshot'] as String?,
      targetLevelSnapshot: json['targetLevelSnapshot'] as String?,
      status: RoadmapTemplateStatus.fromString(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => RoadmapTemplateNodeResponse.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => RoadmapTemplateCourseResponse.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

// ── RoadmapOfferingResponse ───────────────────────────────────────────────

class RoadmapOfferingResponse {
  final int id;
  final int templateId;
  final int mentorId;
  final String? mentorName;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final RoadmapOfferingStatus status;
  final int? maxStudents;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RoadmapTemplateResponse? template;

  const RoadmapOfferingResponse({
    required this.id,
    required this.templateId,
    required this.mentorId,
    this.mentorName,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'VND',
    required this.status,
    this.maxStudents,
    this.createdAt,
    this.updatedAt,
    this.template,
  });

  factory RoadmapOfferingResponse.fromJson(Map<String, dynamic> json) {
    return RoadmapOfferingResponse(
      id: (json['id'] as num).toInt(),
      templateId: (json['templateId'] as num).toInt(),
      mentorId: (json['mentorId'] as num).toInt(),
      mentorName: json['mentorName'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      status: RoadmapOfferingStatus.fromString(json['status'] as String?),
      maxStudents: (json['maxStudents'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
      template: json['template'] != null
          ? RoadmapTemplateResponse.fromJson(
              json['template'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── RoadmapPurchaseResponse ───────────────────────────────────────────────

class RoadmapPurchaseResponse {
  final int id;
  final int studentId;
  final int mentorId;
  final int offeringId;
  final int templateId;
  final int? bookingId;
  final int? journeyId;
  final int? roadmapSessionId;
  final double price;
  final String currency;
  final RoadmapPurchaseStatus status;
  final DateTime? activatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RoadmapOfferingResponse? offering;

  const RoadmapPurchaseResponse({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.offeringId,
    required this.templateId,
    this.bookingId,
    this.journeyId,
    this.roadmapSessionId,
    required this.price,
    this.currency = 'VND',
    required this.status,
    this.activatedAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.offering,
  });

  factory RoadmapPurchaseResponse.fromJson(Map<String, dynamic> json) {
    return RoadmapPurchaseResponse(
      id: (json['id'] as num).toInt(),
      studentId: (json['studentId'] as num).toInt(),
      mentorId: (json['mentorId'] as num).toInt(),
      offeringId: (json['offeringId'] as num).toInt(),
      templateId: (json['templateId'] as num).toInt(),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      journeyId: (json['journeyId'] as num?)?.toInt(),
      roadmapSessionId: (json['roadmapSessionId'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      status: RoadmapPurchaseStatus.fromString(json['status'] as String?),
      activatedAt: json['activatedAt'] != null
          ? DateTime.tryParse(json['activatedAt'].toString())?.toLocal()
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())?.toLocal()
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())?.toLocal()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
      offering: json['offering'] != null
          ? RoadmapOfferingResponse.fromJson(
              json['offering'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── CreateRoadmapPurchaseRequest ──────────────────────────────────────────

class CreateRoadmapPurchaseRequest {
  final int offeringId;

  const CreateRoadmapPurchaseRequest({required this.offeringId});

  Map<String, dynamic> toJson() => {'offeringId': offeringId};
}
