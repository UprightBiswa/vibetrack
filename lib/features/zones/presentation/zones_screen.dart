import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/zones/application/zone_controller.dart';
import 'package:vibetreck/shared/widgets/app_empty_state.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesProvider);
    final lastSession = ref.watch(trackingControllerProvider).lastSessionId;

    return Scaffold(
      appBar: AppBar(title: const Text('Zone Capture')),
      body: Column(
        children: [
          SizedBox(
            height: 240,
            child: zonesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(zonesProvider),
              ),
              data: (zones) {
                final centers = zones
                    .map((zone) => _extractZoneCenter(zone.polygon))
                    .whereType<LatLng>()
                    .toList();
                final center = centers.isNotEmpty
                    ? centers.first
                    : const LatLng(12.9716, 77.5946);
                return FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 12),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vibetrack.app',
                    ),
                    MarkerLayer(
                      markers: centers
                          .map(
                            (point) => Marker(
                              point: point,
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8B5CF6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: zonesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(zonesProvider),
              ),
              data: (zones) {
                if (zones.isEmpty) {
                  return const AppEmptyState(
                    title: 'No zones available',
                    message: 'Connect the backend and seed zones to see territory data here.',
                    icon: Icons.map_outlined,
                  );
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
                                try {
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
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error.toString().replaceFirst('Exception: ', ''),
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

LatLng? _extractZoneCenter(Map<String, dynamic> polygon) {
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
  return LatLng(sumLat / count, sumLng / count);
}
