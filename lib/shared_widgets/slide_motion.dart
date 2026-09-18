import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shared motion: everything in the app enters, leaves and reacts by sliding.
abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}

/// Slides [child] into place from [from] (logical pixels) once, after [delay].
class SlideIn extends StatefulWidget {
  const SlideIn({
    super.key,
    required this.child,
    this.from = const Offset(0, 28),
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Offset from;
  final Duration delay;
  final Duration duration;

  @override
  State<SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<SlideIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration);
  late final _t = CurvedAnimation(parent: _controller, curve: Motion.curve);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () => _controller.forward());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _t.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: widget.from * (1 - _t.value), child: child),
      ),
    );
  }
}

/// Like [AnimatedSwitcher], but the new child slides in from [from] while the
/// old one slides out the opposite way — so content always moves in one
/// direction instead of cross-fading. Give children distinct keys.
class SlideSwitcher extends StatelessWidget {
  const SlideSwitcher({
    super.key,
    required this.child,
    this.from = const Offset(0, 24),
    this.duration = Motion.medium,
    this.alignment = Alignment.center,
    this.clip = false,
  });

  final Widget child;
  final Offset from;
  final Duration duration;
  final Alignment alignment;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final switcher = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Motion.curve,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final incoming = child.key == this.child.key;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value;
            final offset = incoming ? from * (1 - t) : -from * (1 - t);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(offset: offset, child: child),
            );
          },
        );
      },
      child: child,
    );
    return clip ? ClipRect(child: switcher) : switcher;
  }
}

/// Indeterminate loader: a bar sliding along a track.
class SlideLoader extends StatelessWidget {
  const SlideLoader({super.key, this.width = 96});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        child: ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(minHeight: 4)),
      ),
    );
  }
}

/// Press feedback without ripples: the child nudges by [nudge] (a fraction of
/// its size) while pressed and slides back on release.
class PressSlide extends StatefulWidget {
  const PressSlide({super.key, required this.child, this.onTap, this.nudge = const Offset(0, 0.03)});

  final Widget child;
  final VoidCallback? onTap;
  final Offset nudge;

  @override
  State<PressSlide> createState() => _PressSlideState();
}

class _PressSlideState extends State<PressSlide> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        offset: _pressed ? widget.nudge : Offset.zero,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

OverlayEntry? _activeToast;

/// A small message that slides up from the bottom and slides back down.
/// Replaces Material snackbars, which fade.
void showSlideToast(BuildContext context, String message, {Duration hold = const Duration(milliseconds: 2400)}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _activeToast?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      hold: hold,
      onDone: () {
        if (_activeToast == entry) _activeToast = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _activeToast = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.hold, required this.onDone});

  final String message;
  final Duration hold;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final _slide = Tween(
    begin: const Offset(0, 1.6),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Motion.curve, reverseCurve: Curves.easeInCubic));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future<void>.delayed(widget.hold);
    if (!mounted) return;
    await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: AppColors.surfaceHigh,
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}
