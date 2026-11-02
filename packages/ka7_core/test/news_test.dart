import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

const _songs = [
  ProbeItem(videoId: 'aB3dE5fG7hI', title: 'Tsara'),
  ProbeItem(videoId: 'jK9lM1nO3pQ', title: 'Tsy Ferana'),
  ProbeItem(
    videoId: 'rS5tU7vW9xY',
    title: '[Private video]',
    availability: Availability.private,
  ),
];

/// Answers each link URL with a fixed probe, fails otherwise.
final class _Extractor implements Extractor {
  _Extractor(this.probes);

  final Map<String, Probe> probes;

  @override
  String get name => 'fake';

  @override
  Future<Probe> probe(MediaEntry entry) async =>
      probes[entry.url] ?? (throw const ProbeFailure(FailureReason.network));
}

final class _Archive implements Archive {
  _Archive(this.ids);

  final Set<String> ids;

  @override
  Future<bool> contains(String videoId, MediaFormat format) async =>
      format == MediaFormat.mp3 && ids.contains(videoId);

  @override
  Future<void> add(String videoId, MediaFormat format) async {}
}

void main() {
  group('followLinkOf', () {
    test('keeps a playlist id', () {
      expect(
        followLinkOf(
          const Probe(
            title: 'Mahaleo',
            playlistId: 'PLmahaleo00001',
            items: [],
          ),
        ),
        'PLmahaleo00001',
      );
    });

    test('keeps a channel as a link, whatever form its id takes', () {
      const cases = {
        'UCmahaleo0000000000000000':
            'https://www.youtube.com/channel/UCmahaleo0000000000000000',
        '@jawed': 'https://www.youtube.com/@jawed',
        'channel/UCjawed': 'https://www.youtube.com/channel/UCjawed',
      };
      cases.forEach((id, link) {
        final probe = Probe(
          title: 'x',
          playlistId: id,
          isChannel: true,
          items: const [],
        );
        expect(followLinkOf(probe), link, reason: id);
        expect(parseEntry(link), isA<ChannelEntry>(), reason: link);
      });
    });

    test('follows nothing that does not grow', () {
      expect(followLinkOf(const Probe(title: 'Hafatra', items: [])), isNull);
      expect(
        followLinkOf(const Probe(title: 'Mahaleo', isSearch: true, items: [])),
        isNull,
      );
      expect(
        followLinkOf(
          const Probe(title: 'Mix', playlistId: 'RDHb8sJ1kP0wE', items: []),
        ),
        isNull,
      );
    });
  });

  group('findNews', () {
    test('counts the available videos not downloaded yet', () async {
      final news = await findNews(
        [(link: 'PLmahaleo00001', title: 'Mahaleo')],
        extractor: _Extractor({
          'https://www.youtube.com/playlist?list=PLmahaleo00001': const Probe(
            title: 'Mahaleo',
            playlistId: 'PLmahaleo00001',
            items: _songs,
          ),
        }),
        archive: _Archive({'aB3dE5fG7hI'}),
        format: MediaFormat.mp3,
      );

      expect(news.single.link, 'PLmahaleo00001');
      expect(news.single.title, 'Mahaleo');
      expect(news.single.count, 1);
    });

    test('leaves out links with nothing new, or that cannot be read', () async {
      final news = await findNews(
        [
          (link: 'PLmahaleo00001', title: 'Mahaleo'),
          (link: 'PLgone0000001', title: 'Gone'),
        ],
        extractor: _Extractor({
          'https://www.youtube.com/playlist?list=PLmahaleo00001': const Probe(
            title: 'Mahaleo',
            playlistId: 'PLmahaleo00001',
            items: _songs,
          ),
        }),
        archive: _Archive({'aB3dE5fG7hI', 'jK9lM1nO3pQ'}),
        format: MediaFormat.mp3,
      );

      expect(news, isEmpty);
    });
  });
}
