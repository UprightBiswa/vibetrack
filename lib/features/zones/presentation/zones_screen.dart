import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/zones/application/zone_controller.dart';
import 'package:vibetreck/shared/widgets/app_empty_state.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<ZonesCubit>();
    if (cubit.state.status == ViewStatus.initial) {
      cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ZonesCubit>().state;
    final lastSession = context.watch<TrackingCubit>().state.lastSessionId;

    return Scaffold(
      appBar: AppBar(title: const Text('Zone Capture')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 300,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.zoneHeroGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
            ),
            child: _buildMap(state),
          ),
          const SizedBox(height: 16),
          _buildZonesList(context, state, lastSession),
        ],
      ),
    );
  }

  Widget _buildMap(ZonesState state) {
    switch (state.status) {
      case ViewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewStatus.failure:
        return AppErrorState(
          message: state.errorMessage ?? 'Failed to load zones',
          onRetry: () => context.read<ZonesCubit>().load(),
        );
      default:
        final centers = state.zones
            .map((zone) => _extractZoneCenter(zone.polygon))
            .whereType<LatLng>()
            .toList();
        final center = centers.isNotEmpty
            ? centers.first
            : const LatLng(12.9716, 77.5946);
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 12),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vibetrack.app',
                  ),
                  MarkerLayer(
                    markers: centers
                        .map(
                          (point) => Marker(
                            point: point,
                            width: 22,
                            height: 22,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.55),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Territory Live Map'),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildZonesList(BuildContext context, ZonesState state, String? lastSession) {
    switch (state.status) {
      case ViewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewStatus.failure:
        return AppErrorState(
          message: state.errorMessage ?? 'Failed to load zones',
          onRetry: () => context.read<ZonesCubit>().load(),
        );
      default:
        if (state.zones.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: AppEmptyState(
              title: 'No zones available',
              message: 'Connect the backend and seed zones to see territory data here.',
              icon: Icons.map_outlined,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Territory Districts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Claim recent ride sessions and push your aura higher.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 12),
            ...state.zones.map((zone) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(zone.name),
                  subtitle: Text('${zone.city} • x${zone.scoreMultiplier} aura'),
                  trailing: FilledButton(
                    onPressed: lastSession == null
                        ? null
                        : () async {
                            try {
                              final result = await context.read<ZonesCubit>().claim(
                                    zoneId: zone.id,
                                    sessionId: lastSession,
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Claim: ${result['claimStatus']}'),
                                ),
                              );
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
                ),
              );
            }),
          ],
        );
    }
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
