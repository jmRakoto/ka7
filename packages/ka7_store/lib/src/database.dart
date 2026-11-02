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

@DriftDatabase(tables: [ArchiveEntries, HistoryEntries, Settings])
class Ka7Database extends _$Ka7Database {
  Ka7Database(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(settings);
    },
  );
}
