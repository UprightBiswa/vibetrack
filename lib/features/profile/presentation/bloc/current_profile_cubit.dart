import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_state.dart';
import 'package:vibetreck/features/profile/data/profile_repository.dart';
import 'package:vibetreck/features/profile/presentation/bloc/current_profile_state.dart';

class CurrentProfileCubit extends Cubit<CurrentProfileState> {
  CurrentProfileCubit({
    required ProfileRepository profileRepository,
    required AuthCubit authCubit,
  })  : _profileRepository = profileRepository,
        _authCubit = authCubit,
        super(const CurrentProfileState()) {
    _authSubscription = _authCubit.stream.listen(_handleAuthState);
    _handleAuthState(_authCubit.state);
  }

  final ProfileRepository _profileRepository;
  final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _authSubscription;

  Future<void> _handleAuthState(AuthState authState) async {
    final user = authState.user;
    if (user == null) {
      emit(
        const CurrentProfileState(
          status: ViewStatus.initial,
          profile: null,
          errorMessage: null,
        ),
      );
      return;
    }
    await refresh(email: user.email, userId: user.id);
  }

  Future<void> refresh({String? userId, String? email}) async {
    final activeUser = _authCubit.state.user;
    final resolvedUserId = userId ?? activeUser?.id;
    final resolvedEmail = email ?? activeUser?.email;
    if (resolvedUserId == null || resolvedEmail == null) {
      emit(
        const CurrentProfileState(
          status: ViewStatus.initial,
          profile: null,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ViewStatus.loading, clearError: true));
    try {
      final profile = await _profileRepository.getOrCreateProfile(
        userId: resolvedUserId,
        email: resolvedEmail,
      );
      emit(
        state.copyWith(
          status: ViewStatus.success,
          profile: profile,
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

  Future<void> updateProfile({
    required String username,
    required String homeCity,
    String avatarUrl = '',
  }) async {
    emit(state.copyWith(status: ViewStatus.loading, clearError: true));
    try {
      final profile = await _profileRepository.updateProfile(
        username: username,
        homeCity: homeCity,
        avatarUrl: avatarUrl,
      );
      emit(
        state.copyWith(
          status: ViewStatus.success,
          profile: profile,
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

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
