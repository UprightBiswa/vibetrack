import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/core/config/app_env.dart';
import 'package:vibetreck/features/auth/data/auth_repository.dart';
import 'package:vibetreck/features/feed/data/feed_repository.dart';
import 'package:vibetreck/features/profile/data/profile_repository.dart';
import 'package:vibetreck/features/tracking/data/session_repository.dart';
import 'package:vibetreck/features/zones/data/zone_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final env = ref.watch(appEnvProvider);
  if (!env.hasSupabase) {
    return null;
  }
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return LocalAuthRepository();
  }
  return SupabaseAuthRepository(client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return LocalProfileRepository();
  }
  return SupabaseProfileRepository(client);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return LocalSessionRepository();
  }
  return SupabaseSessionRepository(client);
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return LocalFeedRepository();
  }
  return SupabaseFeedRepository(client);
});

final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return LocalZoneRepository();
  }
  return SupabaseZoneRepository(client);
});
