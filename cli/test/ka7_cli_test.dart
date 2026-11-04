import 'dart:async';
import 'dart:io';

import 'package:ka7_cli/ka7_cli.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';
import 'package:test/test.dart';

const _tanalahy = ProbeItem(
  videoId: 'yXs506QBhJY',
  title: 'Tanalahy ny foko',
  channel: 'MAFYBE61',
);
const _somambisamby = ProbeItem(videoId: 'YW-QLSPY8Ew', title: 'Somambisamby');
const _gone = ProbeItem(
  videoId: '9rDT9l8gtF8',
  title: '',
  availability: Availability.unavailable,
);
const _mahaleo = Probe(
  title: 'Mahaleo playlist',
  playlistId: 'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
  items: [_tanalahy, _gone, _somambisamby],
);
const _zoo = Probe(
  title: 'Me at the zoo',
  items: [ProbeItem(videoId: 'jNQXAC9IVRw', title: 'Me at the zoo')],
);

const _channel = Probe(
  title: 'Mahaleo',
  playlistId: 'UC0HN8Wq3EEzK3GF6qKHkdkA',
  isChannel: true,
  items: [_tanalahy, _somambisamby],
);

const _channelLink = 'https://www.youtube.com/@Mahaleo';
const _playlistLink =
    'https://www.youtube.com/playlist?list=PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy';
const _zooLink = 'https://www.youtube.com/watch?v=jNQXAC9IVRw';

/// Reads links from a fixed table; unknown links fail as unavailable.
final class FakeExtractor implements Extractor {
  FakeExtractor(this.answers);

  final Map<String, Object> answers;
  final probed = <String>[];

  @override
  String get name => 'fake';

  @override
  Future<Probe> probe(MediaEntry entry) async {
    probed.add(entry.url);
    return switch (answers[entry.url]) {
      final Probe probe => probe,
      final ProbeFailure failure => throw failure,
      _ => throw const ProbeFailure(FailureReason.unavailable),
    };
  }
}

/// Finishes at once, unless the video is listed in [failures].
final class FakeDownloader implements Downloader {
  FakeDownloader({
    this.failures = const {},
    this.onStart,
    this.progress = const [DownloadProgress(fraction: 1)],
  });

  final Map<String, DownloadFailure> failures;
  final List<DownloadProgress> progress;
  final void Function(DownloadRequest)? onStart;
  final requests = <DownloadRequest>[];

  @override
  Stream<DownloadProgress> download(DownloadRequest request) async* {
    requests.add(request);
    onStart?.call(request);
    yield* Stream.fromIterable(progress);
    if (failures[request.videoId] case final failure?) throw failure;
    // Like the real engine: the file is there once done.
    File(request.destination)
      ..createSync(recursive: true)
      ..writeAsStringSync('audio');
  }
}

