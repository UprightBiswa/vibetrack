import 'dart:math';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
  });
  Future<void> addAura({required String userId, required int delta});
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/profiles/me');
    return UserProfile.fromJson(response.data!);
  }

  @override
  Future<void> addAura({required String userId, required int delta}) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/profiles/me/aura',
      data: {'delta': delta},
    );
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
  }) async {
    final fallbackUsername = _safeUsernameFromEmail(email);
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
      'username': fallbackUsername,
      'avatar_url': '',
      'aura_points': 0,
      'home_city': 'Unknown',
      'created_at': DateTime.now().toIso8601String(),
    };
    final inserted = await _client.from('profiles').insert(payload).select().single();
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
    final fallbackUsername = _safeUsernameFromEmail(email);
    final existing = _profiles[userId];
    if (existing != null) return existing;
    final created = UserProfile(
      id: userId,
      username: fallbackUsername,
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

String _safeUsernameFromEmail(String email) {
  final head = email.split('@').first.trim();
  if (head.isEmpty) return 'rider';
  return head;
}
