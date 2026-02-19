import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/shared/models/activity_session.dart';
import 'package:vibetreck/shared/utils/aura_calculator.dart';

class TrackingState {
  const TrackingState({
    required this.running,
    required this.paused,
    required this.points,
    required this.distanceM,
    required this.durationS,
    required this.avgSpeedMps,
    this.startedAt,
    this.lastSessionId,
    this.lastAuraAwarded = 0,
  });

  final bool running;
  final bool paused;
  final List<Position> points;
  final double distanceM;
  final int durationS;
  final double avgSpeedMps;
  final DateTime? startedAt;
  final String? lastSessionId;
  final int lastAuraAwarded;

  TrackingState copyWith({
    bool? running,
    bool? paused,
    List<Position>? points,
    double? distanceM,
    int? durationS,
    double? avgSpeedMps,
    DateTime? startedAt,
    String? lastSessionId,
    int? lastAuraAwarded,
  }) {
    return TrackingState(
      running: running ?? this.running,
      paused: paused ?? this.paused,
      points: points ?? this.points,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      avgSpeedMps: avgSpeedMps ?? this.avgSpeedMps,
      startedAt: startedAt ?? this.startedAt,
      lastSessionId: lastSessionId ?? this.lastSessionId,
      lastAuraAwarded: lastAuraAwarded ?? this.lastAuraAwarded,
    );
  }

  static const initial = TrackingState(
    running: false,
    paused: false,
    points: [],
    distanceM: 0,
    durationS: 0,
    avgSpeedMps: 0,
  );
}

final trackingControllerProvider =
    NotifierProvider<TrackingController, TrackingState>(TrackingController.new);

final sessionByIdProvider = FutureProvider.family<ActivitySession?, String>((
  ref,
  sessionId,
) {
  return ref.read(sessionRepositoryProvider).getSession(sessionId);
});

class TrackingController extends Notifier<TrackingState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _ticker;

  @override
  TrackingState build() {
    ref.onDispose(() {
      _positionSub?.cancel();
      _ticker?.cancel();
    });
    return TrackingState.initial;
  }

  Future<void> start() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
    state = TrackingState.initial.copyWith(
      running: true,
      startedAt: DateTime.now(),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.running || state.paused) return;
      state = state.copyWith(durationS: state.durationS + 1);
    });
    _positionSub = Geolocator.getPositionStream().listen(_onPosition);
  }

  void pause() => state = state.copyWith(paused: true);
  void resume() => state = state.copyWith(paused: false);

  void _onPosition(Position point) {
    if (!state.running || state.paused) return;
    final next = List<Position>.from(state.points)..add(point);
    final distance = _calculateDistance(next);
    final duration = max(state.durationS, 1);
    state = state.copyWith(
      points: next,
      distanceM: distance,
      avgSpeedMps: distance / duration,
    );
  }

  Future<String> finish({ActivityType type = ActivityType.cycle}) async {
    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) {
      throw Exception('User is not authenticated');
    }
    final endedAt = DateTime.now();
    final startedAt =
        state.startedAt ?? endedAt.subtract(Duration(seconds: state.durationS));
    final sessionId = 's-${endedAt.microsecondsSinceEpoch}';
    final aura = calculateAura(
      distanceMeters: state.distanceM,
      durationSeconds: state.durationS,
      avgSpeedMps: state.avgSpeedMps,
    );
    final session = ActivitySession(
      id: sessionId,
      userId: user.id,
      type: type,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceM: state.distanceM,
      durationS: state.durationS,
      avgPace: state.avgSpeedMps == 0 ? 0 : 1000 / state.avgSpeedMps,
      calories: (state.durationS * 0.12).round(),
      routeGeojson: _toGeoJson(state.points),
    );
    final sessionRepo = ref.read(sessionRepositoryProvider);
    await sessionRepo.createSession(session);
    await ref
        .read(profileRepositoryProvider)
        .addAura(userId: user.id, delta: aura);
    await _positionSub?.cancel();
    _ticker?.cancel();
    state = state.copyWith(
      running: false,
      paused: false,
      lastSessionId: sessionId,
      lastAuraAwarded: aura,
    );
    return sessionId;
  }

  double _calculateDistance(List<Position> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += Geolocator.distanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return total;
  }

  Map<String, dynamic> _toGeoJson(List<Position> points) {
    return {
      'type': 'LineString',
      'coordinates': points.map((p) => [p.longitude, p.latitude]).toList(),
    };
  }
}
