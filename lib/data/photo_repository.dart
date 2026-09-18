import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import 'models.dart';

export 'package:photo_manager/photo_manager.dart' show AssetEntity, PermissionState, PermissionStateExt;

/// The only place in the app that talks to `photo_manager`. Screens and
/// providers go through this so an upgrade or package swap touches one file.
class PhotoRepository {
  static const _permissionOption = PermissionRequestOption(
    androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
  );

  static FilterOptionGroup _filter({DateTimeCond? createdBetween}) => FilterOptionGroup(
    orders: const [OrderOption(type: OrderOptionType.createDate, asc: false)],
    createTimeCond: createdBetween,
  );

  // ---- Permissions --------------------------------------------------------

  Future<PermissionState> permissionState() => PhotoManager.getPermissionState(requestOption: _permissionOption);

  Future<PermissionState> requestPermission() => PhotoManager.requestPermissionExtend(requestOption: _permissionOption);

  Future<void> openAppSettings() => PhotoManager.openSetting();

  /// iOS 14+ / Android 14+: lets a limited-access user pick more photos.
  Future<void> selectMorePhotos() => PhotoManager.presentLimited(type: RequestType.image);

  // ---- Browsing -----------------------------------------------------------

  Future<List<AlbumInfo>> albums() async {
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image, filterOption: _filter());
    final albums = <AlbumInfo>[];
    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (count == 0) continue;
      final cover = await path.getAssetListRange(start: 0, end: 1);
      albums.add(
        AlbumInfo(
          id: path.id,
          name: path.isAll ? 'Everything' : path.name,
          count: count,
          isAll: path.isAll,
          coverAssetId: cover.firstOrNull?.id,
        ),
      );
    }
    albums.sort((a, b) {
      if (a.isAll != b.isAll) return a.isAll ? -1 : 1;
      return b.count.compareTo(a.count);
    });
    return albums;
  }

  /// Groups the whole library into month buckets, newest first. Reads
  /// metadata only (no image data), in pages.
  Future<List<MonthBucket>> monthBuckets() async {
    final all = await _allPath();
    if (all == null) return const [];
    final assets = await _loadAll(all);
    final buckets = <(int, int), List<AssetEntity>>{};
    for (final a in assets) {
      final d = a.createDateTime;
      buckets.putIfAbsent((d.year, d.month), () => []).add(a);
    }
    final keys = buckets.keys.toList()..sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : b.$2.compareTo(a.$2));
    return [
      for (final k in keys)
        MonthBucket(year: k.$1, month: k.$2, count: buckets[k]!.length, coverAssetId: buckets[k]!.first.id),
    ];
  }

  /// Every photo in [scope], newest first. Only metadata is loaded; image
  /// bytes are fetched lazily per card via [cardImage].
  Future<List<AssetEntity>> assetsInScope(PhotoScope scope) async {
    switch (scope.kind) {
      case ScopeKind.all:
        final all = await _allPath();
        return all == null ? const [] : _loadAll(all);
      case ScopeKind.album:
        final paths = await PhotoManager.getAssetPathList(type: RequestType.image, filterOption: _filter());
        final path = paths.where((p) => p.id == scope.albumId).firstOrNull;
        return path == null ? const [] : _loadAll(path);
      case ScopeKind.month:
        final start = DateTime(scope.year!, scope.month!);
        final end = DateTime(scope.year!, scope.month! + 1).subtract(const Duration(milliseconds: 1));
        final all = await _allPath(
          filter: _filter(
            createdBetween: DateTimeCond(min: start, max: end),
          ),
        );
        return all == null ? const [] : _loadAll(all);
    }
  }

  Future<AssetPathEntity?> _allPath({FilterOptionGroup? filter}) async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: filter ?? _filter(),
    );
    return paths.firstOrNull;
  }

  Future<List<AssetEntity>> _loadAll(AssetPathEntity path) async {
    const pageSize = 500;
    final total = await path.assetCountAsync;
    final out = <AssetEntity>[];
    for (var start = 0; start < total; start += pageSize) {
      out.addAll(await path.getAssetListRange(start: start, end: math.min(start + pageSize, total)));
    }
    return out;
  }

  // ---- Single assets ------------------------------------------------------

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

  Future<bool> exists(String id) async {
    try {
      return await PhotoManager.plugin.assetExistsWithId(id);
    } catch (_) {
      return false;
    }
  }

  Future<int> fileSize(AssetEntity asset) async {
    try {
      return await asset.fileSize;
    } catch (_) {
      return 0;
    }
  }

  // ---- Image data (lazy + cached) ----------------------------------------

  final _cache = _LruCache<String, Uint8List?>(capacity: 60);

  static const _gridEdge = 300, _cardEdge = 1600;

  static String _key(AssetEntity asset, int longEdge) => '${asset.id}@$longEdge';

  Future<Uint8List?> gridThumbnail(AssetEntity asset) => _image(asset, _gridEdge, quality: 80);

  /// Already-decoded bytes, if any, so widgets can paint without a
  /// placeholder frame.
  Uint8List? cachedGridThumbnail(String assetId) => _cache.ready('$assetId@$_gridEdge');
  Uint8List? cachedCardImage(String assetId) => _cache.ready('$assetId@$_cardEdge');

  /// Screen-sized image for the swipe card.
  Future<Uint8List?> cardImage(AssetEntity asset) => _image(asset, _cardEdge, quality: 90);

  /// Near-full-resolution image for the zoom view, capped to keep memory sane.
  /// Uses a JPEG render so HEIC and other formats decode everywhere.
  Future<Uint8List?> zoomImage(AssetEntity asset) => _image(asset, 3072, quality: 95, cache: false);

  Future<Uint8List?> _image(AssetEntity asset, int longEdge, {required int quality, bool cache = true}) {
    final key = _key(asset, longEdge);
    final hit = _cache.get(key);
    if (hit != null) return hit;

    final w = asset.orientatedWidth, h = asset.orientatedHeight;
    final scale = (w <= 0 || h <= 0) ? 1.0 : math.min(1.0, longEdge / math.max(w, h));
    final size = (w <= 0 || h <= 0)
        ? ThumbnailSize.square(longEdge)
        : ThumbnailSize(math.max(1, (w * scale).round()), math.max(1, (h * scale).round()));

    final future = asset.thumbnailDataWithSize(size, quality: quality).catchError((Object e) {
      debugPrint('thumbnail(${asset.id}) failed: $e');
      return null;
    });
    if (cache) {
      _cache.put(key, future);
      // Don't cache failures; a retry later may succeed (e.g. iCloud download).
      future.then((bytes) {
        if (bytes == null) {
          _cache.remove(key);
        } else {
          _cache.markReady(key, bytes);
        }
      });
    }
    return future;
  }

  void evict(Iterable<String> assetIds) {
    final ids = assetIds.toSet();
    _cache.removeWhere((key) => ids.contains(key.split('@').first));
  }

  // ---- Deletion -----------------------------------------------------------

  /// Asks the OS to delete [ids] in one request: one confirmation dialog on
  /// iOS (PHAssetChangeRequest.deleteAssets) and Android 11+
  /// (MediaStore.createDeleteRequest). Returns the ids that are confirmed
  /// gone afterwards — verified per id, since a cancelled dialog, a partial
  /// failure, or an older Android version may delete fewer than requested.
  Future<Set<String>> deleteAssets(List<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      await PhotoManager.editor.deleteWithIds(ids);
    } catch (e) {
      debugPrint('deleteWithIds failed: $e');
    }
    final gone = <String>{};
    for (final id in ids) {
      if (!await exists(id)) gone.add(id);
    }
    evict(gone);
    return gone;
  }
}

class _LruCache<K, V> {
  _LruCache({required this.capacity});

  final int capacity;
  final _map = <K, Future<V>>{};
  final _ready = <K, V>{};

  V? ready(K key) => _ready[key];

  void markReady(K key, V value) {
    if (_map.containsKey(key)) _ready[key] = value;
  }

  Future<V>? get(K key) {
    final v = _map.remove(key);
    if (v != null) _map[key] = v;
    return v;
  }

  void put(K key, Future<V> value) {
    _map.remove(key);
    _map[key] = value;
    while (_map.length > capacity) {
      remove(_map.keys.first);
    }
  }

  void remove(K key) {
    _map.remove(key);
    _ready.remove(key);
  }

  void removeWhere(bool Function(K key) test) {
    _map.removeWhere((k, _) => test(k));
    _ready.removeWhere((k, _) => test(k));
  }
}
