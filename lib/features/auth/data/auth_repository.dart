import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? currentUser();
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, {required this.redirectTo});
  final SupabaseClient _client;
  final String redirectTo;

  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.multi((controller) {
      controller.add(currentUser());
      final sub = _client.auth.onAuthStateChange.listen(
        (_) => controller.add(currentUser()),
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  AppUser? currentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw Exception(error.message);
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectTo,
      );
    } on AuthException catch (error) {
      throw Exception(error.message);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (error) {
      throw Exception(error.message);
    } catch (_) {
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw Exception(error.message);
    }
  }
}

class LocalAuthRepository implements AuthRepository {
  static const _configError =
      'Authentication is not configured. Run the app with Supabase environment values.';

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  LocalAuthRepository() {
    _controller.add(null);
  }

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? currentUser() => null;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw Exception(_configError);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    throw Exception(_configError);
  }

  @override
  Future<void> signInWithGoogle() async {
    throw Exception(_configError);
  }

  @override
  Future<void> signOut() async {}
}
