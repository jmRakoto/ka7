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

  test('gives nothing when the picker is closed', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    expect(await pickAndroidFolder(), isNull);
  });
}
