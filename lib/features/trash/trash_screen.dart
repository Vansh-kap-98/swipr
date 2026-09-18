import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/photo_image.dart';
import '../../shared_widgets/slide_motion.dart';
import 'freed_celebration.dart';
import 'trash_controller.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(trashItemsProvider);
    final summary = ref.watch(trashSummaryProvider).value ?? TrashSummary.empty;
    final hasItems = summary.count > 0;

    final Widget body = switch (items) {
      AsyncValue(:final Object error) when !items.hasValue => EmptyState(
        key: const ValueKey('error'),
        emoji: '⚠️',
        title: 'Couldn\'t load the trash',
        message: '$error',
      ),
      AsyncValue(:final List<TrashItem> value) when value.isEmpty => const EmptyState(
        key: ValueKey('empty'),
        emoji: '✨',
        title: 'Nothing marked for deletion',
        message: 'Photos you swipe left on wait here until you empty the trash.',
      ),
      AsyncValue(:final List<TrashItem> value) => _TrashGrid(key: const ValueKey('grid'), items: value),
      _ => const SlideLoader(key: ValueKey('loading')),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          SlideSwitcher(
            from: const Offset(40, 0),
            child: hasItems
                ? TextButton(
                    key: const ValueKey('restore'),
                    onPressed: () => _restoreAll(context, ref, items.value ?? const []),
                    child: const Text('Restore all'),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: SlideSwitcher(child: body)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: AnimatedSlide(
                // Slides up when there's something to delete, down out of view
                // when the trash is empty.
                offset: hasItems ? Offset.zero : const Offset(0, 2),
                duration: Motion.medium,
                curve: Motion.curve,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.delete,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text('Empty Trash (${summary.count} · ${formatBytes(summary.bytes)})'),
                  onPressed: hasItems ? () => commitTrash(context, ref) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreAll(BuildContext context, WidgetRef ref, List<TrashItem> items) async {
    final ids = [for (final i in items) i.assetId];
    await ref.read(trashActionsProvider).restore(ids);
    if (context.mounted) showSlideToast(context, 'Restored ${plural(ids.length, 'photo')}');
  }
}

/// Runs the batch OS delete and shows the outcome. Shared by the Trash
/// screen and the end-of-session prompt.
Future<void> commitTrash(BuildContext context, WidgetRef ref) async {
  final result = await ref.read(trashActionsProvider).commitAll();
  if (!context.mounted) return;
  switch (result) {
    case CommitCancelled():
      showSlideToast(context, 'Nothing was deleted. Your trash is still here.');
    case CommitDone(:final freed, :final remaining):
      await showFreedCelebration(context, freed);
      if (remaining > 0 && context.mounted) {
        showSlideToast(context, '${plural(remaining, 'photo')} couldn\'t be deleted and are still in the trash.');
      }
  }
}

class _TrashGrid extends StatelessWidget {
  const _TrashGrid({super.key, required this.items});

  final List<TrashItem> items;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Tap a photo to restore it. Nothing is deleted until you empty the trash.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 120),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _TrashTile(key: ValueKey(items[i].assetId), item: items[i]),
          ),
        ),
      ],
    );
  }
}

class _TrashTile extends ConsumerStatefulWidget {
  const _TrashTile({super.key, required this.item});

  final TrashItem item;

  @override
  ConsumerState<_TrashTile> createState() => _TrashTileState();
}

class _TrashTileState extends ConsumerState<_TrashTile> {
  bool _leaving = false;

  Future<void> _restore() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    // Let it slide out to the right ("keep" side) before the grid reflows.
    await Future<void>.delayed(Motion.medium);
    await ref.read(trashActionsProvider).restore([widget.item.assetId]);
    if (mounted) showSlideToast(context, 'Restored — it\'ll be kept');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Restore photo',
      child: PressSlide(
        onTap: _restore,
        child: AnimatedSlide(
          offset: _leaving ? const Offset(1.2, 0) : Offset.zero,
          duration: Motion.medium,
          curve: Curves.easeInCubic,
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoImage(assetId: widget.item.assetId),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatBytes(widget.item.fileSizeBytes),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.restore_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
