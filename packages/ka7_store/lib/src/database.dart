import 'package:drift/drift.dart';

part 'database.g.dart';

/// Videos already downloaded, per format.
class ArchiveEntries extends Table {
  TextColumn get videoId => text()();

  /// [MediaFormat.name].
  TextColumn get format => text()();

  @override
  Set<Column<Object>> get primaryKey => {videoId, format};
}

/// How each queued video ended, newest last.
class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get videoId => text()();
  TextColumn get title => text()();

  /// Playlist title; null for a single video.
  TextColumn get album => text().nullable()();

  /// Playlist id, to fetch its new videos; null for a video or a channel.
  TextColumn get playlistId => text().nullable()();
  TextColumn get format => text()();

  /// [HistoryStatus.name].
  TextColumn get status => text()();

  /// Saved file, when it succeeded.
  TextColumn get path => text().nullable()();

  /// [FailureReason.name], when it failed.
  TextColumn get reason => text().nullable()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get at => dateTime()();
}

/// User choices: language, folders… (key → value).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Queued videos not ended yet, to resume after a close or a crash.
@DataClassName('PendingRow')
class PendingDownloads extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// [MediaFormat.name].
  TextColumn get format => text()();
  TextColumn get folder => text()();

  /// The playlist, channel or video it comes from.
  TextColumn get sourceTitle => text()();
  TextColumn get sourcePlaylistId => text().nullable()();
  BoolColumn get sourceIsChannel => boolean()();
  TextColumn get videoId => text()();
  TextColumn get title => text()();
  TextColumn get channel => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();

  /// 1-based position in the source.
  IntColumn get position => integer()();

  /// [AudioQuality.name] and [VideoQuality.name]; null before v6 (default).
  TextColumn get audioQuality => text().nullable()();
  TextColumn get videoQuality => text().nullable()();
}

/// Playlists and channels followed: their new videos are offered at launch.
@DataClassName('SubscriptionRow')
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// A playlist id or a channel URL, as `parseEntry` reads it.
  TextColumn get link => text().unique()();
  TextColumn get title => text()();
}

/// Playlists the user made from downloaded files.
@DataClassName('UserPlaylistRow')
class UserPlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// The folder it plays, read on opening; null when made by hand (v8).
  TextColumn get folder => text().nullable()();
  TextColumn get folderLabel => text().nullable()();

  /// Place chosen by the user; null until ordered: after, by creation (v9).
  IntColumn get position => integer().nullable()();
}

/// The files of each user playlist; a snapshot of the history line.
@DataClassName('PlaylistTrackRow')
class PlaylistTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlist =>
      integer().references(UserPlaylists, #id, onDelete: KeyAction.cascade)();

  /// 0-based play order.
  IntColumn get position => integer()();
  TextColumn get videoId => text()();
  TextColumn get title => text()();

  /// [MediaFormat.name].
  TextColumn get format => text()();
  TextColumn get path => text()();
}

@DriftDatabase(
  tables: [
    ArchiveEntries,
    HistoryEntries,
    Settings,
    PendingDownloads,
    Subscriptions,
    UserPlaylists,
    PlaylistTracks,
  ],
)
class Ka7Database extends _$Ka7Database {
  Ka7Database(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(settings);
      if (from < 3) await migrator.createTable(pendingDownloads);
      if (from < 4) {
        await migrator.addColumn(historyEntries, historyEntries.playlistId);
      }
      if (from < 5) await migrator.createTable(subscriptions);
      // Made with these columns when created above (before v3).
      if (from >= 3 && from < 6) {
        await migrator.addColumn(
          pendingDownloads,
          pendingDownloads.audioQuality,
        );
        await migrator.addColumn(
          pendingDownloads,
          pendingDownloads.videoQuality,
        );
      }
      if (from < 7) {
        await migrator.createTable(userPlaylists);
        await migrator.createTable(playlistTracks);
      }
      // Made with these columns when created above (before v7).
      if (from == 7) {
        await migrator.addColumn(userPlaylists, userPlaylists.folder);
        await migrator.addColumn(userPlaylists, userPlaylists.folderLabel);
      }
      if (from >= 7 && from < 9) {
        await migrator.addColumn(userPlaylists, userPlaylists.position);
      }
    },
  );
}
