import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/photo_repository.dart';
import '../../../shared_widgets/photo_image.dart';

const double kCardRadius = 22;

/// The photo itself: image, caption, rounded clip and shadow.
///
/// This never changes while a card is dragged, so [CardStack] passes it as the
/// `child` of its animation builders. Flutter then reuses this whole subtree
/// (including the decoded image) instead of rebuilding it every frame, and the
/// [RepaintBoundary] lets the GPU move it as a cached layer.
class SwipeCardFace extends StatelessWidget {
  const SwipeCardFace({super.key, required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoImage(asset: asset, size: PhotoImageSize.card),
              Positioned(left: 0, right: 0, bottom: 0, child: _Caption(asset: asset)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The green/red feedback drawn over the top card while it's being dragged.
/// [progress] is -1…1; the sign picks the side.
class SwipeFeedback extends StatelessWidget {
  const SwipeFeedback({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final strength = progress.abs();
    if (strength == 0) return const SizedBox.shrink();

    final keep = progress > 0;
    final color = keep ? AppColors.keep : AppColors.delete;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kCardRadius),
              color: color.withValues(alpha: 0.22 * strength),
              border: Border.all(color: color.withValues(alpha: strength), width: 3),
            ),
          ),
          Positioned(
            top: 36,
            left: keep ? 24 : null,
            right: keep ? null : 24,
            // The stamp slides in from its own side as the drag builds up.
            child: Transform.translate(
              offset: Offset((keep ? -1 : 1) * 40 * (1 - strength), 0),
              child: Opacity(
                opacity: strength,
                child: Transform.rotate(
                  angle: keep ? -0.3 : 0.3,
                  child: _Stamp(label: keep ? 'KEEP' : 'DELETE', color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: color, width: 4), borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.asset});

  final AssetEntity asset;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final d = asset.createDateTime;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xB3000000), Colors.transparent],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 32, 18, 14),
        child: Row(
          children: [
            Text(
              '${_months[d.month - 1]} ${d.day}, ${d.year}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const Spacer(),
            Text(
              '${asset.orientatedWidth}×${asset.orientatedHeight}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.zoom_out_map_rounded, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
