import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/routing/routes.dart';
import '../core/theme/app_theme.dart';
import '../features/trash/trash_controller.dart';
import 'slide_motion.dart';

/// Always-visible "🗑 14 photos · 128 MB" indicator; taps through to Trash.
/// New totals slide up into place like an odometer.
class TrashPill extends ConsumerWidget {
  const TrashPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(trashSummaryProvider).value;
    final count = summary?.count ?? 0;
    final active = count > 0;
    final label = active ? '🗑 ${plural(count, 'item')} · ${formatBytes(summary!.bytes)}' : '🗑 0';

    return Semantics(
      button: true,
      label: 'Trash: $label',
      excludeSemantics: true,
      child: PressSlide(
        onTap: () => Routes.trash(context),
        nudge: const Offset(0, 0.08),
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: active ? AppColors.delete.withValues(alpha: 0.18) : AppColors.surfaceHigh,
          ),
          child: AnimatedSize(
            duration: Motion.medium,
            curve: Motion.curve,
            child: SlideSwitcher(
              clip: true,
              from: const Offset(0, 18),
              child: Text(
                label,
                key: ValueKey(label),
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: active ? const Color(0xFFFF8A80) : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
