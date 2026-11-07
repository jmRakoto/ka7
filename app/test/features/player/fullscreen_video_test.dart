import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_screen.dart';
import 'package:ka7/features/player/track.dart';

import '../../helpers/fake_media_backend.dart';
import '../../helpers/pump_app.dart';

const _clip = Track(
  title: 'Me at the zoo',
  videoId: 'z',
  path: '/v/z.mp4',
  video: true,
);
const _song = Track(title: 'Somambisamby', videoId: 'b', path: '/m/b.mp3');

void main() {
  late FakeMediaBackend backend;
  late PlayerController player;
  late List<MethodCall> system;

  setUp(() {
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
    system = [];
  });

  Future<void> pumpPlayer(
    WidgetTester tester, {
    Size size = const Size(420, 900),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        system.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpApp(tester, PlayerScreen(player: player));
    await tester.pumpAndSettle();
  }

  Iterable<Object?> sent(String method) => [
    for (final call in system)
      if (call.method == method) call.arguments,
  ];

  testWidgets('a video has a fullscreen button, a song has none', (
    tester,
  ) async {
    await player.playAll([_song]);
    await pumpPlayer(tester);
    expect(find.byTooltip('Plein écran'), findsNothing);

    await player.playAll([_clip]);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Plein écran'), findsOneWidget);
  });

  testWidgets('fullscreen: sideways, without the system bars', (tester) async {
    await player.playAll([_clip]);
    await pumpPlayer(tester);

    await tester.tap(find.byTooltip('Plein écran'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake-video')), findsOneWidget);
    expect(find.text('File de lecture'), findsNothing);
    expect(sent('SystemChrome.setPreferredOrientations').last, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(
      sent('SystemChrome.setEnabledSystemUIMode').last,
      'SystemUiMode.immersiveSticky',
    );
  });

  testWidgets('leaving fullscreen gives rotation and bars back', (
    tester,
  ) async {
    await player.playAll([_clip]);
    await pumpPlayer(tester);
    await tester.tap(find.byTooltip('Plein écran'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quitter le plein écran'));
    await tester.pumpAndSettle();

    expect(find.text('File de lecture'), findsOneWidget);
    expect(sent('SystemChrome.setPreferredOrientations').last, isEmpty);
    expect(
      sent('SystemChrome.setEnabledSystemUIMode').last,
      'SystemUiMode.edgeToEdge',
    );
  });

  testWidgets('a tap shows the controls, they pause and jump', (tester) async {
    await player.playAll([_clip]);
    backend
      ..lasts(const Duration(minutes: 2))
      ..at(const Duration(seconds: 30));
    await pumpPlayer(tester);
    await tester.tap(find.byTooltip('Plein écran'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pause'), findsNothing, reason: 'hidden at first');

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Avancer de 10 s'));
    await tester.pump();
    expect(backend.calls.last, 'seek 0:00:40.000000');
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(backend.isPlaying, isFalse);
  });

  testWidgets('the phone turned sideways shows the video fullscreen', (
    tester,
  ) async {
    await player.playAll([_clip]);
    await pumpPlayer(tester, size: const Size(900, 420));

    expect(find.byKey(const Key('fake-video')), findsOneWidget);
    expect(find.text('File de lecture'), findsNothing);
  });

  testWidgets('a song after the video leaves fullscreen', (tester) async {
    await player.playAll([_clip, _song]);
    await pumpPlayer(tester);
    await tester.tap(find.byTooltip('Plein écran'));
    await tester.pumpAndSettle();

    await player.next();
    await tester.pumpAndSettle();

    expect(find.text('File de lecture'), findsOneWidget);
  });
}
