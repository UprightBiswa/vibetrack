class LeaderboardEntry {
  const LeaderboardEntry({
    required this.profileId,
    required this.username,
    required this.auraPoints,
    required this.globalRank,
  });

  final String profileId;
  final String username;
  final int auraPoints;
  final int globalRank;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        profileId: json['profile_id'] as String,
        username: (json['username'] ?? 'Rider') as String,
        auraPoints: (json['aura_points'] ?? 0) as int,
        globalRank: (json['global_rank'] ?? 0) as int,
      );
}
