import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/daos.dart';
import '../data/models.dart';
import '../data/photo_repository.dart';

/// Overridden in `main()` once the database is open.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider not overridden'));

final photoRepositoryProvider = Provider<PhotoRepository>((ref) => PhotoRepository());

final decisionsDaoProvider = Provider((ref) => DecisionsDao(ref.watch(databaseProvider)));
final trashDaoProvider = Provider((ref) => TrashDao(ref.watch(databaseProvider)));
final sessionsDaoProvider = Provider((ref) => SessionsDao(ref.watch(databaseProvider)));
final settingsDaoProvider = Provider((ref) => SettingsDao(ref.watch(databaseProvider)));

final settingsProvider = StreamProvider<AppSettings>((ref) => ref.watch(settingsDaoProvider).watch());
