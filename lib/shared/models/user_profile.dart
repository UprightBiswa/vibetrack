class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.auraPoints,
    required this.homeCity,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String avatarUrl;
  final int auraPoints;
  final String homeCity;
  final DateTime createdAt;

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    int? auraPoints,
    String? homeCity,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      auraPoints: auraPoints ?? this.auraPoints,
      homeCity: homeCity ?? this.homeCity,
      createdAt: createdAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    username: (json['username'] ?? '') as String,
    avatarUrl: (json['avatar_url'] ?? '') as String,
    auraPoints: (json['aura_points'] ?? 0) as int,
    homeCity: (json['home_city'] ?? '') as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_url': avatarUrl,
    'aura_points': auraPoints,
    'home_city': homeCity,
    'created_at': createdAt.toIso8601String(),
  };
}
