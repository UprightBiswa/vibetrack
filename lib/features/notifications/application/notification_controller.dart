import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/features/notifications/data/notification_repository.dart';
import 'package:vibetreck/shared/models/app_notification_item.dart';

class NotificationsState {
  const NotificationsState({
    this.status = ViewStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  final ViewStatus status;
  final List<AppNotificationItem> items;
  final int unreadCount;
  final String? errorMessage;

  NotificationsState copyWith({
    ViewStatus? status,
    List<AppNotificationItem>? items,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearError: true));
    try {
      final results = await Future.wait([
        _repository.fetchNotifications(),
        _repository.fetchUnreadCount(),
      ]);
      emit(
        state.copyWith(
          status: ViewStatus.success,
          items: results[0] as List<AppNotificationItem>,
          unreadCount: results[1] as int,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> markRead(String notificationId) async {
    await _repository.markRead(notificationId);
    await load();
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    await load();
  }
}
