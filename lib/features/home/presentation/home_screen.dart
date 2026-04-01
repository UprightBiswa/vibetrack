import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_cubit.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/shared/widgets/bento_card.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CurrentProfileCubit>().state.profile;
    final tracking = context.watch<TrackingCubit>().state;
    final rankLabel = profile?.globalRank != null ? '#${profile!.globalRank}' : '--';

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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
                      ),
                      child: const Text('ZONE MODE'),
                    ),
                    const Spacer(),
                    Text(
                      rankLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroStat(label: 'Aura', value: '${profile?.auraPoints ?? 0}'),
                    _HeroStat(label: 'Streak', value: '${profile?.currentStreakDays ?? 0}d'),
                    _HeroStat(label: 'Today', value: '${(tracking.distanceM / 1000).toStringAsFixed(2)} km'),
                  ],
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
                  value: rankLabel,
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
                  subtitle: '${tracking.durationS ~/ 60} min logged',
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white60,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
