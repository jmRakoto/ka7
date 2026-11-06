import 'dart:convert';
import 'dart:io';

import 'package:ka7_core/ka7_core.dart';

import 'probe_json.dart';
import 'ytdlp_errors.dart';

/// Runs a program and waits for its result; [Process.run] in production.
typedef RunProcess =
    Future<ProcessResult> Function(String executable, List<String> arguments);

/// Engine driving the official yt-dlp binary (desktop).
final class YtDlpExtractor implements Extractor, ChannelPictures, StreamUrls {
  YtDlpExtractor({
    required this.run,
    this.executable = 'yt-dlp',
    this.mixLimit = defaultMixLimit,
  });

  final RunProcess run;

  /// Path of the yt-dlp binary managed by the app.
  final String executable;

  /// A mix never ends: only its first videos are read, as many as the
  /// settings say at the time of reading.
  final int Function() mixLimit;

  @override
  String get name => 'yt-dlp';

  /// Read from the channel page, without its videos (`--playlist-items 0`).
  @override
  Future<String?> pictureOf(String channelId) async {
    final ProcessResult result;
    try {
      result = await _run([
        '--dump-single-json',
        '--flat-playlist',
        '--no-warnings',
        '--playlist-items',
        '0',
        'https://www.youtube.com/channel/$channelId',
      ]);
    } on ProbeFailure {
      return null;
    }
    if (result.exitCode != 0) return null;
    return avatarOf(
      jsonDecode(result.stdout as String) as Map<String, Object?>,
    );
  }

  @override
  Future<String> streamUrl(String videoId, {required bool video}) async {
    final result = await _run([
      '--no-warnings',
      '--get-url',
      '--format',
      // Video: YouTube only joins sound and picture up to 360p, enough to
      // check it is the right one.
      video ? 'best[vcodec!=none][acodec!=none]' : 'bestaudio/best',
      // Not the quicker android_vr client: its addresses answer 403 to
      // anyone but yt-dlp (2026-11-06).
      'https://www.youtube.com/watch?v=$videoId',
    ]);
    if (result.exitCode != 0) {
      final message = (result.stderr as String).trim();
      throw ProbeFailure(failureReasonOf(message), message);
    }
    return (result.stdout as String).trim().split('\n').first;
  }

  @override
  Future<Probe> probe(MediaEntry entry) async {
    final result = await _run([
      '--dump-single-json',
      '--flat-playlist',
      '--no-warnings',
      // Lists: a date from YouTube's « 1 year ago », for each video.
      '--extractor-args',
      'youtubetab:approximate_date',
      if (entry case PlaylistEntry(isMix: true)) ...[
        '--playlist-end',
        '${mixLimit()}',
      ],
      // Long videos only: a channel's root also lists its shorts and lives.
      switch (entry) {
        ChannelEntry() => '${entry.url}/videos',
        SearchEntry(:final query) => 'ytsearch$searchLimit:$query',
        _ => entry.url,
      },
    ]);
    if (result.exitCode != 0) {
      final message = (result.stderr as String).trim();
      throw ProbeFailure(failureReasonOf(message), message);
    }
    final json = jsonDecode(result.stdout as String) as Map<String, Object?>;
    return parseProbeJson(json);
  }

  Future<ProcessResult> _run(List<String> arguments) async {
    try {
      return await run(executable, arguments);
    } on ProcessException catch (e) {
      throw ProbeFailure(FailureReason.engineMissing, e.message);
    }
  }
}
