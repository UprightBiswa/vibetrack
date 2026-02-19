import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/features/auth/data/auth_repository.dart';
import 'package:vibetreck/shared/models/app_user.dart';

final authUserProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

final authActionsProvider = Provider<AuthActions>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthActions(repo);
});

class AuthActions {
  AuthActions(this._repo);
  final AuthRepository _repo;

  Future<void> signIn(String email, String password) =>
      _repo.signInWithEmail(email: email, password: password);
  Future<void> signUp(String email, String password) =>
      _repo.signUpWithEmail(email: email, password: password);
  Future<void> signInWithGoogle() => _repo.signInWithGoogle();
  Future<void> signOut() => _repo.signOut();
}
