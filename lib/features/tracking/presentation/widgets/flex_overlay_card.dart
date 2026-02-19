import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibetreck/shared/models/activity_session.dart';

enum OverlayTemplate { verticalBar, cornerBadge, monoStamp }

class FlexOverlayCard extends StatelessWidget {
  const FlexOverlayCard({
    super.key,
    required this.session,
    required this.template,
  });

  final ActivitySession session;
  final OverlayTemplate template;

  @override
  Widget build(BuildContext context) {
    switch (template) {
      case OverlayTemplate.verticalBar:
        return _VerticalOverlay(session: session);
      case OverlayTemplate.cornerBadge:
        return _CornerOverlay(session: session);
      case OverlayTemplate.monoStamp:
        return _MonoOverlay(session: session);
    }
  }
}

class _BaseCanvas extends StatelessWidget {
  const _BaseCanvas({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 460,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1B1B), Color(0xFF070707)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white12),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _VerticalOverlay extends StatelessWidget {
  const _VerticalOverlay({required this.session});
  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    return _BaseCanvas(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  '${(session.distanceM / 1000).toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    color: Color(0xFFCCFF00),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _SessionStats(session: session),
          ],
        ),
      ),
    );
  }
}

class _CornerOverlay extends StatelessWidget {
  const _CornerOverlay({required this.session});
  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    return _BaseCanvas(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: _SessionStats(session: session),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${session.type.name.toUpperCase()} SESSION',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonoOverlay extends StatelessWidget {
  const _MonoOverlay({required this.session});
  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    return _BaseCanvas(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VIBETRACK',
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Text(
              '${(session.distanceM / 1000).toStringAsFixed(2)} KM',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'TIME ${session.durationS ~/ 60}m ${session.durationS % 60}s',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              DateFormat('MMM d, y • HH:mm').format(session.endedAt),
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionStats extends StatelessWidget {
  const _SessionStats({required this.session});
  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Duration: ${session.durationS ~/ 60} min'),
        Text('Calories: ${session.calories}'),
        Text('Pace: ${session.avgPace.toStringAsFixed(2)}'),
      ],
    );
  }
}
