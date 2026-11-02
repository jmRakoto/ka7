import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/link_drop.dart';

void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('ka7_drop_'));
  tearDown(() => folder.deleteSync(recursive: true));

  String file(String name, String content) =>
      (File('${folder.path}/$name')..writeAsStringSync(content)).path;

  test('keeps dropped links and text as they are', () async {
    expect(
      await droppedText([
        'https://www.youtube.com/watch?v=Qm7tR2vLx9A',
        'PLe7rK2mErickManana01',
      ]),
      'https://www.youtube.com/watch?v=Qm7tR2vLx9A\nPLe7rK2mErickManana01',
    );
  });

  test('reads a dropped links file', () async {
    final links = file('links.txt', '# Mahaleo\nQm7tR2vLx9A\n');

    expect(await droppedText([links]), '# Mahaleo\nQm7tR2vLx9A');
  });

  test('leaves out files that are not text, and folders', () async {
    final song = file('song.mp3', 'ID3');
    final links = file('LINKS.TXT', 'Qm7tR2vLx9A');

    expect(await droppedText([song, folder.path, links]), 'Qm7tR2vLx9A');
  });
}
