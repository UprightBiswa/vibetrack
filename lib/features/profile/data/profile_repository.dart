import 'dart:math';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/leaderboard_entry.dart';
import 'package:vibetreck/shared/models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getOrCreateProfile({
    required String userId,
    required String email,
  });
  Future<UserProfile?> getProfileById(String profileId);
  Future<UserProfile> updateProfile({
    required String username,
    required String homeCity,
    String avatarUrl = '',
  });
  Future<void> addAura({required String userId, required int delta});
  Future<int?> getMyRank();
  Future<Map<String, dynamic>> getMyStreak();
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 20});
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
    final profile = UserProfile.fromJson(response.data!);
    final rank = await getMyRank();
    final streak = await getMyStreak();
    return profile.copyWith(
      globalRank: rank,
      currentStreakDays: streak['current_streak_days'] as int?,
      longestStreakDays: streak['longest_streak_days'] as int?,
      activeToday: streak['active_today'] as bool?,
    );
  }

  @override
  Future<UserProfile?> getProfileById(String profileId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/profiles/$profileId');
      return UserProfile.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String username,
    required String homeCity,
    String avatarUrl = '',
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/profiles/me',
      data: {
        'username': username,
        'home_city': homeCity,
        'avatar_url': avatarUrl,
      },
    );
    final profile = UserProfile.fromJson(response.data!);
    final rank = await getMyRank();
    final streak = await getMyStreak();
    return profile.copyWith(
      globalRank: rank,
      currentStreakDays: streak['current_streak_days'] as int?,
      longestStreakDays: streak['longest_streak_days'] as int?,
      activeToday: streak['active_today'] as bool?,
    );
  }

  @override
  Future<void> addAura({required String userId, required int delta}) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/profiles/me/aura',
      data: {'delta': delta},
    );
  }

  @override
  Future<int?> getMyRank() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/profiles/me/rank');
    return response.data?['global_rank'] as int?;
  }

  @override
  Future<Map<String, dynamic>> getMyStreak() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/profiles/me/streak');
    return response.data ?? <String, dynamic>{};
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 20}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/profiles/leaderboard',
      queryParameters: {'limit': limit},
    );
    return (response.data ?? <dynamic>[])
        .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
        .toList();
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
      'email': email,
    };
    final inserted = await _client.from('profiles').insert(payload).select().single();
    return UserProfile.fromJson(inserted);
  }

  @override
  Future<UserProfile?> getProfileById(String profileId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  @override
  Future<UserProfile> updateProfile({
    required String username,
    required String homeCity,
    String avatarUrl = '',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    final response = await _client
        .from('profiles')
        .update({
          'username': username,
          'home_city': homeCity,
          'avatar_url': avatarUrl,
        })
        .eq('id', userId)
        .select()
        .single();
    return UserProfile.fromJson(response);
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

  @override
  Future<int?> getMyRank() async => null;

  @override
  Future<Map<String, dynamic>> getMyStreak() async => <String, dynamic>{};

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 20}) async => const [];
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
      email: email,
      globalRank: 1,
      currentStreakDays: 3,
      longestStreakDays: 7,
      activeToday: true,
    );
    _profiles[userId] = created;
    return created;
  }

  @override
  Future<UserProfile?> getProfileById(String profileId) async => _profiles[profileId];

  @override
  Future<UserProfile> updateProfile({
    required String username,
    required String homeCity,
    String avatarUrl = '',
  }) async {
    final current = _profiles.values.isEmpty ? null : _profiles.values.first;
    if (current == null) throw Exception('Profile not found');
    final updated = current.copyWith(
      username: username,
      homeCity: homeCity,
      avatarUrl: avatarUrl,
    );
    _profiles[current.id] = updated;
    return updated;
  }

  @override
  Future<void> addAura({required String userId, required int delta}) async {
    final profile = _profiles[userId];
    if (profile == null) return;
    _profiles[userId] = profile.copyWith(
      auraPoints: profile.auraPoints + delta,
    );
  }

  @override
  Future<int?> getMyRank() async => _profiles.values.isEmpty ? null : 1;

  @override
  Future<Map<String, dynamic>> getMyStreak() async => {
        'current_streak_days': 3,
        'longest_streak_days': 7,
        'active_today': true,
      };

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 20}) async {
    return _profiles.values
        .toList()
        .asMap()
        .entries
        .map((entry) => LeaderboardEntry(
              profileId: entry.value.id,
              username: entry.value.username,
              auraPoints: entry.value.auraPoints,
              globalRank: entry.key + 1,
            ))
        .toList();
  }
}

String _safeUsernameFromEmail(String email) {
  final head = email.split('@').first.trim();
  if (head.isEmpty) return 'rider';
  return head;
}
