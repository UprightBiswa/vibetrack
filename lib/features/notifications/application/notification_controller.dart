import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/shared/models/app_notification_item.dart';

final notificationsProvider = FutureProvider<List<AppNotificationItem>>(
  retry: (count, error) => null,
  (ref) async {
    return ref.read(notificationRepositoryProvider).fetchNotifications();
  },
);

final unreadNotificationCountProvider = FutureProvider<int>(
  retry: (count, error) => null,
  (ref) async {
    return ref.read(notificationRepositoryProvider).fetchUnreadCount();
  },
);

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  NotificationActions(this._ref);

  final Ref _ref;

  Future<void> markRead(String notificationId) async {
    await _ref.read(notificationRepositoryProvider).markRead(notificationId);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllRead() async {
    await _ref.read(notificationRepositoryProvider).markAllRead();
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  void refresh() {
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }
}
