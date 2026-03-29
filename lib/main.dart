import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/app.dart';
import 'package:vibetreck/core/config/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AppEnv.fromDefines();
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
  }

  runApp(
    ProviderScope(
      overrides: [appEnvProvider.overrideWithValue(env)],
      child: const VibeTrackApp(),
    ),
  );
}
