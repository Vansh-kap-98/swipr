import 'package:flutter_test/flutter_test.dart';
import 'package:swipr/core/format.dart';
import 'package:swipr/data/database/daos.dart';
import 'package:swipr/data/models.dart';
import 'package:swipr/features/swipe_session/widgets/swipe_physics.dart';

void main() {
  group('SwipePhysics.resolve', () {
    const w = 400.0;

    test('springs back below distance and velocity thresholds', () {
      expect(SwipePhysics.resolve(dx: 100, velocityX: 200, width: w), isNull);
      expect(SwipePhysics.resolve(dx: -139, velocityX: 0, width: w), isNull);
    });

    test('commits past 35% of the width', () {
      expect(SwipePhysics.resolve(dx: 141, velocityX: 0, width: w), Decision.keep);
      expect(SwipePhysics.resolve(dx: -141, velocityX: 0, width: w), Decision.delete);
    });

    test('a fast fling commits regardless of distance', () {
      expect(SwipePhysics.resolve(dx: 20, velocityX: 1500, width: w), Decision.keep);
      expect(SwipePhysics.resolve(dx: -5, velocityX: -1500, width: w), Decision.delete);
    });

    test('a fling back toward center does not flip the decision', () {
      expect(SwipePhysics.resolve(dx: 60, velocityX: -1500, width: w), isNull);
      expect(SwipePhysics.resolve(dx: 200, velocityX: -1500, width: w), Decision.keep);
    });
  });

  test('PhotoScope round-trips through its encoded form', () {
    const scopes = [
      PhotoScope.all(),
      PhotoScope.album(id: 'abc-123', name: 'Screenshots | 2024'),
      PhotoScope.month(year: 2025, month: 2),
    ];
    for (final s in scopes) {
      expect(PhotoScope.decode(s.encode()), s);
    }
    expect(const PhotoScope.month(year: 2025, month: 2).label, 'February 2025');
    expect(PhotoScope.decode('garbage|x'), isNull);
  });

  group('computeStreak', () {
    final now = DateTime(2026, 9, 17, 10);

    test('counts consecutive days ending today', () {
      final times = [DateTime(2026, 9, 17, 8), DateTime(2026, 9, 16, 23), DateTime(2026, 9, 15), DateTime(2026, 9, 13)];
      expect(computeStreak(times, now), 3);
    });

    test('a streak ending yesterday is still alive', () {
      expect(computeStreak([DateTime(2026, 9, 16), DateTime(2026, 9, 15)], now), 2);
    });

    test('broken streak is zero', () {
      expect(computeStreak([DateTime(2026, 9, 14)], now), 0);
    });
  });

  test('formatBytes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2 KB');
    expect(formatBytes(128 * 1024 * 1024), '128 MB');
    expect(formatBytes((1.5 * 1024 * 1024 * 1024).round()), '1.5 GB');
  });
}
