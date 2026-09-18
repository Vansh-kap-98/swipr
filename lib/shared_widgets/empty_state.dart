import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'slide_motion.dart';

/// Centered message whose parts slide up into place one after another.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title, this.message, this.action, this.extra});

  final String emoji;
  final String title;
  final String? message;
  final Widget? action;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    var step = 0;
    Widget slide(Widget child) => SlideIn(
      delay: Duration(milliseconds: 60 * step++),
      child: child,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            slide(Text(emoji, style: const TextStyle(fontSize: 56))),
            const SizedBox(height: 16),
            slide(
              Text(
                title,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              slide(
                Text(
                  message!,
                  style: text.bodyMedium?.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (extra != null) ...[const SizedBox(height: 24), slide(extra!)],
            if (action != null) ...[const SizedBox(height: 24), slide(action!)],
          ],
        ),
      ),
    );
  }
}
