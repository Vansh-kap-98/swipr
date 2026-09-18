# Swipr, explained

A walkthrough of everything in this project: how Flutter works, how each part of the app is built, how the website works, and how apps get published. It assumes you can read code but haven't built a Flutter app before.

Read it top to bottom once, then use it as a reference. Every snippet is real code from this repo, shortened where noted.

**Contents**

1. [The map](#1-the-map)
2. [Flutter in ten minutes](#2-flutter-in-ten-minutes)
3. [State: who owns what](#3-state-who-owns-what)
4. [Talking to the phone](#4-talking-to-the-phone)
5. [The database](#5-the-database)
6. [The swipe](#6-the-swipe)
7. [Look and motion](#7-look-and-motion)
8. [Tests](#8-tests)
9. [The website](#9-the-website)
10. [Building and publishing](#10-building-and-publishing)
11. [Cookbook](#11-cookbook)
12. [Glossary](#12-glossary)

---

## 1. The map

```
lib/               the app (Dart)
  main.dart        starts everything
  core/            theme, routing, permissions, providers, formatting
  data/            models, database, photo_repository
  features/        one folder per screen area
  shared_widgets/  pieces used by more than one feature
android/ ios/      the native wrappers Flutter builds into real apps
assets/icon/       app icon artwork
test/              automated tests
tool/              icon generator
web/               the website (Next.js)
```

Two separate programs live here. The **app** is Dart compiled to native ARM code that runs on a phone. The **website** is HTML/CSS/JS served to browsers. They share nothing but the colour palette and the marketing copy — the site reads the app's version number out of `pubspec.yaml`, and that's the only link.

`pubspec.yaml` is the app's manifest: name, version, and dependencies.

```yaml
name: swipr
version: 1.0.0+1          # 1.0.0 is shown to users, +1 is the build number

dependencies:
  flutter_riverpod: ^3.4.3  # state management
  photo_manager: ^3.12.0    # reads and deletes device photos
  sqflite: ^2.4.4           # local SQLite database
  path: ^1.9.1              # joins file paths correctly per platform
```

The `^` means "this version or any newer one that promises to stay compatible". `pubspec.lock` records the exact versions actually used, so every machine builds the same thing.

---

## 2. Flutter in ten minutes

### Everything is a widget

A widget is a plain, immutable description of a piece of UI. It's not the thing on screen — it's the instruction for what should be on screen. Flutter builds a tree of them and paints the result.

```dart
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(emoji),
          Text(title),
        ],
      ),
    );
  }
}
```

`build` runs whenever this widget needs to appear or change. It must be cheap and free of side effects: no network calls, no database writes — just "given these inputs, here's the UI".

You compose behaviour by wrapping, not by subclassing. Want padding? Wrap in `Padding`. Want it centred? Wrap in `Center`. That's why Flutter code nests deeply — the nesting *is* the layout.

### Stateless vs stateful

- `StatelessWidget` — everything it needs arrives as constructor arguments. Most of the app.
- `StatefulWidget` — it remembers something between builds (an animation's position, whether a menu is open). The memory lives in a companion `State` object that survives rebuilds.

```dart
class _CardStackState extends State<CardStack> with SingleTickerProviderStateMixin {
  bool _flying = false;              // survives rebuilds
  final ValueNotifier<Offset> _offset = ValueNotifier(Offset.zero);

  @override
  void dispose() {                   // always release what you create
    _anim.dispose();
    _offset.dispose();
    super.dispose();
  }
}
```

Two rules that prevent most Flutter bugs:

1. **Anything you create (controllers, notifiers, subscriptions) you must `dispose`.** Otherwise it keeps ticking after the screen is gone.
2. **Call `setState` to tell Flutter something changed.** Mutating a field without it changes the data but not the screen.

### BuildContext

The `context` handed to `build` is the widget's position in the tree. You use it to look upward: `Theme.of(context)`, `MediaQuery.sizeOf(context)`, `Navigator.of(context)`. A context that's gone from the tree is dead — hence the `if (!mounted) return;` checks after every `await` in this codebase:

```dart
final confirm = await showModalBottomSheet<bool>(...);
if (confirm == true && mounted) await commitTrash(context, ref);
```

While that sheet was open the user could have left the screen. Using a dead context throws.

### Keys

When a list of widgets changes, Flutter matches old widgets to new ones to decide what to reuse. By default it matches by position and type — which goes wrong when items move. A `Key` says "this is the same thing as before, it just moved":

```dart
return Positioned.fill(
  key: ValueKey(asset.id),   // card 3 stays card 3 as it moves up the stack
  ...
);
```

Without that key, the photo already decoded for the second card would be thrown away every time the stack advances, and every swipe would flash.

---

## 3. State: who owns what

### The problem

The trash counter appears in the app bar, on the swipe screen, and on the trash screen. When you swipe left, all three must update. Passing values down through constructors gets unwieldy fast.

### Riverpod

A **provider** is a named, lazily created piece of state that any widget can read. Declared at the top level:

```dart
// lib/core/providers.dart
final photoRepositoryProvider = Provider<PhotoRepository>((ref) => PhotoRepository());
final trashDaoProvider = Provider((ref) => TrashDao(ref.watch(databaseProvider)));
final settingsProvider = StreamProvider<AppSettings>((ref) => ref.watch(settingsDaoProvider).watch());
```

Three ways to use one:

| Call | Meaning |
|---|---|
| `ref.watch(p)` | Read it **and rebuild** when it changes. Use inside `build`. |
| `ref.read(p)` | Read once, don't subscribe. Use inside callbacks. |
| `ref.listen(p, cb)` | Run a callback on change without rebuilding — for navigation, dialogs. |

```dart
class TrashPill extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(trashSummaryProvider).value;   // rebuilds on change
    ...
  }
}
```

`ConsumerWidget` is just `StatelessWidget` with `ref` added. `ProviderScope` in `main.dart` holds all provider state:

```dart
final database = await AppDatabase.open();
runApp(ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: const SwiprApp(),
));
```

`overrideWithValue` is how the already-opened database gets injected — and it's also how tests swap in fakes.

### Session state as an immutable snapshot

The swipe session is a `Notifier`: a class holding one immutable state object that it replaces to trigger updates.

```dart
class SwipeSessionState {
  final List<AssetEntity> queue;   // photos not yet decided, index 0 = top card
  final int total, kept, deleted;
  final List<UndoEntry> undoStack;

  int get reviewed => total - queue.length;
  bool get canUndo => undoStack.isNotEmpty;
}
```

Never mutated — replaced:

```dart
state = s.copyWith(
  queue: s.queue.sublist(1),
  kept: s.kept + (decision == Decision.keep ? 1 : 0),
  undoStack: undo,
);
```

Why immutable? Riverpod compares old and new to decide whether to rebuild. If you mutate the same object, the comparison sees no change and the screen quietly goes stale.

### The trick that keeps swiping fast

A swipe must feel instant, but it also writes to the database. So the two are separated: **memory updates synchronously, disk updates in a queue.**

```dart
void decide(AssetEntity asset, Decision decision) {
  state = s.copyWith(...);           // 1. instant — the next card is already on screen

  _enqueueWrite(() async {           // 2. later — file size lookup + database write
    final size = await ref.read(photoRepositoryProvider).fileSize(asset);
    await ref.read(decisionsDaoProvider).record(...);
  });
}

void _enqueueWrite(Future<void> Function() op) {
  _writes = _writes.then((_) => op());   // one chain: writes can never overtake each other
}
```

That chain matters. Undo deletes the row that `decide` inserts. If both ran freely, a fast undo could delete the row *before* it was written, leaving a ghost entry in the trash forever.

---

## 4. Talking to the phone

### The repository pattern

Exactly one file imports `photo_manager`:

```dart
// lib/data/photo_repository.dart
class PhotoRepository {
  Future<List<AlbumInfo>> albums() async { ... }
  Future<List<AssetEntity>> assetsInScope(PhotoScope scope) async { ... }
  Future<Set<String>> deleteAssets(List<String> ids) async { ... }
}
```

Screens ask the repository, never the package. If `photo_manager` changes its API, or you replace it, one file changes instead of fifteen. It's also where the awkward realities get smoothed over:

```dart
/// Asset ids can change if the OS re-indexes the library, so a missing
/// asset is a normal outcome (null), never an exception.
Future<AssetEntity?> assetById(String id) async {
  try {
    return await AssetEntity.fromId(id);
  } catch (e) {
    debugPrint('assetById($id) failed: $e');
    return null;
  }
}
```

### Permissions

Android and iOS both gate photo access, and Android changed the rules three times in recent versions. The app asks for images only:

```dart
static const _permissionOption = PermissionRequestOption(
  androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
);
```

which produces:

| Android version | What the user is asked |
|---|---|
| 13+ | Photos only (`READ_MEDIA_IMAGES`) |
| 14+ | Also offers "Select photos" — partial access |
| 8–12 | Storage read |
| 8–9 | Storage write as well, because those versions need it to delete |

iOS asks once, and the user may pick "Limited" (selected photos only). Both cases are handled: `PermissionState.limited` shows a banner offering to pick more.

Permissions are declared in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`. Declaring one you don't need is a real cost — stores show it to users and ask you to justify it.

### Deleting is not yours to do

Neither OS lets an app delete photos silently. Every delete shows a system dialog the app cannot style or skip. That single fact shaped the whole design: if each left-swipe deleted immediately, you'd tap a system dialog for every photo.

So swiping left only writes a row. The real delete happens once, for the whole batch:

```dart
Future<Set<String>> deleteAssets(List<String> ids) async {
  if (ids.isEmpty) return const {};
  try {
    await PhotoManager.editor.deleteWithIds(ids);   // one system prompt
  } catch (e) {
    debugPrint('deleteWithIds failed: $e');
  }
  final gone = <String>{};
  for (final id in ids) {
    if (!await exists(id)) gone.add(id);            // verify, don't assume
  }
  return gone;
}
```

The verification loop is the important part. The call can half-succeed, the user can cancel, and Android 10 asks per photo. Rather than trusting the return value, the app checks what actually disappeared. That makes the operation **idempotent** — safe to run twice — which in turn makes the app safe to kill mid-delete. On the next launch:

```dart
/// Launch-time reconciliation: if a previous delete was interrupted or photos
/// were removed outside the app, pending rows for assets that no longer exist
/// are settled.
Future<void> reconcile() async { ... }
```

### Images and memory

A modern phone photo is around 4000×3000 pixels. Decoded into memory that's ~48 MB — for *one* photo. Show four at once naively and the app dies.

Two defences. First, ask the OS for a screen-sized version instead of the original:

```dart
Future<Uint8List?> cardImage(AssetEntity asset) => _image(asset, _cardEdge, quality: 90);
```

Second, decode only as large as the screen can show, picking the side that matters for a cover-fit:

```dart
final photoIsWider = w / h > screen.width / screen.height;
return photoIsWider
    ? ResizeImage(image, height: screen.height.round())
    : ResizeImage(image, width: screen.width.round());
```

Then the next few photos are fetched and decoded *before* they're needed, so no swipe frame ever waits on a decode:

```dart
void _warmUpcoming(List<AssetEntity> queue) {
  for (final asset in queue.take(CardStack.builtCards + 2)) {
    if (!_warmed.add(asset.id)) continue;           // each photo once
    repo.cardImage(asset).then((bytes) {
      if (bytes != null && mounted) precacheImage(cardImageProvider(context, bytes, asset), context);
    });
  }
}
```

---

## 5. The database

### Why one at all

The app must remember which photos you've reviewed — across launches, for tens of thousands of photos, with fast lookups. That's a database. SQLite is built into both platforms; `sqflite` is the Dart wrapper.

Four tables, created once:

```sql
CREATE TABLE swipe_decisions (
  asset_id   TEXT PRIMARY KEY,
  decision   TEXT NOT NULL CHECK (decision IN ('keep', 'delete')),
  session_id TEXT NOT NULL,
  timestamp  INTEGER NOT NULL
);
```

`trash_queue` holds photos marked for deletion, `sessions` powers the stats, `app_settings` is key-value. No photos are stored — only the OS's own identifiers.

### Transactions

Recording a delete touches three tables. A transaction makes it all-or-nothing:

```dart
await _db.transaction((txn) async {
  await txn.insert(Tables.decisions, {...}, conflictAlgorithm: ConflictAlgorithm.replace);
  if (decision == Decision.delete) {
    await txn.insert(Tables.trash, {...});
  }
  await txn.rawUpdate('UPDATE ${Tables.sessions} SET $column = $column + 1 WHERE session_id = ?', [sessionId]);
});
```

Kill the app halfway through and you get either all three changes or none — never a trash entry with no decision behind it.

### Making a database reactive

SQLite has no "tell me when this changes". Rather than reaching for a heavier library, `AppDatabase` announces which tables changed and re-runs the query:

```dart
void notify(Iterable<String> tables) { for (final t in tables) _changes.add(t); }

Stream<T> watch<T>(Set<String> tables, Future<T> Function() query) {
  // emits query() now, and again whenever one of `tables` changes
}
```

So the trash pill is:

```dart
Stream<TrashSummary> watchSummary() => _app.watch({Tables.trash}, pendingSummary);
```

Swipe left anywhere in the app and the counter updates itself. About 40 lines of plumbing instead of a dependency.

---

## 6. The swipe

The interaction has four jobs: follow the finger, decide what a release means, animate the card away, and let you take it back.

### Rules as pure functions

The decision rules live apart from the UI, in [`swipe_physics.dart`](../lib/features/swipe_session/widgets/swipe_physics.dart) — no widgets, no animation, just maths:

```dart
static Decision? resolve({required double dx, required double velocityX, required double width}) {
  final flung = velocityX.abs() >= velocityThreshold;
  // A fling against the drag direction cancels rather than flipping sides.
  if (flung && (dx == 0 || dx.sign == velocityX.sign)) {
    return velocityX > 0 ? Decision.keep : Decision.delete;
  }
  if (dx.abs() >= width * distanceThreshold) {
    return dx > 0 ? Decision.keep : Decision.delete;
  }
  return null;   // spring back
}
```

Pure functions are trivially testable — no phone, no screen, no waiting. That file has the most tests in the project for a reason.

### Following the finger

```dart
void _onPanUpdate(DragUpdateDetails d) {
  if (_flying) return;
  _offset.value += d.delta;     // a ValueNotifier, not setState
}
```

`_offset` is a `ValueNotifier` rather than widget state, and this is the optimization pass you asked for. With `setState`, every frame of a drag rebuilds all four cards — including the widget holding the decoded photo. With a notifier, only the small builder that applies the transform re-runs:

```dart
child: ValueListenableBuilder<Offset>(
  valueListenable: _offset,
  child: SwipeCardFace(asset: asset),     // built once, reused every frame
  builder: (context, offset, face) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: SwipePhysics.rotation(offset.dx, _size.width),
        alignment: const Alignment(0, 1.4),   // pivot below the card
        child: Stack(children: [face!, SwipeFeedback(progress: ...)]),
      ),
    );
  },
),
```

The `child` argument is the trick: anything passed there is built once and handed back unchanged on every rebuild. The photo, its shadow and its caption sit inside a `RepaintBoundary`, so the GPU moves a cached layer rather than redrawing the image.

### Letting go

Release below the threshold and the card springs home — using real spring physics, seeded with the speed your finger had, so there's no visual jolt:

```dart
static final _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 1);
// ratio: 1 = critically damped: fast, and it never wobbles past the target.
await _anim.animateWith(SpringSimulation(_spring, 0, 1, v)).orCancel;
```

Release past it and the card flies off, keeping your speed if you threw it:

```dart
if (velocity.dx.abs() >= 800 && velocity.dx.sign == sign) {
  final seconds = (remaining / velocity.dx.abs()).clamp(0.12, 0.35);
  curve = Curves.linear;        // matches the finger exactly
} else {
  duration = const Duration(milliseconds: 260);
  curve = Curves.easeInCubic;   // accelerates away from rest
}
```

### One path for buttons and gestures

The ✕ and ✓ buttons don't have their own logic. They drive the same animation through a controller:

```dart
class CardStackController {
  void swipe(Decision decision) => _state?._flyOut(decision);
  void animateReturn(Decision from) => _state?._animateReturn(from);
}
```

So a button press and a swipe are literally the same code — they can't drift apart, and one test covers both.

### Undo

The session keeps a stack of recent decisions. Undo pops one, puts the photo back at the front of the queue, and reverses the database rows. The UI asks *which way* the card left before restoring it, so it slides back in from the correct side:

```dart
void _undo() {
  final from = _controller.peekUndo;   // Decision.keep or .delete
  if (from == null) return;
  _controller.undo();                  // state changes
  _stack.animateReturn(from);          // card slides back from that side
}
```

---

## 7. Look and motion

### Colours

Flutter's `ColorScheme.fromSeed` generates a palette from one colour — convenient, but it kept producing purple tints in buttons and switches. So every role is stated explicitly:

```dart
const scheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.accent,        // sky blue
  surface: AppColors.surface,
  error: AppColors.delete,
  ...
);
```

Three signal colours carry meaning: green = keep, red = delete, blue = everything interactive.

### One motion language

Everything slides. That's enforced by turning off the alternatives:

```dart
splashFactory: NoSplash.splashFactory,   // no ripples
highlightColor: Colors.transparent,
pageTransitionsTheme: const PageTransitionsTheme(builders: { ... slide ... }),
```

and by sharing a small vocabulary in [`slide_motion.dart`](../lib/shared_widgets/slide_motion.dart):

| Widget | Use |
|---|---|
| `SlideIn` | Content slides up into place once, optionally after a delay |
| `SlideSwitcher` | Swaps one child for another: new one slides in, old one slides out |
| `SlideLoader` | A sliding bar instead of a spinner |
| `PressSlide` | Press feedback: the element nudges in the direction of its action |
| `showSlideToast` | Messages slide up from the bottom |

One detail worth copying into other projects — respect the user's motion setting:

```dart
@media (prefers-reduced-motion: reduce) { ... }   // the website
```
```dart
if (reducedMotion.matches) { /* jump straight to the end state */ }
```

---

## 8. Tests

Three files, three kinds of test.

**`logic_test.dart` — pure functions.** Fast, no Flutter needed:

```dart
test('a fling back toward center does not flip the decision', () {
  expect(SwipePhysics.resolve(dx: 60, velocityX: -1500, width: w), isNull);
  expect(SwipePhysics.resolve(dx: 200, velocityX: -1500, width: w), Decision.keep);
});
```

**`database_test.dart` — real SQLite, in memory.** `sqflite_common_ffi` runs the same database engine on your computer:

```dart
app = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
```

The most valuable one asserts the safety property the delete flow depends on:

```dart
test('markCommitted is idempotent and credits the swiping session', () async {
  final first = await trash.markCommitted(['b', 'c']);
  final again = await trash.markCommitted(['b', 'c']);
  expect((first.count, first.bytes), (2, 1500));
  expect(again.count, 0);      // running twice changes nothing
});
```

**`card_stack_test.dart` — widget tests.** A real widget tree in a fake 400×600 screen, driven by simulated gestures:

```dart
await tester.timedDrag(find.byKey(const ValueKey('1')), const Offset(220, 0), const Duration(milliseconds: 600));
await settle(tester);
expect(swiped, [('1', Decision.keep)]);
```

One gotcha worth knowing: `pumpAndSettle()` waits for *all* animation to stop, and hangs forever if something animates indefinitely (a loading spinner, for instance). That's why these tests advance time explicitly:

```dart
Future<void> settle(WidgetTester tester) async {
  await tester.pump();                             // first frame starts the ticker
  await tester.pump(const Duration(seconds: 1));   // jump past the animation
}
```

Run them with `flutter test`. Run `flutter analyze` too — it catches missing `await`s, dead code, and misuse of `BuildContext` across async gaps.

---

## 9. The website

### Why Next.js, and why "static export"

The site could be plain HTML (it was, at first). The reason to use Next.js is components — a header written once, used on every page. The reason to *export statically* is that search engines and slow phones get finished HTML with no waiting:

```js
// web/next.config.mjs
const nextConfig = {
  output: 'export',      // `next build` writes plain .html files to out/
  trailingSlash: true,   // /download/ -> download/index.html
};
```

There's no server. `out/` is a folder of files you can host anywhere.

### Server and client components

In the App Router, components render on the build machine by default. Only those marked `'use client'` also ship JavaScript to the browser:

```tsx
'use client';   // needs state, effects or event handlers
export function MobileDownloadBar() { ... }
```

Rule of thumb: if it needs `useState`, `useEffect` or an `onClick`, it's a client component. Everything else stays server-rendered and costs the visitor nothing.

### SEO, concretely

Search engines read the HTML. Each page declares its own metadata:

```tsx
export const metadata: Metadata = {
  title: 'Download Swipr for Android & iPhone — Free Photo Cleaner App',
  description: 'Download Swipr, the free swipe-to-delete photo cleaner...',
  alternates: { canonical: '/download/' },
};
```

and structured data describes the app in a format Google parses directly:

```tsx
<JsonLd graph={[appSchema(), breadcrumbSchema('Download', '/download/')]} />
```

The FAQ page builds its schema from the same array that renders the questions, so the two can never disagree. `scripts/check.mjs` then fails the build on the classic mistakes: titles too long, duplicate `<h1>`s, broken links, invalid JSON-LD, missing canonicals.

### Mobile first

The visitors are people holding the phone they'd install on, so on screens under 760px:

- the interactive demo moves **above** the sales copy (it's the hook, and it now appears within the first screenful rather than 700px down);
- every tap target is at least 44px tall;
- a download button sticks to the bottom once you scroll past the hero, and on Android it links straight to the APK.

```css
@media (max-width: 760px) {
  .hero__demo { order: -1; }
  .link-arrow, .site-footer ul a, .faq summary { min-height: 44px; display: flex; align-items: center; }
  .mobile-cta { transform: translateY(110%); transition: transform var(--medium) var(--ease); }
  .mobile-cta.is-shown { transform: none; }
}
```

### The build pipeline

```bash
npm run build
```

runs three scripts around Next:

1. `scripts/prepare.mjs` — reads the version from `pubspec.yaml`, copies the signed APK into `public/downloads`, records its size and SHA-256, writes the manifest and favicon.
2. `next build` — renders every page to HTML.
3. `scripts/headers.mjs` — hashes the inline scripts Next generates and writes `out/_headers` with a strict content security policy.

---

## 10. Building and publishing

### Versions

```yaml
version: 1.0.0+1
```

`1.0.0` is the version name people see. `+1` is the build number — Play and Apple both reject an upload whose build number isn't higher than the last one. Bump it every single upload, even for a one-line fix.

### Signing

Every Android app is signed with a cryptographic key. The signature — not the name, not the file — is how Android knows an update came from the same developer. Install from one key and try to update with another and you get "App not installed"; the user has to uninstall first, losing their data.

That makes your keystore the single most precious file in the project. Ours stays outside the repo, with its passwords in a gitignored file:

```properties
# android/key.properties — never committed
storeFile=C:/Users/greni/keystores/cash-compass.jks
storePassword=…
keyAlias=…
keyPassword=…
```

Gradle reads it, and deliberately falls back to a throwaway debug key when it's missing, so a fresh clone still builds:

```kotlin
val hasReleaseKey = keystoreFile?.exists() == true &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank()

buildTypes {
    release {
        signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
    }
}
```

Verify what you actually built — never assume:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

If it says `CN=Android Debug`, it's unshippable.

### Two build formats

```bash
flutter build appbundle --release   # .aab — for Google Play only
flutter build apk --release         # .apk — installs directly, for your website
```

An **App Bundle** isn't installable. You upload it and Google generates a tailored APK per device, so downloads are smaller. An **APK** is the installable package — needed for anything outside the store.

`flutter build apk --split-per-abi` produces one APK per processor type (~20 MB each instead of 46 MB), at the cost of making the user pick.

**The gotcha to plan for:** if you use Play App Signing with a key Google generates, Play re-signs your app. Your website APK and the Play version then have *different* signatures, so sideloaders can't update through Play. Either upload your own key to Play so both match, or drop the direct download once Play is live.

### iOS

iOS builds require macOS — Xcode only runs there. From Windows the options are a Mac, or a cloud Mac service (Codemagic, Xcode Cloud). You also need the Apple Developer Program ($99/year). The flow is `flutter build ipa`, upload, then TestFlight before the App Store.

### The store paperwork

Both stores ask what data you collect. For this app the answer is genuinely "none" — no analytics, no crash reporter, no internet permission on Android — which makes Play's Data Safety form and Apple's privacy labels quick. Both also require a privacy policy URL, which is why the site has `/privacy/`.

Photo access is a sensitive permission. Expect to explain in the listing why a photo cleaner needs it.

The full sequence is in [LAUNCH.md](../LAUNCH.md).

---

## 11. Cookbook

**Change a colour.** `lib/core/theme/app_theme.dart` → `AppColors`. Everything reads from there.

**Add a setting.**
1. Add the field to `AppSettings` in `lib/data/models.dart` (and `copyWith`).
2. Read/write it in `SettingsDao` (`lib/data/database/daos.dart`).
3. Add the control to `lib/features/stats/settings_sheet.dart`.
4. Add a case to `database_test.dart`.

**Add a screen.**
1. Create `lib/features/<area>/<name>_screen.dart`.
2. Add a helper to `lib/core/routing/routes.dart` so navigation stays in one place.
3. Use `SlideSwitcher` / `SlideIn` so it matches the motion language.

**Change how a swipe commits.** `swipe_physics.dart` — then update `logic_test.dart`, which will tell you immediately if you broke the feel.

**Change website copy.** Text lives in the page files under `web/app/`; FAQ entries in `web/lib/faq.ts`. Then `npm run build && npm run check`.

**Release a new version.**
```bash
# 1. bump version: 1.0.1+2 in pubspec.yaml
flutter analyze && flutter test
flutter build appbundle --release          # upload to Play
flutter build apk --release                # for the site
cd web && npm run build && npm run check   # picks up the new APK + checksum
```

---

## 12. Glossary

**AAB / App Bundle** — upload format for Play; Google builds per-device APKs from it.
**Adaptive icon** — Android icon made of separate background and foreground layers so launchers can mask it into any shape.
**APK** — the installable Android package.
**Build number** — the `+1` in `1.0.0+1`; must increase with every store upload.
**Content security policy** — a header telling the browser which scripts and styles are allowed to run. Blocks most injected-script attacks.
**Hydration** — a server-rendered page's HTML being "brought to life" by JavaScript in the browser.
**Idempotent** — running it twice has the same effect as running it once. What makes the delete flow interruption-safe.
**Keystore** — the file holding your signing keys. Lose it and you can never update your app.
**Provider** — a named piece of state in Riverpod that widgets can watch.
**Repository pattern** — one class owning all access to an external system, so the rest of the code doesn't depend on it.
**Scoped storage** — Android's rule that apps can't freely read and write shared files; media goes through MediaStore, which is why deletes need OS confirmation.
**Static export** — pre-rendering a site to plain HTML files at build time.
**Widget** — an immutable description of part of the UI. Flutter's basic unit.
