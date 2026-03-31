import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/feed/presentation/feed_screen.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class FeedPostDetailScreen extends ConsumerStatefulWidget {
  const FeedPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<FeedPostDetailScreen> createState() => _FeedPostDetailScreenState();
}

class _FeedPostDetailScreenState extends ConsumerState<FeedPostDetailScreen> {
  final _commentController = TextEditingController();
  final _shareController = ScreenshotController();
  bool _submitting = false;
  bool _sharing = false;
  String? _status;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) {
      setState(() => _status = 'Write a comment first.');
      return;
    }

    setState(() {
      _submitting = true;
      _status = null;
    });

    try {
      await ref.read(feedActionsProvider).addComment(
            postId: widget.postId,
            body: body,
          );
      _commentController.clear();
      if (!mounted) return;
      setState(() => _status = 'Comment posted');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
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
        text:
            '$username just shared a VibeTrack activity: ${stats['distanceKm'] ?? '-'} km in ${stats['durationMin'] ?? '-'} min.',
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
    final postAsync = ref.watch(feedPostProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: error.toString()),
        data: (post) {
          final stats = post.statsJson;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(post.username),
                subtitle: Text(DateFormat('MMM d - HH:mm').format(post.createdAt)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.likedByMe ? Icons.favorite : Icons.favorite_border,
                      color: post.likedByMe ? Colors.redAccent : null,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likeCount}'),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PostMedia(post: post, stats: stats),
              ),
              const SizedBox(height: 12),
              Text(post.caption),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricChip(label: 'Distance', value: '${stats['distanceKm'] ?? '-'} km'),
                  _MetricChip(label: 'Duration', value: '${stats['durationMin'] ?? '-'} min'),
                  _MetricChip(label: 'Calories', value: '${stats['calories'] ?? '-'} kcal'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Share Card Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Screenshot(
                controller: _shareController,
                child: _PostShareCard(post: post),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ref.read(feedActionsProvider).like(post.id),
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
                    label: Text(_sharing ? 'Sharing...' : 'Share'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Add a comment',
                  hintText: 'Strong ride. Nice route.',
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submitting ? null : _submitComment,
                child: Text(_submitting ? 'Posting...' : 'Post Comment'),
              ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(_status!, style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 24),
              Text(
                'Comments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              commentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(postCommentsProvider(widget.postId)),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No comments yet. Start the conversation.'),
                    );
                  }
                  return Column(
                    children: comments.map((comment) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(comment.username),
                          subtitle: Text(comment.body),
                          trailing: Text(
                            DateFormat('HH:mm').format(comment.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}

class _PostShareCard extends StatelessWidget {
  const _PostShareCard({required this.post});

  final dynamic post;

  @override
  Widget build(BuildContext context) {
    final stats = (post.statsJson as Map<String, dynamic>);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF141414), Color(0xFF1D3B2A), Color(0xFF0A0A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Text(
                'VibeTrack',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                post.username,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PostMedia(post: post, stats: stats),
          ),
          const SizedBox(height: 16),
          Text(
            post.caption.isEmpty ? 'Ride completed' : post.caption,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(label: 'Distance', value: '${stats['distanceKm'] ?? '-'} km'),
              _MetricChip(label: 'Duration', value: '${stats['durationMin'] ?? '-'} min'),
              _MetricChip(label: 'Calories', value: '${stats['calories'] ?? '-'} kcal'),
            ],
          ),
        ],
      ),
    );
  }
}
