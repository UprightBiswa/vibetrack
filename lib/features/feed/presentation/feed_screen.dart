import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/shared/models/feed_post.dart';
import 'package:vibetreck/shared/widgets/app_empty_state.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<FeedCubit>();
    if (cubit.state.status == ViewStatus.initial) {
      cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FeedCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Flex Feed')),
      body: switch (state.status) {
        ViewStatus.loading => const Center(child: CircularProgressIndicator()),
        ViewStatus.failure => AppErrorState(
            message: state.errorMessage ?? 'Failed to load feed',
            onRetry: () => context.read<FeedCubit>().load(),
          ),
        _ => state.posts.isEmpty
            ? const AppEmptyState(
                title: 'No posts yet',
                message: 'Complete a session and publish your first ride to the feed.',
                icon: Icons.photo_library_outlined,
              )
            : RefreshIndicator(
                onRefresh: () => context.read<FeedCubit>().refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.posts.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = state.posts[index];
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
                            onTap: () => context.push(AppRoutes.publicProfile(post.userId)),
                            title: Text(post.username),
                            subtitle: Text(
                              DateFormat('MMM d - HH:mm').format(post.createdAt),
                            ),
                            trailing: const Chip(label: Text('Zone Guardian')),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push(AppRoutes.feedPost(post.id)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: PostMedia(post: post, stats: stats),
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
                                onPressed: () => context.read<FeedCubit>().toggleLike(post.id),
                                icon: Icon(
                                  post.likedByMe ? Icons.favorite : Icons.favorite_border,
                                  color: post.likedByMe ? Colors.redAccent : null,
                                ),
                              ),
                              Text('${post.likeCount}'),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () => context.push(AppRoutes.feedPost(post.id)),
                                icon: const Icon(Icons.chat_bubble_outline),
                              ),
                              Text('${post.commentCount}'),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () => context.push(AppRoutes.feedPost(post.id)),
                                icon: const Icon(Icons.share_outlined),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      },
    );
  }
}

class PostMedia extends StatelessWidget {
  const PostMedia({super.key, required this.post, required this.stats});

  final FeedPost post;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrl;
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => FallbackCard(stats: stats),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }
    return FallbackCard(stats: stats);
  }
}

class FallbackCard extends StatelessWidget {
  const FallbackCard({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
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
    );
  }
}
