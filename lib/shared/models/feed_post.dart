class FeedPost {
  const FeedPost({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.imageUrl,
    required this.caption,
    required this.statsJson,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.username,
    required this.likedByMe,
  });

  final String id;
  final String userId;
  final String sessionId;
  final String imageUrl;
  final String caption;
  final Map<String, dynamic> statsJson;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final String username;
  final bool likedByMe;

  FeedPost copyWith({
    String? imageUrl,
    String? caption,
    Map<String, dynamic>? statsJson,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return FeedPost(
      id: id,
      userId: userId,
      sessionId: sessionId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      statsJson: statsJson ?? this.statsJson,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      username: username,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    sessionId: (json['session_id'] ?? '') as String,
    imageUrl: (json['image_url'] ?? '') as String,
    caption: (json['caption'] ?? '') as String,
    statsJson:
        (json['stats_json'] ?? <String, dynamic>{}) as Map<String, dynamic>,
    createdAt: DateTime.parse(json['created_at'] as String),
    likeCount: (json['like_count'] ?? 0) as int,
    commentCount: (json['comment_count'] ?? 0) as int,
    username:
        (json['username'] ?? json['profiles']?['username'] ?? 'Rider') as String,
    likedByMe: (json['liked_by_me'] ?? false) as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'session_id': sessionId,
    'image_url': imageUrl,
    'caption': caption,
    'stats_json': statsJson,
    'created_at': createdAt.toIso8601String(),
    'like_count': likeCount,
    'comment_count': commentCount,
    'liked_by_me': likedByMe,
  };
}
