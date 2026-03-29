import 'package:flutter_riverpod/flutter_riverpod.dart';

final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromDefines());

enum AppMode { dev, staging, production }

class AppEnv {
  const AppEnv({
    required this.appMode,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.supabaseRedirectUrl,
  });

  final AppMode appMode;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String supabaseRedirectUrl;

  bool get isProduction => appMode == AppMode.production;
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasSupabaseRedirectUrl => supabaseRedirectUrl.isNotEmpty;
  bool get hasRequiredProductionKeys => hasSupabase && hasSupabaseRedirectUrl;

  List<String> get missingProductionKeys {
    final missing = <String>[];
    if (!hasSupabase) {
      missing.add('SUPABASE_URL and/or SUPABASE_ANON_KEY');
    }
    if (!hasSupabaseRedirectUrl) {
      missing.add('SUPABASE_REDIRECT_URL');
    }
    return missing;
  }

  static AppEnv fromDefines() {
    const modeRaw = String.fromEnvironment('APP_MODE', defaultValue: 'dev');
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    const supabaseRedirectUrl = String.fromEnvironment(
      'SUPABASE_REDIRECT_URL',
      defaultValue: 'vibetreck://login-callback',
    );

    return AppEnv(
      appMode: _parseMode(modeRaw),
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      supabaseRedirectUrl: supabaseRedirectUrl,
    );
  }
}

AppMode _parseMode(String raw) {
  switch (raw.toLowerCase().trim()) {
    case 'production':
    case 'prod':
      return AppMode.production;
    case 'staging':
      return AppMode.staging;
    default:
      return AppMode.dev;
  }
}
