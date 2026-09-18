import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/permissions/photo_permission.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'features/album_browser/album_browser_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Room for the screen-sized card images kept decoded ahead of each swipe.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20;
  final database = await AppDatabase.open();
  runApp(ProviderScope(overrides: [databaseProvider.overrideWithValue(database)], child: const SwiprApp()));
}

class SwiprApp extends StatelessWidget {
  const SwiprApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipr',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const PermissionGate(child: AlbumBrowserScreen()),
    );
  }
}
