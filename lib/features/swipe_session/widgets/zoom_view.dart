import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/photo_repository.dart';
import '../../../shared_widgets/photo_image.dart';
import '../../../shared_widgets/slide_motion.dart';

Future<void> showZoomView(BuildContext context, AssetEntity asset) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => ZoomView(asset: asset),
      // Slides up from the bottom; closing slides it back down.
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: anim.drive(
          Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: RepaintBoundary(child: child),
      ),
    ),
  );
}

/// Full-resolution view with pinch-to-zoom; drag down (when not zoomed in) to
/// dismiss back to the card.
class ZoomView extends ConsumerStatefulWidget {
  const ZoomView({super.key, required this.asset});

  final AssetEntity asset;

  @override
  ConsumerState<ZoomView> createState() => _ZoomViewState();
}

class _ZoomViewState extends ConsumerState<ZoomView> {
  final _transform = TransformationController();
  late final Future<Uint8List?> _bytes = ref.read(photoRepositoryProvider).zoomImage(widget.asset);

  double _dismissDy = 0;
  bool _dragging = false;

  bool get _atBaseScale => _transform.value.getMaxScaleOnAxis() <= 1.01;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _onUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount != 1 || !_atBaseScale) return;
    setState(() {
      _dragging = true;
      _dismissDy = (_dismissDy + d.focalPointDelta.dy).clamp(0, double.infinity);
    });
  }

  void _onEnd(ScaleEndDetails d) {
    if (!_dragging) return;
    final fling = d.velocity.pixelsPerSecond.dy > 700;
    if (_dismissDy > 120 || fling) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragging = false;
        _dismissDy = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final fade = (1 - _dismissDy / (height * 0.6)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: fade),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: _dragging ? Duration.zero : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _dismissDy, 0),
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: 8,
              onInteractionUpdate: _onUpdate,
              onInteractionEnd: _onEnd,
              child: SizedBox.expand(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The card image is already decoded, so the view is never
                    // empty; the sharper full-resolution render lands on top.
                    PhotoImage(
                      asset: widget.asset,
                      size: PhotoImageSize.card,
                      fit: BoxFit.contain,
                      placeholderColor: Colors.transparent,
                    ),
                    FutureBuilder<Uint8List?>(
                      future: _bytes,
                      builder: (context, snap) {
                        final bytes = snap.data;
                        if (bytes != null) {
                          return Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            frameBuilder: (context, child, frame, sync) =>
                                frame == null && !sync ? const SizedBox.shrink() : child,
                          );
                        }
                        if (snap.connectionState == ConnectionState.done) return const SizedBox.shrink();
                        return const Align(alignment: Alignment(0, 0.9), child: SlideLoader());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Opacity(
                opacity: fade,
                child: Semantics(
                  button: true,
                  label: 'Close',
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
