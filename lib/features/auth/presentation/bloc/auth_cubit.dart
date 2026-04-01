import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetreck/features/auth/data/auth_repository.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_state.dart';
import 'package:vibetreck/shared/models/app_user.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(AuthState(user: _repository.currentUser())) {
    _subscription = _repository.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _subscription;

  void _onAuthChanged(AppUser? user) {
    emit(
      state.copyWith(
        user: user,
        updateUser: true,
        isSubmitting: false,
        initialized: true,
        clearError: true,
      ),
    );
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(isSubmitting: true, clearError: true, clearInfo: true));
    try {
      await _repository.signInWithEmail(email: email, password: password);
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _friendlyError(error),
          clearInfo: true,
          initialized: true,
        ),
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(state.copyWith(isSubmitting: true, clearError: true, clearInfo: true));
    try {
      await _repository.signUpWithEmail(email: email, password: password);
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage:
              'Account created. If email confirmation is enabled, verify your email to continue.',
          clearError: true,
          initialized: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _friendlyError(error),
          clearInfo: true,
          initialized: true,
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isSubmitting: true, clearError: true, clearInfo: true));
    try {
      await _repository.signInWithGoogle();
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _friendlyError(error),
          clearInfo: true,
          initialized: true,
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(
      state.copyWith(
        user: null,
        updateUser: true,
        isSubmitting: true,
        clearError: true,
        clearInfo: true,
        initialized: true,
      ),
    );
    try {
      await _repository.signOut();
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _friendlyError(error),
          initialized: true,
        ),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Authentication failed. Please try again.' : message;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
