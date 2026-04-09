import 'package:json_annotation/json_annotation.dart';

part 'messaging_models.g.dart';

/// Message status enum
enum MessageStatus {
  @JsonValue('RECEIVED')
  received,
  @JsonValue('DELIVERED')
  delivered,
}

/// DTO for a single user-to-user message (PreChat)
@JsonSerializable()
class MessagingMessage {
  final int id;
  @JsonKey(name: 'mentorId')
  final int? mentorId; // null if not to mentor
  @JsonKey(name: 'learnerId')
  final int? learnerId; // null if not from learner
  @JsonKey(name: 'senderId')
  final int senderId;
  @JsonKey(name: 'content')
  final String content;
  @JsonKey(name: 'createdAt')
  final String createdAt;

  const MessagingMessage({
    required this.id,
    this.mentorId,
    this.learnerId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory MessagingMessage.fromJson(Map<String, dynamic> json) =>
      _$MessagingMessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessagingMessageToJson(this);
}

/// Request to send a message
@JsonSerializable()
class SendMessageRequest {
  @JsonKey(name: 'mentorId')
  final int mentorId;
  @JsonKey(name: 'content')
  final String content;

  const SendMessageRequest({
    required this.mentorId,
    required this.content,
  });

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

/// Conversation summary from /prechat/threads
@JsonSerializable()
class MessagingConversation {
  @JsonKey(name: 'counterpartId')
  final int counterpartId;
  @JsonKey(name: 'counterpartName')
  final String counterpartName;
  @JsonKey(name: 'counterpartAvatar')
  final String? counterpartAvatar;
  @JsonKey(name: 'lastContent')
  final String lastContent;
  @JsonKey(name: 'lastTime')
  final String lastTime;
  @JsonKey(name: 'unreadCount')
  final int unreadCount;
  @JsonKey(name: 'myRoleMentor')
  final bool myRoleMentor;

  const MessagingConversation({
    required this.counterpartId,
    required this.counterpartName,
    this.counterpartAvatar,
    required this.lastContent,
    required this.lastTime,
    this.unreadCount = 0,
    this.myRoleMentor = false,
  });

  factory MessagingConversation.fromJson(Map<String, dynamic> json) =>
      _$MessagingConversationFromJson(json);
  Map<String, dynamic> toJson() => _$MessagingConversationToJson(this);
}