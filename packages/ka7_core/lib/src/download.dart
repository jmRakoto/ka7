import 'file_naming.dart';
import 'probe.dart';

/// Tags written into the file once downloaded.
final class TrackTags {
  const TrackTags({
    required this.title,
    this.artist,
    this.album,
    this.trackNumber,
  });

  final String title;
  final String? artist;

  /// Playlist title; null for a single video.
  final String? album;
  final int? trackNumber;
}

/// One video for an engine to fetch, convert, tag and save.
final class DownloadRequest {
  const DownloadRequest({
    required this.videoId,
    required this.format,
    required this.destination,
    required this.tags,
  });

  final String videoId;
  final MediaFormat format;

  /// Absolute path of the final file, extension included.
  final String destination;
  final TrackTags tags;

  String get url => 'https://www.youtube.com/watch?v=$videoId';
}

/// Where an engine is with one download.
final class DownloadProgress {
  const DownloadProgress({required this.fraction, this.speed, this.eta});

  /// From 0 to 1.
  final double fraction;

  /// Bytes per second.
  final double? speed;
  final Duration? eta;
}

/// A video the engine could not download; [message] is its own words.
final class DownloadFailure implements Exception {
  const DownloadFailure(this.reason, [this.message = '']);

  final FailureReason reason;
  final String message;

  @override
  String toString() => 'DownloadFailure(${reason.name}): $message';
}

/// Downloads one video at a time: yt-dlp on desktop, youtube_explode on iOS…
abstract interface class Downloader {
  /// Emits progress, then closes once [DownloadRequest.destination] is
  /// written. Fails with [DownloadFailure]. Cancelling the subscription stops
  /// the download and removes the partial file.
  Stream<DownloadProgress> download(DownloadRequest request);
}

/// Videos already downloaded, so a playlist run again only fetches new ones.
abstract interface class Archive {
  Future<bool> contains(String videoId, MediaFormat format);
  Future<void> add(String videoId, MediaFormat format);
}
