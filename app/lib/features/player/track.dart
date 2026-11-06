import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

/// Something the player can play: a downloaded file, or a YouTube video
/// played online before downloading it.
final class Track {
  const Track({
    required this.title,
    required this.videoId,
    this.path,
    this.video = false,
    this.format,
  });

  /// A downloaded file from the history.
  factory Track.ofHistory(HistoryItem item) => Track(
    title: item.title,
    videoId: item.videoId,
    path: item.path,
    format: item.format,
    video: item.format == MediaFormat.mp4,
  );

  factory Track.ofPlaylist(PlaylistTrack track) => Track(
    title: track.title,
    videoId: track.videoId,
    path: track.path,
    format: track.format,
    video: track.format == MediaFormat.mp4,
  );

  /// A file from a folder the user picked, Ka7's or not.
  factory Track.ofFile(MediaFile file) => Track(
    title: file.title,
    videoId: file.path,
    path: file.path,
    video: file.isVideo,
  );

  /// Read online, from its YouTube stream.
  factory Track.online(ProbeItem item, {bool video = false}) =>
      Track(title: item.title, videoId: item.videoId, video: video);

  final String title;
  final String videoId;

  /// The file; null to play it online.
  final String? path;
  final MediaFormat? format;
  final bool video;

  bool get isOnline => path == null;

  /// What a user playlist keeps of it; null when online.
  PlaylistTrack? get asPlaylistTrack => switch ((path, format)) {
    (final path?, final format?) => PlaylistTrack(
      videoId: videoId,
      title: title,
      format: format,
      path: path,
    ),
    _ => null,
  };
}
