import 'package:flutter/material.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/chat_models.dart';
import '../../data/services/chat_service.dart';
import 'auth_provider.dart';

/// Chat Provider
///
/// Uses [LoadingProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `performAsync()` — try/finally/loading wrapper
///
/// Error handling is done inline (adding error messages to chat UI),
/// so error-tracking mixin is not needed.
class ChatProvider with ChangeNotifier, LoadingProviderMixin {
  final ChatService _chatService = ChatService();
  final AuthProvider _authProvider;

  ChatProvider(this._authProvider);

  List<UIMessage> _messages = [];
  int? _currentSessionId;

  List<UIMessage> get messages => _messages;
  int? get currentSessionId => _currentSessionId;

  /// Initialize with welcome message
  void initialize() {
    _messages = [
      UIMessage(
        id: 'welcome',
        role: 'assistant',
        content: 'Xin chào! Tôi là Meowl, trợ lý AI của SkillVerse. Tôi có thể giúp bạn tìm khóa học, trả lời câu hỏi về lập trình, hoặc hỗ trợ học tập. Bạn cần giúp gì hôm nay? 🐱',
        timestamp: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to UI
    final userMessage = UIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    setLoading(true);

    try {
      // Create chat history from current messages (excluding the current user message)
      final chatHistory = _messages
          .where((msg) => msg.role != 'user' || msg.id != userMessage.id) // Exclude current user message
          .take(10) // Last 10 messages
          .map((msg) => ChatHistoryItem(
                role: msg.role,
                content: msg.content,
              ))
          .toList();

      final request = ChatRequest(
        message: message,
        language: 'vi', // Default to Vietnamese, can be made configurable later
        userId: _authProvider.user?.id,
        includeReminders: true,
        chatHistory: chatHistory,
      );

      final response = await _chatService.sendMessage(request);

      // Log reminders and notifications if available (for future use)
      if (response.reminders != null && response.reminders!.isNotEmpty) {
        debugPrint('Reminders: ${response.reminders}');
      }

      // Add AI response to UI
      final aiMessage = UIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: response.message.isNotEmpty ? response.message : (response.originalMessage ?? '...'),
        timestamp: DateTime.now(),
      );

      _messages.add(aiMessage);
    } catch (e) {
      // Add error message to UI (inline error handling)
      final errorMessage = UIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'Xin lỗi, có lỗi xảy ra khi gửi tin nhắn. Vui lòng thử lại.',
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      setLoading(false);
    }
  }

  /// Add messages directly to the chat (for guard responses)
  void addMessagesDirectly(List<UIMessage> messages) {
    _messages.addAll(messages);
    notifyListeners();
  }

  /// Load conversation history for a session
  Future<void> loadHistory(int sessionId) async {
    await performAsync(() async {
      final history = await _chatService.getHistory(sessionId);

      // Convert ChatMessage to UIMessage
      _messages = history.expand((chatMessage) => [
        UIMessage(
          id: 'user_${chatMessage.id}',
          role: 'user',
          content: chatMessage.userMessage,
          timestamp: DateTime.parse(chatMessage.createdAt),
        ),
        UIMessage(
          id: 'ai_${chatMessage.id}',
          role: 'assistant',
          content: chatMessage.aiResponse,
          timestamp: DateTime.parse(chatMessage.createdAt),
        ),
      ]).toList();

      _currentSessionId = sessionId;
    });
  }

  /// Start a new conversation
  void startNewConversation() {
    _messages = [
      UIMessage(
        id: 'welcome',
        role: 'assistant',
        content: 'Xin chào! Tôi là Meowl, trợ lý AI của SkillVerse. Tôi có thể giúp bạn tìm khóa học, trả lời câu hỏi về lập trình, hoặc hỗ trợ học tập. Bạn cần giúp gì hôm nay? 🐱',
        timestamp: DateTime.now(),
      ),
    ];
    _currentSessionId = null;
    notifyListeners();
  }
}