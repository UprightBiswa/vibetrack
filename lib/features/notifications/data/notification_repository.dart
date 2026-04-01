import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/shared/models/app_notification_item.dart';

abstract class NotificationRepository {
  Future<List<AppNotificationItem>> fetchNotifications({int limit = 50});
  Future<int> fetchUnreadCount();
  Future<AppNotificationItem> markRead(String notificationId);
  Future<void> markAllRead();
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<AppNotificationItem>> fetchNotifications({int limit = 50}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/notifications',
      queryParameters: {'limit': limit},
    );
    return (response.data ?? <dynamic>[])
        .map((item) => AppNotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/notifications/unread-count');
    return (response.data?['unread_count'] ?? 0) as int;
  }

  @override
  Future<AppNotificationItem> markRead(String notificationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/notifications/$notificationId/read',
    );
    return AppNotificationItem.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<void> markAllRead() async {
    await _dio.post<Map<String, dynamic>>('/api/v1/notifications/read-all');
  }
}

class LocalNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotificationItem>> fetchNotifications({int limit = 50}) async => const [];

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<AppNotificationItem> markRead(String notificationId) async {
    throw StateError('Notifications are unavailable without backend API');
  }

  @override
  Future<void> markAllRead() async {}
}
