import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/di/app_services.dart';
import 'package:vibetreck/features/profile/application/profile_controller.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LeaderboardCubit(
        context.read<AppServices>().profileRepository,
      )..load(),
      child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Leaderboard')),
            body: switch (state.status) {
              ViewStatus.loading => const Center(child: CircularProgressIndicator()),
              ViewStatus.failure => AppErrorState(
                  message: state.errorMessage ?? 'Failed to load leaderboard',
                  onRetry: () => context.read<LeaderboardCubit>().load(),
                ),
              _ => state.entries.isEmpty
                  ? const Center(child: Text('No riders ranked yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = state.entries[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('#${entry.globalRank}')),
                            title: Text(entry.username),
                            subtitle: const Text('Aura leaderboard'),
                            trailing: Text('${entry.auraPoints}'),
                          ),
                        );
                      },
                    ),
            },
          );
        },
      ),
    );
  }
}
