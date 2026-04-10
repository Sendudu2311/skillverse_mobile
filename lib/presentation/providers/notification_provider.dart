import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/notification_models.dart';
import '../../data/services/notification_service.dart';
import '../../core/utils/pagination_helper.dart';

enum NotificationFilter { all, unread, read }

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  late final PaginationHelper<AppNotification> _pagination;
  NotificationFilter _filter = NotificationFilter.all;
  Timer? _pollingTimer;

  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService() {
    _pagination = PaginationHelper<AppNotification>(
      fetchPage: (page) async {
        // PaginationHelper uses 1-based pages; API uses 0-based
        final result = await _service.getNotifications(
          page: page - 1,
          size: 10,
          isRead: _filterToIsRead(_filter),
        );
        return PaginatedResponse(
          data: result.content,
          currentPage: page - 1,
          totalPages: result.totalPages,
          totalItems: result.totalElements.toInt(),
          hasMore: !result.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
  }

  // ── State delegation from PaginationHelper ────────────────────────────────

  List<AppNotification> get notifications => _pagination.items;
  bool get isLoading => _pagination.isInitialLoading;
  bool get isLoadingMore => _pagination.isLoadingMore;
  bool get hasError => _pagination.hasError;
  String? get errorMessage => _pagination.error;
  NotificationFilter get filter => _filter;
  bool get hasMore => _pagination.hasMore;

  // ── Polling ──────────────────────────────────────────────────────────────

  /// Start polling unread count every 60 seconds.
  /// Call this once when the user is authenticated (e.g., from MainLayout.initState).
  void startPolling() {
    fetchUnreadCount();
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

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

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

  // ── Data ─────────────────────────────────────────────────────────────────

  /// Load first page of notifications, optionally switching filter.
  Future<void> loadNotifications({NotificationFilter? filter}) async {
    if (filter != null) {
      _filter = filter;
      // Reset pagination so next fetchPage uses new filter
      _pagination.reset();
    }
    await _pagination.loadFirstPage();
  }

  /// Load the next page and append to [notifications].
  Future<void> loadNextPage() async {
    await _pagination.loadNextPage();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _service.markAsRead(id);
      final idx = _pagination.findIndex((n) => n.id == id);
      if (idx != -1 && !notifications[idx].isRead) {
        _pagination.updateItem(
          idx,
          notifications[idx].copyWith(isRead: true),
        );
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
      // Update all items in place
      for (var i = 0; i < _pagination.items.length; i++) {
        final n = _pagination.items[i];
        if (!n.isRead) {
          _pagination.updateItem(i, n.copyWith(isRead: true));
        }
      }
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
    _pagination.dispose();
    super.dispose();
  }
}
