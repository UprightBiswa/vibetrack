import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/zones/application/zone_controller.dart';

class ZonesScreen extends ConsumerWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      key: ValueKey('zones-map'),
                      cameraOptions: CameraOptions(zoom: 11),
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
              data: (zones) => ListView.builder(
                itemCount: zones.length,
                itemBuilder: (context, index) {
                  final zone = zones[index];
                  return ListTile(
                    title: Text(zone.name),
                    subtitle: Text(
                      '${zone.city} • x${zone.scoreMultiplier} aura',
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
