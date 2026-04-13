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
/// Matches backend PreChatMessageResponse.java
@JsonSerializable()
class MessagingMessage {
  final int id;
  @JsonKey(name: 'bookingId')
  final int? bookingId;
  @JsonKey(name: 'mentorId')
  final int? mentorId;
  @JsonKey(name: 'learnerId')
  final int? learnerId;
  @JsonKey(name: 'senderId')
  final int senderId;
  @JsonKey(name: 'senderName')
  final String? senderName;
  @JsonKey(name: 'senderAvatar')
  final String? senderAvatar;
  @JsonKey(name: 'content')
  final String content;
  @JsonKey(name: 'createdAt')
  final String createdAt;
  @JsonKey(name: 'chatEnabled')
  final bool chatEnabled;

  const MessagingMessage({
    required this.id,
    this.bookingId,
    this.mentorId,
    this.learnerId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.createdAt,
    this.chatEnabled = true,
  });

  factory MessagingMessage.fromJson(Map<String, dynamic> json) =>
      _$MessagingMessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessagingMessageToJson(this);
}

/// Request to send a message
/// Backend now requires bookingId instead of mentorId
@JsonSerializable()
class SendMessageRequest {
  @JsonKey(name: 'bookingId')
  final int bookingId;
  @JsonKey(name: 'content')
  final String content;

  const SendMessageRequest({required this.bookingId, required this.content});

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}

/// Conversation summary from /prechat/threads
/// Matches backend PreChatThreadSummary.java
@JsonSerializable()
class MessagingConversation {
  @JsonKey(name: 'bookingId')
  final int? bookingId;
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
  @JsonKey(name: 'bookingStartTime')
  final String? bookingStartTime;
  @JsonKey(name: 'bookingEndTime')
  final String? bookingEndTime;
  @JsonKey(name: 'bookingStatus')
  final String? bookingStatus;
  @JsonKey(name: 'chatEnabled')
  final bool chatEnabled;

  const MessagingConversation({
    this.bookingId,
    required this.counterpartId,
    required this.counterpartName,
    this.counterpartAvatar,
    required this.lastContent,
    required this.lastTime,
    this.unreadCount = 0,
    this.myRoleMentor = false,
    this.bookingStartTime,
    this.bookingEndTime,
    this.bookingStatus,
    this.chatEnabled = true,
  });

  factory MessagingConversation.fromJson(Map<String, dynamic> json) =>
      _$MessagingConversationFromJson(json);
  Map<String, dynamic> toJson() => _$MessagingConversationToJson(this);
}
