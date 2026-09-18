import 'package:sqflite/sqflite.dart';

import '../models.dart';
import 'app_database.dart';

int _now() => DateTime.now().millisecondsSinceEpoch;

DateTime _time(Object? ms) => DateTime.fromMillisecondsSinceEpoch(ms! as int);

class DecisionsDao {
  DecisionsDao(this._app);

  final AppDatabase _app;
  Database get _db => _app.db;

  Future<Set<String>> decidedAssetIds() async {
    final rows = await _db.query(Tables.decisions, columns: ['asset_id']);
    return {for (final r in rows) r['asset_id']! as String};
  }

  /// Records a decision. For deletes, also queues the asset in the trash —
  /// in one transaction so the two tables can't disagree.
  Future<void> record({
    required String assetId,
    required Decision decision,
    required String sessionId,
    int fileSizeBytes = 0,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(Tables.decisions, {
        'asset_id': assetId,
        'decision': decision.name,
        'session_id': sessionId,
        'timestamp': _now(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      if (decision == Decision.delete) {
        await txn.insert(Tables.trash, {
          'asset_id': assetId,
          'file_size_bytes': fileSizeBytes,
          'added_at': _now(),
          'status': TrashStatus.pending.name,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final column = decision == Decision.keep ? 'kept_count' : 'deleted_count';
      await txn.rawUpdate('UPDATE ${Tables.sessions} SET $column = $column + 1 WHERE session_id = ?', [sessionId]);
    });
    _app.notify([Tables.decisions, Tables.trash, Tables.sessions]);
  }

  /// Reverses [record] (used by in-session undo).
  Future<void> undo({required String assetId, required Decision decision, required String sessionId}) async {
    await _db.transaction((txn) async {
      await txn.delete(Tables.decisions, where: 'asset_id = ?', whereArgs: [assetId]);
      if (decision == Decision.delete) {
        await txn.delete(
          Tables.trash,
          where: 'asset_id = ? AND status != ?',
          whereArgs: [assetId, TrashStatus.committed.name],
        );
      }
      final column = decision == Decision.keep ? 'kept_count' : 'deleted_count';
      await txn.rawUpdate('UPDATE ${Tables.sessions} SET $column = MAX($column - 1, 0) WHERE session_id = ?', [
        sessionId,
      ]);
    });
    _app.notify([Tables.decisions, Tables.trash, Tables.sessions]);
  }

  /// Forgets past decisions so photos show up again. Photos still waiting in
  /// the trash stay marked, so they aren't offered twice.
  Future<void> resetHistory() async {
    await _db.delete(
      Tables.decisions,
      where: 'asset_id NOT IN (SELECT asset_id FROM ${Tables.trash} WHERE status = ?)',
      whereArgs: [TrashStatus.pending.name],
    );
    _app.notify([Tables.decisions]);
  }
}

class TrashDao {
  TrashDao(this._app);

  final AppDatabase _app;
  Database get _db => _app.db;

  static const _pendingWhere = 'status = ?';

  Future<List<TrashItem>> pendingItems() async {
    final rows = await _db.query(
      Tables.trash,
      where: _pendingWhere,
      whereArgs: [TrashStatus.pending.name],
      orderBy: 'added_at DESC',
    );
    return rows
        .map(
          (r) => TrashItem(
            assetId: r['asset_id']! as String,
            fileSizeBytes: r['file_size_bytes']! as int,
            addedAt: _time(r['added_at']),
            status: TrashStatus.values.byName(r['status']! as String),
          ),
        )
        .toList();
  }

  Future<TrashSummary> pendingSummary() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c, COALESCE(SUM(file_size_bytes), 0) AS b FROM ${Tables.trash} WHERE $_pendingWhere',
      [TrashStatus.pending.name],
    );
    return TrashSummary(count: rows.first['c']! as int, bytes: rows.first['b']! as int);
  }

  Stream<List<TrashItem>> watchPending() => _app.watch({Tables.trash}, pendingItems);

  Stream<TrashSummary> watchSummary() => _app.watch({Tables.trash}, pendingSummary);

  /// Un-marks a photo: it leaves the trash and counts as kept.
  Future<void> restore(Iterable<String> assetIds) async {
    await _db.transaction((txn) async {
      for (final id in assetIds) {
        await txn.update(
          Tables.trash,
          {'status': TrashStatus.restored.name},
          where: 'asset_id = ? AND $_pendingWhere',
          whereArgs: [id, TrashStatus.pending.name],
        );
        await txn.update(
          Tables.decisions,
          {'decision': Decision.keep.name, 'timestamp': _now()},
          where: 'asset_id = ?',
          whereArgs: [id],
        );
      }
    });
    _app.notify([Tables.trash, Tables.decisions]);
  }

  /// Marks assets as actually deleted from the device and credits the freed
  /// bytes to the session in which each one was swiped left. Safe to call
  /// repeatedly with the same ids: only pending rows are affected.
  Future<TrashSummary> markCommitted(Iterable<String> assetIds) async {
    var count = 0;
    var bytes = 0;
    await _db.transaction((txn) async {
      for (final id in assetIds) {
        final rows = await txn.query(
          Tables.trash,
          where: 'asset_id = ? AND $_pendingWhere',
          whereArgs: [id, TrashStatus.pending.name],
        );
        if (rows.isEmpty) continue;
        final size = rows.first['file_size_bytes']! as int;
        await txn.update(Tables.trash, {'status': TrashStatus.committed.name}, where: 'asset_id = ?', whereArgs: [id]);
        await txn.rawUpdate(
          'UPDATE ${Tables.sessions} SET bytes_freed = bytes_freed + ? '
          'WHERE session_id = (SELECT session_id FROM ${Tables.decisions} WHERE asset_id = ?)',
          [size, id],
        );
        count++;
        bytes += size;
      }
    });
    if (count > 0) _app.notify([Tables.trash, Tables.sessions]);
    return TrashSummary(count: count, bytes: bytes);
  }
}

class SessionsDao {
  SessionsDao(this._app);

  final AppDatabase _app;
  Database get _db => _app.db;

  SessionRecord _fromRow(Map<String, Object?> r) => SessionRecord(
    id: r['session_id']! as String,
    startedAt: _time(r['started_at']),
    endedAt: r['ended_at'] == null ? null : _time(r['ended_at']),
    scope: PhotoScope.decode(r['scope']! as String),
    keptCount: r['kept_count']! as int,
    deletedCount: r['deleted_count']! as int,
    bytesFreed: r['bytes_freed']! as int,
  );

  Future<void> create(String sessionId, PhotoScope scope) async {
    await _db.insert(Tables.sessions, {'session_id': sessionId, 'started_at': _now(), 'scope': scope.encode()});
    _app.notify([Tables.sessions]);
  }

  Future<SessionRecord?> byId(String sessionId) async {
    final rows = await _db.query(Tables.sessions, where: 'session_id = ?', whereArgs: [sessionId]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<void> end(String sessionId) async {
    await _db.update(
      Tables.sessions,
      {'ended_at': _now()},
      where: 'session_id = ? AND ended_at IS NULL',
      whereArgs: [sessionId],
    );
    _app.notify([Tables.sessions]);
  }

  /// Closes every open session except [keepOpenId]. Sessions where nothing
  /// was swiped are dropped so they don't pad the stats.
  Future<void> closeOthers({String? keepOpenId}) async {
    final keep = keepOpenId ?? '';
    await _db.transaction((txn) async {
      await txn.delete(
        Tables.sessions,
        where: 'ended_at IS NULL AND session_id != ? AND kept_count + deleted_count = 0',
        whereArgs: [keep],
      );
      await txn.update(
        Tables.sessions,
        {'ended_at': _now()},
        where: 'ended_at IS NULL AND session_id != ?',
        whereArgs: [keep],
      );
    });
    _app.notify([Tables.sessions]);
  }

  Future<SessionRecord?> latestUnfinished() async {
    final rows = await _db.query(Tables.sessions, where: 'ended_at IS NULL', orderBy: 'started_at DESC', limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Stream<SessionRecord?> watchLatestUnfinished() => _app.watch({Tables.sessions}, latestUnfinished);

  Future<AllTimeStats> allTimeStats({DateTime? now}) async {
    final totals = (await _db.rawQuery('''
      SELECT COUNT(*) AS sessions, COALESCE(SUM(kept_count + deleted_count), 0) AS reviewed
      FROM ${Tables.sessions} WHERE kept_count + deleted_count > 0''')).first;
    final trash = (await _db.rawQuery(
      'SELECT COUNT(*) AS c, COALESCE(SUM(file_size_bytes), 0) AS b FROM ${Tables.trash} WHERE status = ?',
      [TrashStatus.committed.name],
    )).first;
    final dayRows = await _db.query(Tables.sessions, columns: ['started_at'], where: 'kept_count + deleted_count > 0');
    final recent = await _db.query(
      Tables.sessions,
      where: 'kept_count + deleted_count > 0',
      orderBy: 'started_at DESC',
      limit: 20,
    );

    return AllTimeStats(
      sessionCount: totals['sessions']! as int,
      reviewedCount: totals['reviewed']! as int,
      deletedPhotoCount: trash['c']! as int,
      bytesFreed: trash['b']! as int,
      currentStreakDays: computeStreak(dayRows.map((r) => _time(r['started_at'])), now ?? DateTime.now()),
      recentSessions: recent.map(_fromRow).toList(),
    );
  }

  Stream<AllTimeStats> watchAllTimeStats() => _app.watch({Tables.sessions, Tables.trash}, allTimeStats);
}

/// Consecutive calendar days with at least one session, ending today — or
/// yesterday, so the streak isn't shown as broken before today's swipe.
int computeStreak(Iterable<DateTime> sessionTimes, DateTime now) {
  DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);
  final days = sessionTimes.map(day).toSet();
  var cursor = day(now);
  if (!days.contains(cursor)) cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}

class SettingsDao {
  SettingsDao(this._app);

  final AppDatabase _app;
  Database get _db => _app.db;

  static const _undoLimit = 'undo_limit';
  static const _promptOnEnd = 'prompt_delete_on_session_end';

  Future<AppSettings> load() async {
    final rows = await _db.query(Tables.settings);
    final map = {for (final r in rows) r['key']! as String: r['value']! as String};
    const defaults = AppSettings();
    return AppSettings(
      undoLimit: int.tryParse(map[_undoLimit] ?? '') ?? defaults.undoLimit,
      promptDeleteOnSessionEnd: map[_promptOnEnd] == null
          ? defaults.promptDeleteOnSessionEnd
          : map[_promptOnEnd] == 'true',
    );
  }

  Stream<AppSettings> watch() => _app.watch({Tables.settings}, load);

  Future<void> save(AppSettings s) async {
    final batch = _db.batch();
    for (final e in {_undoLimit: '${s.undoLimit}', _promptOnEnd: '${s.promptDeleteOnSessionEnd}'}.entries) {
      batch.insert(Tables.settings, {'key': e.key, 'value': e.value}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    _app.notify([Tables.settings]);
  }
}
