import 'package:ka7_core/ka7_core.dart';

/// Reads the output of `yt-dlp -J --flat-playlist`.
Probe parseProbeJson(Map<String, Object?> json) {
  if (json['_type'] != 'playlist') {
    return Probe(title: json['title'] as String? ?? '', items: [_item(json)]);
  }
  final entries = (json['entries'] as List<Object?>? ?? const [])
      .cast<Map<String, Object?>>();
  if (json['extractor_key'] == 'YoutubeSearch') {
    return Probe(
      title: json['title'] as String? ?? '',
      isSearch: true,
      // Results also list channels and playlists: videos as items, channels
      // to follow apart; playlists left out.
      items: [
        for (final entry in entries)
          if (entry['ie_key'] == 'Youtube') _item(entry),
      ],
      channels: [
        for (final entry in entries)
          if (entry['ie_key'] == 'YoutubeTab' &&
              entry['id'] is String &&
              entry['id'] == entry['channel_id'])
            ChannelRef(
              name: (entry['channel'] ?? entry['title']) as String? ?? '',
              channelId: entry['id'] as String,
              avatar: _largest(entry['thumbnails']),
            ),
      ],
    );
  }
  final id = json['id'] as String?;
  // A channel tab: its id is the channel's, and its title "Name - Videos".
  final isChannel = id != null && id == json['channel_id'];
  return Probe(
    title: (isChannel ? json['channel'] : json['title']) as String? ?? '',
    playlistId: id,
    isChannel: isChannel,
    items: [for (final entry in entries) _item(entry)],
  );
}

ProbeItem _item(Map<String, Object?> json) {
  final seconds = json['duration'] as num?;
  return ProbeItem(
    videoId: json['id'] as String,
    title: json['title'] as String? ?? '',
    duration: seconds == null ? null : Duration(seconds: seconds.round()),
    channel: json['channel'] as String?,
    channelId: json['channel_id'] as String?,
    published: switch (json['timestamp']) {
      final num seconds => DateTime.fromMillisecondsSinceEpoch(
        (seconds * 1000).round(),
        isUtc: true,
      ),
      _ => null,
    },
    availability: _availabilityOf(json['title']),
  );
}

/// yt-dlp lists unreachable playlist videos under a placeholder title, or
/// with no title at all.
Availability _availabilityOf(Object? title) => switch (title) {
  null => Availability.unavailable,
  '[Private video]' => Availability.private,
  '[Deleted video]' => Availability.deleted,
  _ => Availability.available,
};

/// The widest of yt-dlp's [thumbnails], as an https address.
String? _largest(Object? thumbnails) {
  final pictures = [
    for (final picture in (thumbnails as List<Object?>?) ?? const [])
      if (picture case {'url': final String url})
        (
          url.startsWith('//') ? 'https:$url' : url,
          (picture['width'] as num?) ?? 0,
        ),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return pictures.firstOrNull?.$1;
}

/// The channel's own picture in a channel page: the square one (banners are
/// wide), asked at 176 px.
String? avatarOf(Map<String, Object?> json) {
  for (final picture in (json['thumbnails'] as List<Object?>?) ?? const []) {
    if (picture case {
      'url': final String url,
      'width': final num width,
      'height': final num height,
    } when width == height) {
      return url.replaceFirst(RegExp(r'=s\d+'), '=s176');
    }
  }
  return null;
}
