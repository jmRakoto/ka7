import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/user_folders.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

RunProcess _answer(int exitCode, String stdout) =>
    (executable, arguments) async => ProcessResult(1, exitCode, stdout, '');

void main() {
  test('asks xdg-user-dir for the localized folder', () async {
    List<String>? asked;
    final folder = await userFolder(
      UserFolder.music,
      home: '/home/me',
      run: (executable, arguments) async {
        asked = [executable, ...arguments];
        return ProcessResult(1, 0, '/home/me/Musique\n', '');
      },
    );

    expect(asked, ['xdg-user-dir', 'MUSIC']);
    expect(folder, '/home/me/Musique');
  });

  test('falls back to ~/Videos when xdg-user-dir only knows home', () async {
    final folder = await userFolder(
      UserFolder.videos,
      home: '/home/me',
      run: _answer(0, '/home/me\n'),
    );

    expect(folder, '/home/me/Videos');
  });

  test('falls back to ~/Music without xdg-user-dir', () async {
    final folder = await userFolder(
      UserFolder.music,
      home: '/home/me',
      run: (executable, arguments) async =>
          throw ProcessException(executable, arguments, 'not found', 2),
    );

    expect(folder, '/home/me/Music');
  });

  test('Ka7 files in its own folder there, as on the phone', () async {
    final music = await ka7Folder(
      UserFolder.music,
      home: '/home/me',
      run: _answer(0, '/home/me/Musique\n'),
    );
    final videos = await ka7Folder(
      UserFolder.videos,
      home: '/home/me',
      run: _answer(0, '/home/me\n'),
    );

    expect(music, '/home/me/Musique/Ka7');
    expect(videos, '/home/me/Videos/Ka7');
  });
}
