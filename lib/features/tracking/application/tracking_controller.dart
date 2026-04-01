import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/profile/data/profile_repository.dart';
import 'package:vibetreck/features/tracking/data/session_repository.dart';
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

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({
    required SessionRepository sessionRepository,
    required ProfileRepository profileRepository,
    required AuthCubit authCubit,
  })  : _sessionRepository = sessionRepository,
        _profileRepository = profileRepository,
        _authCubit = authCubit,
        super(TrackingState.initial);

  final SessionRepository _sessionRepository;
  final ProfileRepository _profileRepository;
  final AuthCubit _authCubit;
  StreamSubscription<Position>? _positionSub;
  Timer? _ticker;

  Future<void> start() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled. Enable GPS and retry.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission denied forever. Open app settings to continue.',
      );
    }
    await _positionSub?.cancel();
    _ticker?.cancel();
    emit(
      TrackingState.initial.copyWith(
        running: true,
        startedAt: DateTime.now(),
      ),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.running || state.paused) return;
      emit(state.copyWith(durationS: state.durationS + 1));
    });
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void pause() => emit(state.copyWith(paused: true));
  void resume() => emit(state.copyWith(paused: false));

  Future<ActivitySession?> loadSession(String sessionId) {
    return _sessionRepository.getSession(sessionId);
  }

  void _onPosition(Position point) {
    if (!state.running || state.paused) return;
    final next = List<Position>.from(state.points)..add(point);
    final distance = _calculateDistance(next);
    final duration = max(state.durationS, 1);
    emit(
      state.copyWith(
        points: next,
        distanceM: distance,
        avgSpeedMps: distance / duration,
      ),
    );
  }

  Future<String> finish({ActivityType type = ActivityType.cycle}) async {
    final user = _authCubit.state.user;
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
    await _sessionRepository.createSession(session);
    await _profileRepository.addAura(userId: user.id, delta: aura);
    await _positionSub?.cancel();
    _ticker?.cancel();
    emit(
      state.copyWith(
        running: false,
        paused: false,
        lastSessionId: sessionId,
        lastAuraAwarded: aura,
      ),
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

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    _ticker?.cancel();
    return super.close();
  }
}
