import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:test/test.dart';

/// Stands in for a running yt-dlp: replays fixed output, then exits.
final class FakeProcess implements Process {
  FakeProcess({
    this.lines = const [],
    this.errorText = '',
    this.exit = 0,
    this.hangs = false,
  });

  final List<String> lines;
  final String errorText;
  final int exit;

  /// Never exits by itself: waits to be killed.
  final bool hangs;
  final _exitCode = Completer<int>();
  var killed = false;

  @override
  Stream<List<int>> get stdout async* {
    for (final line in lines) {
      yield utf8.encode('$line\n');
    }
    if (!hangs) _exitCode.complete(exit);
  }

  @override
  Stream<List<int>> get stderr => Stream.value(utf8.encode(errorText));

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exitCode.isCompleted) _exitCode.complete(-15);
    return true;
  }

  @override
  int get pid => 4242;

  @override
  IOSink get stdin => throw UnimplementedError();
}

final class FakeStart {
  FakeStart(this.process, {this.writes = const []});

  final FakeProcess process;

  /// Files yt-dlp writes once started.
  final List<File> writes;
  String? executable;
  List<String>? arguments;

  Future<Process> call(String executable, List<String> arguments) async {
    this.executable = executable;
    this.arguments = arguments;
    for (final file in writes) {
      file.createSync();
    }
    return process;
  }
}

DownloadRequest _request({
  MediaFormat format = MediaFormat.mp3,
  String destination = "/music/Mahaleo playlist/03 - It's: a-test.mp3",
  String? album = 'Mahaleo playlist',
  int? trackNumber = 3,
}) => DownloadRequest(
  videoId: 'jNQXAC9IVRw',
  format: format,
  destination: destination,
  tags: TrackTags(
    title: "It's: a/test",
    artist: 'jawed',
    album: album,
    trackNumber: trackNumber,
  ),
);

/// Real yt-dlp 2026.10.26 output for "Me at the zoo" as MP3.
final _realProgress = File(
  'test/fixtures/download_progress.txt',
).readAsLinesSync();

