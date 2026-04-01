import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/notifications/notification_navigation.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/notifications/application/notification_controller.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationsCubit>().markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: switch (state.status) {
        ViewStatus.loading => const Center(child: CircularProgressIndicator()),
        ViewStatus.failure => AppErrorState(
            message: state.errorMessage ?? 'Failed to load notifications',
            onRetry: () => context.read<NotificationsCubit>().load(),
          ),
        _ => state.items.isEmpty
            ? const Center(child: Text('No notifications yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      if (!item.isRead) {
                        await context.read<NotificationsCubit>().markRead(item.id);
                      }
                      if (!context.mounted) return;
                      openNotificationTarget(
                        context,
                        route: item.route,
                        entityId: item.entityId,
                        payload: item.payloadJson,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.surface,
                            item.isRead
                                ? AppTheme.surface
                                : AppTheme.primary.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: item.isRead
                              ? AppTheme.border.withValues(alpha: 0.7)
                              : AppTheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? Colors.white10
                                  : AppTheme.primary.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.isRead
                                  ? Icons.notifications_none_rounded
                                  : Icons.notifications_active_rounded,
                              color: item.isRead ? Colors.white70 : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(item.title, style: Theme.of(context).textTheme.titleMedium)),
                                    if (!item.isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.body,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMM d, HH:mm').format(item.createdAt.toLocal()),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      },
    );
  }
}
