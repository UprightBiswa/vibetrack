import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibetreck/core/bloc/view_status.dart';
import 'package:vibetreck/core/di/app_services.dart';
import 'package:vibetreck/core/network/network_status_provider.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/feed/presentation/feed_screen.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';
import 'package:vibetreck/shared/widgets/route_snapshot_card.dart';

class FeedPostDetailScreen extends StatefulWidget {
  const FeedPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<FeedPostDetailScreen> createState() => _FeedPostDetailScreenState();
}

class _FeedPostDetailScreenState extends State<FeedPostDetailScreen> {
  final _commentController = TextEditingController();
  final _shareController = ScreenshotController();
  bool _sharing = false;
  String? _status;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(FeedPostDetailCubit cubit) async {
    final body = _commentController.text.trim();
    if (body.isEmpty) {
      setState(() => _status = 'Write a comment first.');
      return;
    }

    try {
      await cubit.addComment(body);
      _commentController.clear();
      if (!mounted) return;
      setState(() => _status = 'Comment posted');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    }
  }

  Future<void> _sharePost(String username, Map<String, dynamic> stats) async {
    setState(() {
      _sharing = true;
      _status = null;
    });
    try {
      final bytes = await _shareController.capture(pixelRatio: 2.5);
      if (bytes == null) {
        throw Exception('Failed to render share card.');
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/vibetrack-post-${widget.postId}.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$username just shared a VibeTrack route flex.',
      );
      if (!mounted) return;
      setState(() => _status = 'Share sheet opened');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeedPostDetailCubit(
        postId: widget.postId,
        repository: context.read<AppServices>().feedRepository,
        connectivityCubit: context.read<ConnectivityCubit>(),
        feedCubit: context.read<FeedCubit>(),
      )..load(),
      child: BlocBuilder<FeedPostDetailCubit, FeedPostDetailState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Activity Detail'),
              actions: [
                IconButton(
                  onPressed: () => context.push(AppRoutes.notifications),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            body: switch (state.status) {
              ViewStatus.loading => const Center(child: CircularProgressIndicator()),
              ViewStatus.failure => AppErrorState(
                  message: state.errorMessage ?? 'Failed to load post',
                  onRetry: () => context.read<FeedPostDetailCubit>().load(),
                ),
              _ => _buildContent(context, state),
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, FeedPostDetailState state) {
    final post = state.post;
    if (post == null) {
      return const AppErrorState(message: 'Post not found');
    }
    final stats = post.statsJson;
    final title = (stats['title'] ?? '').toString();
    final details = (stats['details'] ?? post.caption).toString();
    final routeGeojson = (stats['routeGeojson'] as Map<String, dynamic>?) ?? const {};
    final cubit = context.read<FeedPostDetailCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF17181B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.push(AppRoutes.publicProfile(post.userId)),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
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
                        Text(post.username, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d • HH:mm').format(post.createdAt),
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
              IconButton(
                onPressed: cubit.toggleLike,
                icon: Icon(
                  post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.likedByMe ? Colors.redAccent : Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RouteSnapshotCard(
          routeGeojson: routeGeojson,
          label: 'ROUTE SNAPSHOT',
          height: 250,
          showExpand: true,
        ),
        const SizedBox(height: 16),
        if (post.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PostMedia(post: post, stats: stats, aspectRatio: 4 / 3),
          ),
        if (post.imageUrl.isNotEmpty) const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF17181B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  details,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _MetricTile(label: 'Distance', value: '${stats['distanceKm'] ?? '-'} km'),
                  _MetricTile(label: 'Time', value: '${stats['durationMin'] ?? '-'} min'),
                  _MetricTile(label: 'Elevation', value: '${stats['elevationM'] ?? '--'} m'),
                  _MetricTile(label: 'Speed', value: '${stats['avgSpeedKmh'] ?? '--'} km/h'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Screenshot(
          controller: _shareController,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF141414), Color(0xFF1D3B2A), Color(0xFF0A0A0A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text('VibeTrack', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text(post.username, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 14),
                RouteSnapshotCard(
                  routeGeojson: routeGeojson,
                  label: 'SHARE ROUTE',
                  height: 180,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: cubit.toggleLike,
              icon: Icon(
                post.likedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.likedByMe ? Colors.redAccent : null,
              ),
              label: Text(post.likedByMe ? 'Unlike' : 'Like'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _sharing ? null : () => _sharePost(post.username, stats),
              icon: const Icon(Icons.share_outlined),
              label: Text(_sharing ? 'Sharing...' : 'Share Route'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            labelText: 'Add to the pulse...',
            hintText: 'Strong ride. Clean route. Peak effort.',
          ),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: state.isSubmittingComment ? null : () => _submitComment(cubit),
          child: Text(state.isSubmittingComment ? 'Posting...' : 'Post Comment'),
        ),
        if (_status != null) ...[
          const SizedBox(height: 8),
          Text(_status!, style: const TextStyle(color: Colors.white70)),
        ],
        const SizedBox(height: 24),
        Text('Pulse Comments', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (state.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No comments yet. Start the conversation.'),
          )
        else
          Column(
            children: state.comments.map((comment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF17181B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withValues(alpha: 0.12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        comment.username.isEmpty ? 'R' : comment.username[0].toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(comment.username)),
                              Text(
                                DateFormat('HH:mm').format(comment.createdAt),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white54,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.body,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primary,
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
  }
}
