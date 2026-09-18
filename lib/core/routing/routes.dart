import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../features/album_browser/album_browser_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/swipe_session/swipe_session_screen.dart';
import '../../features/trash/trash_screen.dart';

/// Plain Navigator 1.0 routes: the app is a shallow stack of five screens.
abstract final class Routes {
  static Future<void> home(BuildContext context) =>
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const AlbumBrowserScreen()), (_) => false);

  static Future<void> swipe(BuildContext context, PhotoScope scope, {String? resumeSessionId}) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => SwipeSessionScreen(scope: scope, resumeSessionId: resumeSessionId),
        ),
      );

  static Future<void> trash(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrashScreen()));

  static Future<void> stats(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StatsScreen()));
}
