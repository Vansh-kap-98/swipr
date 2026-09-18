import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models.dart';
import '../../data/photo_repository.dart';

@immutable
class UndoEntry {
  const UndoEntry(this.asset, this.decision);

  final AssetEntity asset;
  final Decision decision;
}

@immutable
class SwipeSessionState {
  const SwipeSessionState({
    this.scope,
    this.sessionId,
    this.loading = false,
    this.error,
    this.queue = const [],
    this.total = 0,
    this.kept = 0,
    this.deleted = 0,
    this.undoStack = const [],
  });

  final PhotoScope? scope;
  final String? sessionId;
  final bool loading;
  final Object? error;

  /// Photos not yet decided; index 0 is the top card.
  final List<AssetEntity> queue;

  /// All photos in scope, including ones decided in earlier sessions.
  final int total;

  /// Decisions made in this session (drives the end-of-session summary).
  final int kept;
  final int deleted;

  final List<UndoEntry> undoStack;

  int get reviewed => total - queue.length;
  bool get canUndo => undoStack.isNotEmpty;
  bool get isFinished => scope != null && !loading && error == null && queue.isEmpty;

  SwipeSessionState copyWith({List<AssetEntity>? queue, int? kept, int? deleted, List<UndoEntry>? undoStack}) =>
      SwipeSessionState(
        scope: scope,
        sessionId: sessionId,
        loading: loading,
        error: error,
        queue: queue ?? this.queue,
        total: total,
        kept: kept ?? this.kept,
        deleted: deleted ?? this.deleted,
        undoStack: undoStack ?? this.undoStack,
      );
}

/// In-memory state of the active swipe session. UI state updates happen
/// synchronously (so animations never wait on disk); database writes are
/// queued behind each other so a fast undo can't race its own decision.
class SwipeSessionController extends Notifier<SwipeSessionState> {
  Future<void> _writes = Future.value();
  int _loadToken = 0;

  @override
  SwipeSessionState build() => const SwipeSessionState();

  void _enqueueWrite(Future<void> Function() op) {
    _writes = _writes.then((_) => op()).catchError((Object e, StackTrace st) {
      debugPrint('Swipe session write failed: $e\n$st');
    });
  }

  /// Completes once every queued database write has landed.
  Future<void> flush() => _writes;

  Future<void> start(PhotoScope scope, {String? resumeSessionId}) async {
    final token = ++_loadToken;
    state = SwipeSessionState(scope: scope, loading: true);
    await flush();

    final sessions = ref.read(sessionsDaoProvider);
    try {
      var sessionId = resumeSessionId;
      SessionRecord? resumed;
      if (sessionId != null) resumed = await sessions.byId(sessionId);
      if (resumed == null || resumed.endedAt != null) {
        sessionId = '${DateTime.now().microsecondsSinceEpoch}';
        await sessions.create(sessionId, scope);
      }
      await sessions.closeOthers(keepOpenId: sessionId);

      final assets = await ref.read(photoRepositoryProvider).assetsInScope(scope);
      final decided = await ref.read(decisionsDaoProvider).decidedAssetIds();
      if (token != _loadToken) return;

      state = SwipeSessionState(
        scope: scope,
        sessionId: sessionId,
        queue: [
          for (final a in assets)
            if (!decided.contains(a.id)) a,
        ],
        total: assets.length,
        kept: resumed?.keptCount ?? 0,
        deleted: resumed?.deletedCount ?? 0,
      );
    } catch (e) {
      if (token != _loadToken) return;
      state = SwipeSessionState(scope: scope, error: e);
    }
  }

  /// Called once the card's exit animation has finished — for swipes and for
  /// the ✕/✓ buttons alike.
  void decide(AssetEntity asset, Decision decision) {
    final s = state;
    final sessionId = s.sessionId;
    if (sessionId == null || s.queue.isEmpty || s.queue.first.id != asset.id) return;

    final limit = ref.read(settingsProvider).value?.undoLimit ?? const AppSettings().undoLimit;
    final undo = [...s.undoStack, UndoEntry(asset, decision)];
    state = s.copyWith(
      queue: s.queue.sublist(1),
      kept: s.kept + (decision == Decision.keep ? 1 : 0),
      deleted: s.deleted + (decision == Decision.delete ? 1 : 0),
      undoStack: undo.length > limit ? undo.sublist(undo.length - limit) : undo,
    );

    _enqueueWrite(() async {
      final size = decision == Decision.delete ? await ref.read(photoRepositoryProvider).fileSize(asset) : 0;
      await ref
          .read(decisionsDaoProvider)
          .record(assetId: asset.id, decision: decision, sessionId: sessionId, fileSizeBytes: size);
    });
  }

  /// The decision [undo] would reverse, so the UI can animate the card back
  /// in from the matching side before the state changes.
  Decision? get peekUndo => state.undoStack.lastOrNull?.decision;

  UndoEntry? undo() {
    final s = state;
    final sessionId = s.sessionId;
    if (sessionId == null || s.undoStack.isEmpty) return null;
    final entry = s.undoStack.last;

    state = s.copyWith(
      queue: [entry.asset, ...s.queue],
      kept: s.kept - (entry.decision == Decision.keep ? 1 : 0),
      deleted: s.deleted - (entry.decision == Decision.delete ? 1 : 0),
      undoStack: s.undoStack.sublist(0, s.undoStack.length - 1),
    );

    _enqueueWrite(
      () =>
          ref.read(decisionsDaoProvider).undo(assetId: entry.asset.id, decision: entry.decision, sessionId: sessionId),
    );
    return entry;
  }

  /// Drops undo entries for photos that no longer exist on the device
  /// (e.g. the trash was emptied mid-session).
  void forgetAssets(Set<String> assetIds) {
    if (assetIds.isEmpty) return;
    final s = state;
    state = s.copyWith(
      undoStack: [
        for (final e in s.undoStack)
          if (!assetIds.contains(e.asset.id)) e,
      ],
      queue: [
        for (final a in s.queue)
          if (!assetIds.contains(a.id)) a,
      ],
    );
  }

  Future<void> finish() async {
    final id = state.sessionId;
    if (id == null) return;
    await flush();
    await ref.read(sessionsDaoProvider).end(id);
    state = state.copyWith(undoStack: const []);
  }
}

final swipeSessionProvider = NotifierProvider<SwipeSessionController, SwipeSessionState>(SwipeSessionController.new);
