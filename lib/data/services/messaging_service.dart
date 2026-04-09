import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/messaging_models.dart';

/// Service for user-to-user 1-1 messaging (G3)
///
/// Backend endpoints (PreChatController.java):
/// - GET /api/prechat/threads          — list all conversations
/// - GET /api/prechat/conversation      — get messages with a user (?counterpartId=X)
/// - POST /api/prechat/send            — send a message
class MessagingService {
  final ApiClient _apiClient;

  MessagingService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/prechat/threads
  /// Fetch all conversation threads for the current user.
  Future<List<MessagingConversation>> getConversations() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/prechat/threads',
      );

      if (response.data == null) return [];

      return (response.data as List)
          .map((e) => MessagingConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      rethrow;
    }
  }

  /// GET /api/prechat/conversation?counterpartId={otherUserId}
  /// Fetch bidirectional chat history between current user and another user.
  Future<List<MessagingMessage>> getMessages(int otherUserId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/prechat/conversation',
        queryParameters: {
          'counterpartId': otherUserId,
          'page': 0,
          'size': 100,
        },
      );

      if (response.data == null) return [];

      // BE wraps response in { content: [...], pageable: {...} }
      final content = response.data!['content'];
      if (content == null) return [];

      return (content as List)
          .map((e) => MessagingMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting messages: $e');
      rethrow;
    }
  }

  /// POST /api/prechat/send — send a message (REST fallback)
  Future<MessagingMessage> sendMessage(SendMessageRequest request) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/prechat/send',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw Exception('Empty response from send message API');
      }

      return MessagingMessage.fromJson(response.data!);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// PUT /api/prechat/mark-read?mentorId={id} — mark messages as read
  Future<void> markAsRead(int counterpartId) async {
    try {
      await _apiClient.dio.put('/prechat/mark-read', queryParameters: {
        'mentorId': counterpartId,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
}