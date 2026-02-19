import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
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
        actions: const [
          Padding(padding: EdgeInsets.all(16), child: Icon(Icons.bolt_rounded)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StaggeredGrid.count(
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
                title: 'Zone Status',
                value: 'Guardian',
                subtitle: profile?.homeCity ?? 'City',
                accent: AppTheme.secondary,
              ),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 1,
              child: BentoCard(
                title: 'Today',
                value: '${(tracking.distanceM / 1000).toStringAsFixed(2)} KM',
                subtitle: '${tracking.durationS ~/ 60} min',
              ),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 4,
              mainAxisCellCount: 1.15,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/tracking'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
