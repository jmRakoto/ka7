import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

const _playlist = Probe(
  title: 'Erick Manana · Sélection',
  playlistId: 'PLe7rK2mErickManana01',
  items: [_song],
);
const _song = ProbeItem(
  videoId: 'aB3dE5fG7hI',
  title: "Tsara Ny Hiran' Ny Taniko",
);

void main() {
  group('safeFileName', () {
    test('replaces characters forbidden on Windows, macOS or Linux', () {
      expect(
        safeFileName('AC/DC: Back <In> "Black"?*|'),
        "AC-DC - Back (In) 'Black'",
      );
      expect(safeFileName(r'Side A\B'), 'Side A-B');
    });

    test('drops control characters and collapses spaces', () {
      expect(
        safeFileName('Live\tat\n  Antsahamanitra'),
        'Live at Antsahamanitra',
      );
    });

    test('trims trailing dots and spaces Windows would drop', () {
      expect(safeFileName('  Mahaleo...  '), 'Mahaleo');
    });

    test('prefixes names Windows reserves for devices', () {
      expect(safeFileName('CON'), '_CON');
      expect(safeFileName('com1'), '_com1');
    });

    test('names an empty title instead of returning nothing', () {
      expect(safeFileName(' ?? '), 'untitled');
    });

    test('keeps long names under 150 characters', () {
      expect(safeFileName('a' * 400), hasLength(150));
    });
  });

  group('relativePathOf', () {
    group('by artist', () {
      const sung = ProbeItem(
        videoId: 'aB3dE5fG7hI',
        title: "Tsara Ny Hiran' Ny Taniko",
        channel: 'Erick Manana',
      );

      test('files a video in its artist folder, unnumbered', () {
        expect(
          relativePathOf(
            const PlannedDownload(source: _playlist, item: sung, index: 3),
            MediaFormat.mp3,
            layout: FolderLayout.artist,
          ),
          "Erick Manana/Tsara Ny Hiran' Ny Taniko.mp3",
        );
      });

      test('files a single video in its artist folder too', () {
        const video = Probe(title: 'Tsara', items: [sung]);

        expect(
          relativePathOf(
            const PlannedDownload(source: video, item: sung, index: 1),
            MediaFormat.mp4,
            layout: FolderLayout.artist,
          ),
          "Erick Manana/Tsara Ny Hiran' Ny Taniko.mp4",
        );
      });

      test('falls back to the playlist folder when the artist is unknown', () {
        expect(
          relativePathOf(
            const PlannedDownload(source: _playlist, item: _song, index: 3),
            MediaFormat.mp3,
            layout: FolderLayout.artist,
          ),
          "Erick Manana · Sélection/03 - Tsara Ny Hiran' Ny Taniko.mp3",
        );
      });
    });

    test('files a playlist video in the playlist folder, numbered', () {
      const download = PlannedDownload(
        source: _playlist,
        item: _song,
        index: 3,
      );

      expect(
        relativePathOf(download, MediaFormat.mp3),
        "Erick Manana · Sélection/03 - Tsara Ny Hiran' Ny Taniko.mp3",
      );
    });

    test('numbers on three digits when the playlist has over 99 videos', () {
      final big = Probe(
        title: 'Mahaleo',
        playlistId: 'PLmahaleo0001',
        items: List.filled(120, _song),
      );

      expect(
        relativePathOf(
          PlannedDownload(source: big, item: _song, index: 7),
          MediaFormat.mp4,
        ),
        "Mahaleo/007 - Tsara Ny Hiran' Ny Taniko.mp4",
      );
    });

    test('files a channel video in the channel folder, unnumbered', () {
      const channel = Probe(
        title: 'Mahaleo',
        playlistId: 'UC0HN8Wq3EEzK3GF6qKHkdkA',
        isChannel: true,
        items: [_song],
      );

      expect(
        relativePathOf(
          const PlannedDownload(source: channel, item: _song, index: 4),
          MediaFormat.mp3,
        ),
        "Mahaleo/Tsara Ny Hiran' Ny Taniko.mp3",
      );
    });

    test('names original audio with its m4a extension', () {
      const video = Probe(title: 'Hafatra', items: [_song]);

      expect(
        relativePathOf(
          const PlannedDownload(source: video, item: _song, index: 1),
          MediaFormat.m4a,
        ),
        "Tsara Ny Hiran' Ny Taniko.m4a",
      );
    });

    test('puts a single video at the root, without number nor "NA" folder', () {
      const video = Probe(title: 'Hafatra', items: [_song]);

      expect(
        relativePathOf(
          const PlannedDownload(source: video, item: _song, index: 1),
          MediaFormat.mp3,
        ),
        "Tsara Ny Hiran' Ny Taniko.mp3",
      );
    });
  });
}
