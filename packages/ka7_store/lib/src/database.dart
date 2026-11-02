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
}

/// Playlists and channels followed: their new videos are offered at launch.
@DataClassName('SubscriptionRow')
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// A playlist id or a channel URL, as `parseEntry` reads it.
  TextColumn get link => text().unique()();
  TextColumn get title => text()();
}

@DriftDatabase(
  tables: [
    ArchiveEntries,
    HistoryEntries,
    Settings,
    PendingDownloads,
    Subscriptions,
  ],
)
class Ka7Database extends _$Ka7Database {
  Ka7Database(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(settings);
      if (from < 3) await migrator.createTable(pendingDownloads);
      if (from < 4) {
        await migrator.addColumn(historyEntries, historyEntries.playlistId);
      }
      if (from < 5) await migrator.createTable(subscriptions);
    },
  );
}
