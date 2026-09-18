import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../data/models.dart';
import '../../../data/photo_repository.dart';
import 'swipe_card.dart';
import 'swipe_physics.dart';

/// Lets the ✕/✓ buttons and undo drive the stack through the same animation
/// and callback path as a finger swipe.
class CardStackController {
  _CardStackState? _state;

  bool get isAnimating => _state?._flying ?? false;

  /// Slides the top card off-screen, then fires [CardStack.onSwiped].
  void swipe(Decision decision) => _state?._flyOut(decision);

  /// Slides the (new) top card back in from the side it left through.
  void animateReturn(Decision from) => _state?._animateReturn(from);
}

class CardStack extends StatefulWidget {
  const CardStack({
    super.key,
    required this.cards,
    required this.controller,
    required this.onSwiped,
    required this.onTap,
  });

  /// Remaining cards, top first.
  final List<AssetEntity> cards;
  final CardStackController controller;
  final void Function(AssetEntity asset, Decision decision) onSwiped;
  final void Function(AssetEntity asset) onTap;

  /// Cards actually built: the top one, two peeking behind it, and one hidden
  /// exactly behind the last so it's already there when the stack advances.
  static const builtCards = 4;

  @override
  State<CardStack> createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with SingleTickerProviderStateMixin {
  /// The top card's displacement from the middle. Held in a [ValueNotifier]
  /// rather than widget state so a drag frame only re-runs the small transform
  /// builders — the photos themselves are passed through as `child` and are
  /// never rebuilt while swiping.
  final ValueNotifier<Offset> _offset = ValueNotifier(Offset.zero);

  /// Drives a 0→1 interpolation between [_from] and [_to]. Unbounded so a
  /// spring may overshoot slightly without being clamped into a hard stop.
  late final AnimationController _anim = AnimationController.unbounded(vsync: this)..addListener(_onTick);

  /// Critically damped: settles quickly without wobbling, so a card slides
  /// home instead of bouncing.
  static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 1);

  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  bool _animating = false;
  Size _size = Size.zero;
  bool _flying = false;

  /// Card that has slid off but may not have left [widget.cards] yet.
  String? _dismissedId;

  List<AssetEntity> get _visible =>
      widget.cards.where((a) => a.id != _dismissedId).take(CardStack.builtCards).toList(growable: false);

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(CardStack old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller._state = null;
      widget.controller._state = this;
    }
    if (_dismissedId != null && widget.cards.every((a) => a.id != _dismissedId)) _dismissedId = null;
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _anim.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onTick() {
    if (_animating) _offset.value = Offset.lerp(_from, _to, _anim.value)!;
  }

  void _stop() {
    _animating = false;
    _anim.stop();
  }

  /// Timed slide toward [target]. Returns false if interrupted.
  Future<bool> _slideTo(Offset target, {required Duration duration, required Curve curve}) async {
    _from = _offset.value;
    _to = target;
    _animating = true;
    _anim.value = 0;
    try {
      await _anim.animateTo(1, duration: duration, curve: curve).orCancel;
      return true;
    } on TickerCanceled {
      return false;
    }
  }

  /// Spring toward [target], starting at the finger's release [velocity] so
  /// there's no jolt between dragging and settling.
  Future<void> _springTo(Offset target, Offset velocity) async {
    _from = _offset.value;
    _to = target;
    final delta = _to - _from;
    final distanceSq = delta.distanceSquared;
    // Velocity projected onto the path, in "fractions of the path per second".
    final v = distanceSq == 0 ? 0.0 : (velocity.dx * delta.dx + velocity.dy * delta.dy) / distanceSq;
    _animating = true;
    _anim.value = 0;
    try {
      await _anim.animateWith(SpringSimulation(_spring, 0, 1, v)).orCancel;
    } on TickerCanceled {
      // Grabbed again mid-slide.
    }
  }

  // ---- Gestures -----------------------------------------------------------

