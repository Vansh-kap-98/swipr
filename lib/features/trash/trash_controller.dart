import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models.dart';
import '../swipe_session/swipe_session_controller.dart';

final trashItemsProvider = StreamProvider<List<TrashItem>>((ref) => ref.watch(trashDaoProvider).watchPending());

final trashSummaryProvider = StreamProvider<TrashSummary>((ref) => ref.watch(trashDaoProvider).watchSummary());

sealed class CommitResult {
  const CommitResult();
}

/// Nothing was deleted — typically the user dismissed the OS dialog. The
/// queue is untouched.
class CommitCancelled extends CommitResult {
  const CommitCancelled();
}

class CommitDone extends CommitResult {
  const CommitDone({required this.freed, required this.remaining});

  final TrashSummary freed;

  /// Items still pending (partial deletion).
  final int remaining;
}

class TrashActions {
  TrashActions(this._ref);

  final Ref _ref;

  bool _busy = false;

  Future<void> restore(Iterable<String> assetIds) => _ref.read(trashDaoProvider).restore(assetIds);

  /// Deletes every pending item with ONE OS request, then records whatever
  /// actually disappeared. Because the outcome is verified per asset, this is
  /// safe to retry and safe to interrupt.
  Future<CommitResult> commitAll() async {
    if (_busy) return const CommitCancelled();
    _busy = true;
    try {
      final dao = _ref.read(trashDaoProvider);
      final pending = await dao.pendingItems();
      if (pending.isEmpty) return const CommitCancelled();

      final gone = await _ref.read(photoRepositoryProvider).deleteAssets([for (final i in pending) i.assetId]);
      final freed = await dao.markCommitted(gone);
      _ref.read(swipeSessionProvider.notifier).forgetAssets(gone);

      if (freed.count == 0) return const CommitCancelled();
      return CommitDone(freed: freed, remaining: pending.length - freed.count);
    } finally {
      _busy = false;
    }
  }

  /// Launch-time reconciliation: if a previous delete was interrupted (app
  /// killed while the OS dialog was up) or photos were removed outside the
  /// app, pending rows for assets that no longer exist are settled.
  Future<void> reconcile() async {
    final repo = _ref.read(photoRepositoryProvider);
    final dao = _ref.read(trashDaoProvider);
    final pending = await dao.pendingItems();
    if (pending.isEmpty) return;

    // Each check is a round trip to the OS, so run them in batches instead of
    // one after another — a 200-photo trash settles in a fraction of the time.
    const batchSize = 16;
    final gone = <String>[];
    for (var start = 0; start < pending.length; start += batchSize) {
      final batch = pending.skip(start).take(batchSize);
      final results = await Future.wait(batch.map((item) async => (item.assetId, await repo.exists(item.assetId))));
      gone.addAll(results.where((r) => !r.$2).map((r) => r.$1));
    }
    if (gone.isNotEmpty) await dao.markCommitted(gone);
  }
}

final trashActionsProvider = Provider((ref) => TrashActions(ref));
