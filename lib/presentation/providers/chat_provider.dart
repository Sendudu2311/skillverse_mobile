import 'package:flutter/foundation.dart';
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

  // Onboarding context (G2)
  List<MeowlQuickAction> _quickActions = [];
  List<String> _suggestedPrompts = [];
  String _welcomeMessage = '';
  bool _onboardingLoaded = false;

  List<UIMessage> get messages => _messages;
  int? get currentSessionId => _currentSessionId;
  List<MeowlQuickAction> get quickActions => _quickActions;
  List<String> get suggestedPrompts => _suggestedPrompts;
  String get welcomeMessage => _welcomeMessage;

  /// Initialize with welcome message and load onboarding context (G2)
  void initialize() {
    // Default welcome message (fallback)
    _welcomeMessage =
        'Xin chào! Tôi là Meowl, trợ lý AI của SkillVerse. Tôi có thể giúp bạn tìm khóa học, trả lời câu hỏi về lập trình, hoặc hỗ trợ học tập. Bạn cần giúp gì hôm nay? 🐱';
    _messages = [
      UIMessage(
        id: 'welcome',
        role: 'assistant',
        content: _welcomeMessage,
        timestamp: DateTime.now(),
      ),
    ];
    notifyListeners();

    // Load onboarding context from API (G2)
    _loadOnboardingContext();
  }

  Future<void> _loadOnboardingContext() async {
    if (_onboardingLoaded) return;
    final userId = _authProvider.user?.id;
    if (userId == null) return;

    try {
      final context =
          await _chatService.getOnboardingContext(userId, 'vi');
      if (context != null && context.success) {
        _welcomeMessage = context.welcomeMessage.isNotEmpty
            ? context.welcomeMessage
            : _welcomeMessage;
        _quickActions = context.quickActions ?? [];
        _suggestedPrompts = context.suggestedPrompts ?? [];
        _onboardingLoaded = true;

        // Update welcome message in UI if already shown
        if (_messages.length == 1 && _messages[0].id == 'welcome') {
          _messages = [
            UIMessage(
              id: 'welcome',
              role: 'assistant',
              content: _welcomeMessage,
              timestamp: DateTime.now(),
            ),
          ];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load onboarding context: $e');
    }
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
          .where(
              (msg) => msg.role != 'user' || msg.id != userMessage.id) // Exclude current user message
          .take(10) // Last 10 messages
          .map((msg) => ChatHistoryItem(
                role: msg.role,
                content: msg.content,
              ))
          .toList();

      final request = ChatRequest(
        message: message,
        language:
            'vi', // Default to Vietnamese, can be made configurable later
        userId: _authProvider.user?.id,
        includeReminders: true,
        chatHistory: chatHistory,
      );

      final response = await _chatService.sendMessage(request);

      // Add AI response to UI with reminders (G4)
      final aiMessage = UIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: response.message.isNotEmpty
            ? response.message
            : (response.originalMessage ?? '...'),
        timestamp: DateTime.now(),
        reminders: response.reminders,
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
      _messages = history
          .expand((chatMessage) => [
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
              ])
          .toList();

      _currentSessionId = sessionId;
    });
  }

  /// Start a new conversation
  void startNewConversation() {
    _welcomeMessage =
        'Xin chào! Tôi là Meowl, trợ lý AI của SkillVerse. Tôi có thể giúp bạn tìm khóa học, trả lời câu hỏi về lập trình, hoặc hỗ trợ học tập. Bạn cần giúp gì hôm nay? 🐱';
    _messages = [
      UIMessage(
        id: 'welcome',
        role: 'assistant',
        content: _welcomeMessage,
        timestamp: DateTime.now(),
      ),
    ];
    _currentSessionId = null;
    notifyListeners();
  }
}
