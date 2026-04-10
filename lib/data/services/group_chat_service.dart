import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/environment.dart';
import '../models/group_chat_models.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Service for Group Chat REST API calls and STOMP WebSocket connection.
class GroupChatService {
  static final GroupChatService _instance = GroupChatService._internal();
  factory GroupChatService() => _instance;
  GroupChatService._internal();

  final ApiClient _apiClient = ApiClient();
  StompClient? _stompClient;
  bool _isConnected = false;

  // Active subscriptions keyed by groupId
  final Map<int, StompUnsubscribe> _subscriptions = {};

  // Callback for incoming WebSocket messages
  void Function(GroupChatMessageDTO message)? onMessageReceived;

  // ------------------------------------------------------------------
  // REST API methods
  // ------------------------------------------------------------------

  /// Get list of groups the user is a member of
  Future<List<GroupChatResponse>> getMyGroups(int userId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/group-chats/my-groups',
        queryParameters: {'userId': userId},
      );
      if (response.data == null) return [];
      return response.data!
          .map((e) => GroupChatResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading groups: $e');
      rethrow;
    }
  }

  /// Get detailed group info including members
  Future<GroupChatResponse> getGroupDetail(int groupId, int userId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/group-chats/$groupId/detail',
        queryParameters: {'userId': userId},
      );
      return GroupChatResponse.fromJson(response.data!);
    } catch (e) {
      debugPrint('Error loading group detail: $e');
      rethrow;
    }
  }

  /// Get messages for a group
  Future<List<GroupChatMessageDTO>> getGroupMessages(
      int groupId, int userId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/group-chats/$groupId/messages',
        queryParameters: {'userId': userId},
      );
      if (response.data == null) return [];
      return response.data!
          .map(
              (e) => GroupChatMessageDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      rethrow;
    }
  }

  /// Send a message via REST (also broadcasts via backend WebSocket)
  Future<GroupChatMessageDTO> sendMessageRest(
      int groupId, GroupChatMessageDTO message) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/group-chats/$groupId/messages',
        data: message.toJson(),
      );
      return GroupChatMessageDTO.fromJson(response.data!);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Join a group
  Future<void> joinGroup(int groupId, int userId) async {
    await _apiClient.dio.post(
      '/group-chats/$groupId/join',
      queryParameters: {'userId': userId},
    );
  }

  /// Leave a group
  Future<void> leaveGroup(int groupId, int userId) async {
    await _apiClient.dio.post(
      '/group-chats/$groupId/leave',
      queryParameters: {'userId': userId},
    );
  }

  /// Get group members
  Future<List<GroupMemberDTO>> getGroupMembers(int groupId, int userId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/group-chats/$groupId/members',
        queryParameters: {'userId': userId},
      );
      if (response.data == null) return [];
      return response.data!
          .map((e) => GroupMemberDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading members: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // STOMP WebSocket methods
  // ------------------------------------------------------------------

  /// Derive WS URL from backend URL.
  /// SockJS requires http/https (not ws/wss).
  /// Backend URL: http://host:8080/api → http://host:8080/ws
  String get _wsUrl {
    final base = Environment.backendUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/ws';
  }

  /// Connect to the STOMP broker
  void connect({String? authToken}) {
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
        onConnect: _onStompConnected,
        onDisconnect: _onStompDisconnected,
        onStompError: (frame) {
          debugPrint('STOMP error: ${frame.body}');
        },
        onWebSocketError: (error) {
          debugPrint('WebSocket error: $error');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    debugPrint('🔌 Connecting STOMP to $_wsUrl');
    _stompClient!.activate();
  }

  void _onStompConnected(StompFrame frame) {
    _isConnected = true;
    debugPrint('✅ STOMP connected');
  }

  void _onStompDisconnected(StompFrame frame) {
    _isConnected = false;
    debugPrint('🔌 STOMP disconnected');
  }

  /// Subscribe to a group's message topic
  void subscribeToGroup(int groupId) {
    if (_stompClient == null || !_isConnected) {
      debugPrint('⚠️ Cannot subscribe: STOMP not connected');
      return;
    }

    // Avoid duplicate subscriptions
    if (_subscriptions.containsKey(groupId)) return;

    final unsubscribe = _stompClient!.subscribe(
      destination: '/topic/group.$groupId',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!) as Map<String, dynamic>;
          final msg = GroupChatMessageDTO.fromJson(json);
          onMessageReceived?.call(msg);
        } catch (e) {
          debugPrint('Error parsing WS message: $e');
        }
      },
    );

    _subscriptions[groupId] = unsubscribe;
    debugPrint('📡 Subscribed to /topic/group.$groupId');
  }

  /// Unsubscribe from a group's message topic
  void unsubscribeFromGroup(int groupId) {
    final unsub = _subscriptions.remove(groupId);
    if (unsub != null) {
      unsub(unsubscribeHeaders: {});
      debugPrint('📡 Unsubscribed from group $groupId');
    }
  }

  /// Send a message via STOMP (alternative to REST)
  void sendMessageStomp(GroupChatMessageDTO message) {
    if (_stompClient == null || !_isConnected) {
      debugPrint('⚠️ Cannot send via STOMP: not connected');
      return;
    }
    _stompClient!.send(
      destination: '/app/group.chat',
      body: jsonEncode(message.toJson()),
    );
  }

  /// Disconnect and clean up
  void disconnect() {
    for (final unsub in _subscriptions.values) {
      unsub(unsubscribeHeaders: {});
    }
    _subscriptions.clear();
    _stompClient?.deactivate();
    _isConnected = false;
    debugPrint('🔌 STOMP disconnected and cleaned up');
  }

  bool get isConnected => _isConnected;
}
