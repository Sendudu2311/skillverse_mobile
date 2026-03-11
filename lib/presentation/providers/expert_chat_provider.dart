import 'package:flutter/foundation.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/expert_chat_models.dart';
import '../../data/services/expert_chat_service.dart';

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
  String? _currentSessionTitle; // Title of current session

  // Sessions state
  List<ExpertChatSession> _sessions = [];

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
  bool get isSending => isLoadingFor('sending');

  List<ExpertChatSession> get sessions => _sessions;
  bool get loadingSessions => isLoadingFor('sessions');

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
    if (message.trim().isEmpty || _expertContext == null || isSending) return;

    try {
      setLoadingFor('sending', true);

      // Add user message
      final userMessage = UIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: message,
        timestamp: DateTime.now(),
      );
      _messages = [..._messages, userMessage];
      notifyListeners();

      // Send to API
      final request = ExpertChatRequest(
        message: message,
        sessionId: _sessionId,
        chatMode: ChatMode.expertMode,
        domain: _expertContext!.domain,
        industry: _expertContext!.industry,
        jobRole: _expertContext!.jobRole,
      );

      final response = await _service.sendMessage(request);

      // Update session ID if new
      if (_sessionId == null) {
        _sessionId = response.sessionId;
        // Rename session to expert role
        try {
          await _service.renameSession(
            response.sessionId,
            'Expert ${_expertContext!.jobRole}',
          );
        } catch (_) {}
      }

      // Add assistant message
      final assistantMessage = UIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: response.aiResponse,
        timestamp: DateTime.parse(response.timestamp),
        expertContext: _expertContext,
      );
      _messages = [..._messages, assistantMessage];

      setLoadingFor('sending', false);
    } catch (e) {
      setLoadingFor('sending', false);

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
    await performAsyncFor('session', () async {
      final history = await _service.getHistory(session.sessionId);

      _sessionId = session.sessionId;
      _currentSessionTitle = session.title; // Set session title
      _messages = [];

      for (int i = 0; i < history.length; i++) {
        final msg = history[i];
        _messages.add(
          UIMessage(
            id: '${session.sessionId}-$i-user',
            role: 'user',
            content: msg.userMessage,
            timestamp: DateTime.parse(msg.createdAt),
          ),
        );
        _messages.add(
          UIMessage(
            id: '${session.sessionId}-$i-assistant',
            role: 'assistant',
            content: msg.aiResponse,
            timestamp: DateTime.parse(msg.createdAt),
            expertContext: _expertContext,
          ),
        );
      }
    }).catchError((e) {
      debugPrint('Error loading session: $e');
    });
    notifyListeners();
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
    notifyListeners();
  }

  /// Set expert context directly (for loading existing sessions)
  void setExpertContext(ExpertContext context) {
    _expertContext = context;
    notifyListeners();
  }
}
