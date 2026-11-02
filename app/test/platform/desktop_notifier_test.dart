import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/desktop_notifier.dart';

void main() {
  test('shows the end of downloads through notify-send', () async {
    final calls = <List<String>>[];
    DesktopNotifier(
      run: (executable, arguments) async {
        calls.add([executable, ...arguments]);
        return ProcessResult(1, 0, '', '');
      },
    ).finished(title: 'Téléchargements terminés', body: '2 réussis');
    await Future<void>.delayed(Duration.zero);

    expect(calls, [
      [
        'notify-send',
        '--app-name=Ka7',
        '--icon=mg.rakoto.ka7',
        'Téléchargements terminés',
        '2 réussis',
      ],
    ]);
  });

  test('stays silent where notify-send is missing', () async {
    final errors = <Object>[];
    await runZonedGuarded(() async {
      DesktopNotifier(
        run: (executable, arguments) async =>
            throw const ProcessException('notify-send', []),
      ).finished(title: 'Fin', body: '1 réussi');
      await Future<void>.delayed(Duration.zero);
    }, (error, _) => errors.add(error));

    expect(errors, isEmpty);
  });
}
