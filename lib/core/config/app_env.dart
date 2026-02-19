import 'package:flutter_riverpod/flutter_riverpod.dart';

final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromDefines());

class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.mapboxPublicToken,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String mapboxPublicToken;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasMapboxToken => mapboxPublicToken.isNotEmpty;

  static AppEnv fromDefines() {
    return const AppEnv(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      supabaseAnonKey: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      ),
      mapboxPublicToken: String.fromEnvironment(
        'MAPBOX_PUBLIC_TOKEN',
        defaultValue: '',
      ),
    );
  }
}
