import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vibetreck/features/auth/application/auth_controller.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/features/tracking/presentation/widgets/flex_overlay_card.dart';
import 'package:vibetreck/shared/services/media_upload_service.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

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
  final _picker = ImagePicker();
  OverlayTemplate _template = OverlayTemplate.verticalBar;
  Uint8List? _selectedMediaBytes;
  String _selectedMediaLabel = 'Ride card';
  bool _publishing = false;
  bool _pickingMedia = false;
  String? _status;

  Future<void> _pickMedia(ImageSource source) async {
    setState(() {
      _pickingMedia = true;
      _status = null;
    });
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedMediaBytes = bytes;
        _selectedMediaLabel = source == ImageSource.camera
            ? 'Camera photo selected'
            : 'Gallery photo selected';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _pickingMedia = false);
      }
    }
  }

  Future<void> _publish({
    required Uint8List bytes,
    required Map<String, dynamic> stats,
    required String fileExtension,
    required String contentType,
  }) async {
    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) return;
    setState(() {
      _publishing = true;
      _status = null;
    });
    try {
      final imageUrl = await ref
          .read(mediaUploadServiceProvider)
          .uploadPostMedia(
            userId: user.id,
            sessionId: widget.sessionId,
            bytes: bytes,
            fileExtension: fileExtension,
            contentType: contentType,
          );
      await ref.read(feedActionsProvider).createPost(
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

  Future<void> _publishCurrent(Map<String, dynamic> stats) async {
    if (_selectedMediaBytes != null) {
      await _publish(
        bytes: _selectedMediaBytes!,
        stats: stats,
        fileExtension: 'jpg',
        contentType: 'image/jpeg',
      );
      return;
    }

    final bytes = await _screenshotController.capture();
    if (bytes == null) {
      setState(() => _status = 'Failed to render overlay');
      return;
    }
    await _publish(
      bytes: bytes,
      stats: stats,
      fileExtension: 'png',
      contentType: 'image/png',
    );
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
              if (_selectedMediaBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.memory(
                      _selectedMediaBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ] else ...[
                Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: FlexOverlayCard(
                      session: session,
                      template: _template,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                _selectedMediaLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickingMedia
                        ? null
                        : () => _pickMedia(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Pick from gallery'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickingMedia
                        ? null
                        : () => _pickMedia(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                  TextButton.icon(
                    onPressed: _pickingMedia
                        ? null
                        : () {
                            setState(() {
                              _selectedMediaBytes = null;
                              _selectedMediaLabel = 'Ride card';
                            });
                          },
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Use ride card'),
                  ),
                ],
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
                onSelectionChanged: _selectedMediaBytes != null
                    ? null
                    : (selection) => setState(() => _template = selection.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  hintText: 'Evening climb. Strong legs today.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _publishing ? null : () => _publishCurrent(stats),
                child: Text(_publishing ? 'Publishing...' : 'Publish to Feed'),
              ),
              if (_status != null) ...[
                const SizedBox(height: 10),
                Text(_status!, style: const TextStyle(color: Colors.white70)),
              ],
            ],
          );
        },
        error: (error, _) => AppErrorState(message: error.toString()),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
