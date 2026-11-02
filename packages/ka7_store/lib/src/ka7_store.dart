import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ka7_core/ka7_core.dart';

import 'database.dart';

/// How a video ended, as kept in the history.
enum HistoryStatus { succeeded, skipped, failed, cancelled }

/// One line of the history (flow 5).
final class HistoryItem {
  const HistoryItem({
    required this.videoId,
    required this.title,
    required this.format,
    required this.status,
    required this.at,
    this.album,
    this.path,
    this.reason,
    this.message,
  });

  final String videoId;
  final String title;
  final String? album;
  final MediaFormat format;
  final HistoryStatus status;
  final String? path;
  final FailureReason? reason;
  final String? message;
  final DateTime at;
}

/// Ka7's memory between two launches: archive and history, in one SQLite file.
final class Ka7Store implements Archive {
  Ka7Store._(this._db);

  /// Opens, or creates, the store kept in [file].
  factory Ka7Store.open(File file) =>
      Ka7Store._(Ka7Database(NativeDatabase.createInBackground(file)));

  /// A store that lives only as long as the process: for tests.
  factory Ka7Store.inMemory() =>
      Ka7Store._(Ka7Database(NativeDatabase.memory()));

  final Ka7Database _db;

  @override
  Future<bool> contains(String videoId, MediaFormat format) async {
    final query = _db.select(_db.archiveEntries)
      ..where((a) => a.videoId.equals(videoId) & a.format.equals(format.name));
    return await query.getSingleOrNull() != null;
  }

  @override
  Future<void> add(String videoId, MediaFormat format) => _db
      .into(_db.archiveEntries)
      .insertOnConflictUpdate(
        ArchiveEntriesCompanion.insert(videoId: videoId, format: format.name),
      );

  /// Keeps how [event] ended; progress events are not kept.
  Future<void> record(JobEvent event, MediaFormat format, DateTime at) async {
    final (status, path, failure) = switch (event) {
      JobSucceeded(:final path) => (HistoryStatus.succeeded, path, null),
      JobSkipped() => (HistoryStatus.skipped, null, null),
      JobFailed() => (HistoryStatus.failed, null, event),
      JobCancelled() => (HistoryStatus.cancelled, null, null),
      JobStarted() || JobProgressed() => (null, null, null),
    };
    if (status == null) return;
    final download = event.download;
    await _db
        .into(_db.historyEntries)
        .insert(
          HistoryEntriesCompanion.insert(
            videoId: download.item.videoId,
            title: download.item.title,
            album: Value(
              download.source.playlistId == null ? null : download.source.title,
            ),
            format: format.name,
            status: status.name,
            path: Value(path),
            reason: Value(failure?.reason.name),
            message: Value(failure?.message),
            at: at,
          ),
        );
  }

  /// Newest first; [search] matches the title or the playlist.
  Future<List<HistoryItem>> history({String? search}) async {
    final query = _db.select(_db.historyEntries)
      ..orderBy([
        (h) => OrderingTerm.desc(h.at),
        (h) => OrderingTerm.desc(h.id),
      ]);
    if (search != null && search.isNotEmpty) {
      final pattern = '%${search.toLowerCase()}%';
      query.where(
        (h) => h.title.lower().like(pattern) | h.album.lower().like(pattern),
      );
    }
    return [for (final row in await query.get()) _itemOf(row)];
  }

  /// Removes [videoId] from the archive and the history, to download it again.
  Future<void> forget(String videoId) => _db.transaction(() async {
    await (_db.delete(
      _db.archiveEntries,
    )..where((a) => a.videoId.equals(videoId))).go();
    await (_db.delete(
      _db.historyEntries,
    )..where((h) => h.videoId.equals(videoId))).go();
  });

  Future<String?> setting(String key) async {
    final query = _db.select(_db.settings)..where((s) => s.key.equals(key));
    return (await query.getSingleOrNull())?.value;
  }

  /// Stores [value] under [key]; null removes it.
  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();
    } else {
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: key, value: value),
          );
    }
  }

  Future<void> close() => _db.close();
}

HistoryItem _itemOf(HistoryEntry row) => HistoryItem(
  videoId: row.videoId,
  title: row.title,
  album: row.album,
  format: MediaFormat.values.byName(row.format),
  status: HistoryStatus.values.byName(row.status),
  path: row.path,
  reason: row.reason == null ? null : FailureReason.values.byName(row.reason!),
  message: row.message,
  at: row.at,
);
