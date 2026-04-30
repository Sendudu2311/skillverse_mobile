import 'package:json_annotation/json_annotation.dart';

part 'expert_chat_models.g.dart';

/// Chat mode enum
enum ChatMode {
  @JsonValue('GENERAL_CAREER_ADVISOR')
  generalCareerAdvisor,
  @JsonValue('EXPERT_MODE')
  expertMode,
}

/// Role information within an industry
@JsonSerializable()
class RoleInfo {
  final String jobRole;
  final String? keywords;
  final String? mediaUrl;
  final bool isActive;

  const RoleInfo({
    required this.jobRole,
    this.keywords,
    this.mediaUrl,
    this.isActive = true,
  });

  factory RoleInfo.fromJson(Map<String, dynamic> json) =>
      _$RoleInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RoleInfoToJson(this);
}

/// Industry information with roles
@JsonSerializable()
class IndustryInfo {
  final String industry;
  final List<RoleInfo> roles;

  const IndustryInfo({required this.industry, required this.roles});

  factory IndustryInfo.fromJson(Map<String, dynamic> json) =>
      _$IndustryInfoFromJson(json);
  Map<String, dynamic> toJson() => _$IndustryInfoToJson(this);
}

/// Expert field response - Domain with industries
@JsonSerializable()
class ExpertFieldResponse {
  final String domain;
  final List<IndustryInfo> industries;

  const ExpertFieldResponse({required this.domain, required this.industries});

  /// Get total role count across all industries
  int get totalRoles =>
      industries.fold(0, (sum, industry) => sum + industry.roles.length);

  factory ExpertFieldResponse.fromJson(Map<String, dynamic> json) =>
      _$ExpertFieldResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ExpertFieldResponseToJson(this);
}

/// Expert context - Selected domain/industry/role
@JsonSerializable()
class ExpertContext {
  final String domain;
  final String industry;
  final String jobRole;
  final String? expertName;
  final String? mediaUrl;

  const ExpertContext({
    required this.domain,
    required this.industry,
    required this.jobRole,
    this.expertName,
    this.mediaUrl,
  });

  factory ExpertContext.fromJson(Map<String, dynamic> json) =>
      _$ExpertContextFromJson(json);
  Map<String, dynamic> toJson() => _$ExpertContextToJson(this);
}

/// Expert chat request
@JsonSerializable()
class ExpertChatRequest {
  final String message;
  final int? sessionId;
  final ChatMode chatMode;
  final String? domain;
  final String? industry;
  final String? jobRole;
  @JsonKey(name: 'aiAgentMode')
  final String? aiAgentMode; // G5: null = normal, "deep-research-pro-preview-12-2025" = deep

  const ExpertChatRequest({
    required this.message,
    this.sessionId,
    this.chatMode = ChatMode.expertMode,
    this.domain,
    this.industry,
    this.jobRole,
    this.aiAgentMode,
  });

  factory ExpertChatRequest.fromJson(Map<String, dynamic> json) =>
      _$ExpertChatRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ExpertChatRequestToJson(this);
}

/// Expert chat response
@JsonSerializable()
class ExpertChatResponse {
  final int sessionId;
  final String message;
  final String aiResponse;
  final String timestamp;
  final ChatMode chatMode;
  final ExpertContext? expertContext;
  final String? detectedDomain;

  const ExpertChatResponse({
    required this.sessionId,
    required this.message,
    required this.aiResponse,
    required this.timestamp,
    required this.chatMode,
    this.expertContext,
    this.detectedDomain,
  });

  factory ExpertChatResponse.fromJson(Map<String, dynamic> json) =>
      _$ExpertChatResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ExpertChatResponseToJson(this);
}

/// Chat session for expert mode
@JsonSerializable()
class ExpertChatSession {
  final int sessionId;
  final String title;
  final int messageCount;
  final String lastMessageAt;
  final String? createdAt; // Nullable since API may not return it
  final ChatMode? chatMode;

  const ExpertChatSession({
    required this.sessionId,
    required this.title,
    required this.messageCount,
    required this.lastMessageAt,
    this.createdAt,
    this.chatMode,
  });

  factory ExpertChatSession.fromJson(Map<String, dynamic> json) =>
      _$ExpertChatSessionFromJson(json);
  Map<String, dynamic> toJson() => _$ExpertChatSessionToJson(this);
}

/// Chat message history
@JsonSerializable()
class ExpertChatMessage {
  final int? messageId; // Nullable since API may not return it
  final String userMessage;
  final String aiResponse;
  final String createdAt;

  const ExpertChatMessage({
    this.messageId,
    required this.userMessage,
    required this.aiResponse,
    required this.createdAt,
  });

  factory ExpertChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ExpertChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ExpertChatMessageToJson(this);
}

/// UI Message for display
class UIMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final ExpertContext? expertContext;
  final bool isStreaming;

  const UIMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.expertContext,
    this.isStreaming = false,
  });

  UIMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    ExpertContext? expertContext,
    bool? isStreaming,
  }) {
    return UIMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      expertContext: expertContext ?? this.expertContext,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
