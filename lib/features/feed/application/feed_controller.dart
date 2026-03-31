import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibetreck/core/network/network_status_provider.dart';
import 'package:vibetreck/core/providers/repositories.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/shared/models/feed_comment.dart';
import 'package:vibetreck/shared/models/feed_post.dart';

final feedProvider = FutureProvider<List<FeedPost>>(
  retry: (count, error) => null,
  (ref) async {
    return ref.read(feedRepositoryProvider).fetchPosts();
  },
);

final feedPostProvider = FutureProvider.family<FeedPost, String>(
  retry: (count, error) => null,
  (ref, postId) async {
    return ref.read(feedRepositoryProvider).fetchPost(postId);
  },
);

final postCommentsProvider = FutureProvider.family<List<FeedComment>, String>(
  retry: (count, error) => null,
  (ref, postId) async {
    return ref.read(feedRepositoryProvider).fetchComments(postId);
  },
);

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
    if (!_ref.read(isOnlineProvider)) {
      throw Exception('No internet connection. Try again when online.');
    }
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
      likedByMe: false,
    );
    await _ref.read(feedRepositoryProvider).createPost(post);
    _ref.invalidate(feedProvider);
  }

  Future<void> addComment({
    required String postId,
    required String body,
  }) async {
    if (!_ref.read(isOnlineProvider)) {
      throw Exception('No internet connection.');
    }
    await _ref.read(feedRepositoryProvider).addComment(postId, body.trim());
    _ref.invalidate(feedProvider);
    _ref.invalidate(feedPostProvider(postId));
    _ref.invalidate(postCommentsProvider(postId));
  }

  Future<void> like(String postId) async {
    if (!_ref.read(isOnlineProvider)) {
      throw Exception('No internet connection.');
    }
    await _ref.read(feedRepositoryProvider).likePost(postId);
    _ref.invalidate(feedProvider);
    _ref.invalidate(feedPostProvider(postId));
  }
}
