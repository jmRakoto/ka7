import 'dart:async';
import 'dart:io';

import 'ytdlp_extractor.dart';

/// A program the desktop engine needs.
enum EngineTool { ytDlp, ffmpeg }

/// Where each tool was found; null when missing.
final class EngineStatus {
  const EngineStatus({this.ytDlp, this.ffmpeg});

  final String? ytDlp;
  final String? ffmpeg;

  List<EngineTool> get missing => [
    if (ytDlp == null) EngineTool.ytDlp,
    if (ffmpeg == null) EngineTool.ffmpeg,
  ];

  bool get isReady => missing.isEmpty;
}

/// An HTTP answer, body streamed.
final class FetchResponse {
  const FetchResponse({required this.status, required this.body, this.length});

  final int status;
  final Stream<List<int>> body;

  /// Size in bytes, when the server tells it.
  final int? length;
}

typedef Fetch = Future<FetchResponse> Function(Uri url);

/// Why a tool could not be installed.
final class InstallFailure implements Exception {
  const InstallFailure(this.message);

  final String message;

  @override
  String toString() => 'InstallFailure: $message';
}

/// Checks that the engine's programs are there, and installs them.
abstract interface class EngineSetup {
  Future<EngineStatus> check();

  /// Downloads and installs [tool]; emits the fraction downloaded, fails with
  /// [InstallFailure].
  Stream<double> install(EngineTool tool);
}

/// Finds yt-dlp and ffmpeg, and installs the official builds when missing.
final class EngineBinaries implements EngineSetup {
  EngineBinaries({
    required this.folder,
    required this.run,
    required this.fetch,
  });

  /// Folder the app manages its own copies in.
  final String folder;
  final RunProcess run;
  final Fetch fetch;

  @override
  Future<EngineStatus> check() async =>
      EngineStatus(ytDlp: await _find('yt-dlp'), ffmpeg: await _find('ffmpeg'));

  @override
  Stream<double> install(EngineTool tool) {
    final progress = StreamController<double>();
    progress.onListen = () async {
      try {
        await _install(tool, progress.add);
      } on InstallFailure catch (failure) {
        progress.addError(failure);
      } on IOException catch (e) {
        progress.addError(InstallFailure('$e'));
      }
      await progress.close();
    };
    return progress.stream;
  }

  Future<void> _install(EngineTool tool, void Function(double) report) async {
    final (url, target) = switch (tool) {
      EngineTool.ytDlp => (_ytDlpUrl, '$folder/yt-dlp'),
      EngineTool.ffmpeg => (_ffmpegUrl, '$folder/ffmpeg.tar.xz'),
    };
    await Directory(folder).create(recursive: true);
    final part = File('$target.part');
    try {
      await _download(Uri.parse(url), part, report);
    } catch (_) {
      await _remove(part);
      rethrow;
    }
    final file = await part.rename(target);
    if (tool == EngineTool.ytDlp) return _makeExecutable(file.path);
    final tar = await run('tar', [
      '-xJf',
      file.path,
      '-C',
      folder,
      '--strip-components=2',
      '--wildcards',
      '*/bin/ffmpeg',
      '*/bin/ffprobe',
    ]);
    await file.delete();
    if (tar.exitCode != 0) throw InstallFailure('tar: ${tar.stderr}');
  }

  Future<void> _download(
    Uri url,
    File into,
    void Function(double) report,
  ) async {
    final response = await fetch(url);
    if (response.status != 200) {
      throw InstallFailure('HTTP ${response.status} for $url');
    }
    final sink = into.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.body) {
        sink.add(chunk);
        received += chunk.length;
        if (response.length case final length? when length > 0) {
          report(received / length);
        }
      }
    } finally {
      await sink.close();
    }
  }

  Future<void> _makeExecutable(String path) async {
    final chmod = await run('chmod', ['755', path]);
    if (chmod.exitCode != 0) throw InstallFailure('chmod: ${chmod.stderr}');
  }

  Future<String?> _find(String name) async {
    final managed = File('$folder/$name');
    if (managed.existsSync()) return managed.path;
    try {
      final which = await run('which', [name]);
      final path = (which.stdout as String).trim();
      return which.exitCode == 0 && path.isNotEmpty ? path : null;
    } on ProcessException {
      return null;
    }
  }
}

/// Official standalone yt-dlp (Unlicense).
const _ytDlpUrl =
    'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux';

/// LGPL build of ffmpeg: no GPL obligation on Ka7.
const _ffmpegUrl =
    'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/'
    'ffmpeg-master-latest-linux64-lgpl.tar.xz';

Future<void> _remove(File file) async {
  if (file.existsSync()) await file.delete();
}

/// Plain [HttpClient] download, following GitHub's redirects.
Future<FetchResponse> httpFetch(Uri url) async {
  final client = HttpClient();
  final request = await client.getUrl(url);
  final response = await request.close();
  return FetchResponse(
    status: response.statusCode,
    length: response.contentLength < 0 ? null : response.contentLength,
    body: response.transform(
      StreamTransformer.fromHandlers(
        handleDone: (sink) {
          client.close();
          sink.close();
        },
      ),
    ),
  );
}
