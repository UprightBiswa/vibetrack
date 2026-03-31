import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/features/profile/application/profile_controller.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(leaderboardProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No riders ranked yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('#${entry.globalRank}')),
                  title: Text(entry.username),
                  subtitle: const Text('Aura leaderboard'),
                  trailing: Text('${entry.auraPoints}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
