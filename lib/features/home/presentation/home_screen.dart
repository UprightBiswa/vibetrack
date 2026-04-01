import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/profile/application/profile_controller.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/shared/widgets/bento_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final tracking = ref.watch(trackingControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeTrack'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.leaderboard),
            icon: const Icon(Icons.emoji_events_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.zoneHeroGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: -10,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cyber-Bento Home',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primary,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Capture zones. Build streaks. Turn every ride into territory.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  profile?.username != null
                      ? 'Current rider: ${profile!.username}'
                      : 'Sign in and start tracking your first ride.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.tracking),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Session'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.zones),
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('Open Map'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StaggeredGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 2,
                child: BentoCard(
                  title: 'Aura Points',
                  value: '${profile?.auraPoints ?? 0}',
                  subtitle: profile?.username ?? 'Rider',
                  accent: AppTheme.primary,
                ),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 1,
                child: BentoCard(
                  title: 'Streak',
                  value: '${profile?.currentStreakDays ?? 0} days',
                  subtitle: (profile?.activeToday ?? false)
                      ? 'Active today'
                      : 'Ride today to keep it alive',
                  accent: AppTheme.secondary,
                ),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 1,
                child: BentoCard(
                  title: 'Global Rank',
                  value: profile?.globalRank != null ? '#${profile!.globalRank}' : '-',
                  subtitle: 'Aura leaderboard',
                  accent: const Color(0xFF52B6FF),
                ),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 1,
                child: BentoCard(
                  title: 'Today',
                  value: '${(tracking.distanceM / 1000).toStringAsFixed(2)} KM',
                  subtitle: '${tracking.durationS ~/ 60} min',
                  accent: const Color(0xFFFF7A59),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
