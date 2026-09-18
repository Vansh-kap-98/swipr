import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models.dart';
import '../../../data/photo_repository.dart';
import '../../../shared_widgets/photo_image.dart';

/// One full-bleed photo card. [dragProgress] (-1…1, sign = direction) drives
/// the live green/red feedback while dragging.
///
/// The photo, shadow and rounded clip sit in their own [RepaintBoundary], so
/// while a card is dragged the GPU just moves a cached layer; only the thin
/// feedback overlay is repainted each frame.
class SwipeCard extends StatelessWidget {
  const SwipeCard({super.key, required this.asset, this.dragProgress = 0});

  final AssetEntity asset;
  final double dragProgress;

  static const radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final strength = dragProgress.abs();
    final decision = dragProgress > 0 ? Decision.keep : Decision.delete;
    final color = decision == Decision.keep ? AppColors.keep : AppColors.delete;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: _CardFace(asset: asset)),
        if (strength > 0) ...[
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: color.withValues(alpha: 0.22 * strength),
                border: Border.all(color: color.withValues(alpha: strength), width: 3),
              ),
            ),
          ),
          Positioned(
            top: 36,
            left: decision == Decision.keep ? 24 : null,
            right: decision == Decision.delete ? 24 : null,
            child: IgnorePointer(
              // The stamp slides in from its own side as the drag builds up.
              child: Transform.translate(
                offset: Offset((decision == Decision.keep ? -1 : 1) * 40 * (1 - strength), 0),
                child: Opacity(
                  opacity: strength,
                  child: Transform.rotate(
                    angle: decision == Decision.keep ? -0.3 : 0.3,
                    child: _Stamp(label: decision == Decision.keep ? 'KEEP' : 'DELETE', color: color),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SwipeCard.radius),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SwipeCard.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoImage(asset: asset, size: PhotoImageSize.card),
            Positioned(left: 0, right: 0, bottom: 0, child: _Caption(asset: asset)),
          ],
        ),
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
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 4),
        borderRadius: BorderRadius.circular(10),
      ),
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
