import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:vibetreck/core/di/app_services.dart';
import 'package:vibetreck/core/routing/app_routes.dart';
import 'package:vibetreck/core/theme/app_theme.dart';
import 'package:vibetreck/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:vibetreck/features/feed/application/feed_controller.dart';
import 'package:vibetreck/features/tracking/application/tracking_controller.dart';
import 'package:vibetreck/shared/models/activity_session.dart';
import 'package:vibetreck/shared/utils/aura_calculator.dart';
import 'package:vibetreck/shared/widgets/app_error_state.dart';

class SessionSummaryScreen extends StatefulWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final _screenshotController = ScreenshotController();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _selectedMediaBytes;
  bool _publishing = false;
  bool _pickingMedia = false;
  bool _activityTypeTouched = false;
  String? _status;
  late Future<ActivitySession?> _sessionFuture;
  late ActivityType _selectedType;
  _FlexCardStyle _selectedCardStyle = _FlexCardStyle.spotlight;

  @override
  void initState() {
    super.initState();
    final trackingState = context.read<TrackingCubit>().state;
    _selectedType = trackingState.lastSessionId == widget.sessionId
        ? trackingState.selectedType
        : ActivityType.cycle;
    _sessionFuture = context.read<TrackingCubit>().loadSession(widget.sessionId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    setState(() {
      _pickingMedia = true;
      _status = null;
    });
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _selectedMediaBytes = bytes);
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _pickingMedia = false);
      }
    }
  }

  Future<void> _publish(ActivitySession session, TrackingState trackingState) async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final services = context.read<AppServices>();
    final selectedType = _resolveSelectedType(session, trackingState);
    final elevation = trackingState.lastSessionId == widget.sessionId ? trackingState.elevationGainM : 0.0;
    final aura = trackingState.lastSessionId == widget.sessionId
        ? trackingState.lastAuraAwarded
        : calculateAura(
            distanceMeters: session.distanceM,
            durationSeconds: session.durationS,
            avgSpeedMps: session.durationS > 0 ? session.distanceM / session.durationS : 0,
          );
    setState(() {
      _publishing = true;
      _status = null;
    });
    try {
      final bytes = _selectedMediaBytes ??
          await _screenshotController.captureFromWidget(
            Material(
              color: Colors.transparent,
              child: _FlexComposerPreview(
                session: session,
                elevationM: elevation,
                auraGained: aura,
                activityType: selectedType,
                title: _titleController.text.trim(),
                caption: _detailsController.text.trim(),
                locationLabel: _locationController.text.trim(),
                zoneLabel: _zoneLabel(session),
                cardStyle: _selectedCardStyle,
              ),
            ),
            context: context,
            pixelRatio: 2.4,
            delay: const Duration(milliseconds: 80),
          );
      final imageUrl = await services.mediaUploadService.uploadPostMedia(
        userId: user.id,
        sessionId: widget.sessionId,
        bytes: bytes,
        fileExtension: _selectedMediaBytes == null ? 'png' : 'jpg',
        contentType: _selectedMediaBytes == null ? 'image/png' : 'image/jpeg',
      );

      final title = _titleController.text.trim();
      final details = _detailsController.text.trim();
      final locationLabel = _locationController.text.trim();
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);
      final stats = {
        'title': title,
        'details': details,
        'locationLabel': locationLabel,
        'tags': tags,
        'cardStyle': _selectedCardStyle.name,
        'zoneLabel': _zoneLabel(session),
        'activityType': selectedType.name,
        'distanceKm': (session.distanceM / 1000).toStringAsFixed(2),
        'durationMin': (session.durationS / 60).toStringAsFixed(0),
        'calories': session.calories,
        'avgSpeedKmh': ((session.durationS > 0 ? session.distanceM / session.durationS : 0) * 3.6)
            .toStringAsFixed(1),
        'elevationM': elevation.toStringAsFixed(0),
        'auraGained': aura,
        'routeGeojson': session.routeGeojson,
      };

      await context.read<FeedCubit>().createPost(
            sessionId: widget.sessionId,
            imageUrl: imageUrl,
            caption: details.isNotEmpty ? details : title,
            statsJson: stats,
          );
      if (!mounted) return;
      context.go(AppRoutes.feed);
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = context.watch<TrackingCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Vibe'),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.feed),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: FutureBuilder<ActivitySession?>(
        future: _sessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorState(message: snapshot.error.toString());
          }
          final session = snapshot.data;
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }
          final effectiveElevation = trackingState.lastSessionId == widget.sessionId
              ? trackingState.elevationGainM
              : 0.0;
          final effectiveAura = trackingState.lastSessionId == widget.sessionId
              ? trackingState.lastAuraAwarded
              : calculateAura(
                  distanceMeters: session.distanceM,
                  durationSeconds: session.durationS,
                  avgSpeedMps: session.durationS > 0 ? session.distanceM / session.durationS : 0,
                );
          final selectedType = _resolveSelectedType(session, trackingState);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHARE YOUR VIBE',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        height: 0.95,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Finish line achievement unlocked',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white54,
                        letterSpacing: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                _selectedMediaBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.memory(_selectedMediaBytes!, fit: BoxFit.cover),
                        ),
                      )
                    : _FlexComposerPreview(
                        session: session,
                        elevationM: effectiveElevation,
                        auraGained: effectiveAura,
                        activityType: selectedType,
                        title: _titleController.text.trim(),
                        caption: _detailsController.text.trim(),
                        locationLabel: _locationController.text.trim(),
                        zoneLabel: _zoneLabel(session),
                        cardStyle: _selectedCardStyle,
                      ),
                const SizedBox(height: 14),
                Text(
                  'Share Card Style',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _FlexCardStyle.values
                      .map(
                        (style) => _CardStyleChip(
                          style: style,
                          selected: _selectedCardStyle == style,
                          onTap: () => setState(() => _selectedCardStyle = style),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickingMedia ? null : () => _pickMedia(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Add media'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickingMedia ? null : () => _pickMedia(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take photo'),
                    ),
                    TextButton.icon(
                      onPressed: _pickingMedia
                          ? null
                          : () => setState(() => _selectedMediaBytes = null),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Use route card'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _StaticRoutePreview(
                  routeGeojson: session.routeGeojson,
                  label: 'ROUTE SNAPSHOT',
                  height: 220,
                ),
                const SizedBox(height: 12),
                _StatsPreviewCard(
                  session: session,
                  elevationM: effectiveElevation,
                  auraGained: effectiveAura,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ActivityType.values
                      .where((type) => type != ActivityType.gym)
                      .map(
                        (type) => SizedBox(
                          width: 110,
                          child: _ActivityChoice(
                            type: type,
                            selected: selectedType == type,
                            onTap: () => setState(() {
                              _activityTypeTouched = true;
                              _selectedType = type;
                            }),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                  decoration: const InputDecoration(
                    hintText: 'GIVE IT A TITLE...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _detailsController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Caption / vibe / ride notes...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Location / route area',
                    prefixIcon: const Icon(Icons.place_outlined),
                    suffixText: _zoneLabel(session),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    hintText: 'Tags: sunrise, cardio, city-loop',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _publishing ? null : () => _publish(session, trackingState),
                    child: Text(_publishing ? 'Posting...' : 'Post to Feed'),
                  ),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _status!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  ActivityType _resolveSelectedType(
    ActivitySession session,
    TrackingState trackingState,
  ) {
    if (_activityTypeTouched) return _selectedType;
    if (trackingState.lastSessionId == widget.sessionId) {
      return _selectedType;
    }
    return session.type;
  }

  String _zoneLabel(ActivitySession session) {
    final km = session.distanceM / 1000;
    if (km >= 20) return 'Zone Titan';
    if (km >= 10) return 'Zone Breaker';
    if (km >= 5) return 'Zone Push';
    return 'Zone Start';
  }
}

class _FlexComposerPreview extends StatelessWidget {
  const _FlexComposerPreview({
    required this.session,
    required this.elevationM,
    required this.auraGained,
    required this.activityType,
    required this.title,
    required this.caption,
    required this.locationLabel,
    required this.zoneLabel,
    required this.cardStyle,
  });

  final ActivitySession session;
  final double elevationM;
  final int auraGained;
  final ActivityType activityType;
  final String title;
  final String caption;
  final String locationLabel;
  final String zoneLabel;
  final _FlexCardStyle cardStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _cardGradient(cardStyle),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? 'Route Flex' : title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _activityLabel(activityType).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StaticRoutePreview(
            routeGeojson: session.routeGeojson,
            height: 220,
            label: 'VIBE ROUTE',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewBadge(
                icon: Icons.place_outlined,
                label: locationLabel.isEmpty ? 'Location pending' : locationLabel,
              ),
              _PreviewBadge(
                icon: Icons.shield_outlined,
                label: zoneLabel,
              ),
              _PreviewBadge(
                icon: Icons.style_outlined,
                label: cardStyle.label,
              ),
            ],
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.35,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ComposerMetric(
                  label: 'Distance',
                  value: '${(session.distanceM / 1000).toStringAsFixed(2)} km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComposerMetric(
                  label: 'Elevation',
                  value: '${elevationM.toStringAsFixed(0)} m',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComposerMetric(
                  label: 'Aura',
                  value: '+$auraGained',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsPreviewCard extends StatelessWidget {
  const _StatsPreviewCard({
    required this.session,
    required this.elevationM,
    required this.auraGained,
  });

  final ActivitySession session;
  final double elevationM;
  final int auraGained;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF17181B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryValue(
            label: 'Distance',
            value: '${(session.distanceM / 1000).toStringAsFixed(2)} KM',
          ),
          const SizedBox(height: 18),
          _SummaryValue(
            label: 'Elevation',
            value: '${elevationM.toStringAsFixed(0)} M',
          ),
          const SizedBox(height: 18),
          _SummaryValue(
            label: 'Aura Gained',
            value: '+$auraGained',
            accent: AppTheme.secondary,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verified by Pulse-GPS',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _FlexCardStyle {
  spotlight('Spotlight'),
  explorer('Explorer'),
  proof('Proof Card');

  const _FlexCardStyle(this.label);
  final String label;
}

class _CardStyleChip extends StatelessWidget {
  const _CardStyleChip({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final _FlexCardStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.14) : const Color(0xFF17181B),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          style.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppTheme.primary : Colors.white70,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StaticRoutePreview extends StatelessWidget {
  const _StaticRoutePreview({
    required this.routeGeojson,
    required this.height,
    this.label,
  });

  final Map<String, dynamic> routeGeojson;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final points = _sessionRoutePoints(routeGeojson);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101318),
            Color(0xFF181D24),
            Color(0xFF101318),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RoutePainter(points),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (label != null)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                _RouteLegendDot(
                  color: Colors.white,
                  label: 'Start',
                ),
                const SizedBox(width: 10),
                _RouteLegendDot(
                  color: AppTheme.primary,
                  label: 'Finish',
                ),
                const Spacer(),
                Text(
                  points.length >= 2 ? '${points.length} GPS points' : 'No route points',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLegendDot extends StatelessWidget {
  const _RouteLegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.points);

  final List<LatLng> points;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          const Color(0x33000000),
          AppTheme.primary.withValues(alpha: 0.08),
          const Color(0x22000000),
        ],
        const [0.0, 0.52, 1.0],
      );
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final dx = size.width * i / 5;
      final dy = size.height * i / 5;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (points.length < 2) return;

    final projected = _projectPoints(points, size);
    final path = ui.Path()..moveTo(projected.first.dx, projected.first.dy);
    for (final point in projected.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.primary.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        projected.first,
        projected.last,
        [
          Colors.white,
          AppTheme.primary,
        ],
      );
    canvas.drawPath(path, routePaint);

    final startPaint = Paint()..color = Colors.white;
    final finishPaint = Paint()..color = AppTheme.primary;
    canvas.drawCircle(projected.first, 5, startPaint);
    canvas.drawCircle(projected.last, 6, finishPaint);
    canvas.drawCircle(
      projected.last,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.primary.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

List<Offset> _projectPoints(List<LatLng> points, Size size) {
  final lats = points.map((point) => point.latitude);
  final lngs = points.map((point) => point.longitude);
  final minLat = lats.reduce((a, b) => a < b ? a : b);
  final maxLat = lats.reduce((a, b) => a > b ? a : b);
  final minLng = lngs.reduce((a, b) => a < b ? a : b);
  final maxLng = lngs.reduce((a, b) => a > b ? a : b);
  final latSpan = (maxLat - minLat).abs() < 0.0001 ? 0.0001 : (maxLat - minLat).abs();
  final lngSpan = (maxLng - minLng).abs() < 0.0001 ? 0.0001 : (maxLng - minLng).abs();
  const padding = 22.0;
  final width = size.width - (padding * 2);
  final height = size.height - (padding * 2);

  return points.map((point) {
    final x = ((point.longitude - minLng) / lngSpan) * width + padding;
    final y = ((maxLat - point.latitude) / latSpan) * height + padding;
    return Offset(x.toDouble(), y.toDouble());
  }).toList(growable: false);
}

List<LatLng> _sessionRoutePoints(Map<String, dynamic> routeGeojson) {
  final coordinates = routeGeojson['coordinates'];
  if (coordinates is! List) return const [];
  return coordinates
      .whereType<List>()
      .where((point) => point.length >= 2)
      .map(
        (point) => LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        ),
      )
      .toList(growable: false);
}

class _ActivityChoice extends StatelessWidget {
  const _ActivityChoice({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ActivityType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.14)
              : const Color(0xFF17181B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_activityIcon(type), color: selected ? AppTheme.primary : Colors.white54),
            const SizedBox(height: 6),
            Text(
              _activityLabel(type).toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? AppTheme.primary : Colors.white60,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerMetric extends StatelessWidget {
  const _ComposerMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 0.8,
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

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    this.accent = Colors.white,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accent == Colors.white ? Colors.white54 : accent,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

IconData _activityIcon(ActivityType type) {
  switch (type) {
    case ActivityType.cycle:
      return Icons.directions_bike_rounded;
    case ActivityType.run:
      return Icons.directions_run_rounded;
    case ActivityType.walk:
      return Icons.directions_walk_rounded;
    case ActivityType.gym:
      return Icons.fitness_center_rounded;
  }
}

String _activityLabel(ActivityType type) {
  switch (type) {
    case ActivityType.cycle:
      return 'Cycling';
    case ActivityType.run:
      return 'Running';
    case ActivityType.walk:
      return 'Walking';
    case ActivityType.gym:
      return 'Gym';
  }
}

LinearGradient _cardGradient(_FlexCardStyle style) {
  switch (style) {
    case _FlexCardStyle.spotlight:
      return const LinearGradient(
        colors: [
          Color(0xFF13161D),
          Color(0xFF1A1F29),
          Color(0xFF101318),
        ],
        stops: [0, 0.55, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case _FlexCardStyle.explorer:
      return const LinearGradient(
        colors: [
          Color(0xFF0E171A),
          Color(0xFF17252B),
          Color(0xFF0D1218),
        ],
        stops: [0, 0.5, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case _FlexCardStyle.proof:
      return const LinearGradient(
        colors: [
          Color(0xFF181414),
          Color(0xFF241D1A),
          Color(0xFF111214),
        ],
        stops: [0, 0.55, 1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  }
}
