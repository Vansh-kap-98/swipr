import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../data/photo_repository.dart';
import 'slide_motion.dart';

enum PhotoImageSize { grid, card }

/// Image provider for a swipe card, decoded no larger than the screen needs
/// for `BoxFit.cover` (never upscaled). Card widgets and the precache in the
/// swipe session must both go through here so they share one cache entry.
ImageProvider cardImageProvider(BuildContext context, Uint8List bytes, AssetEntity asset) {
  final screen = MediaQuery.sizeOf(context) * MediaQuery.devicePixelRatioOf(context);
  final w = asset.orientatedWidth, h = asset.orientatedHeight;
  final image = MemoryImage(bytes);
  if (w <= 0 || h <= 0 || screen.isEmpty) return image;
  // Cover-fit is bound by whichever side is relatively shorter.
  final photoIsWider = w / h > screen.width / screen.height;
  return photoIsWider
      ? ResizeImage(image, height: screen.height.round())
      : ResizeImage(image, width: screen.width.round());
}

/// Loads an asset's image lazily when built. Accepts either a resolved
/// [AssetEntity] or just an id (e.g. from the trash table); an id that no
/// longer resolves shows a placeholder instead of failing.
class PhotoImage extends ConsumerStatefulWidget {
  const PhotoImage({
    super.key,
    this.asset,
    this.assetId,
    this.size = PhotoImageSize.grid,
    this.fit = BoxFit.cover,
    this.placeholderColor = AppColors.surfaceHigh,
  }) : assert(asset != null || assetId != null);

  final AssetEntity? asset;
  final String? assetId;
  final PhotoImageSize size;
  final BoxFit fit;
  final Color placeholderColor;

  @override
  ConsumerState<PhotoImage> createState() => _PhotoImageState();
}

class _PhotoImageState extends ConsumerState<PhotoImage> {
  late Future<(AssetEntity?, Uint8List)?> _image;

  String get _id => widget.asset?.id ?? widget.assetId!;

  @override
  void initState() {
    super.initState();
    _image = _load();
  }

  @override
  void didUpdateWidget(PhotoImage old) {
    super.didUpdateWidget(old);
    final oldId = old.asset?.id ?? old.assetId;
    if (oldId != _id || old.size != widget.size) _image = _load();
  }

  Future<(AssetEntity?, Uint8List)?> _load() async {
    final repo = ref.read(photoRepositoryProvider);
    final asset = widget.asset ?? await repo.assetById(_id);
    if (asset == null) return null;
    final bytes = await switch (widget.size) {
      PhotoImageSize.grid => repo.gridThumbnail(asset),
      PhotoImageSize.card => repo.cardImage(asset),
    };
    return bytes == null ? null : (asset, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(photoRepositoryProvider);
    final asset = widget.asset;
    final cached = switch (widget.size) {
      PhotoImageSize.grid => repo.cachedGridThumbnail(_id),
      PhotoImageSize.card => repo.cachedCardImage(_id),
    };

    return FutureBuilder<(AssetEntity?, Uint8List)?>(
      future: _image,
      initialData: cached == null ? null : (asset, cached),
      builder: (context, snap) {
        final loaded = snap.data;
        final failed = loaded == null && snap.connectionState == ConnectionState.done;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: widget.placeholderColor,
              child: failed ? const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.muted)) : null,
            ),
            if (loaded != null)
              Image(
                image: widget.size == PhotoImageSize.card && loaded.$1 != null
                    ? cardImageProvider(context, loaded.$2, loaded.$1!)
                    : MemoryImage(loaded.$2),
                fit: widget.fit,
                gaplessPlayback: true,
                // Decoded-in-cache images appear immediately; anything that had
                // to be decoded slides up into place.
                frameBuilder: (context, child, frame, sync) {
                  if (sync) return child;
                  return AnimatedSlide(
                    offset: frame == null ? const Offset(0, 0.04) : Offset.zero,
                    duration: Motion.medium,
                    curve: Motion.curve,
                    child: AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: Motion.medium,
                      curve: Motion.curve,
                      child: child,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
