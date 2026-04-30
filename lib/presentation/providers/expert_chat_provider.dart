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

  // Cache of real ExpertContext per sessionId — populated when a session is
  // created or sent via this device. Sessions loaded from history without a
  // cached context will be shown in read-only mode.
  final Map<int, ExpertContext> _sessionContexts = {};

  // Whether openLatestSession() has finished at least once
  bool _historyBootstrapDone = false;

  // Full messages snapshot for sessions that are currently waiting for AI.
  // Keyed by sessionId (or -1 for new sessions). When the user switches away
  // and back, we restore this snapshot instead of calling getHistory (which
  // would not yet contain the in-flight user message).
  final Map<int, List<UIMessage>> _pendingMessagesBySession = {};

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
  bool get historyBootstrapDone => _historyBootstrapDone;

  /// True when viewing a session loaded from history that has no cached
  /// ExpertContext — input is disabled and a re-select CTA is shown.
  bool get isReadOnlySession =>
      _sessionId != null && _sessionId != -1 && _expertContext == null;
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
    final isNewSession = _sessionId == null || _sessionId == -1;
    final sentSessionKey = isNewSession ? -1 : _sessionId!;
    if (message.trim().isEmpty ||
        _expertContext == null ||
        _sendingSessions.contains(sentSessionKey)) {
      return;
    }

    // Capture current session context before async gap
    final sentContext = _expertContext;

    try {
      _sendingSessions.add(sentSessionKey);
      notifyListeners();

      // Add user message
      final userMessage = UIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: message,
        timestamp: DateTime.now(),
      );
      _messages = [..._messages, userMessage];

      // Optimistic: add placeholder session so Drawer shows it immediately.
      // Guard: only add if no placeholder exists yet.
      if (isNewSession && sentContext != null) {
        final alreadyHasPlaceholder = _sessions.any((s) => s.sessionId == -1);
        if (!alreadyHasPlaceholder) {
          final optimistic = ExpertChatSession(
            sessionId: -1,
            title: 'Expert ${sentContext.jobRole}',
            messageCount: 1,
            lastMessageAt: DateTime.now().toIso8601String(),
          );
          _sessions = [optimistic, ..._sessions];
        }
        _sessionContexts[-1] = sentContext;
      }

      // Cache a full snapshot of the current messages for this session so that
      // if the user switches away and back before the AI responds, we can
      // restore the conversation (including the pending user message).
      _pendingMessagesBySession[sentSessionKey] = List.of(_messages);
      notifyListeners();

      // Send to API
      final request = ExpertChatRequest(
        message: message,
        // IMPORTANT: null creates a new server session.
        // `-1` is a local-only placeholder and must never be sent upstream.
        sessionId: isNewSession ? null : _sessionId,
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
          sentSessionKey == -1 && (_sessionId == null || _sessionId == -1);
      final isSameExistingSession =
          sentSessionKey != -1 && _sessionId == sentSessionKey;
      if (!isSameNewSession && !isSameExistingSession) {
        debugPrint(
          '⚠️ Session changed while waiting for response '
          '(sent: $sentSessionKey, current: $_sessionId). Skipping UI update.',
        );
        _sendingSessions.remove(sentSessionKey);
        // Clean up stale placeholder if this was a new-session send
        if (sentSessionKey == -1) {
          _sessions = _sessions.where((s) => s.sessionId != -1).toList();
          _sessionContexts.remove(-1);
        }
        _pendingMessagesBySession.remove(sentSessionKey);
        notifyListeners();
        return;
      }

      // Update session ID if new
      if (_sessionId == null || _sessionId == -1) {
        _sendingSessions.remove(-1); // Transition from placeholder to real ID
        _sessionId = response.sessionId;
        // Restore expert context so the user can continue chatting immediately
        // without having to re-select an expert.
        _expertContext = response.expertContext ?? sentContext;
        // Replace placeholder with real session entry immediately
        final realSession = ExpertChatSession(
          sessionId: response.sessionId,
          title: 'Expert ${sentContext.jobRole}',
          messageCount: 2,
          lastMessageAt: response.timestamp,
          chatMode: ChatMode.expertMode,
        );
        _sessions = _sessions.where((s) => s.sessionId != -1).toList();
        _sessions = [realSession, ..._sessions];
        // Clean up -1 artefacts
        _sessionContexts.remove(-1);
        _pendingMessagesBySession.remove(-1);
        // Background sync to pick up server-side title and correct count
        loadSessions();
      }

      // Cache the verified context for this session so switching back to it
      // later restores the real expert, not a title-inferred guess.
      _sessionContexts[response.sessionId] =
          response.expertContext ?? sentContext;

      // Add assistant message (drop the optimistic "processing" placeholder first)
      final assistantMessage = UIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: response.aiResponse,
        timestamp:
            DateTimeHelper.tryParseIso8601(response.timestamp) ??
            DateTime.now(),
        expertContext: sentContext,
      );
      _messages = [
        ..._messages.where((m) => m.id != 'optimistic-processing'),
        assistantMessage,
      ];
      _sendingSessions.remove(sentSessionKey);
      _pendingMessagesBySession.remove(sentSessionKey);
      _pendingMessagesBySession.remove(response.sessionId);
      _sendingSessions.remove(response.sessionId); // Just in case it was added
      notifyListeners();
    } catch (e) {
      _sendingSessions.remove(sentSessionKey);
      _pendingMessagesBySession.remove(sentSessionKey);
      // Remove placeholder if the new-session send failed
      if (sentSessionKey == -1) {
        _sessions = _sessions.where((s) => s.sessionId != -1).toList();
      }
      notifyListeners();

      // Guard: don't pollute a different session with error messages
      final errSameNew =
          sentSessionKey == -1 && (_sessionId == null || _sessionId == -1);
      final errSameExisting =
          sentSessionKey != -1 && _sessionId == sentSessionKey;
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
      final all = await _service.getSessions(chatMode: ChatMode.expertMode);
      // Backend may not filter by chatMode yet — filter client-side as fallback.
      // Also hide any historical corrupted `sessionId == -1` rows created by
      // older mobile builds that accidentally sent the local placeholder ID.
      _sessions = all
          .where(
            (s) =>
                s.sessionId != -1 &&
                (s.chatMode == null || s.chatMode == ChatMode.expertMode),
          )
          .toList();
    }).catchError((e) {
      debugPrint('Error loading sessions: $e');
    });
    notifyListeners();
  }

  /// Load session history
  Future<void> loadSession(ExpertChatSession session) async {
    // Restore real context from cache if available (i.e. the session was
    // started or replied-to from this device). Otherwise fall back to null
    // so the UI enters read-only mode — title-based inference is removed
    // because it can silently produce the wrong expert.
    _expertContext = _sessionContexts[session.sessionId];

    // If this session is currently waiting for an AI response, skip the API
    // call (which wouldn't include the in-flight message yet) and restore
    // the cached snapshot instead.
    if (_sendingSessions.contains(session.sessionId)) {
      _sessionId = session.sessionId;
      _currentSessionTitle = session.title;
      final cached = _pendingMessagesBySession[session.sessionId];
      _messages = [
        if (cached != null) ...cached,
        // Add "processing" bubble so the thinking indicator renders
        UIMessage(
          id: 'optimistic-processing',
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
      // Fallback: if loadSession failed silently (e.g. getHistory network error),
      // _sessionId stays null. Set it directly so the UI enters read-only mode
      // and the user can access the drawer to pick a session manually.
      _sessionId ??= _sessions.first.sessionId;
    }
    _historyBootstrapDone = true;
    notifyListeners();
  }

  /// Delete session
  Future<void> deleteSession(int sessionId) async {
    try {
      await _service.deleteSession(sessionId);
      _sessions = _sessions.where((s) => s.sessionId != sessionId).toList();
      _sessionContexts.remove(sessionId);
      _pendingMessagesBySession.remove(sessionId);

      if (_sessionId == sessionId) {
        _sessionId = null;
        _messages = [];
        _expertContext = null;
        _currentSessionTitle = null;
        _historyBootstrapDone = false; // re-trigger bootstrap
        // Open the next most-recent session if one exists
        if (_sessions.isNotEmpty) {
          await loadSession(_sessions.first);
        }
        _historyBootstrapDone = true;
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
    _aiAgentMode = null; // prevent deep-research mode leaking into next session
    _historyBootstrapDone = false;
    _pendingMessagesBySession.clear();
    _sessionContexts.clear();
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

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() => resetSelection();
}
