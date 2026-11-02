import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ka7_core/ka7_core.dart';

import 'ytdlp_errors.dart';

/// Starts a program without waiting for it; [Process.start] in production.
typedef StartProcess =
    Future<Process> Function(String executable, List<String> arguments);

/// Downloads with the official yt-dlp binary, converting and tagging with
/// ffmpeg (desktop).
final class YtDlpDownloader implements Downloader {
  YtDlpDownloader({
    required this.start,
    this.executable = 'yt-dlp',
    this.ffmpegPath,
  });

  final StartProcess start;

  /// Path of the yt-dlp binary managed by the app.
  final String executable;

  /// ffmpeg binary or folder; found on the PATH when null.
  final String? ffmpegPath;

  @override
  Stream<DownloadProgress> download(DownloadRequest request) {
    Future<Process?>? started;
    // Files older than this were there before: never removed. File times
    // lag the clock a little, hence the margin.
    final startedAt = DateTime.now().subtract(const Duration(seconds: 2));
    var cancelled = false;
    var exited = false;
    late final StreamController<DownloadProgress> progress;
    progress = StreamController(
      onListen: () async {
        final Process process;
        try {
          process = (await (started = _start(request)))!;
        } on ProcessException catch (e) {
          progress.addError(
            DownloadFailure(FailureReason.engineMissing, e.message),
          );
          return progress.close();
        }
        if (cancelled) return;
        final errors = process.stderr.transform(utf8.decoder).join();
        await process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .map(_progressOf)
            .where((line) => line != null)
            .cast<DownloadProgress>()
            .forEach(progress.add);
        final exitCode = await process.exitCode;
        exited = true;
        if (cancelled) return;
        if (exitCode != 0) {
          await _removePartialFiles(request.destination, startedAt);
          final message = (await errors).trim();
          progress.addError(DownloadFailure(failureReasonOf(message), message));
        }
        await progress.close();
      },
      // Also called once the stream is done: only stop a running yt-dlp.
      onCancel: () async {
        if (exited) return;
        cancelled = true;
        final process = await _orNull(started);
        if (process == null) return;
        process.kill();
        // Files are still being written until yt-dlp has really stopped.
        await process.exitCode.timeout(_stopTimeout, onTimeout: () => -1);
        await _removePartialFiles(request.destination, startedAt);
      },
    );
    return progress.stream;
  }

  Future<Process?> _start(DownloadRequest request) =>
      start(executable, _argumentsFor(request));

  List<String> _argumentsFor(DownloadRequest request) {
    final destination = request.destination;
    final stem = destination.substring(0, destination.lastIndexOf('.'));
    return [
      '--quiet',
      '--progress',
      '--newline',
      '--no-playlist',
      '--progress-template',
      'download:$_progressMark %(progress.downloaded_bytes)s '
          '%(progress.total_bytes,progress.total_bytes_estimate)s '
          '%(progress.speed)s %(progress.eta)s',
      if (ffmpegPath case final path?) ...['--ffmpeg-location', path],
      ...switch (request.format) {
        MediaFormat.mp3 => [
          '-f',
          'bestaudio/best',
          '--extract-audio',
          '--audio-format',
          'mp3',
          '--audio-quality',
          '192K',
        ],
        MediaFormat.m4a => [
          '-f',
          'bestaudio[ext=m4a]/bestaudio',
          '--extract-audio',
          '--audio-format',
          'm4a',
        ],
        MediaFormat.mp4 => [
          '-f',
          'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b',
          '--merge-output-format',
          'mp4',
        ],
      },
      '--embed-metadata',
      '--embed-thumbnail',
      '--convert-thumbnails',
      'jpg',
      '--postprocessor-args',
      'Metadata+ffmpeg_o:${_metadataOf(request.tags)}',
      '-o',
      '${stem.replaceAll('%', '%%')}.%(ext)s',
      request.url,
    ];
  }
}

const _progressMark = '[ka7]';
const _stopTimeout = Duration(seconds: 10);

/// The process once started; null if it never started or failed to.
Future<Process?> _orNull(Future<Process?>? started) async {
  try {
    return await started;
  } on ProcessException {
    return null;
  }
}

/// ffmpeg `-metadata` options, quoted for yt-dlp's shell-style splitting.
String _metadataOf(TrackTags tags) =>
    {
          'title': tags.title,
          'artist': tags.artist,
          'album': tags.album,
          'track': tags.trackNumber?.toString(),
        }.entries
        .where((tag) => tag.value != null)
        .map((tag) => '-metadata ${tag.key}=${_quoted(tag.value!)}')
        .join(' ');

String _quoted(String value) => "'${value.replaceAll("'", "'\"'\"'")}'";

/// Reads one line printed through our progress template; null otherwise.
DownloadProgress? _progressOf(String line) {
  final fields = line.split(' ');
  if (fields.length != 5 || fields.first != _progressMark) return null;
  final [_, downloaded, total, speed, eta] = fields;
  final done = double.tryParse(downloaded);
  final size = double.tryParse(total);
  final seconds = int.tryParse(eta);
  return DownloadProgress(
    fraction: done == null || size == null || size == 0 ? 0 : done / size,
    speed: double.tryParse(speed),
    eta: seconds == null ? null : Duration(seconds: seconds),
  );
}

/// yt-dlp leaves `<stem>.webm.part`, `<stem>.webp`… behind when stopped or
/// failed; only files written since [since] are its own.
Future<void> _removePartialFiles(String destination, DateTime since) async {
  final file = File(destination);
  final name = file.uri.pathSegments.last;
  final prefix = '${name.substring(0, name.lastIndexOf('.'))}.';
  final folder = file.parent;
  if (!folder.existsSync()) return;
  await for (final entity in folder.list()) {
    if (entity is File &&
        entity.uri.pathSegments.last.startsWith(prefix) &&
        !entity.lastModifiedSync().isBefore(since)) {
      await entity.delete();
    }
  }
}
