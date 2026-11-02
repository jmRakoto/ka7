/// One line of user input, once recognized.
sealed class LinkEntry {
  const LinkEntry(this.source);

  /// The text as the user typed it, trimmed.
  final String source;
}

/// Input Ka7 can download.
sealed class MediaEntry extends LinkEntry {
  const MediaEntry(super.source);

  /// Standard form of the link, without tracking parameters.
  String get url;
}

const _base = 'https://www.youtube.com';

/// A single video.
final class VideoEntry extends MediaEntry {
  const VideoEntry(super.source, {required this.videoId});

  final String videoId;

  @override
  String get url => '$_base/watch?v=$videoId';
}

/// How many videos of a mix are read until the user picks another number.
int defaultMixLimit() => 50;

/// A playlist: every video in it.
final class PlaylistEntry extends MediaEntry {
  const PlaylistEntry(super.source, {required this.playlistId});

  final String playlistId;

  @override
  String get url => '$_base/playlist?list=$playlistId';

  /// A YouTube mix never ends: the preview caps it.
  bool get isMix => playlistId.startsWith('RD');
}

/// A video opened from a playlist: the preview asks which one to keep.
final class VideoInPlaylistEntry extends MediaEntry {
  const VideoInPlaylistEntry(
    super.source, {
    required this.videoId,
    required this.playlistId,
  });

  final String videoId;
  final String playlistId;

  @override
  String get url => '$_base/watch?v=$videoId&list=$playlistId';
}

/// A channel: all its videos, after the user confirms the count.
final class ChannelEntry extends MediaEntry {
  const ChannelEntry(super.source, {required this.channel});

  /// `@handle` or `channel/UC…`, as it appears in the link path.
  final String channel;

  @override
  String get url => '$_base/$channel';
}

/// Same media as an earlier line: kept for the report, not downloaded twice.
final class DuplicateEntry extends LinkEntry {
  const DuplicateEntry(super.source, {required this.of});

  /// The earlier entry it repeats.
  final MediaEntry of;
}

/// Why a line cannot be downloaded.
enum InvalidReason {
  /// A link to another site: only YouTube is supported.
  notYouTube,

  /// A YouTube link with neither a video nor a playlist.
  noVideoOrPlaylist,

  /// Plain words, not a link (search comes later).
  freeText,
}

/// Input that Ka7 cannot download.
final class InvalidEntry extends LinkEntry {
  const InvalidEntry(super.source, {required this.reason});

  final InvalidReason reason;
}

final _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
final _youTubeHost = RegExp(r'(^|\.)youtube\.com$');

bool _isYouTube(Uri url) =>
    url.host == 'youtu.be' || _youTubeHost.hasMatch(url.host);
final _playlistId = RegExp(r'^(PL|OLAK5uy_|UU|RD)[A-Za-z0-9_-]{8,}$');

/// Recognizes one line of input.
LinkEntry parseEntry(String raw) {
  final text = raw.trim();
  if (_videoId.hasMatch(text)) return VideoEntry(text, videoId: text);
  if (_playlistId.hasMatch(text)) {
    return PlaylistEntry(text, playlistId: text);
  }
  if (text.startsWith('list=')) {
    final id = Uri.splitQueryString(text)['list'];
    if (id != null && _playlistId.hasMatch(id)) {
      return PlaylistEntry(text, playlistId: id);
    }
  }

  final url = _parseUrl(text);
  if (url != null) {
    final videoId = _videoIdOf(url);
    final playlistId = _playlistIdOf(url);
    if (videoId != null && playlistId != null) {
      return VideoInPlaylistEntry(
        text,
        videoId: videoId,
        playlistId: playlistId,
      );
    }
    if (videoId != null) return VideoEntry(text, videoId: videoId);
    if (playlistId != null) return PlaylistEntry(text, playlistId: playlistId);
    final channel = _channelOf(url);
    if (channel != null) return ChannelEntry(text, channel: channel);
    if (_isYouTube(url)) {
      return InvalidEntry(text, reason: InvalidReason.noVideoOrPlaylist);
    }
    if (url.host.contains('.')) {
      return InvalidEntry(text, reason: InvalidReason.notYouTube);
    }
  }
  return InvalidEntry(text, reason: InvalidReason.freeText);
}

/// Recognizes every entry of a pasted text or a `links.txt` file.
List<LinkEntry> parseLinks(String text) {
  final firstByUrl = <String, MediaEntry>{};
  return [
    for (final line in text.split('\n'))
      if (!line.trimLeft().startsWith('#'))
        for (final word in line.split(_spaces))
          if (word.isNotEmpty)
            switch (parseEntry(word)) {
              MediaEntry media when firstByUrl.containsKey(media.url) =>
                DuplicateEntry(media.source, of: firstByUrl[media.url]!),
              MediaEntry media => firstByUrl[media.url] = media,
              final other => other,
            },
  ];
}

final _spaces = RegExp(r'\s+');

/// `@handle` or `channel/UC…` when [url] points to a YouTube channel.
String? _channelOf(Uri url) {
  if (!_youTubeHost.hasMatch(url.host)) return null;
  final segments = url.pathSegments;
  if (segments.isEmpty) return null;
  if (segments.first.startsWith('@')) return segments.first;
  if (segments.first == 'channel' && segments.length > 1) {
    return 'channel/${segments[1]}';
  }
  return null;
}

/// The playlist id in the `list` parameter of a YouTube [url].
String? _playlistIdOf(Uri url) {
  final list = url.queryParameters['list'];
  return _youTubeHost.hasMatch(url.host) &&
          list != null &&
          _playlistId.hasMatch(list)
      ? list
      : null;
}

/// The video id carried by a YouTube [url], wherever it sits.
String? _videoIdOf(Uri url) {
  final segments = url.pathSegments;
  final String? candidate;
  if (url.host == 'youtu.be') {
    candidate = segments.firstOrNull;
  } else if (_youTubeHost.hasMatch(url.host)) {
    candidate = segments.length == 2 && segments.first == 'shorts'
        ? segments.last
        : url.queryParameters['v'];
  } else {
    candidate = null;
  }
  return candidate != null && _videoId.hasMatch(candidate) ? candidate : null;
}

/// Parses [text] as a URL, adding `https://` when the scheme is missing.
Uri? _parseUrl(String text) {
  final withScheme = text.contains('://') ? text : 'https://$text';
  return Uri.tryParse(withScheme);
}
