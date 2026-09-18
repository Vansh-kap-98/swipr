import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo_repository.dart';
import '../../shared_widgets/slide_motion.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

/// Current photo-library permission. `photo_manager` handles the per-OS
/// details (READ_MEDIA_IMAGES on Android 13+, limited access on iOS 14+).
class PhotoPermissionNotifier extends AsyncNotifier<PermissionState> {
  @override
  Future<PermissionState> build() => ref.read(photoRepositoryProvider).permissionState();

  Future<void> request() async {
    state = AsyncData(await ref.read(photoRepositoryProvider).requestPermission());
  }

  Future<void> recheck() async {
    state = AsyncData(await ref.read(photoRepositoryProvider).permissionState());
  }
}

final photoPermissionProvider = AsyncNotifierProvider<PhotoPermissionNotifier, PermissionState>(
  PhotoPermissionNotifier.new,
);

/// Shows [child] once access is granted (full or limited); otherwise an
/// explanation with a way forward — never a dead end.
class PermissionGate extends ConsumerStatefulWidget {
  const PermissionGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends ConsumerState<PermissionGate> with WidgetsBindingObserver {
  bool _askedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have changed access in system settings.
    if (state == AppLifecycleState.resumed) ref.read(photoPermissionProvider.notifier).recheck();
  }

  @override
  Widget build(BuildContext context) {
    final permission = ref.watch(photoPermissionProvider);
    // Granting access slides the app in over the explainer.
    return SlideSwitcher(
      from: const Offset(0, 60),
      child: permission.when(
        loading: () => const Scaffold(key: ValueKey('loading'), body: SlideLoader()),
        error: (e, _) => _Explainer(
          key: const ValueKey('error'),
          title: 'Couldn\'t check photo access',
          body: '$e',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(photoPermissionProvider),
        ),
        data: (state) {
          if (state.hasAccess) return KeyedSubtree(key: const ValueKey('app'), child: widget.child);
          final blocked = _askedOnce || state == PermissionState.denied || state == PermissionState.restricted;
          return _Explainer(
            key: ValueKey('explainer-$blocked'),
            title: 'Let\'s clean up your camera roll',
            body: blocked
                ? 'Swipr needs access to your photos to show them to you. '
                      'Open Settings and allow photo access, then come back.'
                : 'Swipe right to keep, left to delete — like Tinder, but for photos.\n\n'
                      'Swipr needs access to your photo library. Nothing is uploaded; '
                      'everything stays on your device, and nothing is deleted without '
                      'your confirmation.',
            actionLabel: blocked ? 'Open Settings' : 'Allow photo access',
            onAction: () async {
              if (blocked) {
                await ref.read(photoRepositoryProvider).openAppSettings();
              } else {
                await ref.read(photoPermissionProvider.notifier).request();
                if (mounted) setState(() => _askedOnce = true);
              }
            },
          );
        },
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SlideIn(
                from: Offset(-60, 0),
                child: Icon(Icons.photo_library_outlined, size: 72, color: AppColors.accent),
              ),
              const SizedBox(height: 24),
              SlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  title,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              SlideIn(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  body,
                  style: text.bodyLarge?.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              SlideIn(
                delay: const Duration(milliseconds: 240),
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
