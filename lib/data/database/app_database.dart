import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Table names, also used as change-notification topics.
abstract final class Tables {
  static const decisions = 'swipe_decisions';
  static const trash = 'trash_queue';
  static const sessions = 'sessions';
  static const settings = 'app_settings';
}

/// Owns the SQLite connection and broadcasts which tables changed, so
/// providers can re-query and stay reactive without a codegen ORM.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;
  final _changes = StreamController<String>.broadcast();

  static const _version = 1;

  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'swipr.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => _createSchema(db),
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch()
      // Latest decision per asset. A row here means "already swiped, don't show
      // again" until the user resets history.
      ..execute('''
        CREATE TABLE ${Tables.decisions} (
          asset_id   TEXT PRIMARY KEY,
          decision   TEXT NOT NULL CHECK (decision IN ('keep', 'delete')),
          session_id TEXT NOT NULL,
          timestamp  INTEGER NOT NULL
        )''')
      ..execute('CREATE INDEX idx_decisions_session ON ${Tables.decisions}(session_id)')
      ..execute('''
        CREATE TABLE ${Tables.trash} (
          asset_id        TEXT PRIMARY KEY,
          file_size_bytes INTEGER NOT NULL DEFAULT 0,
          added_at        INTEGER NOT NULL,
          status          TEXT NOT NULL CHECK (status IN ('pending', 'committed', 'restored'))
        )''')
      ..execute('CREATE INDEX idx_trash_status ON ${Tables.trash}(status)')
      ..execute('''
        CREATE TABLE ${Tables.sessions} (
          session_id    TEXT PRIMARY KEY,
          started_at    INTEGER NOT NULL,
          ended_at      INTEGER,
          scope         TEXT NOT NULL,
          kept_count    INTEGER NOT NULL DEFAULT 0,
          deleted_count INTEGER NOT NULL DEFAULT 0,
          bytes_freed   INTEGER NOT NULL DEFAULT 0
        )''')
      ..execute('''
        CREATE TABLE ${Tables.settings} (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )''');
    await batch.commit(noResult: true);
  }

  void notify(Iterable<String> tables) {
    for (final t in tables) {
      if (!_changes.isClosed) _changes.add(t);
    }
  }

  /// Emits [query]'s result now and again whenever any of [tables] changes.
  Stream<T> watch<T>(Set<String> tables, Future<T> Function() query) {
    late final StreamController<T> controller;
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final value = await query();
        if (!controller.isClosed) controller.add(value);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        sub = _changes.stream.where(tables.contains).listen((_) => emit());
        emit();
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  Future<void> close() async {
    await _changes.close();
    await db.close();
  }
}
