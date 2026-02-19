enum ActivityType { cycle, run, walk, gym }

class ActivitySession {
  const ActivitySession({
    required this.id,
    required this.userId,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.distanceM,
    required this.durationS,
    required this.avgPace,
    required this.calories,
    required this.routeGeojson,
  });

  final String id;
  final String userId;
  final ActivityType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceM;
  final int durationS;
  final double avgPace;
  final int calories;
  final Map<String, dynamic> routeGeojson;

  factory ActivitySession.fromJson(Map<String, dynamic> json) =>
      ActivitySession(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: _activityFromString((json['type'] ?? 'run') as String),
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: DateTime.parse(json['ended_at'] as String),
        distanceM: ((json['distance_m'] ?? 0) as num).toDouble(),
        durationS: (json['duration_s'] ?? 0) as int,
        avgPace: ((json['avg_pace'] ?? 0) as num).toDouble(),
        calories: (json['calories'] ?? 0) as int,
        routeGeojson:
            (json['route_geojson'] ?? <String, dynamic>{})
                as Map<String, dynamic>,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.name,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt.toIso8601String(),
    'distance_m': distanceM,
    'duration_s': durationS,
    'avg_pace': avgPace,
    'calories': calories,
    'route_geojson': routeGeojson,
  };
}

ActivityType _activityFromString(String value) {
  return ActivityType.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ActivityType.run,
  );
}
