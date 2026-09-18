import 'package:flutter/material.dart';

/// Pushed pages slide in from the right while the page underneath slides a
/// little to the left; popping reverses it.
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();

  static final _enter = Tween(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));
  static final _exit = Tween(
    begin: Offset.zero,
    end: const Offset(-0.3, 0),
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: secondaryAnimation.drive(_exit),
      child: SlideTransition(
        position: animation.drive(_enter),
        // Cache the page as a layer so sliding it only moves pixels instead of
        // repainting the whole page every frame.
        child: RepaintBoundary(
          child: DecoratedBox(
            // Edge shadow so the incoming page reads as sliding over the old one.
            decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 24)]),
            child: child,
          ),
        ),
      ),
    );
  }
}
