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
    this.playlistId,
    this.path,
    this.reason,
    this.message,
  });

  final String videoId;
  final String title;
  final String? album;

  /// The playlist it was downloaded from, to fetch its new videos later;
  /// null for a single video or a channel.
  final String? playlistId;
  final MediaFormat format;
  final HistoryStatus status;
  final String? path;
  final FailureReason? reason;
  final String? message;
  final DateTime at;
}

/// A queued video that had not ended when the app last stopped.
final class PendingDownload {
  const PendingDownload({
    required this.id,
    required this.download,
    required this.format,
    required this.folder,
    this.quality = Quality.standard,
  });

  final int id;
  final PlannedDownload download;

  /// Resumed in the same quality.
  final Quality quality;
  final MediaFormat format;

  /// Absolute folder it was queued to.
  final String folder;
}

/// A playlist or a channel whose new videos are offered at launch.
final class Subscription {
  const Subscription({required this.link, required this.title});

  /// What [parseEntry] reads back: a playlist id or a channel URL.
  final String link;
  final String title;
}

/// A playlist the user made from downloaded files.
final class UserPlaylist {
  const UserPlaylist({
    required this.id,
    required this.name,
    required this.trackCount,
    this.folder,
    this.folderLabel,
  });

  final int id;
  final String name;

  /// Tracks kept in the store; none for a folder (read on opening).
  final int trackCount;

  /// The folder it plays (a path, or a `content://` tree on Android); null
  /// for a playlist made by hand.
  final String? folder;

  /// The folder as the user knows it (`Musique/Mahaleo`).
  final String? folderLabel;

  bool get isFolder => folder != null;
}

/// A downloaded file in a [UserPlaylist].
final class PlaylistTrack {
  const PlaylistTrack({
    required this.videoId,
    required this.title,
    required this.format,
    required this.path,
  });

  /// From a successful line of the history.
  factory PlaylistTrack.of(HistoryItem item) => PlaylistTrack(
    videoId: item.videoId,
    title: item.title,
    format: item.format,
    path: item.path!,
  );

  final String videoId;
  final String title;
  final MediaFormat format;

  /// The file to play.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is PlaylistTrack &&
      other.videoId == videoId &&
      other.format == format &&
      other.path == path &&
      other.title == title;

  @override
  int get hashCode => Object.hash(videoId, format, path, title);
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

  /// Lets [videoId] in [format] be downloaded again; the history stays.
  Future<void> unarchive(String videoId, MediaFormat format) =>
      (_db.delete(_db.archiveEntries)..where(
            (a) => a.videoId.equals(videoId) & a.format.equals(format.name),
          ))
          .go();

