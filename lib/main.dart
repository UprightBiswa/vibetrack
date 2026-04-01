import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/app.dart';
import 'package:vibetreck/core/bloc/app_bloc_observer.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/core/logging/app_logger.dart';
import 'package:vibetreck/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Background isolate may already have Firebase initialized.
  }
  AppLogger.info(
    'Background FCM message received: ${message.messageId ?? 'unknown'}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();

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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    AppLogger.info('Firebase initialized successfully');
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Firebase initialization skipped or failed',
      error: error,
      stackTrace: stackTrace,
    );
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
