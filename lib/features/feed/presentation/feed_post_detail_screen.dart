import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  bool _submitting = false;
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(post.username),
                subtitle: Text(DateFormat('MMM d - HH:mm').format(post.createdAt)),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PostMedia(post: post, stats: post.statsJson),
              ),
              const SizedBox(height: 12),
              Text(post.caption),
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
