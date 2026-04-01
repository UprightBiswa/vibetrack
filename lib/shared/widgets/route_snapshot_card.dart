import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibetreck/core/theme/app_theme.dart';

class RouteSnapshotCard extends StatelessWidget {
  const RouteSnapshotCard({
    super.key,
    required this.routeGeojson,
    this.label,
    this.height = 220,
    this.showExpand = false,
  });

  final Map<String, dynamic> routeGeojson;
  final String? label;
  final double height;
  final bool showExpand;

  @override
  Widget build(BuildContext context) {
    final points = _routePoints(routeGeojson);
    final center = points.isNotEmpty ? points.last : const LatLng(12.9716, 77.5946);
    final fit = points.length >= 2
        ? CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(28),
            maxZoom: 15.5,
          )
        : null;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.45, 0, 0, 0, 0,
              0, 0.55, 0, 0, 0,
              0, 0, 0.52, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: points.length > 2 ? 14.5 : 11.5,
                initialCameraFit: fit,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vibetrack.app',
                ),
                if (points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                if (points.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: points.first,
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                      Marker(
                        point: points.last,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (label != null)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                ),
              ),
            ),
          if (showExpand)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.fullscreen_rounded, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}

List<LatLng> _routePoints(Map<String, dynamic> routeGeojson) {
  final coordinates = routeGeojson['coordinates'];
  if (coordinates is! List) return const [];
  return coordinates
      .whereType<List>()
      .where((point) => point.length >= 2)
      .map(
        (point) => LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        ),
      )
      .toList(growable: false);
}
