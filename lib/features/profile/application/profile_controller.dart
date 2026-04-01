import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/features/profile/data/profile_repository.dart';
import 'package:vibetreck/shared/models/leaderboard_entry.dart';
import 'package:vibetreck/shared/models/user_profile.dart';

class PublicProfileState {
  const PublicProfileState({
    this.status = ViewStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final ViewStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  PublicProfileState copyWith({
    ViewStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PublicProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit(this._repository) : super(const PublicProfileState());

  final ProfileRepository _repository;

  Future<void> load(String profileId) async {
    emit(state.copyWith(status: ViewStatus.loading, clearError: true));
    try {
      final profile = await _repository.getProfileById(profileId);
      emit(
        state.copyWith(
          status: ViewStatus.success,
          profile: profile,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: ViewStatus.failure, errorMessage: error.toString()));
    }
  }
}

class LeaderboardState {
  const LeaderboardState({
    this.status = ViewStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  final ViewStatus status;
  final List<LeaderboardEntry> entries;
  final String? errorMessage;

  LeaderboardState copyWith({
    ViewStatus? status,
    List<LeaderboardEntry>? entries,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._repository) : super(const LeaderboardState());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearError: true));
    try {
      final entries = await _repository.getLeaderboard();
      emit(
        state.copyWith(
          status: ViewStatus.success,
          entries: entries,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: ViewStatus.failure, errorMessage: error.toString()));
    }
  }
}
