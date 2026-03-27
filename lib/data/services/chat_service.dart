import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/chat_models.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Send a message to the AI career counselor
  /// AI responses can take longer, so we use extended timeout (60s)
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/v1/meowl/chat',
        data: request.toJson(),
        options: Options(
          // Extend timeout for AI chat - AI needs time to think and generate response
          receiveTimeout: const Duration(seconds: 60), // 60s for AI response
          sendTimeout: const Duration(seconds: 30),     // 30s for sending request
        ),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      // Check if response is wrapped
      Map<String, dynamic> jsonData = response.data!;
      if (jsonData.containsKey('data') && jsonData['data'] != null) {
        jsonData = jsonData['data'] as Map<String, dynamic>;
      }
      if (jsonData.containsKey('result') && jsonData['result'] != null) {
        jsonData = jsonData['result'] as Map<String, dynamic>;
      }

      return ChatResponse.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Gửi tin nhắn thất bại: ${e.toString()}');
    }
  }

  /// Get conversation history for a session
  Future<List<ChatMessage>> getHistory(int sessionId, {int? userId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['userId'] = userId;
      } else {
        // Try to get userId from storage
        final storedUserId = await _storage.read(key: 'userId');
        if (storedUserId != null) {
          queryParams['userId'] = int.tryParse(storedUserId);
        }
      }

      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/meowl/chat/history/$sessionId',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        return [];
      }

      return response.data!.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy lịch sử trò chuyện thất bại: ${e.toString()}');
    }
  }

  /// Get all chat sessions for current user with titles
  Future<List<ChatSession>> getSessions({int? userId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['userId'] = userId;
      } else {
        // Try to get userId from storage
        final storedUserId = await _storage.read(key: 'userId');
        if (storedUserId != null) {
          queryParams['userId'] = int.tryParse(storedUserId);
        }
      }

      final response = await _apiClient.dio.get<List<dynamic>>(
        '/v1/meowl/chat/sessions',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        return [];
      }

      return response.data!.map((json) => ChatSession.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách phiên thất bại: ${e.toString()}');
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(int sessionId) async {
    try {
      await _apiClient.dio.delete('/v1/meowl/chat/sessions/$sessionId');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Xóa phiên thất bại: ${e.toString()}');
    }
  }

  /// Rename a chat session
  Future<ChatSession> renameSession(int sessionId, String newTitle) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/v1/meowl/chat/sessions/$sessionId',
        queryParameters: {'newTitle': newTitle},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return ChatSession.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Đổi tên phiên thất bại: ${e.toString()}');
    }
  }
}