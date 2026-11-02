import 'package:ka7_core/ka7_core.dart';

/// Reads the output of `yt-dlp -J --flat-playlist`.
Probe parseProbeJson(Map<String, Object?> json) {
  if (json['_type'] != 'playlist') {
    return Probe(title: json['title'] as String? ?? '', items: [_item(json)]);
  }
  final entries = (json['entries'] as List<Object?>? ?? const [])
      .cast<Map<String, Object?>>();
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
