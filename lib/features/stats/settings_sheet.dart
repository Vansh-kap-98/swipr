import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../shared_widgets/slide_motion.dart';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const _SettingsSheet(),
);

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  static const _undoOptions = [10, 50, 200];

  /// The reset confirmation slides in over the settings list instead of
  /// popping a dialog on top.
  bool _confirmingReset = false;

  Future<void> _reset() async {
    await ref.read(decisionsDaoProvider).resetHistory();
    if (!mounted) return;
    showSlideToast(context, 'Swipe history reset');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: AnimatedSize(
          duration: Motion.medium,
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: SlideSwitcher(
            clip: true,
            alignment: Alignment.topCenter,
            // Forward: slide in from the right. Back: slide in from the left.
            from: Offset(_confirmingReset ? 80 : -80, 0),
            child: _confirmingReset ? _buildConfirm() : _buildSettings(),
          ),
        ),
      ),
    );
  }

  Widget _buildSettings() {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final dao = ref.read(settingsDaoProvider);
    return Column(
      key: const ValueKey('settings'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        SwitchListTile(
          title: const Text('Offer to delete at session end'),
          subtitle: const Text('Ask to empty the trash when you run out of photos'),
          value: settings.promptDeleteOnSessionEnd,
          onChanged: (v) => dao.save(settings.copyWith(promptDeleteOnSessionEnd: v)),
        ),
        const ListTile(title: Text('Undo history'), subtitle: Text('How many swipes you can take back per session')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (final n in _undoOptions) ButtonSegment(value: n, label: Text('$n'))],
            selected: {_undoOptions.contains(settings.undoLimit) ? settings.undoLimit : 50},
            onSelectionChanged: (v) => dao.save(settings.copyWith(undoLimit: v.first)),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.restart_alt_rounded, color: AppColors.delete),
          title: const Text('Reset swipe history'),
          subtitle: const Text('Show photos you\'ve already kept again'),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          onTap: () => setState(() => _confirmingReset = true),
        ),
      ],
    );
  }

  Widget _buildConfirm() {
    return Padding(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Reset swipe history?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Photos you already kept will show up again. Photos in the trash stay there, and your stats are kept.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.delete,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _reset,
            child: const Text('Reset'),
          ),
          TextButton(onPressed: () => setState(() => _confirmingReset = false), child: const Text('Cancel')),
        ],
      ),
    );
  }
}
