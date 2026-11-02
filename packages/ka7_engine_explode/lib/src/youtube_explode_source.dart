import 'dart:io';

import 'package:ka7_core/ka7_core.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import 'explode_source.dart';

/// [ExplodeSource] on the real youtube_explode_dart client. Thin on purpose:
/// all the logic lives in the engine, tested without network.
final class YoutubeExplodeSource implements ExplodeSource {
  YoutubeExplodeSource([yt.YoutubeExplode? client])
    : _client = client ?? yt.YoutubeExplode();

  final yt.YoutubeExplode _client;

  /// Streams handed out by [streams], to open them again by identity.
  final _infos = Expando<yt.StreamInfo>();

  @override
  Future<SourceVideo> video(String id) =>
      _reading(() async => _video(await _client.videos.get(id)));

  @override
  Future<SourceList> playlist(String id, {int? limit}) => _reading(() async {
    final playlist = await _client.playlists.get(id);
    var videos = _client.playlists.getVideos(id);
    if (limit != null) videos = videos.take(limit);
    return SourceList(
      title: playlist.title,
      videos: [await for (final video in videos) _video(video)],
    );
  });

  @override
  Future<SourceList> channel(String channel) => _reading(() async {
    final found = channel.startsWith('@')
        ? await _client.channels.getByHandle(channel)
        : await _client.channels.get(channel.substring('channel/'.length));
    return SourceList(
      title: found.title,
      videos: [
        await for (final video in _client.channels.getUploads(found.id))
          _video(video),
      ],
    );
  });

  @override
  Future<List<SourceStream>> streams(String videoId) async {
    try {
      final manifest = await _client.videos.streamsClient.getManifest(videoId);
      return [
        for (final info in manifest.audioOnly) _stream(info, StreamKind.audio),
        for (final info in manifest.muxed) _stream(info, StreamKind.muxed),
      ];
    } on Object catch (error) {
      throw DownloadFailure(_reasonOf(error), '$error');
    }
  }

  @override
  Stream<List<int>> open(String videoId, SourceStream stream) =>
      _client.videos.streamsClient.get(_infos[stream]!);

  /// Releases the HTTP client.
  void close() => _client.close();

  SourceStream _stream(yt.StreamInfo info, StreamKind kind) {
    final stream = SourceStream(
      kind: kind,
      container: info.container.name,
      bitrate: info.bitrate.bitsPerSecond,
      size: info.size.totalBytes,
    );
    _infos[stream] = info;
    return stream;
  }
}

SourceVideo _video(yt.Video video) => SourceVideo(
  id: video.id.value,
  title: video.title,
  author: video.author,
  duration: video.duration,
);

Future<T> _reading<T>(Future<T> Function() read) async {
  try {
    return await read();
  } on ProbeFailure {
    rethrow;
  } on Object catch (error) {
    throw ProbeFailure(_reasonOf(error), '$error');
  }
}

FailureReason _reasonOf(Object error) => switch (error) {
  yt.VideoUnavailableException() => FailureReason.unavailable,
  yt.VideoRequiresPurchaseException() => FailureReason.private,
  yt.VideoUnplayableException() => FailureReason.private,
  SocketException() || HttpException() => FailureReason.network,
  _ => FailureReason.unknown,
};