void main() {
  late Directory folder;
  late Ka7Store store;
  late StringBuffer out;
  late FakeExtractor extractor;
  late FakeDownloader downloader;
  final questions = <String>[];
  var answer = false;

  setUp(() {
    questions.clear();
    answer = false;
    folder = Directory.systemTemp.createTempSync('ka7_cli_');
    store = Ka7Store.inMemory();
    out = StringBuffer();
    extractor = FakeExtractor({
      _playlistLink: _mahaleo,
      _zooLink: _zoo,
      _channelLink: _channel,
    });
    downloader = FakeDownloader();
  });
  tearDown(() async {
    await store.close();
    folder.deleteSync(recursive: true);
  });

  Ka7Cli cli({String language = 'en', bool showProgress = false}) => Ka7Cli(
    extractor: extractor,
    downloader: downloader,
    store: store,
    workingDirectory: folder.path,
    out: out,
    now: () => DateTime(2026, 10, 30, 14, 5),
    language: language,
    showProgress: showProgress,
    ask: (question) async {
      questions.add(question);
      return answer;
    },
  );

  File file(String name) => File('${folder.path}/$name');

  void writeLinks(String text) => file('links.txt').writeAsStringSync(text);

  test('downloads every available video of the links file', () async {
    writeLinks('# Mahaleo\nPLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy\n$_zooLink\n');

    final code = await cli().run(['links.txt']);

    expect(code, ExitCode.ok);
    expect(downloader.requests.map((r) => r.destination), [
      '${folder.path}/downloads/Mahaleo playlist/01 - Tanalahy ny foko.mp3',
      '${folder.path}/downloads/Mahaleo playlist/03 - Somambisamby.mp3',
      '${folder.path}/downloads/Me at the zoo.mp3',
    ]);
    expect(
      out.toString(),
      contains('Mahaleo playlist: 3 videos (1 unavailable)'),
    );
    expect(out.toString(), contains('[1/3] Tanalahy ny foko'));
    expect(
      out.toString(),
      contains('Summary: 3 succeeded, 0 already there, 0 failed, 0 cancelled.'),
    );
  });

  test('follows --format and --out', () async {
    writeLinks(_zooLink);

    await cli().run(['links.txt', '--format', 'mp4', '--out', 'Videos']);

    final request = downloader.requests.single;
    expect(request.format, MediaFormat.mp4);
    expect(request.destination, '${folder.path}/Videos/Me at the zoo.mp4');
  });

  group('video opened from a playlist', () {
    setUp(
      () => writeLinks('$_zooLink&list=PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy'),
    );

    test('asks whether to take the whole playlist', () async {
      answer = true;

      await cli().run(['links.txt']);

      expect(questions, [
        'Mahaleo playlist (3 videos): download the whole playlist? [y/N] ',
      ]);
      expect(downloader.requests, hasLength(2));
    });

    test('keeps the video alone on no', () async {
      await cli().run(['links.txt']);

      expect(downloader.requests.single.videoId, 'jNQXAC9IVRw');
    });

    test('takes the whole playlist without asking with --yes', () async {
      await cli().run(['links.txt', '--yes']);

      expect(questions, isEmpty);
      expect(downloader.requests, hasLength(2));
    });

    test('keeps the video alone when the playlist cannot be read', () async {
      extractor.answers.remove(_playlistLink);

      await cli().run(['links.txt']);

      expect(questions, isEmpty);
      expect(downloader.requests.single.videoId, 'jNQXAC9IVRw');
    });
  });

  group('channel', () {
    setUp(() => writeLinks(_channelLink));

    test('downloads its videos once the count is confirmed', () async {
      answer = true;

      await cli().run(['links.txt']);

      expect(questions, ['Mahaleo: 2 videos. Download them all? [y/N] ']);
      expect(downloader.requests.map((r) => r.destination), [
        '${folder.path}/downloads/Mahaleo/Tanalahy ny foko.mp3',
        '${folder.path}/downloads/Mahaleo/Somambisamby.mp3',
      ]);
    });

    test('leaves it out on no, and says so', () async {
      final code = await cli().run(['links.txt']);

      expect(code, ExitCode.ok);
      expect(downloader.requests, isEmpty);
      expect(out.toString(), contains('- Mahaleo: left out'));
    });
  });

  test('leaves searches to the app: nothing to tick here', () async {
    writeLinks('Erick Manana\n$_zooLink');

    final code = await cli().run(['links.txt']);

    expect(code, ExitCode.ok);
    expect(out.toString(), contains('! Erick Manana: not a link'));
    expect(downloader.requests, hasLength(1));
  });

  test('reports invalid lines and goes on', () async {
    writeLinks('vimeo.com/123456\n$_zooLink\n$_zooLink');

    final code = await cli().run(['links.txt']);

    expect(code, ExitCode.ok);
    expect(
      out.toString(),
      contains('1 links to read, 1 invalid, 1 duplicates.'),
    );
    expect(out.toString(), contains('! vimeo.com/123456: not a YouTube link'));
    expect(downloader.requests, hasLength(1));
  });

  group('progress bar', () {
    setUp(() {
      writeLinks(_zooLink);
      downloader = FakeDownloader(
        progress: const [
          DownloadProgress(fraction: 0.5, speed: 1500000),
          DownloadProgress(fraction: 1, speed: 1500000),
        ],
      );
    });

    test('redraws one line on a terminal', () async {
      await cli(showProgress: true).run(['links.txt']);

      expect(
        out.toString(),
        contains('\r\x1b[K  ▕██████████░░░░░░░░░░▏  50% · 0/1 · 1.5 MB/s'),
      );
      expect(
        out.toString(),
        contains('\r\x1b[K  ✓ ${folder.path}/downloads/Me at the zoo.mp3'),
      );
    });

    test('is left out when the output is not a terminal', () async {
      await cli().run(['links.txt']);

      expect(out.toString(), isNot(contains('▕')));
      expect(out.toString(), isNot(contains('\r')));
    });

    test('formats speed the French way in French', () async {
      await cli(language: 'fr', showProgress: true).run(['links.txt']);

      expect(out.toString(), contains(' 50 % · 0/1 · 1,5 Mo/s'));
    });
  });

  test('saves failed videos and unreadable links to failed.txt', () async {
    extractor.answers['https://www.youtube.com/watch?v=Qm7tR2vLx9A'] =
        const ProbeFailure(FailureReason.network, 'timed out');
    downloader = FakeDownloader(
      failures: {
        'YW-QLSPY8Ew': const DownloadFailure(FailureReason.private, 'Private'),
      },
    );
    writeLinks('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy\nQm7tR2vLx9A');

    final code = await cli().run(['links.txt']);

    expect(code, ExitCode.someFailed);
    expect(out.toString(), contains('✗ Qm7tR2vLx9A: network problem'));
    expect(out.toString(), contains('✗ private'));
    expect(
      out.toString(),
      contains('Summary: 1 succeeded, 0 already there, 2 failed, 0 cancelled.'),
    );
    final failed = parseLinks(file('failed.txt').readAsStringSync());
    expect(failed.map((e) => (e as MediaEntry).url), [
      'https://www.youtube.com/watch?v=YW-QLSPY8Ew',
      'https://www.youtube.com/watch?v=Qm7tR2vLx9A',
    ]);
    expect(out.toString(), contains('failed.txt'));
  });

  test('removes an old failed.txt once everything succeeded', () async {
    file('failed.txt').writeAsStringSync('# old\n$_zooLink\n');
    writeLinks(_zooLink);

    await cli().run(['links.txt']);

    expect(file('failed.txt').existsSync(), isFalse);
  });

  test('retry downloads the links of failed.txt', () async {
    file(
      'failed.txt',
    ).writeAsStringSync('# Me at the zoo: network\n$_zooLink\n');

    final code = await cli().run(['retry']);

    expect(code, ExitCode.ok);
    expect(downloader.requests.single.videoId, 'jNQXAC9IVRw');
  });

  test('skips what an earlier run already downloaded', () async {
    writeLinks(_zooLink);
    await cli().run(['links.txt']);
    out.clear();

    await cli().run(['links.txt']);

    expect(downloader.requests, hasLength(1));
    expect(out.toString(), contains('= already downloaded'));
  });

  test('downloads again what was deleted since', () async {
    writeLinks(_zooLink);
    await cli().run(['links.txt']);
    File(downloader.requests.single.destination).deleteSync();
    out.clear();

    await cli().run(['links.txt']);

    expect(downloader.requests, hasLength(2));
    expect(out.toString(), isNot(contains('= already downloaded')));
  });

  test('keeps the history of the run', () async {
    writeLinks(_zooLink);

    await cli().run(['links.txt']);

    final [item] = await store.history();
    expect(item.status, HistoryStatus.succeeded);
    expect(item.path, '${folder.path}/downloads/Me at the zoo.mp3');
  });

  test('cancel stops the run and reports what was left', () async {
    late Ka7Cli running;
    downloader = FakeDownloader(onStart: (_) => running.cancel());
    writeLinks('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy');

    running = cli();
    await running.run(['links.txt', '--jobs', '1']);

    expect(downloader.requests, hasLength(1));
    expect(out.toString(), contains('0 failed, 2 cancelled.'));
  });

  test('explains how to use it when called without a file', () async {
    final code = await cli().run([]);

    expect(code, ExitCode.usage);
    expect(out.toString(), startsWith('Usage: ka7 <links.txt>'));
  });

  test('says so when the links file is missing', () async {
    final code = await cli().run(['nowhere.txt']);

    expect(code, ExitCode.noInput);
    expect(out.toString(), contains('File not found: nowhere.txt'));
  });

  test('speaks French when the system or --lang asks for it', () async {
    writeLinks(_zooLink);

    await cli(language: 'fr_FR').run(['links.txt']);
    await cli().run(['links.txt', '--lang', 'fr']);

    expect(
      out.toString(),
      contains('Bilan : 1 réussis, 0 déjà là, 0 échoués, 0 annulés.'),
    );
    expect(out.toString(), isNot(contains('Summary')));
  });
}
