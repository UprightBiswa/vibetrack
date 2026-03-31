import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/core/config/app_env.dart';

final authTokenProvider = Provider<AuthTokenProvider>((ref) {
  final env = ref.watch(appEnvProvider);
  return SupabaseAuthTokenProvider(enabled: env.hasSupabase);
});

abstract class AuthTokenProvider {
  Future<String?> getAccessToken();
}

class SupabaseAuthTokenProvider implements AuthTokenProvider {
  SupabaseAuthTokenProvider({required this.enabled});

  final bool enabled;

  @override
  Future<String?> getAccessToken() async {
    if (!enabled) return null;
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }
}
