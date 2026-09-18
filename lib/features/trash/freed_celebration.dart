import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../shared_widgets/slide_motion.dart';

/// The payoff moment after a batch delete: the panel slides up, then the
/// check, the amount freed and the photo count slide in one after another.
Future<void> showFreedCelebration(BuildContext context, TrashSummary freed) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, _, _) => _Celebration(freed: freed),
    transitionBuilder: (context, anim, _, child) => SlideTransition(
      position: anim.drive(Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Motion.curve))),
      child: child,
    ),
  );
}

class _Celebration extends StatelessWidget {
  const _Celebration({required this.freed});

  final TrashSummary freed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SlideIn(
                from: const Offset(-120, 0),
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 520),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.keep,
                    boxShadow: [
                      BoxShadow(color: AppColors.keep.withValues(alpha: 0.45), blurRadius: 40, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 72, color: Colors.black),
                ),
              ),
              const SizedBox(height: 28),
              SlideIn(
                delay: const Duration(milliseconds: 320),
                child: Text(
                  'Freed ${formatBytes(freed.bytes)}',
                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              SlideIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'across ${plural(freed.count, 'photo')}',
                  style: text.titleMedium?.copyWith(color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 32),
              SlideIn(
                delay: const Duration(milliseconds: 480),
                child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Nice')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
