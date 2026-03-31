import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/features/profile/application/profile_controller.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).asData?.value;
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          final rawName = (profile?.username ?? '').trim();
          final avatarInitial = rawName.isEmpty
              ? 'R'
              : rawName.characters.first.toUpperCase();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(radius: 34, child: Text(avatarInitial)),
              const SizedBox(height: 12),
              Text(
                profile?.username ?? 'Rider',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                user?.email ?? profile?.email ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  title: const Text('Aura Points'),
                  trailing: Text('${profile?.auraPoints ?? 0}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Home City'),
                  trailing: Text(profile?.homeCity ?? '-'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Global Aura Rank'),
                  trailing: Text(
                    profile?.globalRank != null ? '#${profile!.globalRank}' : '-',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authActionsProvider).signOut();
                  if (context.mounted) context.go(AppRoutes.auth);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
