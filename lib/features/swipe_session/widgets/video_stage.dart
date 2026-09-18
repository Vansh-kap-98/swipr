import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/photo_repository.dart';
import '../../../shared_widgets/photo_image.dart';
import '../../../shared_widgets/slide_motion.dart';

/// Plays a video from the photo library. Shows the thumbnail until the file is
/// ready (it can take a moment — iOS may fetch it from iCloud), then loops it.
/// Tap to pause or resume.
class VideoStage extends StatefulWidget {
  const VideoStage({super.key, required this.asset});

  final AssetEntity asset;

  @override
  State<VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<VideoStage> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    VideoPlayerController? controller;
    try {
      final File? file = await widget.asset.file;
      if (file == null) throw StateError('video file unavailable');
      controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.play();
      setState(() => _controller = controller);
    } catch (_) {
      await controller?.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => controller.value.isPlaying ? controller.pause() : controller.play());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller == null) {
      // Still loading (or unplayable): the poster frame keeps the view filled.
      return Stack(
        fit: StackFit.expand,
        children: [
          PhotoImage(
            asset: widget.asset,
            size: PhotoImageSize.card,
            fit: BoxFit.contain,
            placeholderColor: Colors.transparent,
            showVideoBadge: false,
          ),
          if (_failed)
            Align(
              alignment: const Alignment(0, 0.82),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('This video can\'t be played here', style: TextStyle(fontSize: 13)),
              ),
            )
          else
            const Align(alignment: Alignment(0, 0.9), child: SlideLoader()),
        ],
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          // Paused state gets a play affordance so it's clear a tap resumes.
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) => AnimatedOpacity(
              opacity: value.isPlaying ? 0 : 1,
              duration: Motion.fast,
              child: const Center(
                child: Icon(Icons.play_arrow_rounded, size: 72, color: Colors.white70),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: _Scrubber(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final position = value.position;
        final total = value.duration;
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.accent,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${formatDuration(position)} / ${formatDuration(total)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
}
