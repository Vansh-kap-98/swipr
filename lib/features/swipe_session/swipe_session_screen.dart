import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../data/photo_repository.dart';
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/photo_image.dart';
import '../../shared_widgets/slide_motion.dart';
import '../../shared_widgets/trash_pill.dart';
import '../trash/trash_controller.dart';
import '../trash/trash_screen.dart';
import 'swipe_session_controller.dart';
import 'widgets/card_stack.dart';
import 'widgets/zoom_view.dart';

class SwipeSessionScreen extends ConsumerStatefulWidget {
  const SwipeSessionScreen({super.key, required this.scope, this.resumeSessionId});

  final PhotoScope scope;
  final String? resumeSessionId;

  @override
  ConsumerState<SwipeSessionScreen> createState() => _SwipeSessionScreenState();
}

class _SwipeSessionScreenState extends ConsumerState<SwipeSessionScreen> {
  final _stack = CardStackController();
  final _warmed = <String>{};
  bool _endHandled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(swipeSessionProvider.notifier).start(widget.scope, resumeSessionId: widget.resumeSessionId),
    );
  }

  SwipeSessionController get _controller => ref.read(swipeSessionProvider.notifier);

  /// Fetches and decodes the next few cards ahead of time, so a card is fully
  /// rendered before it slides into view — no decode work on swipe frames.
  void _warmUpcoming(List<AssetEntity> queue) {
    final repo = ref.read(photoRepositoryProvider);
    for (final asset in queue.take(CardStack.builtCards + 2)) {
      if (!_warmed.add(asset.id)) continue;
      repo.cardImage(asset).then((bytes) {
        if (bytes == null) {
          _warmed.remove(asset.id);
        } else if (mounted) {
          precacheImage(cardImageProvider(context, bytes, asset), context);
        }
      });
    }
  }

  void _onSwiped(AssetEntity asset, Decision decision) {
    HapticFeedback.selectionClick();
    _controller.decide(asset, decision);
  }

  void _undo() {
    final from = _controller.peekUndo;
    if (from == null) return;
    HapticFeedback.lightImpact();
    _controller.undo();
    _stack.animateReturn(from);
  }

  Future<void> _onFinished() async {
    if (_endHandled) return;
    _endHandled = true;
    await _controller.finish();
    if (!mounted) return;

    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final pending = await ref.read(trashDaoProvider).pendingSummary();
    if (!mounted || !settings.promptDeleteOnSessionEnd || pending.count == 0) return;

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => _DeleteNowSheet(pending: pending),
    );
    if (confirm == true && mounted) await commitTrash(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(swipeSessionProvider);
    // The provider may still hold a previous session for a frame or two.
    final isCurrent = s.scope == widget.scope;

    ref.listen(swipeSessionProvider, (prev, next) {
      if (next.scope != widget.scope) return;
      if (!identical(prev?.queue, next.queue)) _warmUpcoming(next.queue);
      if (next.isFinished && !(prev?.isFinished ?? false)) _onFinished();
    });

    final Widget body = switch ((isCurrent, s)) {
      (false, _) || (_, SwipeSessionState(loading: true)) => const SlideLoader(key: ValueKey('loading')),
      (_, SwipeSessionState(error: final Object e)) => EmptyState(
        key: const ValueKey('error'),
        emoji: '⚠️',
        title: 'Couldn\'t load this album',
        message: '$e',
        action: FilledButton(
          onPressed: () => _controller.start(widget.scope, resumeSessionId: widget.resumeSessionId),
          child: const Text('Try again'),
        ),
      ),
      (_, SwipeSessionState(isFinished: true)) => _FinishedView(key: const ValueKey('finished'), state: s),
      _ => _SwipeBody(key: const ValueKey('swipe'), state: s, stack: _stack, onSwiped: _onSwiped, onUndo: _undo),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scope.label, overflow: TextOverflow.ellipsis),
        actions: const [TrashPill(), SizedBox(width: 12)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: AnimatedSlide(
            offset: isCurrent && !s.loading && s.total > 0 ? Offset.zero : const Offset(0, -1),
            duration: Motion.medium,
            curve: Motion.curve,
            child: _ProgressHeader(state: s),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SlideSwitcher(from: const Offset(0, 40), child: body),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final SwipeSessionState state;

  @override
  Widget build(BuildContext context) {
    final current = state.total == 0 ? 0 : (state.reviewed + 1).clamp(1, state.total);
    final counter = state.queue.isEmpty ? '${state.total} / ${state.total}' : '$current / ${state.total}';
    return SizedBox(
      height: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: state.total == 0 ? 0 : state.reviewed / state.total),
                  duration: Motion.medium,
                  curve: Motion.curve,
                  builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Each new position slides up, like a ticker.
            SlideSwitcher(
              clip: true,
              from: const Offset(0, 14),
              duration: Motion.fast,
              alignment: Alignment.centerRight,
              child: Text(
                counter,
                key: ValueKey(counter),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBody extends StatelessWidget {
  const _SwipeBody({super.key, required this.state, required this.stack, required this.onSwiped, required this.onUndo});

  final SwipeSessionState state;
  final CardStackController stack;
  final void Function(AssetEntity, Decision) onSwiped;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            child: CardStack(
              cards: state.queue,
              controller: stack,
              onSwiped: onSwiped,
              onTap: (asset) => showZoomView(context, asset),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: Icons.close_rounded,
                color: AppColors.delete,
                size: 68,
                label: 'Delete',
                nudge: const Offset(-0.12, 0),
                onPressed: () => stack.swipe(Decision.delete),
              ),
              const SizedBox(width: 28),
              _RoundButton(
                icon: Icons.undo_rounded,
                color: AppColors.muted,
                size: 50,
                label: 'Undo',
                nudge: const Offset(-0.12, 0),
                onPressed: state.canUndo ? onUndo : null,
              ),
              const SizedBox(width: 28),
              _RoundButton(
                icon: Icons.check_rounded,
                color: AppColors.keep,
                size: 68,
                label: 'Keep',
                nudge: const Offset(0.12, 0),
                onPressed: () => stack.swipe(Decision.keep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular action button. Instead of a ripple, it nudges toward the side
/// its action sends the card.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.label,
    required this.nudge,
    this.onPressed,
  });

  final IconData icon;
  final Color color;
  final double size;
  final String label;
  final Offset nudge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressSlide(
        onTap: onPressed,
        nudge: nudge,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          width: size,
          height: size,
          decoration: ShapeDecoration(
            color: AppColors.surface,
            shape: CircleBorder(
              side: BorderSide(color: color.withValues(alpha: enabled ? 0.6 : 0.15), width: 2),
            ),
          ),
          child: Icon(icon, size: size * 0.5, color: enabled ? color : color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class _FinishedView extends ConsumerWidget {
  const _FinishedView({super.key, required this.state});

  final SwipeSessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = ref.watch(trashSummaryProvider).value ?? TrashSummary.empty;
    final nothingHere = state.total == 0;
    return EmptyState(
      emoji: nothingHere ? '📭' : '🎉',
      title: nothingHere ? 'Nothing here' : 'All done with ${state.scope!.label}',
      message: nothingHere
          ? 'This album is empty, or Swipr can\'t see what\'s in it.'
          : state.kept + state.deleted == 0
          ? 'You\'ve already reviewed everything here.'
          : 'Session complete.',
      extra: state.kept + state.deleted == 0
          ? null
          : _SessionSummary(kept: state.kept, marked: state.deleted, pending: trash),
      action: Column(
        children: [
          if (trash.count > 0)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.delete, foregroundColor: Colors.white),
              onPressed: () => Routes.trash(context),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text('Review trash (${trash.count})'),
            ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to albums')),
        ],
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.kept, required this.marked, required this.pending});

  final int kept;
  final int marked;
  final TrashSummary pending;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(
          children: [
            stat('${kept + marked}', 'reviewed', Colors.white),
            stat('$kept', 'kept', AppColors.keep),
            stat('$marked', 'marked', AppColors.delete),
            stat(formatBytes(pending.bytes), 'to free', AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _DeleteNowSheet extends StatelessWidget {
  const _DeleteNowSheet({required this.pending});

  final TrashSummary pending;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delete ${plural(pending.count, 'item')} now?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You have ${plural(pending.count, 'item')} marked for deletion (${formatBytes(pending.bytes)}). '
              'Your phone will ask you to confirm.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.delete,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete now'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Later')),
          ],
        ),
      ),
    );
  }
}
