import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/activity_session.dart';

abstract class SessionRepository {
  Future<ActivitySession> createSession(ActivitySession session);
  Future<ActivitySession?> getSession(String sessionId);
  Future<List<ActivitySession>> listSessions();
}

class ApiSessionRepository implements SessionRepository {
  ApiSessionRepository(this._dio);

  final Dio _dio;

  @override
  Future<ActivitySession> createSession(ActivitySession session) async {
    final avgSpeedMps = session.durationS > 0 ? session.distanceM / session.durationS : 0.0;
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/rides/sessions',
      data: {
        'session_id': session.id,
        'activity_type': session.type.name,
        'started_at': session.startedAt.toIso8601String(),
        'ended_at': session.endedAt.toIso8601String(),
        'distance_m': session.distanceM,
        'duration_s': session.durationS,
        'avg_speed_mps': avgSpeedMps,
        'avg_pace': session.avgPace,
        'calories': session.calories,
        'route_geojson': session.routeGeojson,
      },
    );
    return ActivitySession.fromJson(response.data!);
  }

  @override
  Future<ActivitySession?> getSession(String sessionId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/rides/sessions/$sessionId',
      );
      return ActivitySession.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<ActivitySession>> listSessions() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/v1/rides/sessions/mine');
      final rows = response.data ?? const [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(ActivitySession.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }
}

class SupabaseSessionRepository implements SessionRepository {
  SupabaseSessionRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<ActivitySession> createSession(ActivitySession session) async {
    final response = await _client
        .from('sessions')
        .insert(session.toJson())
        .select()
        .single();
    return ActivitySession.fromJson(response);
  }

  @override
  Future<ActivitySession?> getSession(String sessionId) async {
    final response = await _client
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();
    if (response == null) return null;
    return ActivitySession.fromJson(response);
  }

  @override
  Future<List<ActivitySession>> listSessions() async {
    final response = await _client
        .from('sessions')
        .select()
        .order('started_at', ascending: false);
    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(ActivitySession.fromJson)
        .toList(growable: false);
  }
}

class LocalSessionRepository implements SessionRepository {
  final Map<String, ActivitySession> _store = {};

  @override
  Future<ActivitySession> createSession(ActivitySession session) async {
    _store[session.id] = session;
    return session;
  }

  @override
  Future<ActivitySession?> getSession(String sessionId) async =>
      _store[sessionId];

  @override
  Future<List<ActivitySession>> listSessions() async {
    final sessions = _store.values.toList(growable: false)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }
}
