import 'package:flutter/foundation.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/messaging_models.dart';
import '../../data/services/messaging_service.dart';
import 'auth_provider.dart';

/// Provider for user-to-user 1-1 messaging (G3)
/// Uses PreChatController backend: /api/prechat/threads, /api/prechat/conversation, /api/prechat/send
class MessagingProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final AuthProvider _authProvider;
  final MessagingService _service = MessagingService();

  MessagingProvider(this._authProvider);

  // Conversations list
  List<MessagingConversation> _conversations = [];
  List<MessagingConversation> get conversations => _conversations;

  // Active chat (with another user)
  int? _activeOtherUserId;
  List<MessagingMessage> _messages = [];
  List<MessagingMessage> get messages => _messages;
  int? get activeOtherUserId => _activeOtherUserId;

  // Send state
  bool get isSending => isLoading;

  int? get currentUserId => _authProvider.user?.id;

  /// Load all conversations
  Future<void> loadConversations() async {
    await executeAsync(() async {
      _conversations = await _service.getConversations();
    });
    notifyListeners();
  }

  /// Open chat with a specific user and load message history
  Future<void> openChat(int otherUserId) async {
    _activeOtherUserId = otherUserId;
    _messages = [];
    notifyListeners();

    await executeAsync(() async {
      _messages = await _service.getMessages(otherUserId);
    });
    notifyListeners();
  }

  /// Send a message to the active chat partner
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _activeOtherUserId == null) return;

    final userId = currentUserId;
    if (userId == null) return;

    // Optimistically add user message to UI
    final userMsg = MessagingMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: userId,
      content: content,
      createdAt: DateTime.now().toIso8601String(),
    );

    _messages = [..._messages, userMsg];
    notifyListeners();

    try {
      setLoading(true);

      final sentMsg = await _service.sendMessage(
        SendMessageRequest(
          mentorId: _activeOtherUserId!,
          content: content,
        ),
      );

      // Replace optimistic message with server response
      _messages = [
        ..._messages.where((m) => m.id != userMsg.id),
        sentMsg,
      ];
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Close active chat
  void closeChat() {
    _activeOtherUserId = null;
    _messages = [];
    notifyListeners();
  }

  /// Refresh conversations list
  Future<void> refreshConversations() async {
    await loadConversations();
  }

  /// Refresh active chat messages
  Future<void> refreshMessages() async {
    if (_activeOtherUserId == null) return;

    await executeAsync(() async {
      _messages = await _service.getMessages(_activeOtherUserId!);
    });
    notifyListeners();
  }
}
