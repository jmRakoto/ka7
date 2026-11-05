import 'probe.dart';

/// An engine that can find a channel's picture (search results only give
/// it for some channels).
abstract interface class ChannelPictures {
  /// Its address (https), or null when none can be found.
  Future<String?> pictureOf(String channelId);
}

/// A YouTube channel met in search results.
final class ChannelRef {
  const ChannelRef({required this.name, required this.channelId, this.avatar});

  final String name;

  /// Its picture (https); null where unknown (met only through a video).
  final String? avatar;

  /// `UC…`.
  final String channelId;

  /// The address a followed channel is kept under: the same one its own
  /// preview gives (`followLinkOf`), so « Suivi » shows in both places.
  String get link => 'https://www.youtube.com/channel/$channelId';
}

/// Channels of [search] whose name holds every word of [query], any case:
/// those it found, then those of its videos; each once, in that order.
List<ChannelRef> channelsMatching(Probe search, String query) {
  final words = _words(query);
  if (words.isEmpty) return const [];
  bool matches(String name) {
    final inName = _words(name).join(' ');
    return words.every(inName.contains);
  }

  final found = <String, ChannelRef>{};
  final candidates = [
    ...search.channels,
    for (final item in search.items)
      if ((item.channel, item.channelId) case (final name?, final id?))
        ChannelRef(name: name, channelId: id),
  ];
  for (final channel in candidates) {
    if (found.containsKey(channel.channelId) || !matches(channel.name)) {
      continue;
    }
    found[channel.channelId] = ChannelRef(
      name: channel.name.trim(),
      channelId: channel.channelId,
      avatar: channel.avatar,
    );
  }
  return [...found.values];
}

List<String> _words(String text) => [
  for (final word in text.toLowerCase().split(RegExp(r'\s+')))
    if (word.isNotEmpty) word,
];