  void _onPanStart(DragStartDetails _) {
    if (_flying) return;
    _stop(); // catch a card that is still sliding home
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_flying) return;
    _offset.value += d.delta;
  }

  void _onPanEnd(DragEndDetails d) {
    if (_flying) return;
    final velocity = d.velocity.pixelsPerSecond;
    final decision = SwipePhysics.resolve(dx: _offset.value.dx, velocityX: velocity.dx, width: _size.width);
    if (decision == null) {
      _springTo(Offset.zero, velocity);
    } else {
      _flyOut(decision, velocity: velocity);
    }
  }

  // ---- Commit / return ----------------------------------------------------

  Future<void> _flyOut(Decision decision, {Offset velocity = Offset.zero}) async {
    final visible = _visible;
    if (_flying || visible.isEmpty || _size.isEmpty) return;
    final asset = visible.first;
    _stop();
    _flying = true;

    final sign = decision == Decision.keep ? 1.0 : -1.0;
    final exitX = sign * _size.width * 1.4;
    final remaining = (exitX - _offset.value.dx).abs();

    final Duration duration;
    final Curve curve;
    final double exitY;
    if (velocity.dx.abs() >= 800 && velocity.dx.sign == sign) {
      // Thrown: keep the finger's exact speed and heading (linear, so the
      // first frame moves as fast as the last drag event did).
      final seconds = (remaining / velocity.dx.abs()).clamp(0.12, 0.35);
      duration = Duration(microseconds: (seconds * 1e6).round());
      curve = Curves.linear;
      exitY = _offset.value.dy + velocity.dy * seconds;
    } else {
      // Button or slow release: accelerate away from rest.
      duration = const Duration(milliseconds: 260);
      curve = Curves.easeInCubic;
      exitY = _offset.value == Offset.zero ? _size.height * 0.04 : _offset.value.dy * 1.3;
    }

    final completed = await _slideTo(Offset(exitX, exitY), duration: duration, curve: curve);
    // Interrupted (e.g. by an undo) — that path owns the card now.
    if (!mounted || !completed || !_flying) return;

    _animating = false;
    _offset.value = Offset.zero;
    _flying = false;
    setState(() => _dismissedId = asset.id);
    widget.onSwiped(asset, decision);
  }

  void _animateReturn(Decision from) {
    if (_size.isEmpty) return;
    _stop();
    final sign = from == Decision.keep ? 1.0 : -1.0;
    _flying = false;
    _offset.value = Offset(sign * _size.width * 1.2, _size.height * 0.04);
    setState(() => _dismissedId = null);
    _slideTo(Offset.zero, duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic);
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final visible = _visible;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Back to front. Every card uses the same subtree shape, so a card's
            // loaded image survives being promoted to the top.
            for (var i = visible.length - 1; i >= 0; i--) _buildCard(visible[i], i),
          ],
        );
      },
    );
  }

  Widget _buildCard(AssetEntity asset, int index) {
    final isTop = index == 0;
    return Positioned.fill(
      key: ValueKey(asset.id),
      child: IgnorePointer(
        ignoring: !isTop,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isTop && !_flying ? () => widget.onTap(asset) : null,
          onPanStart: isTop ? _onPanStart : null,
          onPanUpdate: isTop ? _onPanUpdate : null,
          onPanEnd: isTop ? _onPanEnd : null,
          child: ValueListenableBuilder<Offset>(
            valueListenable: _offset,
            // Built once and reused on every frame of the swipe.
            child: SwipeCardFace(asset: asset),
            builder: (context, offset, face) {
              final progress = SwipePhysics.progress(offset.dx, _size.width);
              if (!isTop) {
                // Cards behind slide up a step as the top card is dragged away.
                // The hidden 4th card sits exactly behind the 3rd until revealed.
                final depth = (index - progress).clamp(0.0, 2.0);
                return Transform.translate(
                  offset: Offset(0, depth * 14),
                  child: Transform.scale(scale: 1 - depth * 0.05, alignment: Alignment.bottomCenter, child: face),
                );
              }
              return Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  // Pivot below the card so it swings like it's held from underneath.
                  angle: SwipePhysics.rotation(offset.dx, _size.width),
                  alignment: const Alignment(0, 1.4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [face!, SwipeFeedback(progress: offset.dx.sign * progress)],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
