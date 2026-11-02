import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/android_ytdlp.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

const _channel = MethodChannel('mg.rakoto.ka7/ytdlp');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Map<String, Object?> Function(MethodCall call) answer;

  setUp(() {
    calls = [];
    answer = (_) => {};
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return answer(call);
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  /// The Kotlin side calling back into Dart.
  Future<void> native(String method, Map<String, Object?> arguments) =>
      messenger.handlePlatformMessage(
        _channel.name,
        _channel.codec.encodeMethodCall(MethodCall(method, arguments)),
        (_) {},
      );

  test('unpacks the engine once', () async {
    final ytDlp = AndroidYtDlp();

    await ytDlp.init();
    await ytDlp.init();

    expect(calls.map((c) => c.method), ['init']);
  });

  test('runs yt-dlp and returns its output like Process.run', () async {
    answer = (_) => {'exitCode': 1, 'out': '', 'err': 'ERROR: Private video'};

    final result = await AndroidYtDlp().run('yt-dlp', ['-J', 'url']);

    expect(calls.last.method, 'run');
    expect(calls.last.arguments, {
      'args': ['-J', 'url'],
    });
    expect(result.exitCode, 1);
    expect(result.stderr, 'ERROR: Private video');
  });

  test('streams the lines of a download like Process.start', () async {
    final process = await AndroidYtDlp().start('yt-dlp', ['url']);
    final id = (calls.last.arguments as Map)['id'] as String;
    expect(calls.last.method, 'start');
    expect((calls.last.arguments as Map)['args'], ['url']);

    final lines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
    await native('line', {'id': id, 'line': '[ka7] 1 2 3 4'});
    await native('line', {'id': id, 'line': '[ka7] 2 2 3 0'});
    await native('exit', {'id': id, 'exitCode': 1, 'err': 'ERROR: boom'});

    expect(await lines, ['[ka7] 1 2 3 4', '[ka7] 2 2 3 0']);
    expect(await process.exitCode, 1);
    expect(await process.stderr.transform(utf8.decoder).join(), 'ERROR: boom');
  });

  test('keeps parallel downloads apart', () async {
    final ytDlp = AndroidYtDlp();
    final first = await ytDlp.start('yt-dlp', ['a']);
    final firstId = (calls.last.arguments as Map)['id'];
    final second = await ytDlp.start('yt-dlp', ['b']);
    final secondId = (calls.last.arguments as Map)['id'];
    expect(firstId, isNot(secondId));

    final firstLines = first.stdout.transform(utf8.decoder).join();
    await native('line', {'id': secondId, 'line': 'b'});
    await native('line', {'id': firstId, 'line': 'a'});
    await native('exit', {'id': firstId, 'exitCode': 0, 'err': ''});
    await native('exit', {'id': secondId, 'exitCode': 0, 'err': ''});

    expect(await firstLines, 'a\n');
    expect(await second.exitCode, 0);
  });

  test('kill stops the download on the Kotlin side', () async {
    final process = await AndroidYtDlp().start('yt-dlp', ['url']);
    final id = (calls.last.arguments as Map)['id'];

    expect(process.kill(), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(calls.last.method, 'kill');
    expect(calls.last.arguments, {'id': id});
  });

  test('reports a failed start as a missing engine', () async {
    answer = (call) => throw PlatformException(code: 'init', message: 'no');

    await expectLater(
      AndroidYtDlp().start('yt-dlp', ['url']),
      throwsA(isA<ProcessException>()),
    );
  });

  group('engine setup', () {
    test('is ready once the engine is unpacked', () async {
      final status = await AndroidEngineSetup(AndroidYtDlp()).check();

      expect(calls.map((c) => c.method), ['init', 'update']);
      expect(status.isReady, isTrue);
    });

    test('stays ready when yt-dlp cannot be updated (offline)', () async {
      answer = (call) {
        if (call.method == 'update') throw PlatformException(code: 'net');
        return {};
      };

      final status = await AndroidEngineSetup(AndroidYtDlp()).check();

      expect(status.isReady, isTrue);
    });

    test('reports both tools missing when unpacking fails', () async {
      answer = (call) =>
          throw PlatformException(code: 'ytdlp', message: 'disk');

      final status = await AndroidEngineSetup(AndroidYtDlp()).check();

      expect(status.missing, [EngineTool.ytDlp, EngineTool.ffmpeg]);
    });

    test('installing tries to unpack again', () async {
      var fail = true;
      answer = (call) {
        if (fail) throw PlatformException(code: 'ytdlp');
        return {};
      };
      final setup = AndroidEngineSetup(AndroidYtDlp());
      await setup.check();
      fail = false;

      await setup.install(EngineTool.ytDlp).drain<void>();

      expect((await setup.check()).isReady, isTrue);
    });
  });
}
