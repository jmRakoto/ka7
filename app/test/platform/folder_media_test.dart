import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/folder_media.dart';

void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('ka7_folder_'));
  tearDown(() => folder.deleteSync(recursive: true));

  void touch(String path) => File('${folder.path}/$path')
    ..createSync(recursive: true)
    ..writeAsStringSync('x');

  test('lists the playable files, subfolders too, sorted', () async {
    touch('2 Veloma.mp3');
    touch('10 Bonga.mp3');
    touch('cover.jpg');
    touch('Mahaleo/1 Ny Fitiavana.m4a');
    touch('Clips/Hafatra.mp4');

    final files = await listFolderMedia(folder.path);

    expect(
      [for (final f in files) f.path.substring(folder.path.length)],
      [
        '/2 Veloma.mp3',
        '/10 Bonga.mp3',
        '/Clips/Hafatra.mp4',
        '/Mahaleo/1 Ny Fitiavana.m4a',
      ],
    );
    expect(files.first.name, '2 Veloma.mp3');
  });

  test('a folder gone gives nothing, without failing', () async {
    expect(await listFolderMedia('${folder.path}/gone'), isEmpty);
  });

  test('shows a folder from the home folder', () {
    expect(
      folderLabel('/home/me/Musique/Mahaleo', home: '/home/me'),
      'Musique/Mahaleo',
    );
    expect(folderLabel('/home/me/', home: '/home/me'), '/home/me');
    expect(
      folderLabel('/media/usb/Mozika', home: '/home/me'),
      '/media/usb/Mozika',
    );
    expect(folderLabel('/home/meme/x', home: '/home/me'), '/home/meme/x');
  });
}
