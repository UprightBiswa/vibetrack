import 'dart:convert';

class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.polygon,
    required this.city,
    required this.scoreMultiplier,
    required this.currentGuardianUserId,
  });

  final String id;
  final String name;
  final Map<String, dynamic> polygon;
  final String city;
  final double scoreMultiplier;
  final String? currentGuardianUserId;

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id: json['id'] as String,
    name: (json['name'] ?? '') as String,
    polygon: _parsePolygon(json['polygon']),
    city: (json['city'] ?? '') as String,
    scoreMultiplier: ((json['score_multiplier'] ?? 1) as num).toDouble(),
    currentGuardianUserId: json['current_guardian_user_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'polygon': polygon,
    'city': city,
    'score_multiplier': scoreMultiplier,
    'current_guardian_user_id': currentGuardianUserId,
  };
}

Map<String, dynamic> _parsePolygon(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return <String, dynamic>{};
    }
  }
  return <String, dynamic>{};
}
