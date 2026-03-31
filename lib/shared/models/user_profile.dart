class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.auraPoints,
    required this.homeCity,
    required this.createdAt,
    this.email,
    this.globalRank,
    this.currentStreakDays,
    this.longestStreakDays,
    this.activeToday,
  });

  final String id;
  final String username;
  final String avatarUrl;
  final int auraPoints;
  final String homeCity;
  final DateTime createdAt;
  final String? email;
  final int? globalRank;
  final int? currentStreakDays;
  final int? longestStreakDays;
  final bool? activeToday;

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    int? auraPoints,
    String? homeCity,
    String? email,
    int? globalRank,
    int? currentStreakDays,
    int? longestStreakDays,
    bool? activeToday,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      auraPoints: auraPoints ?? this.auraPoints,
      homeCity: homeCity ?? this.homeCity,
      createdAt: createdAt,
      email: email ?? this.email,
      globalRank: globalRank ?? this.globalRank,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      activeToday: activeToday ?? this.activeToday,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    username: (json['username'] ?? '') as String,
    avatarUrl: (json['avatar_url'] ?? '') as String,
    auraPoints: (json['aura_points'] ?? 0) as int,
    homeCity: (json['home_city'] ?? '') as String,
    createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
        DateTime.now(),
    email: json['email'] as String?,
    globalRank: json['global_rank'] as int?,
    currentStreakDays: json['current_streak_days'] as int?,
    longestStreakDays: json['longest_streak_days'] as int?,
    activeToday: json['active_today'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_url': avatarUrl,
    'aura_points': auraPoints,
    'home_city': homeCity,
    'created_at': createdAt.toIso8601String(),
    'email': email,
    'global_rank': globalRank,
    'current_streak_days': currentStreakDays,
    'longest_streak_days': longestStreakDays,
    'active_today': activeToday,
  };
}
