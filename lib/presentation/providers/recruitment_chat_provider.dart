import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/recruitment_chat_models.dart';
import '../../data/services/recruitment_chat_service.dart';

/// Provider for Recruitment Chat state management.
/// Manages session list, active chat messages, and polling for new messages.
class RecruitmentChatProvider extends ChangeNotifier {
  final RecruitmentChatService _service = RecruitmentChatService();

  // ── State ────────────────────────────────────────────────────────────
  List<RecruitmentSessionResponse> _sessions = [];
  List<RecruitmentMessageResponse> _messages = [];
  RecruitmentSessionResponse? _activeSession;
  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _error;
  int _unreadCount = 0;

  // Current user
  int? _currentUserId;

  // Polling timer for simulated real-time
  Timer? _pollTimer;

  // ── Getters ──────────────────────────────────────────────────────────
  List<RecruitmentSessionResponse> get sessions => _sessions;
  List<RecruitmentMessageResponse> get messages => _messages;
  RecruitmentSessionResponse? get activeSession => _activeSession;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  // ── Configuration ────────────────────────────────────────────────────
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  // ── Session list ─────────────────────────────────────────────────────
  Future<void> loadMySessions() async {
    _isLoadingSessions = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _service.getCandidateSessions();
      _unreadCount = await _service.getUnreadCount();
    } catch (e) {
      _error = 'Không thể tải danh sách chat tuyển dụng';
      debugPrint('Error loading recruitment sessions: $e');
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  // ── Enter a chat session ─────────────────────────────────────────────
  Future<void> enterSession(int sessionId) async {
    _isLoadingMessages = true;
    _messages = [];
    _error = null;
    notifyListeners();

    try {
      _activeSession = await _service.getSessionById(sessionId);

      final rawMessages = await _service.getSessionMessages(sessionId);
      // API returns descending order; reverse for UI (oldest-first)
      _messages = rawMessages.reversed.toList();

      // Mark messages as read
      _service.markMessagesAsRead(sessionId);

      // Start polling for new messages
      _startPolling(sessionId);
    } catch (e) {
      _error = 'Không thể tải tin nhắn';
      debugPrint('Error entering session: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // ── Leave session ────────────────────────────────────────────────────
  void leaveSession() {
    _stopPolling();
    _activeSession = null;
    _messages = [];
    notifyListeners();
  }

  // ── Send a message ───────────────────────────────────────────────────
  Future<void> sendMessage(String content, {String type = 'TEXT'}) async {
    if (_activeSession == null || content.trim().isEmpty) return;

    _isSending = true;
    notifyListeners();

    // Optimistic UI
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = RecruitmentMessageResponse(
      id: tempId,
      sessionId: _activeSession!.id,
      senderId: _currentUserId ?? 0,
      senderName: 'Bạn',
      senderRole: 'CANDIDATE',
      content: content,
      messageType: type,
      createdAt: DateTime.now().toIso8601String(),
    );
    _messages.add(optimistic);
    notifyListeners();

    try {
      final saved = await _service.sendMessage(
        sessionId: _activeSession!.id,
        content: content,
        messageType: type,
      );

      // Replace optimistic with server response
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx >= 0) {
        _messages[idx] = saved;
      }
    } catch (e) {
      _messages.removeWhere((m) => m.id == tempId);
      _error = 'Gửi tin nhắn thất bại';
      debugPrint('Error sending message: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ── Polling ──────────────────────────────────────────────────────────
  void _startPolling(int sessionId) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      try {
        final rawMessages = await _service.getSessionMessages(sessionId);
        final newMessages = rawMessages.reversed.toList();

        if (newMessages.length != _messages.length) {
          _messages = newMessages;
          notifyListeners();
          _service.markMessagesAsRead(sessionId);
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Refresh active session info ──────────────────────────────────────
  Future<void> refreshActiveSession() async {
    if (_activeSession == null) return;
    try {
      _activeSession = await _service.getSessionById(_activeSession!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing session: $e');
    }
  }

  // ── Cleanup ──────────────────────────────────────────────────────────
  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
