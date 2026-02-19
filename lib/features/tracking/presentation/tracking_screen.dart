import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  PolylineAnnotation? _routeAnnotation;
  PointAnnotationManager? _pointManager;
  PointAnnotation? _currentPoint;
  int _lastRenderedPointCount = -1;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _mapboxMap!.setCamera(CameraOptions(zoom: 13, pitch: 45));
    _polylineManager = await _mapboxMap!.annotations
        .createPolylineAnnotationManager();
    _pointManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
  }

  Future<void> _syncRouteOnMap(TrackingState state) async {
    if (_mapboxMap == null ||
        _polylineManager == null ||
        _pointManager == null) {
      return;
    }
    if (state.points.length == _lastRenderedPointCount) {
      return;
    }
    _lastRenderedPointCount = state.points.length;
    if (state.points.isEmpty) {
      await _polylineManager!.deleteAll();
      await _pointManager!.deleteAll();
      _routeAnnotation = null;
      _currentPoint = null;
      return;
    }

    final coordinates = state.points
        .map((point) => Position(point.longitude, point.latitude))
        .toList();

    final line = LineString(coordinates: coordinates);
    if (_routeAnnotation == null) {
      _routeAnnotation = await _polylineManager!.create(
        PolylineAnnotationOptions(
          geometry: line,
          lineColor: const Color(0xFFCCFF00).toARGB32(),
          lineWidth: 4.0,
          lineOpacity: 0.95,
        ),
      );
    } else {
      _routeAnnotation!
        ..geometry = line
        ..lineColor = const Color(0xFFCCFF00).toARGB32()
        ..lineWidth = 4.0
        ..lineOpacity = 0.95;
      await _polylineManager!.update(_routeAnnotation!);
    }

    final latest = coordinates.last;
    if (_currentPoint == null) {
      _currentPoint = await _pointManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: latest),
          iconColor: const Color(0xFF8B5CF6).toARGB32(),
          iconSize: 1.2,
        ),
      );
    } else {
      _currentPoint!
        ..geometry = Point(coordinates: latest)
        ..iconColor = const Color(0xFF8B5CF6).toARGB32();
      await _pointManager!.update(_currentPoint!);
    }

    await _mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: latest), zoom: 15, bearing: 0),
      MapAnimationOptions(duration: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final state = ref.watch(trackingControllerProvider);
    final controller = ref.read(trackingControllerProvider.notifier);
    final hasToken = ref.watch(appEnvProvider).hasMapboxToken;
    if (hasToken) {
      _syncRouteOnMap(state);
    }

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
                        key: const ValueKey('tracking-map'),
                        cameraOptions: CameraOptions(zoom: 12),
                        onMapCreated: _onMapCreated,
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
