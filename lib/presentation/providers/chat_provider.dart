import 'package:flutter/foundation.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/expert_chat_models.dart' show ChatMode;
import '../../data/services/chat_service.dart';
import '../../data/services/expert_chat_service.dart';
import 'auth_provider.dart';

/// Chat Provider
///
/// Uses [LoadingProviderMixin] to auto-manage:
/// - `isLoading` / `setLoading(bool)` — loading state
/// - `performAsync()` — try/finally/loading wrapper
///
/// Error handling is done inline (adding error messages to chat UI),
/// so error-tracking mixin is not needed.
class ChatProvider with ChangeNotifier, MultiLoadingProviderMixin {
  final ChatService _chatService = ChatService();
  final ExpertChatService _sessionService = ExpertChatService();
  final AuthProvider _authProvider;

  ChatProvider(this._authProvider);

  List<UIMessage> _messages = [];
  int? _currentSessionId;

  // Session management (G1)
  List<ChatSession> _sessions = [];
  bool _sessionsLoaded = false;
  String? _currentSessionTitle;

  // Onboarding context (G2)
  List<MeowlQuickAction> _quickActions = [];
  List<String> _suggestedPrompts = [];
  String _welcomeMessage = '';
  bool _onboardingLoaded = false;

  List<UIMessage> get messages => _messages;
  int? get currentSessionId => _currentSessionId;
  String? get currentSessionTitle => _currentSessionTitle;
  List<ChatSession> get sessions => _sessions;
  bool get loadingSessions => isLoadingFor('sessions');
  bool get isSending => isLoadingFor('sending');
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
      final context = await _chatService.getOnboardingContext(userId, 'vi');
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
    setLoadingFor('sending', true);

    try {
      // Create chat history from current messages (excluding the current user message)
      final chatHistory = _messages
          .where(
            (msg) => msg.role != 'user' || msg.id != userMessage.id,
          ) // Exclude current user message
          .take(10) // Last 10 messages
          .map((msg) => ChatHistoryItem(role: msg.role, content: msg.content))
          .toList();

      final request = ChatRequest(
        message: message,
        language: 'vi', // Default to Vietnamese, can be made configurable later
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

      // Refresh sessions list to pick up new/updated session
      if (_sessionsLoaded) {
        loadSessions();
      }
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
      setLoadingFor('sending', false);
    }
  }

  /// Add messages directly to the chat (for guard responses)
  void addMessagesDirectly(List<UIMessage> messages) {
    _messages.addAll(messages);
    notifyListeners();
  }

  /// Load conversation history for a session
  Future<void> loadHistory(int sessionId) async {
    await performAsyncFor('history', () async {
      final history = await _sessionService.getHistory(sessionId);

      // Convert ExpertChatMessage to UIMessage
      _messages = history
          .expand(
            (msg) => [
              UIMessage(
                id: 'user_${msg.messageId}',
                role: 'user',
                content: msg.userMessage,
                timestamp:
                    DateTimeHelper.tryParseIso8601(msg.createdAt) ??
                    DateTime.now(),
              ),
              UIMessage(
                id: 'ai_${msg.messageId}',
                role: 'assistant',
                content: msg.aiResponse,
                timestamp:
                    DateTimeHelper.tryParseIso8601(msg.createdAt) ??
                    DateTime.now(),
              ),
            ],
          )
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
    _currentSessionTitle = null;
    notifyListeners();
  }

  // ════════════════════ G1: Session Management ════════════════════

  /// Load all general-mode chat sessions from the AI Chat API.
  /// Uses ExpertChatService since session endpoints live at /v1/ai/chat/sessions
  Future<void> loadSessions() async {
    await performAsyncFor('sessions', () async {
      final all = await _sessionService.getSessions(
        chatMode: ChatMode.generalCareerAdvisor,
      );
      // Filter to only show general advisor sessions
      _sessions = all
          .where((s) => s.chatMode == null || s.chatMode == ChatMode.generalCareerAdvisor)
          .map((s) => ChatSession(
                sessionId: s.sessionId,
                title: s.title,
                lastMessageAt: s.lastMessageAt,
                messageCount: s.messageCount,
              ))
          .toList();
      _sessionsLoaded = true;
    }).catchError((e) {
      debugPrint('Error loading chat sessions: $e');
    });
    notifyListeners();
  }

  /// Load a specific session's history
  Future<void> loadSession(ChatSession session) async {
    _currentSessionTitle = session.title;
    await loadHistory(session.sessionId);
    notifyListeners();
  }

  /// Delete a chat session
  Future<void> deleteSession(int sessionId) async {
    try {
      await _sessionService.deleteSession(sessionId);
      _sessions = _sessions.where((s) => s.sessionId != sessionId).toList();

      if (_currentSessionId == sessionId) {
        startNewConversation();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() {
    _messages = [];
    _currentSessionId = null;
    _currentSessionTitle = null;
    _sessions = [];
    _sessionsLoaded = false;
    _quickActions = [];
    _suggestedPrompts = [];
    _welcomeMessage = '';
    _onboardingLoaded = false;
    notifyListeners();
  }
}
