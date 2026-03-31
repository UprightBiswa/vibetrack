class FeedComment {
  const FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.createdAt,
    required this.username,
  });

  final String id;
  final String postId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String username;

  factory FeedComment.fromJson(Map<String, dynamic> json) => FeedComment(
    id: json['id'] as String,
    postId: json['post_id'] as String,
    userId: json['user_id'] as String,
    body: (json['body'] ?? '') as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    username: (json['username'] ?? 'Rider') as String,
  );
}
