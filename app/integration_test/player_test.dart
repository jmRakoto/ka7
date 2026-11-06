import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ka7_core/ka7_core.dart' show StreamCache;
import 'package:ka7/features/player/media_kit_backend.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/track.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;

/// Real player on the desktop: libmpv through media_kit, a real file made by
/// ffmpeg, and a real YouTube stream read by yt-dlp (both from the PATH).
/// `cd app && fvm flutter test integration_test/player_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  late Directory folder;
  late String tone;

  setUpAll(() async {
    folder = Directory.systemTemp.createTempSync('ka7_player_');
    tone = '${folder.path}/tone.mp3';
    // 4 seconds of a 440 Hz tone.
    final made = await Process.run('ffmpeg', [
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=440:duration=4',
      tone,
    ]);
    expect(made.exitCode, 0, reason: '${made.stderr}');
  });
  tearDownAll(() => folder.deleteSync(recursive: true));

  /// Waits until [done] holds, polling the real player.
  Future<void> until(
    bool Function() done, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (!done()) {
      if (DateTime.now().isAfter(end)) fail('timed out');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  testWidgets('plays a downloaded file offline, seeks, stops, ends', (
    tester,
  ) async {
    final backend = MediaKitBackend();
    final player = PlayerController(backend: backend);
    addTearDown(backend.dispose);

    await player.playAll([
      Track(title: 'Tone', videoId: 'tone', path: tone),
      Track(title: 'Tone again', videoId: 'tone2', path: tone),
    ]);
    await until(() => player.duration > Duration.zero);
    expect(player.duration.inSeconds, inInclusiveRange(3, 5));
    await until(() => player.position > const Duration(milliseconds: 500));
    expect(player.playing, isTrue);

    await player.toggle();
    await until(() => !player.playing);
    await player.toggle();
    await until(() => player.playing);

    await player.seek(const Duration(seconds: 2));
    await until(() => player.position >= const Duration(seconds: 2));

    await player.stop();
    await until(() => !player.playing);
    expect(player.position, Duration.zero);

    // Played to its end: the next track follows.
    await player.toggle();
    await player.seek(const Duration(milliseconds: 3500));
    await until(() => player.current?.title == 'Tone again');
    await until(() => player.playing);
  });

  testWidgets('plays a YouTube video online, before downloading it', (
    tester,
  ) async {
    final backend = MediaKitBackend();
    final engine = YtDlpExtractor(run: Process.run);
    final player = PlayerController(
      backend: backend,
      streamUrl: engine.streamUrl,
    );
    addTearDown(backend.dispose);

    final started = DateTime.now();
    await player.playAll([
      const Track(title: 'Me at the zoo', videoId: 'jNQXAC9IVRw'),
    ]);
    // ignore: avoid_print
    print(
      'address and open took ${DateTime.now().difference(started).inMilliseconds} ms',
    );
    await until(() => player.position > const Duration(milliseconds: 500));
    final waited = DateTime.now().difference(started);
    // ignore: avoid_print
    print('online audio started after ${waited.inMilliseconds} ms');
    expect(player.error, isNull);
    expect(player.duration.inSeconds, inInclusiveRange(18, 20));
    await player.close();
  });

  testWidgets('the first video played shows its pictures', (tester) async {
    final backend = MediaKitBackend();
    final engine = YtDlpExtractor(run: Process.run);
    final player = PlayerController(
      backend: backend,
      streamUrl: engine.streamUrl,
    );
    addTearDown(backend.dispose);

    // As in the app: frames keep coming while the video opens.
    final opening = player.playAll([
      const Track(title: 'Me at the zoo', videoId: 'jNQXAC9IVRw', video: true),
    ]);
    var opened = false;
    opening.then((_) => opened = true);
    final start = DateTime.now().add(const Duration(seconds: 30));
    while (!opened || player.position <= const Duration(milliseconds: 500)) {
      if (DateTime.now().isAfter(start)) fail('never played');
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The player page opens once it plays, as in the app.
    await until(() => player.position > const Duration(milliseconds: 500));
    // The player page opens once it plays, as in the app.
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('picture'),
        child: SizedBox(
          width: 320,
          height: 240,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: backend.videoView(),
          ),
        ),
      ),
    );
    await backend.firstFrame.timeout(
      const Duration(seconds: 20),
      onTimeout: () => fail('no frame'),
    );
    // Not black: some pixel carries the zoo.
    final end = DateTime.now().add(const Duration(seconds: 20));
    var lit = 0;
    while (lit == 0) {
      if (DateTime.now().isAfter(end)) fail('no picture: black screen');
      await tester.pump(const Duration(milliseconds: 200));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('picture')),
      );
      final image = await boundary.toImage();
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      lit = 0;
      for (var p = 0; p < bytes.length; p += 4) {
        if (bytes[p] + bytes[p + 1] + bytes[p + 2] > 60) lit++;
      }
      // ignore: avoid_print
      print('lit pixels: $lit');
    }
    await player.close();
  });

  testWidgets('plays the video stream of a YouTube video', (tester) async {
    final backend = MediaKitBackend();
    final engine = YtDlpExtractor(run: Process.run);
    final player = PlayerController(
      backend: backend,
      streamUrl: engine.streamUrl,
    );
    addTearDown(backend.dispose);

    var opened = false;
    player
        .playAll([
          const Track(
            title: 'Me at the zoo',
            videoId: 'jNQXAC9IVRw',
            video: true,
          ),
        ])
        .then((_) => opened = true);
    // As in the app: frames keep coming while the video opens.
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (!opened || player.position <= const Duration(milliseconds: 500)) {
      if (DateTime.now().isAfter(end)) fail('never played');
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(player.error, isNull);
    await player.close();
  });

  testWidgets('▶ starts in under 5 s once the address was asked ahead', (
    tester,
  ) async {
    final backend = MediaKitBackend();
    final streams = StreamCache(YtDlpExtractor(run: Process.run));
    final player = PlayerController(
      backend: backend,
      streamUrl: streams.streamUrl,
    );
    addTearDown(backend.dispose);

    // The preview shows the title; the user reads for a few seconds.
    streams.prefetch('jNQXAC9IVRw', video: false);
    await Future<void>.delayed(const Duration(seconds: 10));

    final started = DateTime.now();
    await player.playAll([
      const Track(title: 'Me at the zoo', videoId: 'jNQXAC9IVRw'),
    ]);
    await until(() => player.position > const Duration(milliseconds: 500));
    final waited = DateTime.now().difference(started);
    // ignore: avoid_print
    print('prefetched audio started after ${waited.inMilliseconds} ms');
    expect(waited, lessThan(const Duration(seconds: 5)));
    await player.close();
  });
}
