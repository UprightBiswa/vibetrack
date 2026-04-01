import 'package:supabase_flutter/supabase_flutter.dart';

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
