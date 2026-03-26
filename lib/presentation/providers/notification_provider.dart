import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/notification_models.dart';
import '../../data/services/notification_service.dart';

enum NotificationFilter { all, unread, read }

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService();

  // ── State ────────────────────────────────────────────────────────────────

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  NotificationFilter _filter = NotificationFilter.all;
  Timer? _pollingTimer;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  NotificationFilter get filter => _filter;
  bool get hasMore => _currentPage + 1 < _totalPages;

  // ── Polling ──────────────────────────────────────────────────────────────

  /// Start polling unread count every 60 seconds.
  /// Call this once when the user is authenticated (e.g., from MainLayout.initState).
  void startPolling() {
    fetchUnreadCount(); // immediate first fetch
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => fetchUnreadCount(),
    );
  }

  /// Stop polling — call on logout or dispose.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  /// Refresh unread count silently (no loading state, no error shown).
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Silent fail — polling should not disrupt the UI
    }
  }

  /// Load first page of notifications, optionally switching filter.
  Future<void> loadNotifications({NotificationFilter? filter}) async {
    if (filter != null) _filter = filter;
    _currentPage = 0;
    _notifications = [];
    _hasError = false;
    _isLoading = true;
    notifyListeners();

    try {
      final page = await _service.getNotifications(
        page: 0,
        size: 10,
        isRead: _filterToIsRead(_filter),
      );
      _notifications = page.content;
      _totalPages = page.totalPages;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Không tải được thông báo';
      debugPrint('❌ loadNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load the next page and append to [notifications].
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final page = await _service.getNotifications(
        page: nextPage,
        size: 10,
        isRead: _filterToIsRead(_filter),
      );
      _notifications = [..._notifications, ...page.content];
      _currentPage = nextPage;
      _totalPages = page.totalPages;
    } catch (_) {
      // Silent fail for load-more
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ markAllAsRead error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool? _filterToIsRead(NotificationFilter f) {
    switch (f) {
      case NotificationFilter.unread:
        return false;
      case NotificationFilter.read:
        return true;
      case NotificationFilter.all:
        return null;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
