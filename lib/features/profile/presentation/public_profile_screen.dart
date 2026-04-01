import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/di/app_services.dart';
import 'package:vibetreck/features/profile/application/profile_controller.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PublicProfileCubit(
        context.read<AppServices>().profileRepository,
      )..load(profileId),
      child: BlocBuilder<PublicProfileCubit, PublicProfileState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Rider Profile')),
            body: switch (state.status) {
              ViewStatus.loading => const Center(child: CircularProgressIndicator()),
              ViewStatus.failure => AppErrorState(
                  message: state.errorMessage ?? 'Failed to load profile',
                  onRetry: () => context.read<PublicProfileCubit>().load(profileId),
                ),
              _ => _buildContent(context, state),
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PublicProfileState state) {
    final profile = state.profile;
    if (profile == null) {
      return const Center(child: Text('Profile not found'));
    }
    final initial = profile.username.trim().isEmpty
        ? 'R'
        : profile.username.characters.first.toUpperCase();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(radius: 36, child: Text(initial)),
        const SizedBox(height: 12),
        Text(
          profile.username,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          profile.homeCity.isEmpty ? 'Unknown City' : profile.homeCity,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            title: const Text('Aura Points'),
            trailing: Text('${profile.auraPoints}'),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Current City'),
            trailing: Text(
              profile.homeCity.isEmpty ? '-' : profile.homeCity,
            ),
          ),
        ),
      ],
    );
  }
}
