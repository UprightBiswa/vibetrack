import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/logging/app_logger.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.palette_rounded),
            title: Text('Theme'),
            subtitle: Text('Cyber-Bento Dark'),
          ),
          const ListTile(
            leading: Icon(Icons.notifications_active_rounded),
            title: Text('Notifications'),
            subtitle: Text('Deferred in MVP'),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode_rounded),
            title: const Text('Backend API'),
            subtitle: Text(
              env.hasBackendApi ? env.effectiveBackendApiUrl : 'Not configured',
            ),
          ),
          if (env.backendSetupHint != null)
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Backend setup hint'),
              subtitle: Text(env.backendSetupHint!),
            ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_rounded),
            title: Text('Privacy'),
            subtitle: Text('RLS + least privilege'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Debug Logs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: AppLogger.clear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<AppLogEntry>>(
            valueListenable: AppLogger.entries,
            builder: (context, logs, _) {
              if (logs.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.bug_report_outlined),
                  title: Text('No logs yet'),
                  subtitle: Text('App, auth, and API logs will appear here.'),
                );
              }

              return Column(
                children: logs.map((log) {
                  final message = StringBuffer()
                    ..writeln(log.message)
                    ..write(DateFormat('HH:mm:ss').format(log.timestamp));
                  if (log.error != null) {
                    message
                      ..writeln()
                      ..write(log.error);
                  }
                  return Card(
                    child: ListTile(
                      leading: _LogBadge(level: log.level),
                      title: Text(
                        log.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${DateFormat('HH:mm:ss').format(log.timestamp)}${log.error != null ? ' • ${log.error}' : ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_all_outlined),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: message.toString()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Log copied')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LogBadge extends StatelessWidget {
  const _LogBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'ERROR' => Colors.redAccent,
      'WARN' => Colors.orangeAccent,
      _ => Colors.lightBlueAccent,
    };

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        level.substring(0, 1),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
