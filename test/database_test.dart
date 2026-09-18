import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:swipr/data/database/app_database.dart';
import 'package:swipr/data/database/daos.dart';
import 'package:swipr/data/models.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase app;
  late DecisionsDao decisions;
  late TrashDao trash;
  late SessionsDao sessions;
  late SettingsDao settings;

  setUp(() async {
    app = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    decisions = DecisionsDao(app);
    trash = TrashDao(app);
    sessions = SessionsDao(app);
    settings = SettingsDao(app);
    await sessions.create('s1', const PhotoScope.all());
  });

  tearDown(() => app.close());

  test('delete decision queues trash and updates session counts', () async {
    await decisions.record(assetId: 'a', decision: Decision.keep, sessionId: 's1');
    await decisions.record(assetId: 'b', decision: Decision.delete, sessionId: 's1', fileSizeBytes: 1000);

    expect(await decisions.decidedAssetIds(), {'a', 'b'});
    final summary = await trash.pendingSummary();
    expect((summary.count, summary.bytes), (1, 1000));
    final s = (await sessions.byId('s1'))!;
    expect((s.keptCount, s.deletedCount), (1, 1));
  });

  test('undo reverses a decision completely', () async {
    await decisions.record(assetId: 'b', decision: Decision.delete, sessionId: 's1', fileSizeBytes: 1000);
    await decisions.undo(assetId: 'b', decision: Decision.delete, sessionId: 's1');

    expect(await decisions.decidedAssetIds(), isEmpty);
    expect((await trash.pendingSummary()).count, 0);
    expect((await sessions.byId('s1'))!.deletedCount, 0);
  });

  test('restore turns a pending delete into a keep', () async {
    await decisions.record(assetId: 'b', decision: Decision.delete, sessionId: 's1', fileSizeBytes: 1000);
    await trash.restore(['b']);

    expect((await trash.pendingSummary()).count, 0);
    expect(await decisions.decidedAssetIds(), {'b'}); // still won't be shown again
  });

  test('markCommitted is idempotent and credits the swiping session', () async {
    await decisions.record(assetId: 'b', decision: Decision.delete, sessionId: 's1', fileSizeBytes: 1000);
    await decisions.record(assetId: 'c', decision: Decision.delete, sessionId: 's1', fileSizeBytes: 500);

    final first = await trash.markCommitted(['b', 'c']);
    final again = await trash.markCommitted(['b', 'c']);

    expect((first.count, first.bytes), (2, 1500));
    expect(again.count, 0);
    expect((await sessions.byId('s1'))!.bytesFreed, 1500);
    final stats = await sessions.allTimeStats();
    expect((stats.deletedPhotoCount, stats.bytesFreed, stats.sessionCount), (2, 1500, 1));
  });

  test('resetHistory keeps photos that are still in the trash', () async {
    await decisions.record(assetId: 'a', decision: Decision.keep, sessionId: 's1');
    await decisions.record(assetId: 'b', decision: Decision.delete, sessionId: 's1', fileSizeBytes: 1);
    await decisions.resetHistory();

    expect(await decisions.decidedAssetIds(), {'b'});
  });

  test('closeOthers ends used sessions and drops empty ones', () async {
    await decisions.record(assetId: 'a', decision: Decision.keep, sessionId: 's1');
    await sessions.create('s2', const PhotoScope.all());
    await sessions.create('s3', const PhotoScope.all());

    await sessions.closeOthers(keepOpenId: 's3');

    expect((await sessions.byId('s1'))!.isOpen, isFalse);
    expect(await sessions.byId('s2'), isNull);
    expect((await sessions.latestUnfinished())!.id, 's3');
  });

  test('watch re-emits when a table changes', () async {
    final emitted = <int>[];
    final sub = trash.watchSummary().listen((s) => emitted.add(s.count));
    await pumpEventQueue();
    await decisions.record(assetId: 'b', decision: Decision.delete, sessionId: 's1');
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted, [0, 1]);
  });

  test('settings persist', () async {
    expect((await settings.load()).undoLimit, 50);
    await settings.save(const AppSettings(undoLimit: 10, promptDeleteOnSessionEnd: false));
    final loaded = await settings.load();
    expect((loaded.undoLimit, loaded.promptDeleteOnSessionEnd), (10, false));
  });
}
