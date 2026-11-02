import 'dart:io';

import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:test/test.dart';

const _ytDlpUrl =
    'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux';
const _ffmpegUrl =
    'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/'
    'ffmpeg-master-latest-linux64-lgpl.tar.xz';

/// Answers `which` from a fixed table; records every call.
final class FakeRun {
  FakeRun({this.onPath = const {}, this.onTar});

  final Map<String, String> onPath;

  /// Exit code of every other program.
  var exitCode = 0;

  /// Runs instead of `tar`, to lay down what it would extract.
  final void Function(List<String> arguments)? onTar;
  final calls = <List<String>>[];

  Future<ProcessResult> call(String executable, List<String> arguments) async {
    calls.add([executable, ...arguments]);
    if (executable == 'which') {
      final path = onPath[arguments.single];
      return ProcessResult(1, path == null ? 1 : 0, path ?? '', '');
    }
    if (executable == 'tar') onTar?.call(arguments);
    return ProcessResult(1, exitCode, '', '');
  }
}

/// Serves fixed bytes for known URLs, 404 otherwise.
final class FakeFetch {
  FakeFetch(this.files, {this.failing = false});

  final Map<String, List<int>> files;
  final bool failing;
  final asked = <String>[];

  Future<FetchResponse> call(Uri url) async {
    asked.add('$url');
    if (failing) throw const SocketException('Network is unreachable');
    final bytes = files['$url'];
    if (bytes == null) {
      return const FetchResponse(status: 404, body: Stream.empty());
    }
    return FetchResponse(
      status: 200,
      length: bytes.length,
      body: Stream.fromIterable([
        bytes.sublist(0, bytes.length ~/ 2),
        bytes.sublist(bytes.length ~/ 2),
      ]),
    );
  }
}

void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('ka7_bin_'));
  tearDown(() => folder.deleteSync(recursive: true));

  EngineBinaries binaries(FakeRun run, [FakeFetch? fetch]) => EngineBinaries(
    folder: folder.path,
    run: run.call,
    fetch: (fetch ?? FakeFetch({})).call,
  );

  group('check', () {
    test('prefers the copies the app installed', () async {
      File('${folder.path}/yt-dlp').createSync();
      File('${folder.path}/ffmpeg').createSync();
      final run = FakeRun(onPath: {'yt-dlp': '/usr/bin/yt-dlp\n'});

      final status = await binaries(run).check();

      expect(status.ytDlp, '${folder.path}/yt-dlp');
      expect(status.ffmpeg, '${folder.path}/ffmpeg');
      expect(status.isReady, isTrue);
    });

    test('falls back to the programs on the PATH', () async {
      final run = FakeRun(
        onPath: {
          'yt-dlp': '/usr/local/bin/yt-dlp\n',
          'ffmpeg': '/usr/bin/ffmpeg\n',
        },
      );

      final status = await binaries(run).check();

      expect(status.ytDlp, '/usr/local/bin/yt-dlp');
      expect(status.ffmpeg, '/usr/bin/ffmpeg');
    });

    test('lists what is missing', () async {
      final status = await binaries(
        FakeRun(onPath: {'ffmpeg': '/usr/bin/ffmpeg'}),
      ).check();

      expect(status.missing, [EngineTool.ytDlp]);
      expect(status.isReady, isFalse);
    });
  });

  group('install', () {
    test('downloads the official yt-dlp as an executable', () async {
      final fetch = FakeFetch({_ytDlpUrl: List.filled(100, 7)});
      final run = FakeRun();

      final progress = await binaries(
        run,
        fetch,
      ).install(EngineTool.ytDlp).toList();

      final file = File('${folder.path}/yt-dlp');
      expect(fetch.asked, [_ytDlpUrl]);
      expect(file.lengthSync(), 100);
      expect(run.calls, contains(equals(['chmod', '755', file.path])));
      expect(progress, [0.5, 1.0]);
      expect(folder.listSync().map((e) => e.uri.pathSegments.last), ['yt-dlp']);
    });

    test('extracts ffmpeg and ffprobe from the LGPL archive', () async {
      final run = FakeRun(
        onTar: (_) {
          File('${folder.path}/ffmpeg').createSync();
          File('${folder.path}/ffprobe').createSync();
        },
      );
      final fetch = FakeFetch({_ffmpegUrl: List.filled(10, 1)});

      await binaries(run, fetch).install(EngineTool.ffmpeg).drain<void>();

      final tar = run.calls.singleWhere((call) => call.first == 'tar');
      expect(tar, [
        'tar',
        '-xJf',
        '${folder.path}/ffmpeg.tar.xz',
        '-C',
        folder.path,
        '--strip-components=2',
        '--wildcards',
        '*/bin/ffmpeg',
        '*/bin/ffprobe',
      ]);
      expect(folder.listSync().map((e) => e.uri.pathSegments.last).toSet(), {
        'ffmpeg',
        'ffprobe',
      });
      expect((await binaries(run).check()).ffmpeg, '${folder.path}/ffmpeg');
    });

    test('fails readably and leaves nothing behind', () async {
      await expectLater(
        binaries(
          FakeRun(),
          FakeFetch({}, failing: true),
        ).install(EngineTool.ytDlp),
        emitsError(isA<InstallFailure>()),
      );
      await expectLater(
        binaries(FakeRun(), FakeFetch({})).install(EngineTool.ytDlp),
        emitsError(
          isA<InstallFailure>().having(
            (f) => f.message,
            'message',
            contains('404'),
          ),
        ),
      );

      expect(folder.listSync(), isEmpty);
    });
  });

  group('updateYtDlp', () {
    test('self-updates the copy the app installed', () async {
      File('${folder.path}/yt-dlp').createSync();
      final run = FakeRun();

      final updated = await binaries(run).updateYtDlp();

      expect(updated, isTrue);
      expect(run.calls, [
        ['${folder.path}/yt-dlp', '-U'],
      ]);
    });

    test('leaves a yt-dlp from the PATH alone', () async {
      final run = FakeRun(onPath: {'yt-dlp': '/usr/bin/yt-dlp\n'});

      final updated = await binaries(run).updateYtDlp();

      expect(updated, isFalse);
      expect(run.calls, isEmpty);
    });

    test('reports a failed update', () async {
      File('${folder.path}/yt-dlp').createSync();
      final run = FakeRun()..exitCode = 1;

      expect(await binaries(run).updateYtDlp(), isFalse);
    });
  });
}
