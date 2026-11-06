import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/mini_player.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_screen.dart';
import 'package:ka7/features/player/track.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../helpers/fake_media_backend.dart';
import '../../helpers/pump_app.dart';

const _a = Track(title: 'Tanalahy ny foko', videoId: 'a', path: '/m/a.mp3');
const _b = Track(title: 'Somambisamby', videoId: 'b', path: '/m/b.mp3');
const _clip = Track(
  title: 'Me at the zoo',
  videoId: 'z',
  path: '/v/z.mp4',
  video: true,
);

void main() {
  late FakeMediaBackend backend;
  late PlayerController player;

  setUp(() {
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
  });

  group('mini player', () {
    Future<void> pumpMini(WidgetTester tester, {VoidCallback? onOpen}) =>
        pumpApp(
          tester,
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayer(player: player, onOpen: onOpen ?? () {}),
            ),
          ),
        );

    testWidgets('is hidden while nothing plays', (tester) async {
      await pumpMini(tester);

      expect(find.byTooltip('Pause'), findsNothing);
      expect(find.byTooltip('Lire'), findsNothing);
    });

    testWidgets('shows the track, pauses and plays it', (tester) async {
      await player.playAll([_a, _b]);
      await pumpMini(tester);

      expect(find.text('Tanalahy ny foko'), findsOneWidget);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(backend.isPlaying, isFalse);
      await tester.tap(find.byTooltip('Lire'));
      await tester.pump();
      expect(backend.isPlaying, isTrue);
    });

    testWidgets('goes to the next track', (tester) async {
      await player.playAll([_a, _b]);
      await pumpMini(tester);

      await tester.tap(find.byTooltip('Suivant'));
      await tester.pump();

      expect(find.text('Somambisamby'), findsOneWidget);
    });

    testWidgets('closes the player', (tester) async {
      await player.playAll([_a]);
      await pumpMini(tester);

      await tester.tap(find.byTooltip('Fermer le lecteur'));
      await tester.pump();

      expect(find.text('Tanalahy ny foko'), findsNothing);
    });

    testWidgets('opens the full player when tapped', (tester) async {
      var opened = false;
      await player.playAll([_a]);
      await pumpMini(tester, onOpen: () => opened = true);

      await tester.tap(find.bySemanticsLabel('Ouvrir le lecteur'));

      expect(opened, isTrue);
    });

    group('listening from the preview (online audio)', () {
      const online = Track(title: 'Hafatra', videoId: 'h');
      late PlayerController preview;

      setUp(() {
        preview = PlayerController(
          backend: backend,
          streamUrl: (id, {required video}) async => 'https://stream/$id',
        );
      });

      Future<void> pumpPreview(WidgetTester tester, {VoidCallback? onOpen}) =>
          pumpApp(
            tester,
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: MiniPlayer(player: preview, onOpen: onOpen ?? () {}),
              ),
            ),
          );

      testWidgets('only pause, back, forward and close', (tester) async {
        await preview.playAll([online]);
        await pumpPreview(tester);

        for (final label in [
          'Pause',
          'Reculer de 10 s',
          'Avancer de 10 s',
          'Fermer le lecteur',
        ]) {
          expect(find.byTooltip(label), findsOneWidget, reason: label);
        }
        expect(find.byTooltip('Suivant'), findsNothing);
      });

      testWidgets('does not open the whole player', (tester) async {
        var opened = false;
        await preview.playAll([online]);
        await pumpPreview(tester, onOpen: () => opened = true);

        await tester.tap(find.text('Hafatra'));

        expect(opened, isFalse);
        expect(find.bySemanticsLabel('Ouvrir le lecteur'), findsNothing);
      });

      testWidgets('a bar to drag, with the times', (tester) async {
        await preview.playAll([online]);
        backend
          ..lasts(const Duration(minutes: 3, seconds: 12))
          ..at(const Duration(seconds: 42));
        await pumpPreview(tester);

        expect(find.text('0:42'), findsOneWidget);
        expect(find.text('3:12'), findsOneWidget);
        await tester.tap(find.byType(Slider));
        await tester.pump();
        expect(backend.calls.last, startsWith('seek 0:01:'));
      });

      testWidgets('jumps 10 s forward and back', (tester) async {
        await preview.playAll([online]);
        backend
          ..lasts(const Duration(minutes: 3))
          ..at(const Duration(seconds: 30));
        await pumpPreview(tester);

        await tester.tap(find.byTooltip('Avancer de 10 s'));
        await tester.pump();
        expect(backend.calls.last, 'seek 0:00:40.000000');
        await tester.tap(find.byTooltip('Reculer de 10 s'));
        await tester.pump();
        expect(backend.calls.last, 'seek 0:00:30.000000');
      });

      testWidgets('a video from the preview still opens the player', (
        tester,
      ) async {
        await preview.playAll([
          const Track(title: 'Hafatra', videoId: 'h', video: true),
        ]);
        await pumpPreview(tester);

        expect(find.bySemanticsLabel('Ouvrir le lecteur'), findsOneWidget);
      });
    });

    testWidgets('says why a track does not play', (tester) async {
      await player.playAll([const Track(title: 'Me at the zoo', videoId: 'z')]);
      await pumpMini(tester);

      expect(find.text('Ce titre ne peut pas être lu'), findsOneWidget);
    });
  });

  group('full player', () {
    Future<void> pumpFull(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, PlayerScreen(player: player));
    }

    testWidgets('has every control of a player', (tester) async {
      await player.playAll([_a, _b]);
      await pumpFull(tester);

      for (final label in [
        'Pause',
        'Arrêter',
        'Suivant',
        'Précédent',
        'Avancer de 10 s',
        'Reculer de 10 s',
        'Lecture aléatoire',
        'Répéter : non',
      ]) {
        expect(find.byTooltip(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('jumps 10 s forward and back', (tester) async {
      await player.playAll([_a]);
      backend
        ..lasts(const Duration(minutes: 3))
        ..at(const Duration(seconds: 30));
      await pumpFull(tester);

      await tester.tap(find.byTooltip('Avancer de 10 s'));
      await tester.pump();
      expect(backend.calls.last, 'seek 0:00:40.000000');

      await tester.tap(find.byTooltip('Reculer de 10 s'));
      await tester.pump();
      expect(backend.calls.last, 'seek 0:00:30.000000');
    });

    testWidgets('shows where it is in the track', (tester) async {
      await player.playAll([_a]);
      backend
        ..lasts(const Duration(minutes: 3, seconds: 5))
        ..at(const Duration(seconds: 42));
      await pumpFull(tester);

      expect(find.text('0:42'), findsOneWidget);
      expect(find.text('3:05'), findsOneWidget);
    });

    testWidgets('stop goes back to the start, paused', (tester) async {
      await player.playAll([_a]);
      await pumpFull(tester);

      await tester.tap(find.byTooltip('Arrêter'));
      await tester.pump();

      expect(backend.isPlaying, isFalse);
      expect(find.byTooltip('Lire'), findsOneWidget);
    });

    testWidgets('repeat goes off, list, track, off', (tester) async {
      await player.playAll([_a]);
      await pumpFull(tester);

      await tester.tap(find.byTooltip('Répéter : non'));
      await tester.pump();
      expect(player.repeat, Repeat.all);
      await tester.tap(find.byTooltip('Répéter la liste'));
      await tester.pump();
      expect(player.repeat, Repeat.one);
      await tester.tap(find.byTooltip('Répéter ce titre'));
      await tester.pump();
      expect(player.repeat, Repeat.off);
    });

    testWidgets('shuffle turns on and off', (tester) async {
      await player.playAll([_a, _b]);
      await pumpFull(tester);

      await tester.tap(find.byTooltip('Lecture aléatoire'));
      await tester.pump();

      expect(player.shuffled, isTrue);
    });

    testWidgets('lists the queue and plays a track from it', (tester) async {
      await player.playAll([_a, _b]);
      await pumpFull(tester);

      await tester.scrollUntilVisible(find.text('Somambisamby'), 200);
      await tester.tap(find.text('Somambisamby'));
      await tester.pump();

      expect(backend.opened.last, '/m/b.mp3');
    });

    testWidgets('shows the pictures of a video', (tester) async {
      await player.playAll([_clip]);
      await pumpFull(tester);

      expect(find.byKey(const Key('fake-video')), findsOneWidget);
    });
  });
}
