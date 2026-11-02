import 'dart:async';
import 'dart:io';

import 'package:ka7_core/ka7_core.dart';

import 'explode_source.dart';

/// Engine in pure Dart: reads and downloads through youtube_explode, writes
/// files itself. Makes m4a and low-quality mp4; mp3 needs ffmpeg.
final class ExplodeEngine implements Extractor, Downloader {
  ExplodeEngine({required this.source, this.mixLimit = defaultMixLimit});

  final ExplodeSource source;

  /// A mix never ends: only its first videos are read, as many as the
  /// settings say at the time of reading.
  final int Function() mixLimit;

  @override
  String get name => 'youtube_explode';

  @override
  Future<Probe> probe(MediaEntry entry) async => switch (entry) {
    VideoEntry(:final videoId) || VideoInPlaylistEntry(:final videoId) =>
      _single(await source.video(videoId)),
    PlaylistEntry(:final playlistId, :final isMix) => _list(
      playlistId,
      await source.playlist(playlistId, limit: isMix ? mixLimit() : null),
    ),
    ChannelEntry(:final channel) => _list(
      channel,
      await source.channel(channel),
      isChannel: true,
    ),
  };

  @override
  Stream<DownloadProgress> download(DownloadRequest request) {
    StreamSubscription<List<int>>? reading;
    IOSink? sink;
    final part = File('${request.destination}.part');
    late final StreamController<DownloadProgress> progress;
    progress = StreamController(
      onListen: () async {
        try {
          final stream = _pick(
            request.format,
            await source.streams(request.videoId),
          );
          await part.parent.create(recursive: true);
          final out = sink = part.openWrite();
          var received = 0;
          final done = Completer<void>();
          reading = source
              .open(request.videoId, stream)
              .listen(
                (chunk) {
                  out.add(chunk);
                  received += chunk.length;
                  progress.add(
                    DownloadProgress(
                      fraction: stream.size == 0 ? 0 : received / stream.size,
                    ),
                  );
                },
                onError: done.completeError,
                onDone: done.complete,
                cancelOnError: true,
              );
          await done.future;
          await out.close();
          await part.rename(request.destination);
        } on DownloadFailure catch (failure) {
          await _discard(sink, part);
          progress.addError(failure);
        } on Object catch (error) {
          await _discard(sink, part);
          progress.addError(DownloadFailure(FailureReason.network, '$error'));
        }
        await progress.close();
      },
      onCancel: () async {
        await reading?.cancel();
        await _discard(sink, part);
      },
    );
    return progress.stream;
  }
}

Probe _single(SourceVideo video) =>
    Probe(title: video.title, items: [_item(video)]);

Probe _list(String id, SourceList list, {bool isChannel = false}) {
  // youtube_explode has broken this way before: never pass it on as "empty".
  if (list.videos.isEmpty) {
    throw ProbeFailure(
      FailureReason.unknown,
      'youtube_explode returned no video for $id',
    );
  }
  return Probe(
    title: list.title,
    playlistId: id,
    isChannel: isChannel,
    items: [for (final video in list.videos) _item(video)],
  );
}

ProbeItem _item(SourceVideo video) => ProbeItem(
  videoId: video.id,
  title: video.title,
  channel: video.author,
  duration: video.duration,
);

/// The best stream for [format]: audio in an mp4 container for m4a, the
/// muxed stream for mp4.
SourceStream _pick(MediaFormat format, List<SourceStream> streams) {
  final kind = switch (format) {
    MediaFormat.m4a => StreamKind.audio,
    MediaFormat.mp4 => StreamKind.muxed,
    MediaFormat.mp3 => throw const DownloadFailure(
      FailureReason.formatUnsupported,
      'MP3 needs ffmpeg',
    ),
  };
  final fitting = [
    for (final stream in streams)
      if (stream.kind == kind && stream.container == 'mp4') stream,
  ]..sort((a, b) => b.bitrate.compareTo(a.bitrate));
  if (fitting.isEmpty) {
    throw DownloadFailure(
      FailureReason.unavailable,
      'No ${format.extension} stream',
    );
  }
  return fitting.first;
}

Future<void> _discard(IOSink? sink, File part) async {
  try {
    await sink?.close();
  } on Object {
    // Already closed or failed: the file is removed anyway.
  }
  if (part.existsSync()) await part.delete();
}
