import 'package:flutter/foundation.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/expert_chat_models.dart';
import '../../data/models/premium_models.dart';
import '../../data/services/expert_chat_service.dart';
import '../../data/services/premium_service.dart';

/// Expert Chat Provider — State management for AI Expert consultation feature
///
/// Uses [MultiLoadingProviderMixin] to manage multiple independent loading states:
/// - `isLoadingFor('fields')` — loading expert fields
/// - `isLoadingFor('session')` — loading session history
/// - `isLoadingFor('sessions')` — loading session list
/// - `isLoadingFor('sending')` — sending a message
class ExpertChatProvider extends ChangeNotifier with MultiLoadingProviderMixin {
  final ExpertChatService _service = ExpertChatService();

  // Expert fields state
  List<ExpertFieldResponse> _expertFields = [];
  String? _fieldsError;

  // Selection state
  ExpertFieldResponse? _selectedDomain;
  IndustryInfo? _selectedIndustry;
  RoleInfo? _selectedRole;

  // Chat state
  ExpertContext? _expertContext;
  List<UIMessage> _messages = [];
  int? _sessionId;
  final Set<int> _sendingSessions = {}; // Tracks all sessions waiting for AI
  String? _currentSessionTitle; // Title of current session

  // Sessions state
  List<ExpertChatSession> _sessions = [];

  // G5: Deep Research mode
  String?
  _aiAgentMode; // null = normal, "deep-research-pro-preview-12-2025" = deep

  // G6: Subscription for gate check
  UserSubscriptionDto? _subscription;

  // Getters
  List<ExpertFieldResponse> get expertFields => _expertFields;
  bool get loadingFields => isLoadingFor('fields');
  String? get fieldsError => _fieldsError;

  ExpertFieldResponse? get selectedDomain => _selectedDomain;
  IndustryInfo? get selectedIndustry => _selectedIndustry;
  RoleInfo? get selectedRole => _selectedRole;

  ExpertContext? get expertContext => _expertContext;
  List<UIMessage> get messages => _messages;
  int? get sessionId => _sessionId;
  String? get currentSessionTitle => _currentSessionTitle;
  bool get isLoading => isLoadingFor('session');

  /// Check if a specific session is currently waiting for AI response
  bool isSessionSending(int? id) => _sendingSessions.contains(id ?? -1);
  bool get isSending => isSessionSending(_sessionId);

  List<ExpertChatSession> get sessions => _sessions;
  bool get loadingSessions => isLoadingFor('sessions');
  String? get aiAgentMode => _aiAgentMode;
  UserSubscriptionDto? get subscription => _subscription;

  /// Load expert fields from API
  Future<void> loadExpertFields() async {
    if (_expertFields.isNotEmpty) return; // Already loaded

    await performAsyncFor('fields', () async {
      _fieldsError = null;
      _expertFields = await _service.getExpertFields();
    }).catchError((e) {
      _fieldsError = e.toString();
      debugPrint('Error loading expert fields: $e');
    });
    notifyListeners();
  }

  /// Select a domain
  void selectDomain(ExpertFieldResponse domain) {
    _selectedDomain = domain;
    _selectedIndustry = null;
    _selectedRole = null;
    notifyListeners();
  }

  /// Select an industry
  void selectIndustry(IndustryInfo industry) {
    _selectedIndustry = industry;
    _selectedRole = null;
    notifyListeners();
  }

  /// Select a role and create expert context
  void selectRole(RoleInfo role) {
    if (_selectedDomain == null || _selectedIndustry == null) return;

    _selectedRole = role;
    _expertContext = ExpertContext(
      domain: _selectedDomain!.domain,
      industry: _selectedIndustry!.industry,
      jobRole: role.jobRole,
      expertName: '${role.jobRole} Expert',
      mediaUrl: role.mediaUrl,
    );
    notifyListeners();
  }

  /// Start new chat with welcome message
  void startNewChat() {
    if (_expertContext == null) return;

    _sessionId = null;
    _currentSessionTitle = null; // Clear title for new chat
    _messages = [
      UIMessage(
        id: '1',
        role: 'assistant',
        content: _generateWelcomeMessage(),
        timestamp: DateTime.now(),
        expertContext: _expertContext,
      ),
    ];
    notifyListeners();
  }

