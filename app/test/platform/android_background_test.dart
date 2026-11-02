import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/android_background.dart';

const _channel = MethodChannel('mg.rakoto.ka7/background');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test('sends progress to the notification, then releases', () async {
    final work = AndroidBackgroundWork()
      ..keep(title: 'Téléchargement', done: 0, total: 3)
      ..keep(title: 'Téléchargement', done: 1, total: 3);
    await Future<void>.delayed(Duration.zero);

    expect(calls.map((c) => c.method), ['keep', 'keep']);
    expect(calls.last.arguments, {
      'title': 'Téléchargement',
      'text': '1/3',
      'done': 1,
      'total': 3,
    });
    work.release();
    await Future<void>.delayed(Duration.zero);
    expect(calls.last.method, 'release');
  });

  test('releases only what it kept', () async {
    AndroidBackgroundWork()
      ..release()
      ..release();
    await Future<void>.delayed(Duration.zero);

    expect(calls, isEmpty);
  });
}
