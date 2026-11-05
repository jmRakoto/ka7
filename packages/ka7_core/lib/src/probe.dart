import 'link_entry.dart';
import 'search_channels.dart';

/// Whether a video can be downloaded.
enum Availability {
  available,

  /// Private: only its owner can watch it.
  private,

  /// Removed by its owner or by YouTube.
  deleted,

  /// Listed without any detail: account closed, blocked in the region…
  unavailable,
}

/// One video, as seen before downloading.
final class ProbeItem {
  const ProbeItem({
    required this.videoId,
    required this.title,
    this.duration,
    this.channel,
    this.channelId,
    this.availability = Availability.available,
  });

  final String videoId;
  final String title;
  final Duration? duration;
  final String? channel;

  /// `UC…`, to follow the channel; null where unknown.
  final String? channelId;
  final Availability availability;
}

/// What a link contains, read without downloading (flow 2).
final class Probe {
  const Probe({
    required this.title,
    required this.items,
    this.playlistId,
    this.isChannel = false,
    this.isSearch = false,
    this.channels = const [],
  });

  /// Channels a search found, besides its videos.
  final List<ChannelRef> channels;

  /// Results of a search: the user picks among them, none checked at first.
  final bool isSearch;

  /// Playlist title, channel name, or the video title for a single video.
  final String title;

  /// Playlist id, or channel id (`UC…`) for a channel.
  final String? playlistId;

  /// Every video of a channel, newest first: not a numbered album.
  final bool isChannel;
  final List<ProbeItem> items;
}

/// Why a link could not be read or downloaded.
enum FailureReason {
  unavailable,
  private,
  network,

  /// The engine itself is missing (yt-dlp not installed yet).
  engineMissing,

  /// The engine cannot make this format (MP3 without ffmpeg).
  formatUnsupported,
  unknown,
}

/// A link the engine could not read; [message] is the engine's own words.
final class ProbeFailure implements Exception {
  const ProbeFailure(this.reason, [this.message = '']);

  final FailureReason reason;
  final String message;

  @override
  String toString() => 'ProbeFailure(${reason.name}): $message';
}

/// A download engine: yt-dlp on desktop, youtube_explode on iOS, …
abstract interface class Extractor {
  String get name;

  /// Reads what [entry] contains without downloading it.
  /// Throws [ProbeFailure] when the link cannot be read.
  Future<Probe> probe(MediaEntry entry);
}

/// A video the user chose in the preview, ready to be queued (flow 3).
final class PlannedDownload {
  const PlannedDownload({
    required this.source,
    required this.item,
    required this.index,
  });

  /// The playlist or video it comes from: names the folder.
  final Probe source;
  final ProbeItem item;

  /// 1-based position in [source], for `01 - Title`.
  final int index;
}
