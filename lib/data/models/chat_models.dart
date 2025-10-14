import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

@JsonSerializable()
class ChatMessage {
  final int id;
  final String userMessage;
  final String aiResponse;
  final String createdAt;
  final int userId;
  final String userEmail;

  ChatMessage({
    required this.id,
    required this.userMessage,
    required this.aiResponse,
    required this.createdAt,
    required this.userId,
    required this.userEmail,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class ChatRequest {
  final String message;
  final String language;
  final int? userId;
  final bool includeReminders;
  final List<ChatHistoryItem>? chatHistory;

  ChatRequest({
    required this.message,
    required this.language,
    this.userId,
    this.includeReminders = true,
    this.chatHistory,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) => _$ChatRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRequestToJson(this);
}

@JsonSerializable()
class ChatHistoryItem {
  final String role;
  final String content;

  ChatHistoryItem({
    required this.role,
    required this.content,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) => _$ChatHistoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$ChatHistoryItemToJson(this);
}

@JsonSerializable()
class ChatReminder {
  final String type;
  final String title;
  final String description;
  final String actionUrl;
  final String emoji;

  ChatReminder({
    required this.type,
    required this.title,
    required this.description,
    required this.actionUrl,
    required this.emoji,
  });

  factory ChatReminder.fromJson(Map<String, dynamic> json) => _$ChatReminderFromJson(json);
  Map<String, dynamic> toJson() => _$ChatReminderToJson(this);
}

@JsonSerializable()
class ChatResponse {
  final String message;
  final String? originalMessage;
  final List<ChatReminder>? reminders;
  final bool? success;
  final String? timestamp;

  ChatResponse({
    required this.message,
    this.originalMessage,
    this.reminders,
    this.success,
    this.timestamp,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    // Handle wrapped responses
    Map<String, dynamic> data = json;
    if (data.containsKey('data') && data['data'] != null) {
      data = data['data'] as Map<String, dynamic>;
    }
    if (data.containsKey('result') && data['result'] != null) {
      data = data['result'] as Map<String, dynamic>;
    }

    return _$ChatResponseFromJson(data);
  }

  Map<String, dynamic> toJson() => _$ChatResponseToJson(this);
}

@JsonSerializable()
class ChatSession {
  final int sessionId;
  final String title;
  final String lastMessageAt;
  final int messageCount;

  ChatSession({
    required this.sessionId,
    required this.title,
    required this.lastMessageAt,
    required this.messageCount,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => _$ChatSessionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);
}

// UI-specific message type for rendering
class UIMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  UIMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}