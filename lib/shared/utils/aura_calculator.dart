int calculateAura({
  required double distanceMeters,
  required int durationSeconds,
  required double avgSpeedMps,
  double zoneMultiplier = 1.0,
}) {
  final distanceScore = (distanceMeters / 100).round();
  final effortScore = (durationSeconds / 60).round();
  final speedBonus = (avgSpeedMps * 6).round();
  final raw = (distanceScore + effortScore + speedBonus) * zoneMultiplier;
  return raw.clamp(0, 100000).round();
}
