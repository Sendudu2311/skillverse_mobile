import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/expert_chat_models.dart';

/// Expert Chat Service
/// Handles API calls for AI Expert consultation
class ExpertChatService {
  static final ExpertChatService _instance = ExpertChatService._internal();
  factory ExpertChatService() => _instance;
  ExpertChatService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get all expert fields (hierarchical domain/industry/role structure)
  Future<List<ExpertFieldResponse>> getExpertFields() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/expert-fields',
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (json) =>
                ExpertFieldResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting expert fields: $e');
      rethrow;
    }
  }

  /// Send message to AI expert
  Future<ExpertChatResponse> sendMessage(ExpertChatRequest request) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/ai/chat',
        data: request.toJson(),
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data == null) {
        throw Exception('No response data');
      }

      // Handle wrapped responses
      Map<String, dynamic> jsonData = response.data!;
      if (jsonData.containsKey('data') && jsonData['data'] != null) {
        jsonData = jsonData['data'] as Map<String, dynamic>;
      }

      return ExpertChatResponse.fromJson(jsonData);
    } catch (e) {
      debugPrint('❌ Error sending expert message: $e');
      rethrow;
    }
  }

  /// Get chat sessions filtered by expert mode
  Future<List<ExpertChatSession>> getSessions({ChatMode? chatMode}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (chatMode != null) {
        queryParams['chatMode'] = chatMode == ChatMode.expertMode
            ? 'EXPERT_MODE'
            : 'GENERAL_CAREER_ADVISOR';
      }

      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/ai/chat/sessions',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (json) => ExpertChatSession.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting sessions: $e');
      rethrow;
    }
  }

  /// Get conversation history for a session
  Future<List<ExpertChatMessage>> getHistory(int sessionId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/ai/chat/history/$sessionId',
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (json) => ExpertChatMessage.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting history: $e');
      rethrow;
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(int sessionId) async {
    try {
      await _apiClient.dio.delete('/v1/ai/chat/sessions/$sessionId');
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
      rethrow;
    }
  }

  /// Rename a chat session
  Future<ExpertChatSession> renameSession(
    int sessionId,
    String newTitle,
  ) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/ai/chat/sessions/$sessionId',
        queryParameters: {'newTitle': newTitle},
      );

      if (response.data == null) {
        throw Exception('No response data');
      }

      return ExpertChatSession.fromJson(response.data!);
    } catch (e) {
      debugPrint('❌ Error renaming session: $e');
      rethrow;
    }
  }
}
