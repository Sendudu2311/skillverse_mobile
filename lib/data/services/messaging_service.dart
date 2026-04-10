import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/environment.dart';
import '../models/messaging_models.dart';

/// Service for user-to-user 1-1 messaging (G3)
///
/// Backend endpoints (PreChatController.java):
/// - GET  /api/prechat/threads          — list all conversations
/// - GET  /api/prechat/conversation      — get messages with a user (?counterpartId=X)
/// - POST /api/prechat/send             — learner send (REST fallback)
/// - POST /api/prechat/mentor/send      — mentor send (REST)
/// - PUT  /api/prechat/mark-read        — mark read
///
/// STOMP endpoints:
/// - Send:      /app/prechat
/// - Receive:   /user/{userId}/queue/prechat
/// - Typing:    /app/prechat.typing  →  /user/{userId}/queue/prechat.typing
class MessagingService {
  final ApiClient _apiClient;

  MessagingService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ── STOMP WebSocket ─────────────────────────────────────────────────
  StompClient? _stompClient;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  StompUnsubscribe? _preChatSubscription;

  /// Callback when a real-time message arrives via WebSocket
  void Function(MessagingMessage message)? onMessageReceived;

  /// Derive WS URL from backend URL.
  /// SockJS requires http/https (not ws/wss).
  /// Backend URL: http://host:8080/api → http://host:8080/ws
  String get _wsUrl {
    final base = Environment.backendUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/ws';
  }

  /// Connect STOMP and subscribe to personal prechat queue
  void connectStomp({String? authToken}) {
    if (_isConnected) return;

    final headers = <String, String>{};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: _wsUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: _onConnected,
        onDisconnect: _onDisconnected,
        onStompError: (frame) =>
            debugPrint('🔴 PreChat STOMP error: ${frame.body}'),
        onWebSocketError: (error) =>
            debugPrint('🔴 PreChat WS error: $error'),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    debugPrint('🔌 PreChat STOMP connecting to $_wsUrl');
    _stompClient!.activate();
  }

  void _onConnected(StompFrame frame) {
    _isConnected = true;
    debugPrint('✅ PreChat STOMP connected');

    // Subscribe to personal prechat queue
    _preChatSubscription = _stompClient!.subscribe(
      destination: '/user/queue/prechat',
      callback: _handleFrame,
    );
    debugPrint('📡 Subscribed to /user/queue/prechat');
  }

  void _onDisconnected(StompFrame frame) {
    _isConnected = false;
    debugPrint('🔌 PreChat STOMP disconnected');
  }

  void _handleFrame(StompFrame frame) {
    if (frame.body == null) return;
    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final msg = MessagingMessage.fromJson(json);
      onMessageReceived?.call(msg);
    } catch (e) {
      debugPrint('Error parsing prechat WS frame: $e');
    }
  }

  /// Send a message via STOMP (real-time path)
  void sendStomp(SendMessageRequest request) {
    if (_stompClient == null || !_isConnected) {
      debugPrint('⚠️ Cannot send via STOMP: not connected');
      return;
    }
    _stompClient!.send(
      destination: '/app/prechat',
      body: jsonEncode(request.toJson()),
    );
  }

  /// Disconnect and clean up
  void disconnectStomp() {
    _preChatSubscription?.call(unsubscribeHeaders: {});
    _preChatSubscription = null;
    _stompClient?.deactivate();
    _isConnected = false;
    debugPrint('🔌 PreChat STOMP disconnected and cleaned up');
  }

  // ── REST API ────────────────────────────────────────────────────────

  /// GET /api/prechat/threads
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