import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../core/network/api_client.dart';
import '../../data/models/messaging_models.dart';
import '../../data/services/messaging_service.dart';
import 'auth_provider.dart';

/// Provider for user-to-user 1-1 messaging (G3)
/// Uses PreChatController backend: /api/prechat/threads, /api/prechat/conversation, /api/prechat/send
/// + STOMP WebSocket for real-time message delivery via /user/queue/prechat
class MessagingProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final AuthProvider _authProvider;
  final MessagingService _service = MessagingService();
  SharedPreferences? _prefs;

  MessagingProvider(this._authProvider);

  // Conversations list
  List<MessagingConversation> _conversations = [];
  List<MessagingConversation> get conversations => _conversations;

  // Active chat (with another user via booking)
  int? _activeOtherUserId;
  int? _activeBookingId;
  List<MessagingMessage> _messages = [];
  List<MessagingMessage> get messages => _messages;
  int? get activeOtherUserId => _activeOtherUserId;
  int? get activeBookingId => _activeBookingId;

  // Send state
  bool get isSending => isLoading;

  int? get currentUserId => _authProvider.user?.id;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── WebSocket lifecycle ─────────────────────────────────────────────

  bool _wsConnected = false;

  /// Connect STOMP WebSocket for real-time prechat messages.
  /// Safe to call multiple times (idempotent).
  void connectWebSocket() {
    if (_wsConnected) return;
    _wsConnected = true;

    _service.onMessageReceived = _handleIncomingMessage;
    _service.connectStomp(authToken: ApiClient().authToken);
  }

  /// Disconnect STOMP WebSocket
  void disconnectWebSocket() {
    _service.disconnectStomp();
    _wsConnected = false;
  }

  // ── Load conversations ──────────────────────────────────────────────

  /// Load all conversations
  Future<void> loadConversations() async {
    await executeAsync(() async {
      final raw = await _service.getConversations();
      // LỌC BỎ các thread tài khoản này đang làm Mentor (chỉ dành cho Web)
      final learnerRaw = raw.where((c) => c.myRoleMentor == false).toList();
      _conversations = await _processConversations(learnerRaw);
    });
    notifyListeners();
  }

  /// Process conversations to check local read cache and sort.
  Future<List<MessagingConversation>> _processConversations(
    List<MessagingConversation> raw,
  ) async {
    await _initPrefs();

    // We already filtered out myRoleMentor == true, so counterpartId should be unique
    // but just in case, we can still use a Map to ensure uniqueness.
    final map = <int, MessagingConversation>{};
    for (final conv in raw) {
      if (!map.containsKey(conv.counterpartId)) {
        map[conv.counterpartId] = conv;
      } else {
        // If there are duplicates despite filtering, keep the newest
        final existingTime = DateTime.tryParse(
          map[conv.counterpartId]!.lastTime,
        );
        final newTime = DateTime.tryParse(conv.lastTime);
        if (newTime != null &&
            (existingTime == null || newTime.isAfter(existingTime))) {
          map[conv.counterpartId] = conv;
        }
      }
    }

    final out = <MessagingConversation>[];
    for (final conv in map.values) {
      final key = 'prechat_read_time_${currentUserId}_${conv.counterpartId}';
      final readTimeStr = _prefs!.getString(key);
      int finalUnread = conv.unreadCount;

      if (readTimeStr != null && conv.unreadCount > 0) {
        final readTime = DateTime.tryParse(readTimeStr);
        final msgTime = DateTime.tryParse(conv.lastTime);
        if (readTime != null && msgTime != null) {
          if (msgTime.isBefore(readTime) ||
              msgTime.isAtSameMomentAs(readTime)) {
            finalUnread = 0;
          }
        }
      }

      out.add(
        MessagingConversation(
          bookingId: conv.bookingId,
          counterpartId: conv.counterpartId,
          counterpartName: conv.counterpartName,
          counterpartAvatar: conv.counterpartAvatar,
          lastContent: conv.lastContent,
          lastTime: conv.lastTime,
          unreadCount: finalUnread,
          myRoleMentor: conv.myRoleMentor,
          bookingStartTime: conv.bookingStartTime,
          bookingEndTime: conv.bookingEndTime,
          bookingStatus: conv.bookingStatus,
          chatEnabled: conv.chatEnabled,
        ),
      );
    }
    // Sort so newest is on top
    out.sort(
      (a, b) => (DateTime.tryParse(b.lastTime) ?? DateTime.now()).compareTo(
        DateTime.tryParse(a.lastTime) ?? DateTime.now(),
      ),
    );
    return out;
  }

  // ── Open / close chat ───────────────────────────────────────────────

  /// Open chat with a specific user via a specific booking
  Future<void> openChat(int otherUserId, {int? bookingId}) async {
    _activeOtherUserId = otherUserId;
    _activeBookingId = bookingId;
    _messages = [];
    notifyListeners();

    // Auto-connect WS if not already
    connectWebSocket();

    if (bookingId != null) {
      await executeAsync(() async {
        _messages = await _service.getMessages(bookingId);
      });

      // Mark as read on backend + clear badge locally
      _service.markAsRead(bookingId);
    }
    _clearLocalUnread(otherUserId);

    notifyListeners();
  }

  /// Clear unread count locally so the badge disappears immediately
  Future<void> _clearLocalUnread(int counterpartId) async {
    await _initPrefs();
    final idx = _conversations.indexWhere(
      (c) => c.counterpartId == counterpartId,
    );
    if (idx >= 0) {
      final old = _conversations[idx];
      if (old.unreadCount > 0) {
        _conversations[idx] = MessagingConversation(
          bookingId: old.bookingId,
          counterpartId: old.counterpartId,
          counterpartName: old.counterpartName,
          counterpartAvatar: old.counterpartAvatar,
          lastContent: old.lastContent,
          lastTime: old.lastTime,
          unreadCount: 0,
          myRoleMentor: old.myRoleMentor,
          bookingStartTime: old.bookingStartTime,
          bookingEndTime: old.bookingEndTime,
          bookingStatus: old.bookingStatus,
          chatEnabled: old.chatEnabled,
        );
        notifyListeners();
      }
      final key = 'prechat_read_time_${currentUserId}_${counterpartId}';
      await _prefs!.setString(key, old.lastTime);
    }
  }

  /// Close active chat
  void closeChat() {
    _activeOtherUserId = null;
    _activeBookingId = null;
    _messages = [];
    notifyListeners();
  }

  // ── Send message ────────────────────────────────────────────────────

  /// Send a message to the active chat partner via REST API.
  /// STOMP is used only for receiving incoming messages from the counterpart.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _activeOtherUserId == null) return;

    if (_activeBookingId == null) {
      debugPrint('Error sending message: No active booking for this chat');
      return;
    }

    try {
      setLoading(true);

      final request = SendMessageRequest(
        bookingId: _activeBookingId!,
        content: content,
      );

      final sentMsg = await _service.sendMessage(request);
      _messages = [..._messages, sentMsg];
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // ── Incoming WebSocket message ──────────────────────────────────────

  void _handleIncomingMessage(MessagingMessage msg) {
    final myId = currentUserId;

    // If chat with this person is currently open → add to messages
    if (_activeOtherUserId != null) {
      // Determine if this message belongs to the active conversation
      final isFromActivePartner = msg.senderId == _activeOtherUserId;
      final isSentByMe = msg.senderId == myId;

      if (isFromActivePartner || isSentByMe) {
        // Deduplicate: skip if same content + sender + close timestamp
        final isDuplicate = _messages.any(
          (m) =>
              m.senderId == msg.senderId &&
              m.content == msg.content &&
              (m.id == msg.id ||
                  (DateTime.tryParse(m.createdAt)
                              ?.difference(
                                DateTime.tryParse(msg.createdAt) ??
                                    DateTime.now(),
                              )
                              .inSeconds
                              .abs() ??
                          999) <
                      3),
        );

        if (!isDuplicate) {
          _messages = [..._messages, msg];
        } else if (isSentByMe) {
          // Replace optimistic temp message with real server message
          _messages = [
            ..._messages.where(
              (m) =>
                  !(m.senderId == msg.senderId &&
                      m.content == msg.content &&
                      m.id != msg.id),
            ),
            msg,
          ];
        }

        // Auto mark as read since chat is open
        if (isFromActivePartner) {
          if (_activeBookingId != null) {
            _service.markAsRead(_activeBookingId!);
          }
          _initPrefs().then((_) {
            final key =
                'prechat_read_time_${currentUserId}_$_activeOtherUserId';
            _prefs!.setString(key, msg.createdAt);
          });
        }

        notifyListeners();
        return;
      }
    }

    // Chat is NOT open with this sender → update conversations list
    _updateConversationPreview(msg);
    notifyListeners();
  }

  /// Update conversation list when a message arrives for a non-active chat
  void _updateConversationPreview(MessagingMessage msg) {
    final myId = currentUserId;
    final counterpartId = msg.senderId == myId
        ? (msg.mentorId ?? msg.learnerId ?? msg.senderId)
        : msg.senderId;

    final idx = _conversations.indexWhere(
      (c) => c.counterpartId == counterpartId,
    );

    if (idx >= 0) {
      final old = _conversations[idx];
      _conversations[idx] = MessagingConversation(
        bookingId: old.bookingId,
        counterpartId: old.counterpartId,
        counterpartName: old.counterpartName,
        counterpartAvatar: old.counterpartAvatar,
        lastContent: msg.content,
        lastTime: msg.createdAt,
        unreadCount: old.unreadCount + 1,
        myRoleMentor: old.myRoleMentor,
        bookingStartTime: old.bookingStartTime,
        bookingEndTime: old.bookingEndTime,
        bookingStatus: old.bookingStatus,
        chatEnabled: old.chatEnabled,
      );
      // Move to top
      final updated = _conversations.removeAt(idx);
      _conversations.insert(0, updated);
    } else {
      // New conversation from unknown sender — add placeholder
      _conversations.insert(
        0,
        MessagingConversation(
          counterpartId: counterpartId,
          counterpartName: 'User #$counterpartId',
          lastContent: msg.content,
          lastTime: msg.createdAt,
          unreadCount: 1,
        ),
      );
    }
  }

  // ── Refresh ─────────────────────────────────────────────────────────

  /// Refresh conversations list
  Future<void> refreshConversations() async {
    await loadConversations();
  }

  /// Refresh active chat messages
  Future<void> refreshMessages() async {
    if (_activeBookingId == null) return;

    await executeAsync(() async {
      _messages = await _service.getMessages(_activeBookingId!);
    });
    notifyListeners();
  }

  // ── Cleanup ─────────────────────────────────────────────────────────

  /// Called by app-level logout listener: disconnect WebSocket and purge all user data.
  void clearOnLogout() {
    disconnectWebSocket();
    _conversations = [];
    _messages = [];
    _activeOtherUserId = null;
    _activeBookingId = null;
    resetState();
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}
