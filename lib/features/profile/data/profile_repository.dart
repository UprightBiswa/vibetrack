import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
  });
  Future<void> addAura({required String userId, required int delta});
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
  }) async {
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (existing != null) {
      return UserProfile.fromJson(existing);
    }
    final payload = {
      'id': userId,
      'username': email.split('@').first,
      'avatar_url': '',
      'aura_points': 0,
      'home_city': 'Unknown',
      'created_at': DateTime.now().toIso8601String(),
    };
    final inserted = await _client
        .from('profiles')
        .insert(payload)
        .select()
        .single();
    return UserProfile.fromJson(inserted);
  }

  @override
  Future<void> addAura({required String userId, required int delta}) async {
    final profile = await _client
        .from('profiles')
        .select('aura_points')
        .eq('id', userId)
        .single();
    final current = (profile['aura_points'] ?? 0) as int;
    await _client
        .from('profiles')
        .update({'aura_points': max(current + delta, 0)})
        .eq('id', userId);
  }
}

class LocalProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> _profiles = {};

  @override
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
  }) async {
    final existing = _profiles[userId];
    if (existing != null) return existing;
    final created = UserProfile(
      id: userId,
      username: email.split('@').first,
      avatarUrl: '',
      auraPoints: 1200,
      homeCity: 'Demo City',
      createdAt: DateTime.now(),
    );
    _profiles[userId] = created;
    return created;
  }

  @override
  Future<void> addAura({required String userId, required int delta}) async {
    final profile = _profiles[userId];
    if (profile == null) return;
    _profiles[userId] = profile.copyWith(
      auraPoints: profile.auraPoints + delta,
    );
  }
}