void main() {
  test('asks yt-dlp for a tagged MP3 at the exact destination', () async {
    final start = FakeStart(FakeProcess());

    await YtDlpDownloader(
      start: start.call,
      executable: '/opt/ka7/yt-dlp',
      ffmpegPath: '/opt/ka7/ffmpeg',
    ).download(_request()).drain<void>();

    expect(start.executable, '/opt/ka7/yt-dlp');
    expect(start.arguments, [
      '--quiet',
      '--progress',
      '--newline',
      '--no-playlist',
      '--progress-template',
      'download:[ka7] %(progress.downloaded_bytes)s '
          '%(progress.total_bytes,progress.total_bytes_estimate)s '
          '%(progress.speed)s %(progress.eta)s',
      '--ffmpeg-location',
      '/opt/ka7/ffmpeg',
      '-f',
      'bestaudio/best',
      '--extract-audio',
      '--audio-format',
      'mp3',
      '--audio-quality',
      '192K',
      '--embed-metadata',
      '--embed-thumbnail',
      '--convert-thumbnails',
      'jpg',
      '--postprocessor-args',
      'Metadata+ffmpeg_o:'
          "-metadata title='It'\"'\"'s: a/test' "
          "-metadata artist='jawed' "
          "-metadata album='Mahaleo playlist' "
          "-metadata track='3'",
      '-o',
      "/music/Mahaleo playlist/03 - It's: a-test.%(ext)s",
      'https://www.youtube.com/watch?v=jNQXAC9IVRw',
    ]);
  });

  test('asks for an MP4 with merged audio, without empty tags', () async {
    final start = FakeStart(FakeProcess());

    await YtDlpDownloader(start: start.call)
        .download(
          _request(
            format: MediaFormat.mp4,
            destination: '/videos/Me at the zoo.mp4',
            album: null,
            trackNumber: null,
          ),
        )
        .drain<void>();

    final arguments = start.arguments!;
    expect(arguments, isNot(contains('--ffmpeg-location')));
    expect(arguments, isNot(contains('--extract-audio')));
    expect(
      arguments,
      containsAllInOrder([
        '-f',
        'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b',
        '--merge-output-format',
        'mp4',
        '--postprocessor-args',
        "Metadata+ffmpeg_o:-metadata title='It'\"'\"'s: a/test' "
            "-metadata artist='jawed'",
        '-o',
        '/videos/Me at the zoo.%(ext)s',
      ]),
    );
  });

  test('asks for the original audio as m4a, without re-encoding', () async {
    final start = FakeStart(FakeProcess());

    await YtDlpDownloader(start: start.call)
        .download(
          _request(format: MediaFormat.m4a, destination: '/music/Hafatra.m4a'),
        )
        .drain<void>();

    expect(
      start.arguments,
      containsAllInOrder([
        '-f',
        'bestaudio[ext=m4a]/bestaudio',
        '--extract-audio',
        '--audio-format',
        'm4a',
        '--embed-metadata',
        '-o',
        '/music/Hafatra.%(ext)s',
      ]),
    );
    expect(start.arguments, isNot(contains('--audio-quality')));
  });

  test('keeps a % in the file name literal for yt-dlp', () async {
    final start = FakeStart(FakeProcess());

    await YtDlpDownloader(
      start: start.call,
    ).download(_request(destination: '/music/100% Mahaleo.mp3')).drain<void>();

    expect(start.arguments, contains('/music/100%% Mahaleo.%(ext)s'));
  });

  test('reads progress from the real yt-dlp output', () async {
    final start = FakeStart(FakeProcess(lines: _realProgress));

    final progress = await YtDlpDownloader(
      start: start.call,
    ).download(_request()).toList();

    expect(progress, hasLength(9));
    expect(progress.first.fraction, closeTo(1024 / 252182, 1e-9));
    expect(progress.first.speed, closeTo(29591.08, 0.01));
    expect(progress.first.eta, const Duration(seconds: 8));
    expect(progress.last.fraction, 1);
    expect(progress.last.eta, isNull);
  });

  test('ignores other lines yt-dlp prints', () async {
    final start = FakeStart(
      FakeProcess(lines: ['[youtube] Extracting URL', '[ka7] NA NA NA NA']),
    );

    final progress = await YtDlpDownloader(
      start: start.call,
    ).download(_request()).toList();

    expect(progress.single.fraction, 0);
    expect(progress.single.speed, isNull);
  });

  test('fails with a readable reason when yt-dlp exits in error', () async {
    const error =
        'ERROR: [youtube] 9rDT9l8gtF8: Video unavailable. This video is no '
        'longer available because the YouTube account associated with this '
        'video has been terminated.';
    final start = FakeStart(FakeProcess(exit: 1, errorText: '$error\n'));

    await expectLater(
      YtDlpDownloader(start: start.call).download(_request()),
      emitsError(
        isA<DownloadFailure>()
            .having((f) => f.reason, 'reason', FailureReason.unavailable)
            .having((f) => f.message, 'message', error),
      ),
    );
  });

  test('reports a missing yt-dlp binary instead of crashing', () async {
    final downloader = YtDlpDownloader(
      start: (executable, arguments) async =>
          throw ProcessException(executable, arguments, 'No such file', 2),
    );

    await expectLater(
      downloader.download(_request()),
      emitsError(
        isA<DownloadFailure>().having(
          (f) => f.reason,
          'reason',
          FailureReason.engineMissing,
        ),
      ),
    );
  });

  test('cancelling kills yt-dlp and removes the partial files', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_test_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final partial = File('${folder.path}/01 - Song.webm.part');
    final converting = File('${folder.path}/01 - Song.mp3');
    final neighbour = File('${folder.path}/01 - Song (live).mp3')..createSync();
    final process = FakeProcess(
      lines: _realProgress.take(1).toList(),
      hangs: true,
    );

    final subscription = YtDlpDownloader(
      start: FakeStart(process, writes: [partial, converting]).call,
    ).download(_request(destination: converting.path)).listen(null);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(process.killed, isTrue);
    expect(partial.existsSync(), isFalse);
    expect(converting.existsSync(), isFalse);
    expect(neighbour.existsSync(), isTrue);
  });

  test('cancelling before yt-dlp has started still stops it', () async {
    final process = FakeProcess(hangs: true);
    final started = Completer<Process>();

    final subscription = YtDlpDownloader(
      start: (executable, arguments) => started.future,
    ).download(_request()).listen(null);
    await Future<void>.delayed(Duration.zero);
    final cancelling = subscription.cancel();
    started.complete(process);
    await cancelling;
    await Future<void>.delayed(Duration.zero);

    expect(process.killed, isTrue);
  });

  test('keeps the finished file once yt-dlp is done', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_test_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final finished = File('${folder.path}/01 - Song.mp3')..createSync();

    await YtDlpDownloader(
      start: FakeStart(FakeProcess(lines: _realProgress)).call,
    ).download(_request(destination: finished.path)).drain<void>();

    expect(finished.existsSync(), isTrue);
  });

  test('removes leftovers when yt-dlp fails, keeping neighbours', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_test_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final target = '${folder.path}/Me at the zoo.mp3';
    final thumbnail = File('${folder.path}/Me at the zoo.webp');
    final neighbour = File('${folder.path}/Me at the zoo (live).mp3')
      ..createSync();

    await expectLater(
      YtDlpDownloader(
        start: FakeStart(
          FakeProcess(exit: 1, errorText: 'ERROR: x'),
          writes: [thumbnail],
        ).call,
      ).download(_request(destination: target)),
      emitsError(isA<DownloadFailure>()),
    );

    expect(thumbnail.existsSync(), isFalse);
    expect(neighbour.existsSync(), isTrue);
  });

  test('never removes a file that was there before the download', () async {
    final folder = Directory.systemTemp.createTempSync('ka7_test_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final target = '${folder.path}/Me at the zoo.mp3';
    final older = File(target)
      ..createSync()
      ..setLastModifiedSync(DateTime(2024));

    await expectLater(
      YtDlpDownloader(
        start: FakeStart(FakeProcess(exit: 1, errorText: 'ERROR: x')).call,
      ).download(_request(destination: target)),
      emitsError(isA<DownloadFailure>()),
    );

    expect(older.existsSync(), isTrue);
  });
}
