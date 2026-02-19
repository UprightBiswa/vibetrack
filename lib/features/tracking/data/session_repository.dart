import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/activity_session.dart';

abstract class SessionRepository {
  Future<ActivitySession> createSession(ActivitySession session);
  Future<ActivitySession?> getSession(String sessionId);
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
}
