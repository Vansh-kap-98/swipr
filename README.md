# Swipr

Swipe right to keep, left to delete — a photo cleaner for Android and iOS.

Two projects live here:

| Folder | What it is | How to run it |
|---|---|---|
| root (`lib/`, `android/`, `ios/`) | The Flutter app | `flutter run` |
| [`web/`](web) | The website at swipr.app (Next.js, static export) | `cd web && npm install && npm run dev` |

Before publishing, work through [LAUNCH.md](LAUNCH.md).

## The app

```bash
flutter pub get
flutter run            # needs a phone or emulator with photos on it
flutter test           # 24 tests
flutter analyze
```

### How it's built

- **State:** Riverpod 3, no code generation.
- **Photos:** `photo_manager`. Everything goes through [lib/data/photo_repository.dart](lib/data/photo_repository.dart), so upgrading or replacing that package touches one file.
- **Storage:** SQLite (`sqflite`), on-device only. Tables: `swipe_decisions`, `trash_queue`, `sessions`, `app_settings`. `AppDatabase.watch` re-runs a query whenever its tables change, so screens update themselves.
- **Deleting photos:** swiping left only queues the photo in the app's trash. **Empty Trash** sends one `deleteWithIds` request, so you get a single system prompt on iOS and Android 11+ (Android 10 still asks per photo). Afterwards the app verifies each photo is really gone, which makes deleting safe to retry or interrupt; leftovers are reconciled at the next launch.
- **Swiping:** a custom `CardStack`, no extra package. The rules for when a swipe counts live in `SwipePhysics` and are tested. The ✕/✓ buttons run the same animation and code path as a gesture.
- **Privacy:** no network code, and no internet permission in release builds. Backups are off on Android, and on iOS the database is excluded from iCloud and device backups.
- **Motion:** everything slides. Shared pieces are in [lib/shared_widgets/slide_motion.dart](lib/shared_widgets/slide_motion.dart) (`SlideIn`, `SlideSwitcher`, `SlideLoader`, `PressSlide`, `showSlideToast`); page transitions are in [lib/core/theme/slide_page_transitions.dart](lib/core/theme/slide_page_transitions.dart). No ripples, no fades, no spinners. Colours are set explicitly in `app_theme.dart` (no `fromSeed`), and there's no purple.

### Layout

```
lib/
  core/            theme, routing, permissions, providers, formatting
  data/            models, database + DAOs, photo_repository
  features/        album_browser, swipe_session, trash, stats
  shared_widgets/  pieces used by more than one feature
assets/icon/       app icon sources (see tool/render_app_icon.mjs)
test/              logic, database and card-stack tests
tool/              one-off generators
```

### App icons

Sources live in `assets/icon`. To change the icon, edit [tool/render_app_icon.mjs](tool/render_app_icon.mjs) and run:

```bash
node tool/render_app_icon.mjs   # redraws the 1024px sources (needs Chrome)
dart run flutter_launcher_icons  # writes every Android and iOS size
```

Not in v1: duplicate detection, cloud backup checks, videos, sharing, and syncing between devices.
