import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/android_folders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('mg.rakoto.ka7/folders');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('hands over the folder picked, and how to show it', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pick');
      return {'uri': 'content://tree/1234%3AMozika', 'label': 'SD/Mozika'};
    });

    final picked = await pickAndroidFolder();

    expect(picked, (uri: 'content://tree/1234%3AMozika', label: 'SD/Mozika'));
  });

  test('opens on the folder given', () async {
    Object? sent;
    messenger.setMockMethodCallHandler(channel, (call) async {
      sent = call.arguments;
      return null;
    });

    await pickAndroidFolder(from: 'content://tree/primary%3AK7');

    expect(sent, {'from': 'content://tree/primary%3AK7'});
  });

  test('gives nothing when the picker is closed', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    expect(await pickAndroidFolder(), isNull);
  });

  test('lists a folder\'s playable files, by their place in it', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'list');
      expect(call.arguments, {'uri': 'content://tree/primary%3AMusic'});
      return [
        {
          'uri': 'content://doc/b1',
          'name': '10 Bonga.mp3',
          'path': '10 Bonga.mp3',
        },
        {'uri': 'content://doc/c', 'name': 'cover.jpg', 'path': 'cover.jpg'},
        {
          'uri': 'content://doc/m1',
          'name': '1 Ny.m4a',
          'path': 'Mahaleo/1 Ny.m4a',
        },
        {
          'uri': 'content://doc/v2',
          'name': '2 Veloma.mp3',
          'path': '2 Veloma.mp3',
        },
      ];
    });

    final files = await listAndroidFolder('content://tree/primary%3AMusic');

    expect(
      [for (final f in files) f.name],
      ['2 Veloma.mp3', '10 Bonga.mp3', '1 Ny.m4a'],
    );
    expect(files.first.path, 'content://doc/v2');
  });

  test('a folder that cannot be read gives nothing', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'gone'),
    );

    expect(await listAndroidFolder('content://tree/x'), isEmpty);
  });
}
