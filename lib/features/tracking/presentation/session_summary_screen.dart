import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/tracking/presentation/widgets/flex_overlay_card.dart';
import 'package:vibetreck/shared/services/media_upload_service.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  final _screenshotController = ScreenshotController();
  final _captionController = TextEditingController();
  OverlayTemplate _template = OverlayTemplate.verticalBar;
  bool _publishing = false;
  String? _status;

  Future<void> _publish(Uint8List bytes, Map<String, dynamic> stats) async {
    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) return;
    setState(() {
      _publishing = true;
      _status = null;
    });
    try {
      final imageUrl = await ref
          .read(mediaUploadServiceProvider)
          .uploadOverlay(
            userId: user.id,
            sessionId: widget.sessionId,
            bytes: bytes,
          );
      await ref
          .read(feedActionsProvider)
          .createPost(
            sessionId: widget.sessionId,
            imageUrl: imageUrl,
            caption: _captionController.text.trim(),
            statsJson: stats,
          );
      if (mounted) {
        setState(() => _status = 'Posted to feed');
        context.go('/feed');
      }
    } catch (err) {
      setState(() => _status = err.toString());
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionByIdProvider(widget.sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Session Summary')),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }
          final stats = {
            'distanceKm': (session.distanceM / 1000).toStringAsFixed(2),
            'durationMin': (session.durationS / 60).toStringAsFixed(0),
            'calories': session.calories,
          };
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: FlexOverlayCard(session: session, template: _template),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<OverlayTemplate>(
                segments: const [
                  ButtonSegment(
                    value: OverlayTemplate.verticalBar,
                    label: Text('Vertical'),
                  ),
                  ButtonSegment(
                    value: OverlayTemplate.cornerBadge,
                    label: Text('Corner'),
                  ),
                  ButtonSegment(
                    value: OverlayTemplate.monoStamp,
                    label: Text('Mono'),
                  ),
                ],
                selected: {_template},
                onSelectionChanged: (selection) =>
                    setState(() => _template = selection.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'Evening climb. Strong legs today.',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _publishing
                    ? null
                    : () async {
                        final bytes = await _screenshotController.capture();
                        if (bytes == null) {
                          setState(() => _status = 'Failed to render overlay');
                          return;
                        }
                        await _publish(bytes, stats);
                      },
                child: Text(_publishing ? 'Publishing...' : 'Publish to Feed'),
              ),
              if (_status != null) ...[
                const SizedBox(height: 10),
                Text(_status!, style: const TextStyle(color: Colors.white70)),
              ],
            ],
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
