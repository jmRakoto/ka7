import 'download.dart';
import 'file_naming.dart';
import 'link_entry.dart';
import 'probe.dart';

/// What to keep to follow [probe] later (a link `parseEntry` reads back);
/// null for what does not grow: a video, a search, a mix.
String? followLinkOf(Probe probe) {
  final id = probe.playlistId;
  if (id == null || probe.isSearch) return null;
  if (!probe.isChannel) return id.startsWith('RD') ? null : id;
  if (id.startsWith('@') || id.startsWith('channel/')) {
    return 'https://www.youtube.com/$id';
  }
  return 'https://www.youtube.com/channel/$id';
}

/// New videos in a followed playlist or channel.
final class News {
  const News({required this.link, required this.title, required this.count});

  final String link;
  final String title;
  final int count;
}

/// Reads each followed link; keeps those with videos not downloaded yet in
/// [format]. Links that cannot be read are left out, not reported.
Future<List<News>> findNews(
  Iterable<({String link, String title})> followed, {
  required Extractor extractor,
  required Archive archive,
  required MediaFormat format,
}) async {
  final news = <News>[];
  for (final (:link, :title) in followed) {
    if (parseEntry(link) case final MediaEntry entry) {
      final Probe probe;
      try {
        probe = await extractor.probe(entry);
      } on ProbeFailure {
        continue;
      }
      var count = 0;
      for (final item in probe.items) {
        if (item.availability == Availability.available &&
            !await archive.contains(item.videoId, format)) {
          count++;
        }
      }
      if (count > 0) news.add(News(link: link, title: title, count: count));
    }
  }
  return news;
}
