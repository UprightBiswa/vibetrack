import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/zones/application/zone_controller.dart';
import 'package:vibetreck/shared/models/zone.dart';

class ZonesScreen extends ConsumerStatefulWidget {
  const ZonesScreen({super.key});

  @override
  ConsumerState<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends ConsumerState<ZonesScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointManager;
  int _lastZoneCount = -1;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    await _mapboxMap!.setCamera(CameraOptions(zoom: 11));
  }

  Future<void> _syncZonesOnMap(List<Zone> zones) async {
    if (_mapboxMap == null || _pointManager == null) return;
    if (_lastZoneCount == zones.length) return;
    _lastZoneCount = zones.length;

    await _pointManager!.deleteAll();

    final centers = zones
        .map((zone) => _extractZoneCenter(zone.polygon))
        .whereType<Position>()
        .toList();

    if (centers.isEmpty) return;

    final options = centers
        .map(
          (center) => PointAnnotationOptions(
            geometry: Point(coordinates: center),
            iconColor: const Color(0xFF8B5CF6).toARGB32(),
            iconSize: 1.1,
            textColor: Colors.white.toARGB32(),
          ),
        )
        .toList();
    await _pointManager!.createMulti(options);
    await _mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: centers.first), zoom: 12.5),
      MapAnimationOptions(duration: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesProvider);
    final lastSession = ref.watch(trackingControllerProvider).lastSessionId;
    final hasToken = ref.watch(appEnvProvider).hasMapboxToken;

    return Scaffold(
      appBar: AppBar(title: const Text('Zone Capture')),
      body: Column(
        children: [
          SizedBox(
            height: 210,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasToken
                  ? MapWidget(
                      key: const ValueKey('zones-map'),
                      cameraOptions: CameraOptions(zoom: 11),
                      onMapCreated: _onMapCreated,
                    )
                  : Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Map preview available when MAPBOX_PUBLIC_TOKEN is set',
                      ),
                    ),
            ),
          ),
          Expanded(
            child: zonesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (zones) {
                if (hasToken) {
                  _syncZonesOnMap(zones);
                }
                return ListView.builder(
                  itemCount: zones.length,
                  itemBuilder: (context, index) {
                    final zone = zones[index];
                    return ListTile(
                      title: Text(zone.name),
                      subtitle: Text(
                        '${zone.city} - x${zone.scoreMultiplier} aura',
                      ),
                      trailing: FilledButton(
                        onPressed: lastSession == null
                            ? null
                            : () async {
                                final result = await ref
                                    .read(zoneActionsProvider)
                                    .claim(
                                      zoneId: zone.id,
                                      sessionId: lastSession,
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Claim: ${result['claimStatus']}',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Claim'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Position? _extractZoneCenter(Map<String, dynamic> polygon) {
  final coordinates = polygon['coordinates'];
  if (coordinates is! List || coordinates.isEmpty) return null;
  final outerRing = coordinates.first;
  if (outerRing is! List || outerRing.isEmpty) return null;

  var sumLng = 0.0;
  var sumLat = 0.0;
  var count = 0;

  for (final vertex in outerRing) {
    if (vertex is! List || vertex.length < 2) continue;
    final lng = (vertex[0] as num?)?.toDouble();
    final lat = (vertex[1] as num?)?.toDouble();
    if (lng == null || lat == null) continue;
    sumLng += lng;
    sumLat += lat;
    count++;
  }
  if (count == 0) return null;
  return Position(sumLng / count, sumLat / count);
}
