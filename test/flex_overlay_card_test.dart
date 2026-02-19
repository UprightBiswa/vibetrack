import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibetreck/features/tracking/presentation/widgets/flex_overlay_card.dart';
import 'package:vibetreck/shared/models/activity_session.dart';

void main() {
  final session = ActivitySession(
    id: 's1',
    userId: 'u1',
    type: ActivityType.cycle,
    startedAt: DateTime(2026, 1, 1, 8),
    endedAt: DateTime(2026, 1, 1, 8, 30),
    distanceM: 12400,
    durationS: 1800,
    avgPace: 4.2,
    calories: 330,
    routeGeojson: const {'type': 'LineString', 'coordinates': []},
  );

  testWidgets('renders vertical template', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlexOverlayCard(
              session: session,
              template: OverlayTemplate.verticalBar,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('KM'), findsOneWidget);
  });
}
