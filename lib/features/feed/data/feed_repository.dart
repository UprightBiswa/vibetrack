import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/feed_post.dart';

abstract class FeedRepository {
  Future<List<FeedPost>> fetchPosts();
  Future<void> createPost(FeedPost post);
  Future<void> likePost(String postId);
}

class SupabaseFeedRepository implements FeedRepository {
  SupabaseFeedRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<FeedPost>> fetchPosts() async {
    final rows = await _client
        .from('posts')
        .select('*, profiles(username)')
        .order('created_at', ascending: false)
        .limit(40);
    return (rows as List<dynamic>)
        .map((item) => FeedPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    await _client.from('posts').insert(post.toJson());
  }

  @override
  Future<void> likePost(String postId) async {
    final row = await _client
        .from('posts')
        .select('like_count')
        .eq('id', postId)
        .single();
    final likes = (row['like_count'] ?? 0) as int;
    await _client
        .from('posts')
        .update({'like_count': likes + 1})
        .eq('id', postId);
  }
}

class LocalFeedRepository implements FeedRepository {
  final List<FeedPost> _items = [
    FeedPost(
      id: 'p1',
      userId: 'guest-user',
      sessionId: 's1',
      imageUrl: '',
      caption: 'Morning city loop.',
      statsJson: {'distanceKm': 12.4, 'durationMin': 42, 'aura': 220},
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likeCount: 18,
      commentCount: 4,
      username: 'neonrider',
    ),
  ];

  @override
  Future<List<FeedPost>> fetchPosts() async => List<FeedPost>.from(_items);

  @override
  Future<void> createPost(FeedPost post) async {
    _items.insert(0, post);
  }

  @override
  Future<void> likePost(String postId) async {
    final index = _items.indexWhere((item) => item.id == postId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      likeCount: _items[index].likeCount + 1,
    );
  }
}
