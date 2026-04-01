import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/core/notifications/notification_navigation.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationActionsProvider).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No notifications yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(item.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded),
                  ),
                  title: Text(item.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item.body),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM d, HH:mm').format(item.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: item.isRead
                      ? null
                      : const Icon(Icons.circle, size: 10, color: Colors.redAccent),
                  onTap: () async {
                    if (!item.isRead) {
                      await ref.read(notificationActionsProvider).markRead(item.id);
                    }
                    if (!context.mounted) return;
                    openNotificationTarget(
                      context,
                      route: item.route,
                      entityId: item.entityId,
                      payload: item.payloadJson,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