  /// The file the latest successful download of [videoId] in [format] made;
  /// null when none is known (skipped, or kept before paths were).
  Future<String?> lastPath(String videoId, MediaFormat format) async {
    final query = _db.select(_db.historyEntries)
      ..where(
        (h) =>
            h.videoId.equals(videoId) &
            h.format.equals(format.name) &
            h.status.equals(HistoryStatus.succeeded.name) &
            h.path.isNotNull(),
      )
      ..orderBy([
        (h) => OrderingTerm.desc(h.at),
        (h) => OrderingTerm.desc(h.id),
      ])
      ..limit(1);
    return (await query.getSingleOrNull())?.path;
  }

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
            playlistId: Value(
              download.source.isChannel ? null : download.source.playlistId,
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

  /// Remembers [downloads], queued to [folder], until each one ends; returns
  /// their ids, in order.
  Future<List<int>> keepPending(
    List<PlannedDownload> downloads,
    MediaFormat format,
    String folder, {
    Quality quality = Quality.standard,
  }) => _db.transaction(() async {
    return [
      for (final download in downloads)
        await _db
            .into(_db.pendingDownloads)
            .insert(
              PendingDownloadsCompanion.insert(
                format: format.name,
                folder: folder,
                sourceTitle: download.source.title,
                sourcePlaylistId: Value(download.source.playlistId),
                sourceIsChannel: download.source.isChannel,
                videoId: download.item.videoId,
                title: download.item.title,
                channel: Value(download.item.channel),
                audioQuality: Value(quality.audio.name),
                videoQuality: Value(quality.video.name),
                durationSeconds: Value(download.item.duration?.inSeconds),
                position: download.index,
              ),
            ),
    ];
  });

  /// [id] has ended: nothing left to resume for it.
  Future<void> dropPending(int id) =>
      (_db.delete(_db.pendingDownloads)..where((p) => p.id.equals(id))).go();

  /// Queued videos that never ended, in queue order.
  Future<List<PendingDownload>> pending() async {
    final query = _db.select(_db.pendingDownloads)
      ..orderBy([(p) => OrderingTerm.asc(p.id)]);
    return [for (final row in await query.get()) _pendingOf(row)];
  }

  /// Follows [link]; following it again renames it.
  Future<void> follow(String link, String title) => _db
      .into(_db.subscriptions)
      .insert(
        SubscriptionsCompanion.insert(link: link, title: title),
        onConflict: DoUpdate(
          (_) => SubscriptionsCompanion(title: Value(title)),
          target: [_db.subscriptions.link],
        ),
      );

  Future<void> unfollow(String link) =>
      (_db.delete(_db.subscriptions)..where((s) => s.link.equals(link))).go();

  /// Oldest first.
  Future<List<Subscription>> subscriptions() async {
    final query = _db.select(_db.subscriptions)
      ..orderBy([(s) => OrderingTerm.asc(s.id)]);
    return [
      for (final row in await query.get())
        Subscription(link: row.link, title: row.title),
    ];
  }

  /// A playlist that plays [folder], read again each time it opens;
  /// returns its id.
  Future<int> createFolderPlaylist(
    String name, {
    required String folder,
    required String label,
  }) => _db
      .into(_db.userPlaylists)
      .insert(
        UserPlaylistsCompanion.insert(
          name: name,
          folder: Value(folder),
          folderLabel: Value(label),
        ),
      );

  /// Makes an empty playlist; returns its id.
  Future<int> createPlaylist(String name) => _db
      .into(_db.userPlaylists)
      .insert(UserPlaylistsCompanion.insert(name: name));

  Future<void> renamePlaylist(int id, String name) =>
      (_db.update(_db.userPlaylists)..where((p) => p.id.equals(id))).write(
        UserPlaylistsCompanion(name: Value(name)),
      );

  /// Removes the playlist; the files stay.
  Future<void> deletePlaylist(int id) => _db.transaction(() async {
    await (_db.delete(
      _db.playlistTracks,
    )..where((t) => t.playlist.equals(id))).go();
    await (_db.delete(_db.userPlaylists)..where((p) => p.id.equals(id))).go();
  });

  /// Puts the playlists in the order of [ids]; any left out keep their
  /// place after them.
  Future<void> orderPlaylists(List<int> ids) => _db.transaction(() async {
    for (final (position, id) in ids.indexed) {
      await (_db.update(_db.userPlaylists)..where((p) => p.id.equals(id)))
          .write(UserPlaylistsCompanion(position: Value(position)));
    }
  });

  /// In the user's order; new ones last.
  Future<List<UserPlaylist>> playlists() async {
    final count = _db.playlistTracks.id.count();
    final query =
        _db.select(_db.userPlaylists).join([
            leftOuterJoin(
              _db.playlistTracks,
              _db.playlistTracks.playlist.equalsExp(_db.userPlaylists.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.userPlaylists.id])
          // Ordered ones by their place, then the others as made.
          ..orderBy([
            OrderingTerm.asc(
              coalesce([
                _db.userPlaylists.position,
                _db.userPlaylists.id + const Constant(1 << 30),
              ]),
            ),
          ]);
    return [
      for (final row in await query.get())
        UserPlaylist(
          id: row.readTable(_db.userPlaylists).id,
          name: row.readTable(_db.userPlaylists).name,
          trackCount: row.read(count) ?? 0,
          folder: row.readTable(_db.userPlaylists).folder,
          folderLabel: row.readTable(_db.userPlaylists).folderLabel,
        ),
    ];
  }

  /// In play order.
  Future<List<PlaylistTrack>> playlistTracks(int id) async {
    final query = _db.select(_db.playlistTracks)
      ..where((t) => t.playlist.equals(id))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return [
      for (final row in await query.get())
        PlaylistTrack(
          videoId: row.videoId,
          title: row.title,
          format: MediaFormat.values.byName(row.format),
          path: row.path,
        ),
    ];
  }

  /// Appends [track] at the end of playlist [id].
  Future<void> addToPlaylist(int id, PlaylistTrack track) =>
      _db.transaction(() async {
        final tracks = await playlistTracks(id);
        await _insertTrack(id, tracks.length, track);
      });

  /// Replaces the tracks of playlist [id]: to remove or reorder.
  Future<void> setPlaylistTracks(int id, List<PlaylistTrack> tracks) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.playlistTracks,
        )..where((t) => t.playlist.equals(id))).go();
        for (final (position, track) in tracks.indexed) {
          await _insertTrack(id, position, track);
        }
      });

  Future<void> _insertTrack(int playlist, int position, PlaylistTrack track) =>
      _db
          .into(_db.playlistTracks)
          .insert(
            PlaylistTracksCompanion.insert(
              playlist: playlist,
              position: position,
              videoId: track.videoId,
              title: track.title,
              format: track.format.name,
              path: track.path,
            ),
          );

  Future<void> close() => _db.close();
}

HistoryItem _itemOf(HistoryEntry row) => HistoryItem(
  videoId: row.videoId,
  title: row.title,
  album: row.album,
  playlistId: row.playlistId,
  format: MediaFormat.values.byName(row.format),
  status: HistoryStatus.values.byName(row.status),
  path: row.path,
  reason: row.reason == null ? null : FailureReason.values.byName(row.reason!),
  message: row.message,
  at: row.at,
);

PendingDownload _pendingOf(PendingRow row) => PendingDownload(
  id: row.id,
  format: MediaFormat.values.byName(row.format),
  folder: row.folder,
  // Kept before v6: the default.
  quality: Quality(
    audio:
        AudioQuality.values.asNameMap()[row.audioQuality] ??
        Quality.standard.audio,
    video:
        VideoQuality.values.asNameMap()[row.videoQuality] ??
        Quality.standard.video,
  ),
  download: PlannedDownload(
    source: Probe(
      title: row.sourceTitle,
      playlistId: row.sourcePlaylistId,
      isChannel: row.sourceIsChannel,
      items: const [],
    ),
    item: ProbeItem(
      videoId: row.videoId,
      title: row.title,
      channel: row.channel,
      duration: row.durationSeconds == null
          ? null
          : Duration(seconds: row.durationSeconds!),
    ),
    index: row.position,
  ),
);
