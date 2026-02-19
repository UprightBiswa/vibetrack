import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Flex Feed')),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text('No posts yet. Complete a session and publish.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(feedProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              separatorBuilder: (_, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                final stats = post.statsJson;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(post.username),
                        subtitle: Text(
                          DateFormat('MMM d - HH:mm').format(post.createdAt),
                        ),
                        trailing: const Chip(label: Text('Zone Guardian')),
                      ),
                      Container(
                        height: 220,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF181818), Color(0xFF070707)],
                          ),
                        ),
                        child: Text(
                          '${stats['distanceKm'] ?? '-'} KM',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(post.caption),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                ref.read(feedActionsProvider).like(post.id),
                            icon: const Icon(Icons.favorite_border),
                          ),
                          Text('${post.likeCount}'),
                          const SizedBox(width: 12),
                          const Icon(Icons.chat_bubble_outline, size: 18),
                          const SizedBox(width: 4),
                          Text('${post.commentCount}'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
