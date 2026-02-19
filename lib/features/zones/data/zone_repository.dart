import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/zone.dart';

abstract class ZoneRepository {
  Future<List<Zone>> fetchZones();
  Future<Map<String, dynamic>> claimZone({
    required String sessionId,
    required String zoneId,
  });
}

class SupabaseZoneRepository implements ZoneRepository {
  SupabaseZoneRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Zone>> fetchZones() async {
    final rows = await _client.from('zones').select().order('name');
    return (rows as List<dynamic>)
        .map((item) => Zone.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> claimZone({
    required String sessionId,
    required String zoneId,
  }) async {
    final response = await _client.functions.invoke(
      'claim-zone',
      body: {'sessionId': sessionId, 'zoneId': zoneId},
    );
    return (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }
}

class LocalZoneRepository implements ZoneRepository {
  @override
  Future<List<Zone>> fetchZones() async {
    return const [
      Zone(
        id: 'z1',
        name: 'Downtown Grid',
        polygon: {'type': 'Polygon', 'coordinates': []},
        city: 'Demo City',
        scoreMultiplier: 1.1,
        currentGuardianUserId: 'neonrider',
      ),
      Zone(
        id: 'z2',
        name: 'Hill Climb',
        polygon: {'type': 'Polygon', 'coordinates': []},
        city: 'Demo City',
        scoreMultiplier: 1.5,
        currentGuardianUserId: null,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> claimZone({
    required String sessionId,
    required String zoneId,
  }) async {
    return {
      'claimStatus': 'claimed',
      'guardianUserId': 'guest-user',
      'auraAwarded': 55,
    };
  }
}
