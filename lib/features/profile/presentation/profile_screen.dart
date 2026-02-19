import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/features/profile/application/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).asData?.value;
    final profile = ref.watch(currentProfileProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 34,
            child: Text(
              (profile?.username ?? 'R').substring(0, 1).toUpperCase(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile?.username ?? 'Rider',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            user?.email ?? '',
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
          const Card(
            child: ListTile(
              title: Text('Weekly Leaderboard'),
              trailing: Text('#12'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(authActionsProvider).signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
