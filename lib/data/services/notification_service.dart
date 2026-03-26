import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/notification_models.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// GET /api/notifications
  /// [isRead] null = all, false = unread, true = read
  Future<NotificationPage> getNotifications({
    int page = 0,
    int size = 10,
    bool? isRead,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'size': size,
          'sort': 'createdAt,desc',
          if (isRead != null) 'isRead': isRead,
        },
      );
      return NotificationPage.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ getNotifications error: $e');
      rethrow;
    }
  }

  /// GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      return (response.data as num).toInt();
    } catch (e) {
      debugPrint('❌ getUnreadCount error: $e');
      rethrow;
    }
  }

  /// POST /api/notifications/{id}/read
  Future<void> markAsRead(int id) async {
    try {
      await _apiClient.dio.post('/notifications/$id/read');
    } catch (e) {
      debugPrint('❌ markAsRead($id) error: $e');
      rethrow;
    }
  }

  /// POST /api/notifications/read-all
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.post('/notifications/read-all');
    } catch (e) {
      debugPrint('❌ markAllAsRead error: $e');
      rethrow;
    }
  }
}