  String _generateWelcomeMessage() {
    final ctx = _expertContext!;
    return '''🎯 **EXPERT SYSTEM INITIALIZED**

✨ Xin chào! Tôi là chuyên gia **${ctx.jobRole}** của SkillVerse.

**Lĩnh vực**: ${ctx.domain}
**Ngành nghề**: ${ctx.industry}
**Chuyên môn**: ${ctx.jobRole}

---

Tôi có thể tư vấn chuyên sâu về:
- 📊 **Kỹ năng chuyên môn** cần thiết
- 🚀 **Lộ trình phát triển** cụ thể
- 💼 **Cơ hội nghề nghiệp** trong lĩnh vực
- 🎓 **Tài nguyên học tập** chất lượng cao
- 💰 **Mức lương & thị trường** hiện tại

💬 **Hãy hỏi tôi bất cứ điều gì về ${ctx.jobRole}!**''';
  }

  /// Send message to expert
  Future<void> sendMessage(String message) async {
    final sentSessionId = _sessionId ?? -1;
    if (message.trim().isEmpty ||
        _expertContext == null ||
        _sendingSessions.contains(sentSessionId))
      return;

    // Capture current session context before async gap
    final sentContext = _expertContext;

    try {
      _sendingSessions.add(sentSessionId);
      notifyListeners();

      // Add user message
      final userMessage = UIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: message,
        timestamp: DateTime.now(),
      );
      _messages = [..._messages, userMessage];

      // Optimistic: add placeholder session so Drawer shows it immediately
      if (sentSessionId == -1 && sentContext != null) {
        final optimistic = ExpertChatSession(
          sessionId: -1, // placeholder ID
          title: 'Expert ${sentContext.jobRole}',
          messageCount: 1,
          lastMessageAt: DateTime.now().toIso8601String(),
        );
        _sessions = [optimistic, ..._sessions];
      }
      notifyListeners();

      // Send to API
      final request = ExpertChatRequest(
        message: message,
        sessionId: sentSessionId,
        chatMode: ChatMode.expertMode,
        domain: sentContext!.domain,
        industry: sentContext.industry,
        jobRole: sentContext.jobRole,
        aiAgentMode: _aiAgentMode, // G5: Deep Research mode
      );

      final response = await _service.sendMessage(request);

      // Guard: if user switched to a different session while waiting,
      // skip UI update. The backend already saved the response, so it
      // will appear when the user reloads the original session.
      // Note: sentSessionId==-1 + _sessionId==-1 means user clicked the
      // optimistic placeholder — same "new" session, so do NOT skip.
      final isSameNewSession =
          sentSessionId == -1 && (_sessionId == null || _sessionId == -1);
      final isSameExistingSession =
          sentSessionId != -1 && _sessionId == sentSessionId;
      if (!isSameNewSession && !isSameExistingSession) {
        debugPrint(
          '⚠️ Session changed while waiting for response '
          '(sent: $sentSessionId, current: $_sessionId). Skipping UI update.',
        );
        _sendingSessions.remove(sentSessionId);
        notifyListeners();
        return;
      }

      // Update session ID if new
      if (_sessionId == null || _sessionId == -1) {
        _sendingSessions.remove(-1); // Transition from placeholder to real ID
        _sessionId = response.sessionId;
        // Rename session to expert role
        try {
          await _service.renameSession(
            response.sessionId,
            'Expert ${sentContext.jobRole}',
          );
        } catch (_) {}
        // Sync session list so new chat shows up in history drawer
        loadSessions();
      }

      // Add assistant message
      final assistantMessage = UIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: response.aiResponse,
        timestamp:
            DateTimeHelper.tryParseIso8601(response.timestamp) ??
            DateTime.now(),
        expertContext: sentContext,
      );
      _messages = [..._messages, assistantMessage];
      _sendingSessions.remove(sentSessionId);
      _sendingSessions.remove(response.sessionId); // Just in case it was added
      notifyListeners();
    } catch (e) {
      _sendingSessions.remove(sentSessionId);
      notifyListeners();

      // Guard: don't pollute a different session with error messages
      final errSameNew =
          sentSessionId == -1 && (_sessionId == null || _sessionId == -1);
      final errSameExisting =
          sentSessionId != -1 && _sessionId == sentSessionId;
      if (!errSameNew && !errSameExisting) return;

      // Add error message
      final errorMessage = UIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: '⚠️ Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.',
        timestamp: DateTime.now(),
      );
      _messages = [..._messages, errorMessage];
      notifyListeners();

      debugPrint('Error sending message: $e');
    }
  }

  /// Load sessions
  Future<void> loadSessions() async {
    await performAsyncFor('sessions', () async {
      _sessions = await _service.getSessions(chatMode: ChatMode.expertMode);
    }).catchError((e) {
      debugPrint('Error loading sessions: $e');
    });
    notifyListeners();
  }

  /// Load session history
  Future<void> loadSession(ExpertChatSession session) async {
    // Synthesize expertContext from session title if missing
    // Backend hydrates the real domain/industry from its DB via sessionId,
    // so we only need a plausible jobRole to pass the local validator.
    if (_expertContext == null) {
      final inferredRole = session.title.startsWith('Expert ')
          ? session.title.substring(7)
          : session.title;
      _expertContext = ExpertContext(
        domain: 'Lịch sử',
        industry: 'Lịch sử',
        jobRole: inferredRole,
      );
    }

    // Skip API call for optimistic sessions (still waiting for AI)
    if (session.sessionId == -1) {
      _sessionId = -1;
      _currentSessionTitle = session.title;
      _messages = [
        UIMessage(
          id: '-1',
          role: 'assistant',
          content: 'Tin nhắn của bạn đang được chuyên gia xử lý...',
          timestamp: DateTime.now(),
        ),
      ];
      notifyListeners();
      return;
    }

    await performAsyncFor('session', () async {
      final history = await _service.getHistory(session.sessionId);

      // Build new messages locally first to avoid blank flash
      final newMessages = <UIMessage>[];
      for (int i = 0; i < history.length; i++) {
        final msg = history[i];
        newMessages.add(
          UIMessage(
            id: '${session.sessionId}-$i-user',
            role: 'user',
            content: msg.userMessage,
            timestamp:
                DateTimeHelper.tryParseIso8601(msg.createdAt) ?? DateTime.now(),
          ),
        );
        newMessages.add(
          UIMessage(
            id: '${session.sessionId}-$i-assistant',
            role: 'assistant',
            content: msg.aiResponse,
            timestamp:
                DateTimeHelper.tryParseIso8601(msg.createdAt) ?? DateTime.now(),
            expertContext: _expertContext,
          ),
        );
      }

      // Atomic swap — UI jumps from old to new without blank state
      _sessionId = session.sessionId;
      _currentSessionTitle = session.title;
      _messages = newMessages;
    }).catchError((e) {
      debugPrint('Error loading session: $e');
    });
    notifyListeners();
  }

  /// Auto-load the most recent session (used when entering chat without context)
  Future<void> openLatestSession() async {
    if (_sessions.isEmpty) {
      await loadSessions();
    }
    if (_sessions.isNotEmpty) {
      await loadSession(_sessions.first);
    }
  }

  /// Delete session
  Future<void> deleteSession(int sessionId) async {
    try {
      await _service.deleteSession(sessionId);
      _sessions = _sessions.where((s) => s.sessionId != sessionId).toList();

      if (_sessionId == sessionId) {
        _sessionId = null;
        _messages = [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  /// Reset selection state
  void resetSelection() {
    _selectedDomain = null;
    _selectedIndustry = null;
    _selectedRole = null;
    _expertContext = null;
    _messages = [];
    _sessionId = null;
    _currentSessionTitle = null;
    // Do NOT clear _sendingSessions, so background sends continue
    notifyListeners();
  }

  /// Set expert context directly (for loading existing sessions)
  void setExpertContext(ExpertContext context) {
    _expertContext = context;
    notifyListeners();
  }

  /// G5: Toggle AI agent mode (Normal / Deep Research)
  void setAiAgentMode(String? mode) {
    _aiAgentMode = mode;
    notifyListeners();
  }

  /// G6: Load user subscription for gate check
  Future<void> loadSubscription() async {
    try {
      _subscription = await PremiumService().getCurrentSubscription();
    } catch (e) {
      _subscription = null;
      debugPrint('Error loading subscription: $e');
    }
    notifyListeners();
  }
}
