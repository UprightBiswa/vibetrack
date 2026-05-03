import 'package:flutter/foundation.dart';

enum AppMode { dev, staging, production }

class AppEnv {
  const AppEnv({
    required this.appMode,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.supabaseRedirectUrl,
    required this.backendApiUrl,
    required this.androidBackendApiUrl,
    required this.backendApiFallbackUrl,
  });

  final AppMode appMode;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String supabaseRedirectUrl;
  final String backendApiUrl;
  final String androidBackendApiUrl;
  final String backendApiFallbackUrl;

  bool get isProduction => appMode == AppMode.production;
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasSupabaseRedirectUrl => supabaseRedirectUrl.isNotEmpty;
  bool get hasBackendApi => effectiveBackendApiUrl.isNotEmpty;
  bool get hasBackendApiFallback =>
      !isProduction &&
      backendApiFallbackUrl.isNotEmpty &&
      backendApiFallbackUrl != effectiveBackendApiUrl;
  bool get hasRequiredProductionKeys => hasSupabase && hasSupabaseRedirectUrl;

  String get effectiveBackendApiUrl {
    if (defaultTargetPlatform == TargetPlatform.android &&
        androidBackendApiUrl.isNotEmpty) {
      return androidBackendApiUrl;
    }
    return backendApiUrl;
  }

  String get effectiveBackendApiFallbackUrl => backendApiFallbackUrl;

  bool get isLoopbackBackendHost {
    final uri = Uri.tryParse(effectiveBackendApiUrl);
    final host = uri?.host.toLowerCase() ?? '';
    return host == '127.0.0.1' || host == 'localhost';
  }

  String? get backendSetupHint {
    if (!hasBackendApi) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        androidBackendApiUrl.isNotEmpty) {
      return null;
    }
    if (!isLoopbackBackendHost) {
      return null;
    }
    return 'Android physical devices cannot use 127.0.0.1 directly. Either run `adb reverse tcp:8001 tcp:8001` before `flutter run`, or set `BACKEND_API_URL_ANDROID` to your computer LAN URL such as `http://192.168.x.x:8001`.';
  }

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
    const backendApiUrl = String.fromEnvironment(
      'BACKEND_API_URL',
      defaultValue: '',
    );
    const androidBackendApiUrl = String.fromEnvironment(
      'BACKEND_API_URL_ANDROID',
      defaultValue: '',
    );
    const backendApiFallbackUrl = String.fromEnvironment(
      'BACKEND_API_URL_FALLBACK',
      defaultValue: '',
    );

    return AppEnv(
      appMode: _parseMode(modeRaw),
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      supabaseRedirectUrl: supabaseRedirectUrl,
      backendApiUrl: backendApiUrl,
      androidBackendApiUrl: androidBackendApiUrl,
      backendApiFallbackUrl: backendApiFallbackUrl,
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
