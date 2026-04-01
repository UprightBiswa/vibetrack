import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/features/zones/data/zone_repository.dart';
import 'package:vibetreck/shared/models/zone.dart';

class ZonesState {
  const ZonesState({
    this.status = ViewStatus.initial,
    this.zones = const [],
    this.errorMessage,
  });

  final ViewStatus status;
  final List<Zone> zones;
  final String? errorMessage;

  ZonesState copyWith({
    ViewStatus? status,
    List<Zone>? zones,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ZonesState(
      status: status ?? this.status,
      zones: zones ?? this.zones,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ZonesCubit extends Cubit<ZonesState> {
  ZonesCubit(this._repository) : super(const ZonesState());

  final ZoneRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearError: true));
    try {
      final zones = await _repository.fetchZones();
      emit(
        state.copyWith(
          status: ViewStatus.success,
          zones: zones,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ViewStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> claim({
    required String zoneId,
    required String sessionId,
  }) async {
    final result = await _repository.claimZone(sessionId: sessionId, zoneId: zoneId);
    await load();
    return result;
  }
}
