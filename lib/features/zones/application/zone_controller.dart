import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/shared/models/zone.dart';

final zonesProvider = FutureProvider<List<Zone>>((ref) {
  return ref.read(zoneRepositoryProvider).fetchZones();
});

final zoneActionsProvider = Provider<ZoneActions>((ref) => ZoneActions(ref));

class ZoneActions {
  ZoneActions(this._ref);
  final Ref _ref;

  Future<Map<String, dynamic>> claim({
    required String zoneId,
    required String sessionId,
  }) async {
    final result = await _ref
        .read(zoneRepositoryProvider)
        .claimZone(sessionId: sessionId, zoneId: zoneId);
    _ref.invalidate(zonesProvider);
    return result;
  }
}
