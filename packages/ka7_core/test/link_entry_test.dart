import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseEntry', () {
    test('recognizes a bare 11-character video id', () {
      final entry = parseEntry('dQw4w9WgXcQ');

      expect(entry, isA<VideoEntry>());
      expect((entry as VideoEntry).videoId, 'dQw4w9WgXcQ');
    });

    test('recognizes watch links on every YouTube host', () {
      for (final link in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'youtube.com/watch?v=dQw4w9WgXcQ',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=42',
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
      ]) {
        final entry = parseEntry(link);

        expect(entry, isA<VideoEntry>(), reason: link);
        expect((entry as VideoEntry).videoId, 'dQw4w9WgXcQ', reason: link);
      }
    });

    test('recognizes youtu.be short links and shorts, ignoring tracking', () {
      for (final link in [
        'https://youtu.be/Qm7tR2vLx9A?si=Xy12abCd',
        'youtu.be/Qm7tR2vLx9A',
        'https://www.youtube.com/shorts/Qm7tR2vLx9A',
      ]) {
        final entry = parseEntry(link);

        expect(entry, isA<VideoEntry>(), reason: link);
        expect((entry as VideoEntry).videoId, 'Qm7tR2vLx9A', reason: link);
      }
    });

    test('recognizes playlists from a link, a bare id or a list= fragment', () {
      const cases = {
        'https://www.youtube.com/playlist?list=PLe7rK2mErickManana01':
            'PLe7rK2mErickManana01',
        'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy':
            'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
        'OLAK5uy_kLoloSyNyTariny0': 'OLAK5uy_kLoloSyNyTariny0',
        'UUa1b2c3d4e5f6g7h8i9j0kl': 'UUa1b2c3d4e5f6g7h8i9j0kl',
        'list=PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy&index=3':
            'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
      };
      cases.forEach((input, playlistId) {
        final entry = parseEntry(input);

        expect(entry, isA<PlaylistEntry>(), reason: input);
        expect((entry as PlaylistEntry).playlistId, playlistId, reason: input);
      });
    });

    test('keeps both ids for a video opened from a playlist', () {
      final entry = parseEntry(
        'https://www.youtube.com/watch?v=Hb8sJ1kP0wE&list=PLmhl0Savigny2011LiveA',
      );

      expect(entry, isA<VideoInPlaylistEntry>());
      entry as VideoInPlaylistEntry;
      expect(entry.videoId, 'Hb8sJ1kP0wE');
      expect(entry.playlistId, 'PLmhl0Savigny2011LiveA');
    });

    test('flags YouTube mixes, and only them', () {
      final mix = parseEntry(
        'https://www.youtube.com/playlist?list=RDHb8sJ1kP0wE',
      );
      final album = parseEntry('OLAK5uy_kLoloSyNyTariny0');

      expect((mix as PlaylistEntry).isMix, isTrue);
      expect((album as PlaylistEntry).isMix, isFalse);
    });

    test('recognizes channels by handle or by id', () {
      const cases = {
        'https://www.youtube.com/@mahaleo': '@mahaleo',
        'youtube.com/@mahaleo/videos': '@mahaleo',
        'https://www.youtube.com/channel/UCa1b2c3d4e5f6g7h8i9j0kl':
            'channel/UCa1b2c3d4e5f6g7h8i9j0kl',
      };
      cases.forEach((input, channel) {
        final entry = parseEntry(input);

        expect(entry, isA<ChannelEntry>(), reason: input);
        expect((entry as ChannelEntry).channel, channel, reason: input);
      });
    });

    test('rejects what it cannot download, with the reason', () {
      const cases = {
        'vimeo.com/123456': InvalidReason.notYouTube,
        'https://www.youtube.com/feed/library': InvalidReason.noVideoOrPlaylist,
        'Mahaleo': InvalidReason.freeText,
        'Erick Manana': InvalidReason.freeText,
      };
      cases.forEach((input, reason) {
        final entry = parseEntry(input);

        expect(entry, isA<InvalidEntry>(), reason: input);
        expect((entry as InvalidEntry).reason, reason, reason: input);
      });
    });

    test('gives each link its standard form, without tracking', () {
      const cases = {
        'https://youtu.be/Qm7tR2vLx9A?si=Xy12abCd':
            'https://www.youtube.com/watch?v=Qm7tR2vLx9A',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ&pp=ygU&t=42':
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy':
            'https://www.youtube.com/playlist?list=PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
        'https://www.youtube.com/watch?v=Hb8sJ1kP0wE&list=PLmhl0Savigny2011LiveA&index=4':
            'https://www.youtube.com/watch?v=Hb8sJ1kP0wE&list=PLmhl0Savigny2011LiveA',
        'youtube.com/@mahaleo/videos': 'https://www.youtube.com/@mahaleo',
      };
      cases.forEach((input, url) {
        final entry = parseEntry(input);

        expect((entry as MediaEntry).url, url, reason: input);
      });
    });
  });

  group('parseLinks', () {
    test(
      'reads one entry per line or per space, skipping blanks and # comments',
      () {
        const text = '''
# YouTube Links File
https://youtu.be/Qm7tR2vLx9A   PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy

   # https://www.youtube.com/watch?v=dQw4w9WgXcQ
vimeo.com/123456
''';

        final entries = parseLinks(text);

        expect(entries.map((e) => e.source), [
          'https://youtu.be/Qm7tR2vLx9A',
          'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
          'vimeo.com/123456',
        ]);
        expect(entries.map((e) => e.runtimeType), [
          VideoEntry,
          PlaylistEntry,
          InvalidEntry,
        ]);
      },
    );

    test('marks a repeated media as a duplicate of the first one', () {
      final entries = parseLinks('''
https://youtu.be/Qm7tR2vLx9A?si=Xy12abCd
https://www.youtube.com/watch?v=Qm7tR2vLx9A
Qm7tR2vLx9A
''');

      expect(entries[0], isA<VideoEntry>());
      expect(entries[1], isA<DuplicateEntry>());
      expect(entries[2], isA<DuplicateEntry>());
      expect((entries[1] as DuplicateEntry).of, same(entries[0]));
    });
  });
}
