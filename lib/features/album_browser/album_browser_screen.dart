import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/permissions/photo_permission.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../data/photo_repository.dart';
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/photo_image.dart';
import '../../shared_widgets/slide_motion.dart';
import '../../shared_widgets/trash_pill.dart';
import '../stats/settings_sheet.dart';
import '../trash/trash_controller.dart';

final albumsProvider = FutureProvider<List<AlbumInfo>>((ref) => ref.watch(photoRepositoryProvider).albums());

final monthBucketsProvider = FutureProvider<List<MonthBucket>>(
  (ref) => ref.watch(photoRepositoryProvider).monthBuckets(),
);

final unfinishedSessionProvider = StreamProvider<SessionRecord?>(
  (ref) => ref.watch(sessionsDaoProvider).watchLatestUnfinished(),
);

class AlbumBrowserScreen extends ConsumerStatefulWidget {
  const AlbumBrowserScreen({super.key});

  @override
  ConsumerState<AlbumBrowserScreen> createState() => _AlbumBrowserScreenState();
}

class _AlbumBrowserScreenState extends ConsumerState<AlbumBrowserScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Settle any delete that was interrupted last time the app ran.
    Future.microtask(() => ref.read(trashActionsProvider).reconcile());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // New photos may have been taken while the app was in the background.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    ref.invalidate(albumsProvider);
    ref.invalidate(monthBucketsProvider);
  }

  Future<void> _openScope(PhotoScope scope, {String? resumeSessionId}) async {
    await Routes.swipe(context, scope, resumeSessionId: resumeSessionId);
    // Deletions may have changed album counts.
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isLimited = ref.watch(photoPermissionProvider).value == PermissionState.limited;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Swipr', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          actions: [
            const TrashPill(),
            _AppBarAction(icon: Icons.insights_rounded, label: 'Stats', onTap: () => Routes.stats(context)),
            _AppBarAction(icon: Icons.tune_rounded, label: 'Settings', onTap: () => showSettingsSheet(context)),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Albums'),
              Tab(text: 'By Date'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Banners slide down into place and push the grid down smoothly.
            AnimatedSize(
              duration: Motion.medium,
              curve: Motion.curve,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  SlideSwitcher(
                    clip: true,
                    from: const Offset(0, -40),
                    child: isLimited
                        ? _LimitedAccessBanner(
                            key: const ValueKey('limited'),
                            onSelectMore: () async {
                              await ref.read(photoRepositoryProvider).selectMorePhotos();
                              _refresh();
                            },
                          )
                        : const SizedBox(key: ValueKey('full'), width: double.infinity),
                  ),
                  _ContinueCard(onResume: (session) => _openScope(session.scope!, resumeSessionId: session.id)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AlbumsTab(onOpen: _openScope, onRetry: _refresh),
                  _MonthsTab(onOpen: _openScope, onRetry: _refresh),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressSlide(
        onTap: onTap,
        nudge: const Offset(0, 0.12),
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon)),
      ),
    );
  }
}

class _LimitedAccessBanner extends StatelessWidget {
  const _LimitedAccessBanner({super.key, required this.onSelectMore});

  final VoidCallback onSelectMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          const Expanded(child: Text('Swipr can only see photos you selected.', style: TextStyle(fontSize: 13))),
          TextButton(onPressed: onSelectMore, child: const Text('Select more')),
        ],
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.onResume});

  final void Function(SessionRecord) onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(unfinishedSessionProvider).value;
    final show = session != null && session.scope != null && session.reviewedCount > 0;

    return SlideSwitcher(
      clip: true,
      from: const Offset(0, -60),
      child: !show
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: ValueKey('continue-${session.id}'),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: PressSlide(
                onTap: () => onResume(session),
                nudge: const Offset(0.02, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDeep]),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 32, color: Colors.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue swiping · ${session.scope!.label}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session.keptCount} kept · ${session.deletedCount} marked for deletion',
                              style: const TextStyle(color: Color(0xCC000000), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab({required this.onOpen, required this.onRetry});

  final void Function(PhotoScope) onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);
    return SlideSwitcher(
      child: switch (albums) {
        AsyncValue(:final List<AlbumInfo> value) when value.isEmpty => const EmptyState(
          key: ValueKey('empty'),
          emoji: '🖼️',
          title: 'No photos found',
          message: 'Take some pictures and come back!',
        ),
        AsyncValue(:final List<AlbumInfo> value) => _ScopeGrid(
          key: const ValueKey('grid'),
          tiles: [
            for (final a in value)
              _ScopeTile(
                title: a.name,
                subtitle: plural(a.count, 'photo'),
                coverAssetId: a.coverAssetId,
                onTap: () => onOpen(a.isAll ? const PhotoScope.all() : PhotoScope.album(id: a.id, name: a.name)),
              ),
          ],
        ),
        AsyncValue(:final Object error) => EmptyState(
          key: const ValueKey('error'),
          emoji: '⚠️',
          title: 'Couldn\'t read your albums',
          message: '$error',
          action: FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ),
        _ => const SlideLoader(key: ValueKey('loading')),
      },
    );
  }
}

class _MonthsTab extends ConsumerWidget {
  const _MonthsTab({required this.onOpen, required this.onRetry});

  final void Function(PhotoScope) onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(monthBucketsProvider);
    return SlideSwitcher(
      child: switch (months) {
        AsyncValue(:final List<MonthBucket> value) when value.isEmpty => const EmptyState(
          key: ValueKey('empty'),
          emoji: '📅',
          title: 'No photos found',
        ),
        AsyncValue(:final List<MonthBucket> value) => _ScopeGrid(
          key: const ValueKey('grid'),
          tiles: [
            for (final m in value)
              _ScopeTile(
                title: m.scope.label,
                subtitle: plural(m.count, 'photo'),
                coverAssetId: m.coverAssetId,
                onTap: () => onOpen(m.scope),
              ),
          ],
        ),
        AsyncValue(:final Object error) => EmptyState(
          key: const ValueKey('error'),
          emoji: '⚠️',
          title: 'Couldn\'t group your photos',
          message: '$error',
          action: FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ),
        _ => const SlideLoader(key: ValueKey('loading')),
      },
    );
  }
}

class _ScopeGrid extends StatelessWidget {
  const _ScopeGrid({super.key, required this.tiles});

  final List<_ScopeTile> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) => tiles[i],
    );
  }
}

class _ScopeTile extends StatelessWidget {
  const _ScopeTile({required this.title, required this.subtitle, required this.coverAssetId, required this.onTap});

  final String title;
  final String subtitle;
  final String? coverAssetId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: PressSlide(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: coverAssetId == null
                      ? const ColoredBox(color: AppColors.surfaceHigh, child: SizedBox.expand())
                      : PhotoImage(assetId: coverAssetId),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
