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

  group('playlist of a history entry', () {
    test('is kept for a video from a playlist, not for a single one', () async {
      const single = Probe(title: 'Hafatra', items: [_song]);
      await store.record(
        const JobSucceeded(_songDownload, '/m/01.mp3'),
        MediaFormat.mp3,
        _monday,
      );
      await store.record(
        const JobSucceeded(
          PlannedDownload(source: single, item: _other, index: 1),
          '/m/Somambisamby.mp3',
        ),
        MediaFormat.mp3,
        _friday,
      );

      final [fromSingle, fromPlaylist] = await store.history();
      expect(fromPlaylist.playlistId, 'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy');
      expect(fromSingle.playlistId, isNull);
    });

    test('is not kept for a channel: its id is not a playlist', () async {
      const channel = Probe(
        title: 'Mahaleo',
        playlistId: 'UCmahaleo0000000000000000',
        isChannel: true,
        items: [],
      );
      await store.record(
        const JobSucceeded(
          PlannedDownload(source: channel, item: _song, index: 1),
          '/m/Mahaleo/x.mp3',
        ),
        MediaFormat.mp3,
        _monday,
      );

      expect((await store.history()).single.playlistId, isNull);
    });
  });

  test(
    'upgrades a store from before playlist ids, keeping its history',
    () async {
      final folder = Directory.systemTemp.createTempSync('ka7_store_');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/ka7.sqlite');
      sqlite3.open(file.path)
        ..execute(File('test/fixtures/schema_v3.sql').readAsStringSync())
        ..close();

      final upgraded = Ka7Store.open(file);
      addTearDown(upgraded.close);

      final old = (await upgraded.history()).single;
      expect(old.title, 'Me at the zoo');
      expect(old.playlistId, isNull);
      await upgraded.record(
        const JobSucceeded(_songDownload, '/m/01.mp3'),
        MediaFormat.mp3,
        _friday,
      );
      expect(
        (await upgraded.history()).first.playlistId,
        'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
      );
    },
  );

  group('subscriptions', () {
    test('follows playlists and channels until told to stop', () async {
      await store.follow('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy', 'Mahaleo');
      await store.follow(
        'https://www.youtube.com/channel/UCmahaleo0000000000000000',
        'Mahaleo official',
      );
      await store.follow('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy', 'Mahaleo 2026');

      expect((await store.subscriptions()).map((s) => '${s.link} ${s.title}'), [
        'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy Mahaleo 2026',
        'https://www.youtube.com/channel/UCmahaleo0000000000000000 Mahaleo official',
      ]);

      await store.unfollow('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy');
      expect(await store.subscriptions(), hasLength(1));
    });
  });

  test('upgrades a store from before subscriptions', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_store_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');
    sqlite3.open(file.path)
      ..execute(File('test/fixtures/schema_v4.sql').readAsStringSync())
      ..close();

    final upgraded = Ka7Store.open(file);
    addTearDown(upgraded.close);

    expect(await upgraded.contains('jNQXAC9IVRw', MediaFormat.mp3), isTrue);
    await upgraded.follow('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy', 'Mahaleo');
    expect(await upgraded.subscriptions(), hasLength(1));
  });

  test('upgrades a store from before download quality', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_store_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');
    sqlite3.open(file.path)
      ..execute(File('test/fixtures/schema_v5.sql').readAsStringSync())
      ..close();

    final upgraded = Ka7Store.open(file);
    addTearDown(upgraded.close);

    final [kept] = await upgraded.pending();
    expect(kept.download.item.title, 'Me at the zoo');
    expect(kept.quality.audio, AudioQuality.kbps192);
    expect(kept.quality.video, VideoQuality.p1080);
  });

  group('pending downloads', () {
    test('keeps the quality they were asked in', () async {
      await store.keepPending(
        [_songDownload],
        MediaFormat.mp4,
        '/home/me/Vidéos',
        quality: const Quality(
          audio: AudioQuality.kbps320,
          video: VideoQuality.p720,
        ),
      );

      final [kept] = await store.pending();
      expect(kept.quality.audio, AudioQuality.kbps320);
      expect(kept.quality.video, VideoQuality.p720);
    });

    test('keeps queued videos, with their source, until they end', () async {
      final ids = await store.keepPending(
        [_songDownload, _otherDownload],
        MediaFormat.mp3,
        '/home/me/Musique',
      );

      await store.dropPending(ids.first);

      final [left] = await store.pending();
      expect(left.id, ids.last);
      expect(left.format, MediaFormat.mp3);
      expect(left.folder, '/home/me/Musique');
      expect(left.download.index, 2);
      expect(left.download.item.videoId, 'YW-QLSPY8Ew');
      expect(left.download.item.title, 'Somambisamby');
      expect(left.download.source.title, 'Mahaleo playlist');
      expect(
        left.download.source.playlistId,
        'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
      );
      expect(left.download.source.isChannel, isFalse);
    });

    test('keeps every detail the file name and tags need', () async {
      const channel = Probe(
        title: 'Mahaleo',
        playlistId: 'UCmahaleo0000000000000000',
        isChannel: true,
        items: [],
      );
      const video = ProbeItem(
        videoId: 'yXs506QBhJY',
        title: 'Tanalahy ny foko',
        channel: 'Mahaleo',
        duration: Duration(minutes: 4, seconds: 12),
      );
      await store.keepPending(
        [const PlannedDownload(source: channel, item: video, index: 7)],
        MediaFormat.mp4,
        '/home/me/Vidéos',
      );

      final [kept] = await store.pending();
      expect(kept.download.source.isChannel, isTrue);
      expect(kept.download.item.channel, 'Mahaleo');
      expect(
        kept.download.item.duration,
        const Duration(minutes: 4, seconds: 12),
      );
      expect(kept.download.index, 7);
    });

    test('lists them in the order they were queued', () async {
      await store.keepPending([_otherDownload], MediaFormat.mp4, '/v');
      await store.keepPending([_songDownload], MediaFormat.mp3, '/m');

      expect((await store.pending()).map((p) => p.download.item.videoId), [
        'YW-QLSPY8Ew',
        'yXs506QBhJY',
      ]);
    });
  });

  test('upgrades a store from before pending downloads', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_store_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');
    sqlite3.open(file.path)
      ..execute(File('test/fixtures/schema_v2.sql').readAsStringSync())
      ..close();

    final upgraded = Ka7Store.open(file);
    addTearDown(upgraded.close);

    expect(await upgraded.setting('language'), 'fr');
    await upgraded.keepPending([_songDownload], MediaFormat.mp3, '/m');
    expect(await upgraded.pending(), hasLength(1));
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

  group('user playlists', () {
    const zoo = PlaylistTrack(
      videoId: 'jNQXAC9IVRw',
      title: 'Me at the zoo',
      format: MediaFormat.mp3,
      path: '/music/Me at the zoo.mp3',
    );
    const song = PlaylistTrack(
      videoId: 'yXs506QBhJY',
      title: 'Tanalahy ny foko',
      format: MediaFormat.mp3,
      path: '/music/Mahaleo/Tanalahy ny foko.mp3',
    );

    test('a new playlist is listed empty', () async {
      final id = await store.createPlaylist('Soirée');

      final [playlist] = await store.playlists();
      expect(playlist.id, id);
      expect(playlist.name, 'Soirée');
      expect(playlist.trackCount, 0);
      expect(await store.playlistTracks(id), isEmpty);
    });

    test('lists playlists oldest first', () async {
      await store.createPlaylist('Soirée');
      await store.createPlaylist('Route');

      expect(
        [for (final p in await store.playlists()) p.name],
        ['Soirée', 'Route'],
      );
    });

    test('keeps added tracks in order, the same one twice too', () async {
      final id = await store.createPlaylist('Soirée');
      await store.addToPlaylist(id, song);
      await store.addToPlaylist(id, zoo);
      await store.addToPlaylist(id, song);

      expect(await store.playlistTracks(id), [song, zoo, song]);
      expect((await store.playlists()).single.trackCount, 3);
    });

    test('replacing the tracks removes and reorders them', () async {
      final id = await store.createPlaylist('Soirée');
      await store.addToPlaylist(id, song);
      await store.addToPlaylist(id, zoo);

      await store.setPlaylistTracks(id, [zoo]);

      expect(await store.playlistTracks(id), [zoo]);
    });

    test('keeps each playlist apart', () async {
      final party = await store.createPlaylist('Soirée');
      final road = await store.createPlaylist('Route');
      await store.addToPlaylist(party, song);
      await store.addToPlaylist(road, zoo);

      expect(await store.playlistTracks(party), [song]);
      expect(await store.playlistTracks(road), [zoo]);
    });

    test('renames a playlist', () async {
      final id = await store.createPlaylist('Soirée');
      await store.renamePlaylist(id, 'Fête');

      expect((await store.playlists()).single.name, 'Fête');
    });

    test('deleting a playlist drops its tracks too', () async {
      final party = await store.createPlaylist('Soirée');
      await store.addToPlaylist(party, song);
      await store.deletePlaylist(party);

      expect(await store.playlists(), isEmpty);
      expect(await store.playlistTracks(party), isEmpty);
    });

    test('a track comes from a successful history line', () {
      final track = PlaylistTrack.of(
        HistoryItem(
          videoId: 'jNQXAC9IVRw',
          title: 'Me at the zoo',
          format: MediaFormat.mp3,
          status: HistoryStatus.succeeded,
          path: '/music/Me at the zoo.mp3',
          at: _monday,
        ),
      );
      expect(track, zoo);
    });
  });

  test('upgrades a store from before user playlists', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_store_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');
    sqlite3.open(file.path)
      ..execute(File('test/fixtures/schema_v6.sql').readAsStringSync())
      ..close();

    final upgraded = Ka7Store.open(file);
    addTearDown(upgraded.close);

    expect(await upgraded.history(), hasLength(1));
    final id = await upgraded.createPlaylist('Soirée');
    expect((await upgraded.playlists()).single.id, id);
  });

  group('folder playlists', () {
    test('keeps the folder a playlist plays', () async {
      final id = await store.createFolderPlaylist(
        'Mahaleo',
        folder: '/home/me/Musique/Mahaleo',
        label: 'Musique/Mahaleo',
      );

      final [playlist] = await store.playlists();
      expect(playlist.id, id);
      expect(playlist.name, 'Mahaleo');
      expect(playlist.isFolder, isTrue);
      expect(playlist.folder, '/home/me/Musique/Mahaleo');
      expect(playlist.folderLabel, 'Musique/Mahaleo');
    });

    test('a playlist made by hand has no folder', () async {
      await store.createPlaylist('Soirée');

      expect((await store.playlists()).single.isFolder, isFalse);
    });
  });

  test('upgrades a store from before folder playlists', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_store_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');
    sqlite3.open(file.path)
      ..execute(File('test/fixtures/schema_v7.sql').readAsStringSync())
      ..close();

    final upgraded = Ka7Store.open(file);
    addTearDown(upgraded.close);

    final [kept] = await upgraded.playlists();
    expect(kept.name, 'Soirée');
    expect(kept.trackCount, 1);
    expect(kept.isFolder, isFalse);
    await upgraded.createFolderPlaylist('M', folder: '/m', label: 'm');
    expect((await upgraded.playlists()).last.folder, '/m');
  });

  group('order of playlists', () {
    test('new playlists come last', () async {
      await store.createPlaylist('A');
      await store.createFolderPlaylist('B', folder: '/b', label: 'b');
      await store.createPlaylist('C');

      expect(
        [for (final p in await store.playlists()) p.name],
        ['A', 'B', 'C'],
      );
    });

    test('keeps the order the user chose', () async {
      final a = await store.createPlaylist('A');
      final b = await store.createPlaylist('B');
      final c = await store.createPlaylist('C');

      await store.orderPlaylists([b, a, c]);

      expect(
        [for (final p in await store.playlists()) p.name],
        ['B', 'A', 'C'],
      );
    });

    test('a playlist made after ordering comes last', () async {
      final a = await store.createPlaylist('A');
      final b = await store.createPlaylist('B');
      await store.orderPlaylists([b, a]);
      await store.createPlaylist('C');

      expect(
        [for (final p in await store.playlists()) p.name],
        ['B', 'A', 'C'],
      );
    });
  });

  test('upgrades a store from before playlists had an order', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_store_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');
    sqlite3.open(file.path)
      ..execute(File('test/fixtures/schema_v8.sql').readAsStringSync())
      ..close();

    final upgraded = Ka7Store.open(file);
    addTearDown(upgraded.close);

    final kept = await upgraded.playlists();
    expect([for (final p in kept) p.name], ['Soirée', 'Mahaleo']);
    await upgraded.orderPlaylists([kept.last.id, kept.first.id]);
    expect(
      [for (final p in await upgraded.playlists()) p.name],
      ['Mahaleo', 'Soirée'],
    );
  });
}
