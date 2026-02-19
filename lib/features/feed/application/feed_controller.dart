import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/shared/models/feed_post.dart';

final feedProvider = FutureProvider<List<FeedPost>>((ref) async {
  return ref.read(feedRepositoryProvider).fetchPosts();
});

final feedActionsProvider = Provider<FeedActions>((ref) {
  return FeedActions(ref);
});

class FeedActions {
  FeedActions(this._ref);
  final Ref _ref;

  Future<void> createPost({
    required String sessionId,
    required String imageUrl,
    required String caption,
    required Map<String, dynamic> statsJson,
  }) async {
    final user = _ref.read(authUserProvider).asData?.value;
    if (user == null) throw Exception('User not found');
    final post = FeedPost(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999)}',
      userId: user.id,
      sessionId: sessionId,
      imageUrl: imageUrl,
      caption: caption,
      statsJson: statsJson,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      username: user.email.split('@').first,
    );
    await _ref.read(feedRepositoryProvider).createPost(post);
    _ref.invalidate(feedProvider);
  }

  Future<void> like(String postId) async {
    await _ref.read(feedRepositoryProvider).likePost(postId);
    _ref.invalidate(feedProvider);
  }
}
