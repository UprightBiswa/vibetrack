import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/app.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught platform error', error: error, stackTrace: stack);
    return false;
  };

  final env = AppEnv.fromDefines();
  AppLogger.info(
    'App boot env: mode=${env.appMode.name}, hasSupabase=${env.hasSupabase}, hasBackendApi=${env.hasBackendApi}, backend=${env.effectiveBackendApiUrl.isEmpty ? 'none' : env.effectiveBackendApiUrl}',
  );
  final backendSetupHint = env.backendSetupHint;
  if (backendSetupHint != null) {
    AppLogger.warning(backendSetupHint);
  }

  if (env.isProduction && !env.hasRequiredProductionKeys) {
    final missing = env.missingProductionKeys.join(', ');
    throw FlutterError('Missing required production configuration: $missing');
  }

  if (env.hasSupabase) {
    await Supabase.initialize(
      url: env.supabaseUrl,
      anonKey: env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
    AppLogger.info('Supabase initialized successfully');
  } else {
    AppLogger.warning('Supabase not initialized because env values are missing');
  }

  runApp(
    ProviderScope(
      overrides: [appEnvProvider.overrideWithValue(env)],
      child: const VibeTrackApp(),
    ),
  );
}
