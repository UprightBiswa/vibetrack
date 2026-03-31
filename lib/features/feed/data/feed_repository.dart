import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/shared/models/feed_comment.dart';
import 'package:vibetreck/shared/models/feed_post.dart';

abstract class FeedRepository {
  Future<List<FeedPost>> fetchPosts();
  Future<FeedPost> fetchPost(String postId);
  Future<List<FeedComment>> fetchComments(String postId);
  Future<void> createPost(FeedPost post);
  Future<FeedComment> addComment(String postId, String body);
  Future<void> likePost(String postId);
}

class ApiFeedRepository implements FeedRepository {
  ApiFeedRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<FeedPost>> fetchPosts() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/feed/posts');
    return (response.data ?? <dynamic>[])
        .map((item) => FeedPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FeedPost> fetchPost(String postId) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/feed/posts/$postId');
    return FeedPost.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<List<FeedComment>> fetchComments(String postId) async {
    final response = await _dio.get<List<dynamic>>('/api/v1/feed/posts/$postId/comments');
    return (response.data ?? <dynamic>[])
        .map((item) => FeedComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/feed/posts',
      data: {
        'session_id': post.sessionId.isEmpty ? null : post.sessionId,
        'caption': post.caption,
        'image_url': post.imageUrl,
        'stats_json': post.statsJson,
      },
    );
  }

  @override
  Future<FeedComment> addComment(String postId, String body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/feed/posts/$postId/comments',
      data: {'body': body},
    );
    return FeedComment.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<void> likePost(String postId) async {
    await _dio.post<Map<String, dynamic>>('/api/v1/feed/posts/$postId/like');
  }
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
  Future<FeedPost> fetchPost(String postId) async {
    final row = await _client
        .from('posts')
        .select('*, profiles(username)')
        .eq('id', postId)
        .single();
    return FeedPost.fromJson(row);
  }

  @override
  Future<List<FeedComment>> fetchComments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select('*, profiles(username)')
        .eq('post_id', postId)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((item) => FeedComment.fromJson({
              ...(item as Map<String, dynamic>),
              'username': item['profiles']?['username'] ?? 'Rider',
            }))
        .toList();
  }

  @override
  Future<void> createPost(FeedPost post) async {
    await _client.from('posts').insert(post.toJson());
  }

  @override
  Future<FeedComment> addComment(String postId, String body) async {
    final created = await _client
        .from('post_comments')
        .insert({'post_id': postId, 'body': body})
        .select('*, profiles(username)')
        .single();
    return FeedComment.fromJson({
      ...created,
      'username': created['profiles']?['username'] ?? 'Rider',
    });
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
  LocalFeedRepository({
    List<FeedPost>? seedPosts,
    Map<String, List<FeedComment>>? seedComments,
  })  : _items = List<FeedPost>.from(seedPosts ?? const []),
        _comments = Map<String, List<FeedComment>>.from(seedComments ?? const {});

  final List<FeedPost> _items;
  final Map<String, List<FeedComment>> _comments;

  @override
  Future<List<FeedPost>> fetchPosts() async => List<FeedPost>.from(_items);

  @override
  Future<FeedPost> fetchPost(String postId) async {
    return _items.firstWhere((item) => item.id == postId);
  }

  @override
  Future<List<FeedComment>> fetchComments(String postId) async {
    return List<FeedComment>.from(_comments[postId] ?? const []);
  }

  @override
  Future<void> createPost(FeedPost post) async {
    _items.insert(0, post);
  }

  @override
  Future<FeedComment> addComment(String postId, String body) async {
    final comment = FeedComment(
      id: 'c-${DateTime.now().microsecondsSinceEpoch}',
      postId: postId,
      userId: 'local-user',
      body: body,
      createdAt: DateTime.now(),
      username: 'Local Rider',
    );
    _comments.putIfAbsent(postId, () => <FeedComment>[]).add(comment);
    final index = _items.indexWhere((item) => item.id == postId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        commentCount: _items[index].commentCount + 1,
      );
    }
    return comment;
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
