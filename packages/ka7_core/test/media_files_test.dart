import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

MediaFile _f(String path) =>
    MediaFile(path: path, name: path.substring(path.lastIndexOf('/') + 1));

void main() {
  test('plays common sound and video files, whatever the case', () {
    for (final name in [
      'a.mp3',
      'a.M4A',
      'a.flac',
      'a.ogg',
      'a.opus',
      'a.wav',
      'a.aac',
      'a.mp4',
      'a.webm',
      'a.mkv',
      'a.MOV',
    ]) {
      expect(isPlayable(name), isTrue, reason: name);
    }
  });

  test('leaves the rest out', () {
    for (final name in [
      'cover.jpg',
      'notes.txt',
      'mp3',
      'a.mp3.part',
      '.mp3x',
    ]) {
      expect(isPlayable(name), isFalse, reason: name);
    }
  });

  test('a title is the name without its extension', () {
    expect(_f('/m/Mahaleo - Besorongola.mp3').title, 'Mahaleo - Besorongola');
    expect(_f('/m/v1.2 live.mp4').title, 'v1.2 live');
  });

  test('knows a video from a song', () {
    expect(_f('/v/clip.mp4').isVideo, isTrue);
    expect(_f('/v/clip.MKV').isVideo, isTrue);
    expect(_f('/m/song.mp3').isVideo, isFalse);
  });

  test('keeps playable files, by path as a person sorts: a subfolder '
      'stays together', () {
    final sorted = playableSorted([
      _f('/m/10 Dix.mp3'),
      _f('/m/cover.jpg'),
      _f('/m/2 deux.mp3'),
      _f('/m/b/1 un.mp3'),
      _f('/m/Été.mp3'),
      _f('/m/abc.mp3'),
    ]);

    expect(
      [for (final f in sorted) f.path],
      [
        '/m/2 deux.mp3',
        '/m/10 Dix.mp3',
        '/m/abc.mp3',
        '/m/b/1 un.mp3',
        '/m/Été.mp3',
      ],
    );
  });
}
