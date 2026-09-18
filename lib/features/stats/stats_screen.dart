import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/slide_motion.dart';

final statsProvider = StreamProvider<AllTimeStats>((ref) => ref.watch(sessionsDaoProvider).watchAllTimeStats());

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your stats')),
      body: SlideSwitcher(
        child: switch (ref.watch(statsProvider)) {
          AsyncValue(:final AllTimeStats value) when value.sessionCount == 0 => const EmptyState(
            key: ValueKey('empty'),
            emoji: '📊',
            title: 'No sessions yet',
            message: 'Swipe through an album and your progress will show up here.',
          ),
          AsyncValue(:final AllTimeStats value) => _StatsBody(key: const ValueKey('stats'), stats: value),
          AsyncValue(:final Object error) => EmptyState(
            key: const ValueKey('error'),
            emoji: '⚠️',
            title: 'Couldn\'t load stats',
            message: '$error',
          ),
          _ => const SlideLoader(key: ValueKey('loading')),
        },
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({super.key, required this.stats});

  final AllTimeStats stats;

  @override
  Widget build(BuildContext context) {
    // Sections slide in one after another; the stat tiles arrive from the side.
    Duration at(int step) => Duration(milliseconds: 70 * step);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SlideIn(
          child: _HeroTile(bytes: stats.bytesFreed, photos: stats.deletedPhotoCount),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (i, tile) in [
              _StatTile(value: '${stats.currentStreakDays}🔥', label: 'day streak'),
              _StatTile(value: '${stats.sessionCount}', label: 'sessions'),
              _StatTile(value: '${stats.reviewedCount}', label: 'photos reviewed'),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: SlideIn(from: const Offset(48, 0), delay: at(i + 1), child: tile),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),
        SlideIn(
          delay: at(4),
          child: const Text('Recent sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        for (final (i, s) in stats.recentSessions.indexed)
          SlideIn(
            delay: at(5 + i.clamp(0, 6)),
            child: _SessionRow(session: s),
          ),
      ],
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.bytes, required this.photos});

  final int bytes;
  final int photos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDeep]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total space freed', style: TextStyle(color: Color(0xB3000000))),
          const SizedBox(height: 4),
          SlideSwitcher(
            clip: true,
            from: const Offset(0, 40),
            alignment: Alignment.centerLeft,
            child: Text(
              formatBytes(bytes),
              key: ValueKey(bytes),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1, color: Colors.black),
            ),
          ),
          Text('${plural(photos, 'photo')} deleted', style: const TextStyle(color: Color(0xB3000000))),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            FittedBox(
              child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    final d = session.startedAt;
    final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(session.scope?.label ?? 'Unknown scope', overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$date · ${session.keptCount} kept · ${session.deletedCount} marked${session.isOpen ? ' · in progress' : ''}',
        style: const TextStyle(color: AppColors.muted),
      ),
      trailing: session.bytesFreed > 0
          ? Text(
              formatBytes(session.bytesFreed),
              style: const TextStyle(color: AppColors.keep, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}
