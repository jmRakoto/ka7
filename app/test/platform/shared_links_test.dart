import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/shared_links.dart';

const _channel = MethodChannel('mg.rakoto.ka7/share');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test('hands over the link that launched the app, then later ones', () async {
    messenger.setMockMethodCallHandler(
      _channel,
      (call) async => call.method == 'initial' ? 'https://youtu.be/a' : null,
    );
    final received = <String>[];

    sharedLinks().listen(received.add);
    await Future<void>.delayed(Duration.zero);
    await messenger.handlePlatformMessage(
      _channel.name,
      _channel.codec.encodeMethodCall(
        const MethodCall('shared', 'https://youtu.be/b'),
      ),
      (_) {},
    );

    expect(received, ['https://youtu.be/a', 'https://youtu.be/b']);
  });

  test('stays quiet when the app was opened normally', () async {
    messenger.setMockMethodCallHandler(_channel, (call) async => null);
    final received = <String>[];

    sharedLinks().listen(received.add);
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });
}
