class ZoneClaimEvent {
  const ZoneClaimEvent({
    required this.id,
    required this.zoneId,
    required this.userId,
    required this.sessionId,
    required this.auraAwarded,
    required this.createdAt,
  });

  final String id;
  final String zoneId;
  final String userId;
  final String sessionId;
  final int auraAwarded;
  final DateTime createdAt;

  factory ZoneClaimEvent.fromJson(Map<String, dynamic> json) => ZoneClaimEvent(
    id: json['id'] as String,
    zoneId: json['zone_id'] as String,
    userId: json['user_id'] as String,
    sessionId: json['session_id'] as String,
    auraAwarded: (json['aura_awarded'] ?? 0) as int,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
