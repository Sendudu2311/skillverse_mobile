// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: (json['id'] as num).toInt(),
  userMessage: json['userMessage'] as String,
  aiResponse: json['aiResponse'] as String,
  createdAt: json['createdAt'] as String,
  userId: (json['userId'] as num).toInt(),
  userEmail: json['userEmail'] as String,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userMessage': instance.userMessage,
      'aiResponse': instance.aiResponse,
      'createdAt': instance.createdAt,
      'userId': instance.userId,
      'userEmail': instance.userEmail,
    };

ChatRequest _$ChatRequestFromJson(Map<String, dynamic> json) => ChatRequest(
  message: json['message'] as String,
  language: json['language'] as String,
  userId: (json['userId'] as num?)?.toInt(),
  includeReminders: json['includeReminders'] as bool? ?? true,
  chatHistory: (json['chatHistory'] as List<dynamic>?)
      ?.map((e) => ChatHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChatRequestToJson(ChatRequest instance) =>
    <String, dynamic>{
      'message': instance.message,
      'language': instance.language,
      'userId': instance.userId,
      'includeReminders': instance.includeReminders,
      'chatHistory': instance.chatHistory,
    };

ChatHistoryItem _$ChatHistoryItemFromJson(Map<String, dynamic> json) =>
    ChatHistoryItem(
      role: json['role'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$ChatHistoryItemToJson(ChatHistoryItem instance) =>
    <String, dynamic>{'role': instance.role, 'content': instance.content};

ChatReminder _$ChatReminderFromJson(Map<String, dynamic> json) => ChatReminder(
  type: json['type'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  actionUrl: json['actionUrl'] as String,
  emoji: json['emoji'] as String,
);

Map<String, dynamic> _$ChatReminderToJson(ChatReminder instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'actionUrl': instance.actionUrl,
      'emoji': instance.emoji,
    };

ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) => ChatResponse(
  message: json['message'] as String,
  originalMessage: json['originalMessage'] as String?,
  reminders: (json['reminders'] as List<dynamic>?)
      ?.map((e) => ChatReminder.fromJson(e as Map<String, dynamic>))
      .toList(),
  success: json['success'] as bool?,
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$ChatResponseToJson(ChatResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'originalMessage': instance.originalMessage,
      'reminders': instance.reminders,
      'success': instance.success,
      'timestamp': instance.timestamp,
    };

ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => ChatSession(
  sessionId: (json['sessionId'] as num).toInt(),
  title: json['title'] as String,
  lastMessageAt: json['lastMessageAt'] as String,
  messageCount: (json['messageCount'] as num).toInt(),
);

Map<String, dynamic> _$ChatSessionToJson(ChatSession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'title': instance.title,
      'lastMessageAt': instance.lastMessageAt,
      'messageCount': instance.messageCount,
    };

MeowlQuickAction _$MeowlQuickActionFromJson(Map<String, dynamic> json) =>
    MeowlQuickAction(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      actionType: json['actionType'] as String,
      actionValue: json['actionValue'] as String,
    );

Map<String, dynamic> _$MeowlQuickActionToJson(MeowlQuickAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'description': instance.description,
      'actionType': instance.actionType,
      'actionValue': instance.actionValue,
    };

MeowlOnboardingContextResponse _$MeowlOnboardingContextResponseFromJson(
  Map<String, dynamic> json,
) => MeowlOnboardingContextResponse(
  success: json['success'] as bool,
  language: json['language'] as String,
  activeRole: json['activeRole'] as String,
  roleSwitchEnabled: json['roleSwitchEnabled'] as bool,
  onboardingSeen: json['onboardingSeen'] as bool,
  welcomeMessage: json['welcomeMessage'] as String,
  nextBestAction: json['nextBestAction'] as String,
  whatYouCanDo: (json['whatYouCanDo'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  quickActions: (json['quickActions'] as List<dynamic>?)
      ?.map((e) => MeowlQuickAction.fromJson(e as Map<String, dynamic>))
      .toList(),
  suggestedPrompts: (json['suggestedPrompts'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$MeowlOnboardingContextResponseToJson(
  MeowlOnboardingContextResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'language': instance.language,
  'activeRole': instance.activeRole,
  'roleSwitchEnabled': instance.roleSwitchEnabled,
  'onboardingSeen': instance.onboardingSeen,
  'welcomeMessage': instance.welcomeMessage,
  'nextBestAction': instance.nextBestAction,
  'whatYouCanDo': instance.whatYouCanDo,
  'quickActions': instance.quickActions,
  'suggestedPrompts': instance.suggestedPrompts,
};
