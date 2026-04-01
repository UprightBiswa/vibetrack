import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/shared/models/activity_session.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TrackingCubit>().state;
    final controller = context.read<TrackingCubit>();

    Future<void> onMainTap() async {
      if (!state.running) {
        try {
          await controller.start(type: state.selectedType);
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
            ),
          );
          if (error.toString().contains('denied forever')) {
            await Geolocator.openAppSettings();
          }
        }
        return;
      }
      if (state.paused) {
        controller.resume();
        return;
      }
      controller.pause();
    }

    Future<void> onFinishTap() async {
      try {
        final sessionId = await controller.finish();
        if (context.mounted) {
          context.push(AppRoutes.summary(sessionId));
        }
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }

    final points = state.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final hasPoints = points.isNotEmpty;
    final center = hasPoints ? points.last : const LatLng(12.9716, 77.5946);
    final currentSpeedKmh = state.currentSpeedMps * 3.6;
    final distanceKm = state.distanceM / 1000;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.42, 0, 0, 0, 0,
                0, 0.55, 0, 0, 0,
                0, 0, 0.5, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: hasPoints ? 15 : 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vibetrack.app',
                  ),
                  if (hasPoints)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 4,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  if (hasPoints)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: points.last,
                          width: 18,
                          height: 18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.76),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sensors_rounded, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            state.running ? 'GPS SIGNAL STRONG' : 'READY TO TRACK',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.primary,
                                  letterSpacing: 1.6,
                                ),
                          ),
                          const Spacer(),
                          _MiniGhostButton(
                            icon: Icons.share_outlined,
                            onTap: state.running ? null : null,
                          ),
                          const SizedBox(width: 10),
                          _MiniGhostButton(
                            icon: Icons.tune_rounded,
                            onTap: () => context.push(AppRoutes.settings),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Speed',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppTheme.primary,
                                        letterSpacing: 2,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: currentSpeedKmh.toStringAsFixed(1),
                                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              height: 0.95,
                                            ),
                                      ),
                                      TextSpan(
                                        text: ' km/h',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Colors.white54,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Distance',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppTheme.primary,
                                      letterSpacing: 2,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: distanceKm.toStringAsFixed(2),
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                    ),
                                    TextSpan(
                                      text: ' km',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: Colors.white54,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (!state.running)
                        Row(
                          children: ActivityType.values
                              .where((type) => type != ActivityType.gym)
                              .map(
                                (type) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: type == ActivityType.walk ? 0 : 10,
                                    ),
                                    child: _ActivityTypeButton(
                                      type: type,
                                      selected: state.selectedType == type,
                                      onTap: () => controller.selectActivityType(type),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        )
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.24)),
                            ),
                            child: Text(
                              _labelForType(state.selectedType).toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TrackerMetric(
                                icon: Icons.timer_outlined,
                                label: 'Duration',
                                value: _formatDuration(state.durationS),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TrackerMetric(
                                icon: Icons.terrain_rounded,
                                label: 'Elevation',
                                value: '${state.elevationGainM.toStringAsFixed(0)} m',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pin_drop_rounded, color: AppTheme.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Territory Capture',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: Colors.white60,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'LVL ${(distanceKm * 2).clamp(1, 9).toStringAsFixed(0)} GRID',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: AppTheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 6,
                                  value: (distanceKm / 20).clamp(0, 1),
                                  color: AppTheme.primary,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SessionAction(
                        label: 'End',
                        icon: Icons.stop_circle_outlined,
                        emphasized: false,
                        onTap: state.running ? onFinishTap : null,
                      ),
                      const SizedBox(width: 22),
                      _PrimarySessionAction(
                        paused: state.paused,
                        running: state.running,
                        onTap: onMainTap,
                      ),
                      const SizedBox(width: 22),
                      _SessionAction(
                        label: 'Flex',
                        icon: Icons.photo_camera_outlined,
                        emphasized: false,
                        onTap: state.running ? onFinishTap : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGhostButton extends StatelessWidget {
  const _MiniGhostButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}

class _ActivityTypeButton extends StatelessWidget {
  const _ActivityTypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ActivityType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForType(type), color: selected ? AppTheme.primary : Colors.white54),
            const SizedBox(height: 4),
            Text(
              _labelForType(type).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? AppTheme.primary : Colors.white60,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerMetric extends StatelessWidget {
  const _TrackerMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white60,
                      letterSpacing: 1.1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _SessionAction extends StatelessWidget {
  const _SessionAction({
    required this.label,
    required this.icon,
    required this.emphasized,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
        ),
      ],
    );
  }
}

class _PrimarySessionAction extends StatelessWidget {
  const _PrimarySessionAction({
    required this.paused,
    required this.running,
    required this.onTap,
  });

  final bool paused;
  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = !running
        ? Icons.play_arrow_rounded
        : paused
        ? Icons.play_arrow_rounded
        : Icons.pause_rounded;
    final label = !running
        ? 'Start'
        : paused
        ? 'Resume'
        : 'Pause';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 48),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                letterSpacing: 1.4,
              ),
        ),
      ],
    );
  }
}

String _formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
      : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

IconData _iconForType(ActivityType type) {
  switch (type) {
    case ActivityType.cycle:
      return Icons.directions_bike_rounded;
    case ActivityType.run:
      return Icons.directions_run_rounded;
    case ActivityType.walk:
      return Icons.directions_walk_rounded;
    case ActivityType.gym:
      return Icons.fitness_center_rounded;
  }
}

String _labelForType(ActivityType type) {
  switch (type) {
    case ActivityType.cycle:
      return 'Cycling';
    case ActivityType.run:
      return 'Running';
    case ActivityType.walk:
      return 'Walking';
    case ActivityType.gym:
      return 'Gym';
  }
}
