import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/shared/models/feed_post.dart';
import 'package:vibetreck/shared/widgets/app_empty_state.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';
import 'package:vibetreck/shared/widgets/route_snapshot_card.dart';

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: state.posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 22),
                  itemBuilder: (context, index) => _FeedPostCard(post: state.posts[index]),
                ),
              ),
      },
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final title = (post.statsJson['title'] ?? '').toString().trim();
    final details = (post.statsJson['details'] ?? post.caption).toString().trim();
    final activityType = (post.statsJson['activityType'] ?? 'ride').toString();
    final routeGeojson = (post.statsJson['routeGeojson'] as Map<String, dynamic>?) ?? const {};
    final distance = (post.statsJson['distanceKm'] ?? '-').toString();
    final avgSpeed = (post.statsJson['avgSpeedKmh'] ?? '').toString();
    final elevation = (post.statsJson['elevationM'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17181B),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.push(AppRoutes.publicProfile(post.userId)),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          post.username.isEmpty ? 'R' : post.username[0].toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_labelForActivity(activityType)} • ${DateFormat('MMM d • HH:mm').format(post.createdAt)}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white54,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _labelForActivity(activityType).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.push(AppRoutes.feedPost(post.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RouteSnapshotCard(
                routeGeojson: routeGeojson,
                label: 'ROUTE FIRST',
                height: 220,
              ),
            ),
          ),
          if (post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.push(AppRoutes.feedPost(post.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: PostMedia(post: post, stats: post.statsJson, aspectRatio: 16 / 10),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          height: 1.02,
                        ),
                  ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatGlass(
                        label: 'Distance',
                        value: '$distance km',
                        accent: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatGlass(
                        label: 'Avg Speed',
                        value: avgSpeed.isEmpty ? '--' : '$avgSpeed km/h',
                        accent: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                if (elevation.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _StatGlass(
                    label: 'Elevation',
                    value: '$elevation m',
                    accent: AppTheme.glowSky,
                    expanded: true,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.read<FeedCubit>().toggleLike(post.id),
                      icon: Icon(
                        post.likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: post.likedByMe ? Colors.redAccent : Colors.white70,
                      ),
                    ),
                    Text('${post.likeCount}', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.feedPost(post.id)),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    Text('${post.commentCount}', style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.feedPost(post.id)),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostMedia extends StatelessWidget {
  const PostMedia({
    super.key,
    required this.post,
    required this.stats,
    this.aspectRatio = 3 / 4,
  });

  final FeedPost post;
  final Map<String, dynamic> stats;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrl;
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return AspectRatio(
        aspectRatio: aspectRatio,
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

class _StatGlass extends StatelessWidget {
  const _StatGlass({
    required this.label,
    required this.value,
    required this.accent,
    this.expanded = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

String _labelForActivity(String raw) {
  switch (raw) {
    case 'cycle':
      return 'Cycling';
    case 'run':
      return 'Running';
    case 'walk':
      return 'Walking';
    default:
      return 'Ride';
  }
}
