import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

const _official = ChannelRef(
  name: 'Mahaleo official ',
  channelId: 'UCt4quCNBZZ0Cc6xWXUSp0zQ',
);

Probe _search({
  List<ChannelRef> channels = const [],
  List<ProbeItem> items = const [],
}) => Probe(title: 'Mahaleo', isSearch: true, channels: channels, items: items);

void main() {
  test('a channel is followed by its YouTube address', () {
    expect(
      _official.link,
      'https://www.youtube.com/channel/UCt4quCNBZZ0Cc6xWXUSp0zQ',
    );
  });

  test('offers the channel found by the search', () {
    final channels = channelsMatching(
      _search(channels: [_official]),
      'mahaleo',
    );

    expect(channels.single.channelId, 'UCt4quCNBZZ0Cc6xWXUSp0zQ');
    expect(channels.single.name, 'Mahaleo official', reason: 'trimmed');
  });

  test('offers the channels of results whose name holds the search', () {
    final channels = channelsMatching(
      _search(
        items: const [
          ProbeItem(
            videoId: '7MSYzO8Avzk',
            title: 'Somambisamby',
            channel: 'Mahaleo official',
            channelId: 'UCt4quCNBZZ0Cc6xWXUSp0zQ',
          ),
          ProbeItem(
            videoId: '-ieWGHvs9xQ',
            title: 'Mahaleo Dadah & Fafah',
            channel: 'Vaovao Malagasy',
            channelId: 'UClsWET8BmyoPbIvMxRVOIDA',
          ),
          ProbeItem(
            videoId: 'kSPriyLUdvk',
            title: 'Madagascar',
            channel: 'Mahaleo Fans',
            channelId: 'UCv2n4bLsEi0p9uMiHLFxXSQ',
          ),
        ],
      ),
      'Mahaleo',
    );

    expect(channels.map((c) => c.name), ['Mahaleo official', 'Mahaleo Fans']);
  });

  test('keeps the picture of a channel the search found', () {
    final channels = channelsMatching(
      _search(
        channels: const [
          ChannelRef(
            name: 'Mahaleo official',
            channelId: 'UCt4quCNBZZ0Cc6xWXUSp0zQ',
            avatar: 'https://yt3.ggpht.com/abc=s176',
          ),
        ],
      ),
      'mahaleo',
    );

    expect(channels.single.avatar, 'https://yt3.ggpht.com/abc=s176');
  });

  test('every word of the search must be in the name, any case', () {
    final search = _search(channels: [_official]);

    expect(channelsMatching(search, '  OFFICIAL   mahaleo '), hasLength(1));
    expect(channelsMatching(search, 'mahaleo live'), isEmpty);
  });

  test('lists each channel once, the one the search found first', () {
    final channels = channelsMatching(
      _search(
        channels: [_official],
        items: const [
          ProbeItem(
            videoId: '7MSYzO8Avzk',
            title: 'Somambisamby',
            channel: 'Mahaleo official',
            channelId: 'UCt4quCNBZZ0Cc6xWXUSp0zQ',
          ),
        ],
      ),
      'mahaleo',
    );

    expect(channels, hasLength(1));
  });

  test('offers nothing for a result without a known channel', () {
    final channels = channelsMatching(
      _search(
        items: const [ProbeItem(videoId: 'x', title: 'y', channel: 'Mahaleo')],
      ),
      'mahaleo',
    );

    expect(channels, isEmpty);
  });

  group('holdsWords', () {
    test('every word, anywhere, any case', () {
      expect(
        holdsWords('Denise - Jalousie (Clip Officiel)', 'clip jalou'),
        isTrue,
      );
      expect(holdsWords('Denise - Jalousie', 'live'), isFalse);
    });

    test('reads styled letters as plain ones', () {
      expect(
        holdsWords(
          '𝐒𝐀𝐌𝐎𝐄̈𝐋𝐀 - 𝐓𝐈𝐀𝐕𝐈𝐍𝐀 🇲🇬 (Official Video Clip)',
          'samoela tiavina',
        ),
        isTrue,
        reason: 'mathematical bold, and Ë as E plus its accent mark',
      );
      expect(holdsWords('𝘛𝘪𝘢𝘷𝘪𝘯𝘢', 'tiavina'), isTrue, reason: 'italic');
      expect(holdsWords('ＴＩＡＶＩＮＡ ２０２１', 'tiavina 2021'), isTrue);
    });

    test('ignores accents both ways', () {
      expect(holdsWords('Fitiavàna lehibé', 'fitiavana lehibe'), isTrue);
      expect(holdsWords('Fitiavana', 'fitiavàna'), isTrue);
    });

    test('an empty filter holds everything', () {
      expect(holdsWords('Denise', '   '), isTrue);
    });
  });
}
