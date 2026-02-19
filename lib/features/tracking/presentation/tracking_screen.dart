import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingControllerProvider);
    final controller = ref.read(trackingControllerProvider.notifier);
    final hasToken = ref.watch(appEnvProvider).hasMapboxToken;

    Future<void> onMainTap() async {
      if (!state.running) {
        await controller.start();
        return;
      }
      if (state.paused) {
        controller.resume();
        return;
      }
      controller.pause();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Active Session')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: hasToken
                    ? MapWidget(
                        key: ValueKey('tracking-map'),
                        cameraOptions: CameraOptions(zoom: 12),
                      )
                    : Container(
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: const Text(
                          'Add MAPBOX_PUBLIC_TOKEN to enable live map',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Distance',
                    value: '${(state.distanceM / 1000).toStringAsFixed(2)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: 'Duration',
                    value: '${state.durationS}s',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: 'Speed',
                    value: '${state.avgSpeedMps.toStringAsFixed(2)} m/s',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onMainTap,
                    child: Text(
                      !state.running
                          ? 'Start'
                          : state.paused
                          ? 'Resume'
                          : 'Pause',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.running
                        ? () async {
                            final sessionId = await controller.finish();
                            if (context.mounted) {
                              context.go('/summary/$sessionId');
                            }
                          }
                        : null,
                    child: const Text('Finish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
