import 'package:ka7_core/ka7_core.dart';

/// One video as youtube_explode describes it.
final class SourceVideo {
  const SourceVideo({
    required this.id,
    required this.title,
    this.author,
    this.duration,
  });

  final String id;
  final String title;
  final String? author;
  final Duration? duration;
}

/// A playlist or a channel's uploads.
final class SourceList {
  const SourceList({required this.title, required this.videos});

  final String title;
  final List<SourceVideo> videos;
}

/// What a downloadable stream holds.
enum StreamKind {
  /// Audio only: m4a (mp4 container) or webm.
  audio,

  /// Audio and video in one file, at most 360p.
  muxed,
}

final class SourceStream {
  const SourceStream({
    required this.kind,
    required this.container,
    required this.bitrate,
    required this.size,
  });

  final StreamKind kind;

  /// `mp4` or `webm`.
  final String container;

  /// Bits per second.
  final int bitrate;

  /// Bytes.
  final int size;
}

/// The part of youtube_explode Ka7 uses. Implementations throw
/// [ProbeFailure] (reading) or [DownloadFailure] (streams) with a readable
/// reason.
abstract interface class ExplodeSource {
  Future<SourceVideo> video(String id);

  /// The first [limit] videos of a playlist, all of them when null.
  Future<SourceList> playlist(String id, {int? limit});

  /// Uploads of a channel, `@handle` or `channel/UC…`.
  Future<SourceList> channel(String channel);

  Future<List<SourceStream>> streams(String videoId);
  Stream<List<int>> open(String videoId, SourceStream stream);
}
