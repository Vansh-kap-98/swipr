import 'package:flutter/foundation.dart';

enum Decision { keep, delete }

enum TrashStatus { pending, committed, restored }

enum ScopeKind { all, album, month }

/// What the user chose to swipe through: everything, one album, or one month.
@immutable
class PhotoScope {
  const PhotoScope.all() : kind = ScopeKind.all, albumId = null, albumName = null, year = null, month = null;

  const PhotoScope.album({required String id, required String name})
    : kind = ScopeKind.album,
      albumId = id,
      albumName = name,
      year = null,
      month = null;

  const PhotoScope.month({required int this.year, required int this.month})
    : kind = ScopeKind.month,
      albumId = null,
      albumName = null;

  final ScopeKind kind;
  final String? albumId;
  final String? albumName;
  final int? year;
  final int? month;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get label => switch (kind) {
    ScopeKind.all => 'Everything',
    ScopeKind.album => albumName ?? 'Album',
    ScopeKind.month => '${_monthNames[month! - 1]} $year',
  };

  /// Stable string form stored in `sessions.scope`.
  String encode() => switch (kind) {
    ScopeKind.all => 'all',
    ScopeKind.album => 'album|$albumId|$albumName',
    ScopeKind.month => 'month|$year|$month',
  };

  static PhotoScope? decode(String raw) {
    final parts = raw.split('|');
    try {
      switch (parts.first) {
        case 'all':
          return const PhotoScope.all();
        case 'album':
          return PhotoScope.album(id: parts[1], name: parts.sublist(2).join('|'));
        case 'month':
          return PhotoScope.month(year: int.parse(parts[1]), month: int.parse(parts[2]));
      }
    } catch (_) {
      // Fall through: unreadable scopes are ignored rather than crashing.
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is PhotoScope && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

@immutable
class AlbumInfo {
  const AlbumInfo({required this.id, required this.name, required this.count, required this.isAll, this.coverAssetId});

  final String id;
  final String name;
  final int count;
  final bool isAll;
  final String? coverAssetId;
}

@immutable
class MonthBucket {
  const MonthBucket({required this.year, required this.month, required this.count, this.coverAssetId});

  final int year;
  final int month;
  final int count;
  final String? coverAssetId;

  PhotoScope get scope => PhotoScope.month(year: year, month: month);
}

@immutable
class TrashItem {
  const TrashItem({required this.assetId, required this.fileSizeBytes, required this.addedAt, required this.status});

  final String assetId;
  final int fileSizeBytes;
  final DateTime addedAt;
  final TrashStatus status;
}

@immutable
class TrashSummary {
  const TrashSummary({required this.count, required this.bytes});

  static const empty = TrashSummary(count: 0, bytes: 0);

  final int count;
  final int bytes;
}

@immutable
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.scope,
    required this.keptCount,
    required this.deletedCount,
    required this.bytesFreed,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final PhotoScope? scope;
  final int keptCount;
  final int deletedCount;
  final int bytesFreed;

  int get reviewedCount => keptCount + deletedCount;
  bool get isOpen => endedAt == null;
}

@immutable
class AllTimeStats {
  const AllTimeStats({
    required this.sessionCount,
    required this.reviewedCount,
    required this.deletedPhotoCount,
    required this.bytesFreed,
    required this.currentStreakDays,
    required this.recentSessions,
  });

  final int sessionCount;
  final int reviewedCount;
  final int deletedPhotoCount;
  final int bytesFreed;
  final int currentStreakDays;
  final List<SessionRecord> recentSessions;
}

@immutable
class AppSettings {
  const AppSettings({this.undoLimit = 50, this.promptDeleteOnSessionEnd = true});

  final int undoLimit;
  final bool promptDeleteOnSessionEnd;

  AppSettings copyWith({int? undoLimit, bool? promptDeleteOnSessionEnd}) => AppSettings(
    undoLimit: undoLimit ?? this.undoLimit,
    promptDeleteOnSessionEnd: promptDeleteOnSessionEnd ?? this.promptDeleteOnSessionEnd,
  );
}
