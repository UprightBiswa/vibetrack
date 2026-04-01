import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TrackingCubit>().state;
    final controller = context.read<TrackingCubit>();

    Future<void> onMainTap() async {
      if (!state.running) {
        try {
          await controller.start();
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
        .toList();
    final hasPoints = points.isNotEmpty;
    final center = hasPoints ? points.last : const LatLng(12.9716, 77.5946);

    return Scaffold(
      appBar: AppBar(title: const Text('Active Session')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: hasPoints ? 15 : 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vibetrack.app',
                    ),
                    if (hasPoints)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 4,
                            color: const Color(0xFFCCFF00),
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
                              decoration: const BoxDecoration(
                                color: Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
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
                    onPressed: state.running ? onFinishTap : null,
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
