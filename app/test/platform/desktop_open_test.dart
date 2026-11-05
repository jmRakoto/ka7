import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/desktop_open.dart';

void main() {
  late List<List<String>> calls;
  Future<ProcessResult> run(String executable, List<String> arguments) async {
    calls.add([executable, ...arguments]);
    return ProcessResult(1, 0, '', '');
  }

  setUp(() => calls = []);

  test('Linux: xdg-open for folders and links', () async {
    await openOnDesktop('/home/me/Music/Ka7', run: run, windows: false);
    await openOnDesktop('https://example.org', run: run, windows: false);

    expect(calls, [
      ['xdg-open', '/home/me/Music/Ka7'],
      ['xdg-open', 'https://example.org'],
    ]);
  });

  test('Windows: Explorer, with backslashes in folders', () async {
    await openOnDesktop(r'C:\Users\me\Music\Ka7/Mix', run: run, windows: true);
    await openOnDesktop('https://example.org/a/b', run: run, windows: true);

    expect(calls, [
      ['explorer', r'C:\Users\me\Music\Ka7\Mix'],
      ['explorer', 'https://example.org/a/b'],
    ]);
  });
}
