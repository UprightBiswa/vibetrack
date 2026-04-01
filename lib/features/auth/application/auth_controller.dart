import 'package:vibetreck/features/auth/data/auth_repository.dart';

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
