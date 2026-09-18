import 'dart:math' as math;

import '../../../data/models.dart';

/// Pure swipe rules, kept free of widgets so they're easy to test.
abstract final class SwipePhysics {
  /// Fraction of the card width a drag must pass to commit.
  static const distanceThreshold = 0.35;

  /// Horizontal fling speed (logical px/s) that commits regardless of distance.
  static const velocityThreshold = 900.0;

  /// Rotation at a full card-width drag.
  static const maxRotation = math.pi / 12; // 15°

  /// Whether a released drag commits, and to which side. Returns null to
  /// spring back.
  static Decision? resolve({required double dx, required double velocityX, required double width}) {
    if (width <= 0) return null;
    final flung = velocityX.abs() >= velocityThreshold;
    // A fling against the drag direction cancels rather than flipping sides.
    if (flung && (dx == 0 || dx.sign == velocityX.sign)) {
      return velocityX > 0 ? Decision.keep : Decision.delete;
    }
    if (dx.abs() >= width * distanceThreshold) {
      return dx > 0 ? Decision.keep : Decision.delete;
    }
    return null;
  }

  static double rotation(double dx, double width) => width <= 0 ? 0 : (dx / width).clamp(-1.5, 1.5) * maxRotation;

  /// 0 → 1 as the drag approaches the commit threshold; drives the tint.
  static double progress(double dx, double width) =>
      width <= 0 ? 0 : (dx.abs() / (width * distanceThreshold)).clamp(0.0, 1.0);
}
