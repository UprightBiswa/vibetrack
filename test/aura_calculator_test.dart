import 'package:flutter_test/flutter_test.dart';
import 'package:vibetreck/shared/utils/aura_calculator.dart';

void main() {
  test('returns positive aura for valid session values', () {
    final aura = calculateAura(
      distanceMeters: 5000,
      durationSeconds: 1500,
      avgSpeedMps: 3.3,
    );
    expect(aura, greaterThan(0));
  });

  test('is deterministic and bounded', () {
    final aura = calculateAura(
      distanceMeters: 1000000,
      durationSeconds: 100000,
      avgSpeedMps: 12,
    );
    expect(aura, lessThanOrEqualTo(100000));
  });
}
