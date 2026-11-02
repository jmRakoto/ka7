import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const _song = ProbeItem(videoId: 'yXs506QBhJY', title: 'Tanalahy ny foko');
const _other = ProbeItem(videoId: 'YW-QLSPY8Ew', title: 'Somambisamby');
const _playlist = Probe(
  title: 'Mahaleo playlist',
  playlistId: 'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
  items: [_song, _other],
);
const _songDownload = PlannedDownload(source: _playlist, item: _song, index: 1);
const _otherDownload = PlannedDownload(
  source: _playlist,
  item: _other,
  index: 2,
);
final _monday = DateTime.utc(2026, 10, 26, 9);
final _friday = DateTime.utc(2026, 10, 30, 18);

void main() {
  // The reopening test holds a file store next to the in-memory one.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Ka7Store store;
  setUp(() => store = Ka7Store.inMemory());
  tearDown(() => store.close());

  group('archive', () {
    test('remembers a video per format', () async {
      await store.add('yXs506QBhJY', MediaFormat.mp3);

      expect(await store.contains('yXs506QBhJY', MediaFormat.mp3), isTrue);
      expect(await store.contains('yXs506QBhJY', MediaFormat.mp4), isFalse);
      expect(await store.contains('YW-QLSPY8Ew', MediaFormat.mp3), isFalse);
    });

    test('accepts the same video twice', () async {
      await store.add('yXs506QBhJY', MediaFormat.mp3);
      await store.add('yXs506QBhJY', MediaFormat.mp3);

      expect(await store.contains('yXs506QBhJY', MediaFormat.mp3), isTrue);
    });

    test('survives closing and reopening its file', () async {
      final folder = Directory.systemTemp.createTempSync('ka7_store_');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/ka7.sqlite');

      final first = Ka7Store.open(file);
      await first.add('yXs506QBhJY', MediaFormat.mp3);
      await first.close();
      final again = Ka7Store.open(file);
      addTearDown(again.close);

      expect(await again.contains('yXs506QBhJY', MediaFormat.mp3), isTrue);
    });
  });

  group('history', () {
    test('keeps how each video ended, newest first', () async {
      await store.record(
        const JobSucceeded(_songDownload, '/music/Mahaleo playlist/01.mp3'),
        MediaFormat.mp3,
        _monday,
      );
      await store.record(
        const JobFailed(_otherDownload, FailureReason.network, 'timed out'),
        MediaFormat.mp3,
        _friday,
      );

      final [failed, succeeded] = await store.history();
      expect(failed.videoId, 'YW-QLSPY8Ew');
      expect(failed.status, HistoryStatus.failed);
      expect(failed.reason, FailureReason.network);
      expect(failed.message, 'timed out');
      expect(failed.at.isAtSameMomentAs(_friday), isTrue);
      expect(succeeded.title, 'Tanalahy ny foko');
      expect(succeeded.album, 'Mahaleo playlist');
      expect(succeeded.format, MediaFormat.mp3);
      expect(succeeded.status, HistoryStatus.succeeded);
      expect(succeeded.path, '/music/Mahaleo playlist/01.mp3');
      expect(succeeded.at.isAtSameMomentAs(_monday), isTrue);
    });

    test('does not keep progress events', () async {
      await store.record(
        const JobStarted(_songDownload),
        MediaFormat.mp3,
        _monday,
      );
      await store.record(
        const JobProgressed(_songDownload, DownloadProgress(fraction: 0.5)),
        MediaFormat.mp3,
        _monday,
      );

      expect(await store.history(), isEmpty);
    });

    test('finds entries by title or playlist, ignoring case', () async {
      await store.record(
        const JobSkipped(_songDownload),
        MediaFormat.mp3,
        _monday,
      );
      await store.record(
        const JobCancelled(_otherDownload),
        MediaFormat.mp4,
        _friday,
      );

      expect((await store.history(search: 'somamb')).map((i) => i.status), [
        HistoryStatus.cancelled,
      ]);
      expect(await store.history(search: 'MAHALEO'), hasLength(2));
    });
  });

  test('forget drops a video from the archive and the history', () async {
    await store.add('yXs506QBhJY', MediaFormat.mp3);
    await store.add('yXs506QBhJY', MediaFormat.mp4);
    await store.record(
      const JobSucceeded(_songDownload, '/music/01.mp3'),
      MediaFormat.mp3,
      _monday,
    );
    await store.record(
      const JobSkipped(_otherDownload),
      MediaFormat.mp3,
      _monday,
    );

    await store.forget('yXs506QBhJY');

    expect(await store.contains('yXs506QBhJY', MediaFormat.mp3), isFalse);
    expect(await store.contains('yXs506QBhJY', MediaFormat.mp4), isFalse);
    expect((await store.history()).map((i) => i.videoId), ['YW-QLSPY8Ew']);
  });

  group('settings', () {
    test('keeps a value until it is changed or removed', () async {
      expect(await store.setting('language'), isNull);

      await store.setSetting('language', 'fr');
      await store.setSetting('language', 'en');
      expect(await store.setting('language'), 'en');

      await store.setSetting('language', null);
      expect(await store.setting('language'), isNull);
    });
  });

  test(
    'upgrades a store written by the first version, keeping its archive',
    () async {
      final folder = Directory.systemTemp.createTempSync('ka7_store_');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/ka7.sqlite');
      sqlite3.open(file.path)
        ..execute(File('test/fixtures/schema_v1.sql').readAsStringSync())
        ..close();

      final upgraded = Ka7Store.open(file);
      addTearDown(upgraded.close);

      expect(await upgraded.contains('jNQXAC9IVRw', MediaFormat.mp3), isTrue);
      await upgraded.setSetting('folder.mp3', '/home/me/Musique');
      expect(await upgraded.setting('folder.mp3'), '/home/me/Musique');
    },
  );
}
