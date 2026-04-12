import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/recruitment_chat_models.dart';

/// Service for Recruitment Chat REST API calls.
/// Recruitment chat is purely REST-based (no WebSocket).
class RecruitmentChatService {
  static final RecruitmentChatService _instance =
      RecruitmentChatService._internal();
  factory RecruitmentChatService() => _instance;
  RecruitmentChatService._internal();

  final ApiClient _apiClient = ApiClient();

  // ── Sessions ──────────────────────────────────────────────────────────

  /// Get sessions for the current candidate (Learner) — paged.
  Future<List<RecruitmentSessionResponse>> getCandidateSessions({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/recruitment/my-sessions',
        queryParameters: {'page': page, 'size': size},
      );
      final content = response.data?['content'] as List<dynamic>? ?? [];
      return content
          .map((e) =>
              RecruitmentSessionResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading recruitment sessions: $e');
      rethrow;
    }
  }

  /// Get a single session by ID.
  Future<RecruitmentSessionResponse> getSessionById(int sessionId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/recruitment/sessions/$sessionId',
      );
      return RecruitmentSessionResponse.fromJson(response.data!);
    } catch (e) {
      debugPrint('Error loading session detail: $e');
      rethrow;
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────

  /// Get messages for a session — paged, descending by default.
  Future<List<RecruitmentMessageResponse>> getSessionMessages(
    int sessionId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/recruitment/sessions/$sessionId/messages',
        queryParameters: {'page': page, 'size': size},
      );
      final content = response.data?['content'] as List<dynamic>? ?? [];
      return content
          .map((e) =>
              RecruitmentMessageResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading session messages: $e');
      rethrow;
    }
  }

  /// Send a message to a session.
  Future<RecruitmentMessageResponse> sendMessage({
    required int sessionId,
    required String content,
    String messageType = 'TEXT',
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/recruitment/messages',
        data: {
          'sessionId': sessionId,
          'content': content,
          'messageType': messageType,
        },
      );
      return RecruitmentMessageResponse.fromJson(response.data!);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────

  /// Mark all messages in a session as read.
  Future<void> markMessagesAsRead(int sessionId) async {
    try {
      await _apiClient.dio.put('/v1/recruitment/sessions/$sessionId/read');
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  /// Get total unread count.
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/v1/recruitment/unread-count',
      );
      return (response.data?['count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}
