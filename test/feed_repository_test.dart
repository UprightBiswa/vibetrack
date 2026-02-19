import 'package:flutter_test/flutter_test.dart';
import 'package:vibetreck/features/feed/data/feed_repository.dart';
import 'package:vibetreck/shared/models/feed_post.dart';

void main() {
  test('local feed like increments count', () async {
    final repo = LocalFeedRepository();
    final posts = await repo.fetchPosts();
    final target = posts.first;
    final before = target.likeCount;
    await repo.likePost(target.id);
    final after = (await repo.fetchPosts()).first.likeCount;
    expect(after, before + 1);
  });

  test('local feed create prepends post', () async {
    final repo = LocalFeedRepository();
    final post = FeedPost(
      id: 'p-new',
      userId: 'u1',
      sessionId: 's1',
      imageUrl: '',
      caption: 'test',
      statsJson: const {},
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      username: 'tester',
    );
    await repo.createPost(post);
    final posts = await repo.fetchPosts();
    expect(posts.first.id, 'p-new');
  });
}
