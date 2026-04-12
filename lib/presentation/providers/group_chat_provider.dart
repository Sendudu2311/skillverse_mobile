import 'package:flutter/foundation.dart';
import '../../data/models/group_chat_models.dart';
import '../../data/services/group_chat_service.dart';

/// Provider for Group Chat state management.
/// Manages group list, current group detail, messages, and WebSocket lifecycle.
class GroupChatProvider extends ChangeNotifier {
  final GroupChatService _service = GroupChatService();

  // ── State ────────────────────────────────────────────────────────────
  List<GroupChatResponse> _groups = [];
  List<GroupChatMessageDTO> _messages = [];
  GroupChatResponse? _currentGroup;
  bool _isLoadingGroups = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _error;

  // Current user info (set from AuthProvider)
  int? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  String? _authToken;

  // ── Getters ──────────────────────────────────────────────────────────
  List<GroupChatResponse> get groups => _groups;
  List<GroupChatMessageDTO> get messages => _messages;
  GroupChatResponse? get currentGroup => _currentGroup;
  bool get isLoadingGroups => _isLoadingGroups;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get error => _error;

  // ── Configuration ────────────────────────────────────────────────────
  void setCurrentUser({
    required int userId,
    required String userName,
    String? avatar,
    String? token,
  }) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserAvatar = avatar;
    _authToken = token;
  }

  // ── Group list ───────────────────────────────────────────────────────
  Future<void> loadMyGroups() async {
    if (_currentUserId == null) return;
    _isLoadingGroups = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _service.getMyGroups(_currentUserId!);
    } catch (e) {
      _error = 'Không thể tải danh sách nhóm';
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoadingGroups = false;
      notifyListeners();
    }
  }

  // ── Enter a group chat ───────────────────────────────────────────────
  Future<void> enterGroup(int groupId) async {
    if (_currentUserId == null) return;
    _isLoadingMessages = true;
    _messages = [];
    _error = null;
    notifyListeners();

    try {
      // Load detail
      _currentGroup =
          await _service.getGroupDetail(groupId, _currentUserId!);

      // Load messages
      _messages =
          await _service.getGroupMessages(groupId, _currentUserId!);

      // Setup WebSocket
      _service.onMessageReceived = _handleIncomingMessage;
      _service.connect(authToken: _authToken);

      // Wait a moment for connection before subscribing
      await Future.delayed(const Duration(milliseconds: 500));
      _service.subscribeToGroup(groupId);
    } catch (e) {
      _error = 'Không thể tải tin nhắn';
      debugPrint('Error entering group: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // ── Leave a group chat (navigation, not API) ────────────────────────
  void leaveCurrentGroup() {
    if (_currentGroup != null) {
      _service.unsubscribeFromGroup(_currentGroup!.id);
    }
    _currentGroup = null;
    _messages = [];
    notifyListeners();
  }

  // ── Send a message ───────────────────────────────────────────────────
  Future<void> sendMessage(String content, {String type = 'TEXT'}) async {
    if (_currentUserId == null || _currentGroup == null) return;
    if (content.trim().isEmpty) return;

    _isSending = true;
    notifyListeners();

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = GroupChatMessageDTO(
      id: tempId,
      groupId: _currentGroup!.id,
      senderId: _currentUserId,
      senderName: _currentUserName,
      senderAvatarUrl: _currentUserAvatar,
      content: content,
      timestamp: DateTime.now().toIso8601String(),
      messageType: type,
    );

    // Optimistic update
    _messages.add(optimistic);
    notifyListeners();

    try {
      final saved = await _service.sendMessageRest(
        _currentGroup!.id,
        optimistic,
      );

      // Handle race condition between REST response and STOMP broadcast
      final hasStompAdded = _messages.any((m) => m.id == saved.id);
      final tempIdx = _messages.indexWhere((m) => m.id == tempId);

      if (hasStompAdded) {
        // STOMP arrived first and is already in the list. Remove temp if it wasn't replaced.
        if (tempIdx >= 0) _messages.removeAt(tempIdx);
      } else {
        // REST arrived first. Replace temp message with server response.
        if (tempIdx >= 0) _messages[tempIdx] = saved;
      }
    } catch (e) {
      // Remove failed message
      _messages.removeWhere((m) => m.id == tempId);
      _error = 'Gửi tin nhắn thất bại';
      debugPrint('Error sending message: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ── Incoming WebSocket message ───────────────────────────────────────
  void _handleIncomingMessage(GroupChatMessageDTO msg) {
    if (_messages.any((m) => m.id == msg.id)) return;

    // Check if this incoming message matches a pending optimistic message
    final tempIdx = _messages.indexWhere((m) =>
        m.id != null &&
        m.id! < 0 &&
        m.senderId == msg.senderId &&
        m.content == msg.content &&
        m.messageType == msg.messageType);

    if (tempIdx >= 0) {
      // Replace the temp message to avoid visual flicker
      _messages[tempIdx] = msg;
    } else {
      _messages.add(msg);
    }
    notifyListeners();
  }

  // ── Cleanup ──────────────────────────────────────────────────────────
  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }
}
