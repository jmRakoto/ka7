import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_hub_screen.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../helpers/fake_media_backend.dart';
import '../../helpers/pump_app.dart';

const _a = ProbeItem(videoId: 'yXs506QBhJY', title: 'Tanalahy ny foko');
const _b = ProbeItem(videoId: 'YW-QLSPY8Ew', title: 'Somambisamby');
const _c = ProbeItem(videoId: 'tXfQdfIY2qg', title: 'Veloma Mahaleo');
const _source = Probe(title: 'Mahaleo', items: [_a, _b, _c]);
final _monday = DateTime(2026, 11, 2, 9);

PlannedDownload _planned(ProbeItem item, int index) =>
    PlannedDownload(source: _source, item: item, index: index);

void main() {
  late Ka7Store store;
  late FakeMediaBackend backend;
  late PlayerController player;
  late ValueNotifier<int> changes;
  var opened = 0;

  setUp(() async {
    store = Ka7Store.inMemory();
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
    changes = ValueNotifier(0);
    opened = 0;
    // Oldest first: newest first on screen, b then a; c failed.
    await store.record(
      JobSucceeded(_planned(_a, 1), '/m/a.mp3'),
      MediaFormat.mp3,
      _monday,
    );
    await store.record(
      JobSucceeded(_planned(_b, 2), '/m/b.mp3'),
      MediaFormat.mp3,
      _monday.add(const Duration(minutes: 1)),
    );
    await store.record(
      JobFailed(_planned(_c, 3), FailureReason.network),
      MediaFormat.mp3,
      _monday.add(const Duration(minutes: 2)),
    );
  });
  tearDown(() => store.close());

  Future<void> pumpHub(
    WidgetTester tester, {
    Size size = const Size(900, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      PlayerHubScreen(
        store: store,
        player: player,
        changes: changes,
        onOpenPlayer: () => opened++,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String title) async {
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(title),
          matching: find.byType(ListTile),
        ),
        matching: find.byTooltip('Actions'),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> titles() => [for (final t in player.tracks) t.title];

  group('titles', () {
    testWidgets('lists only the downloaded files, newest first', (
      tester,
    ) async {
      await pumpHub(tester);

      expect(find.text('Somambisamby'), findsOneWidget);
      expect(find.text('Tanalahy ny foko'), findsOneWidget);
      expect(find.text('Veloma Mahaleo'), findsNothing, reason: 'failed');
      expect(
        tester.getTopLeft(find.text('Somambisamby')).dy,
        lessThan(tester.getTopLeft(find.text('Tanalahy ny foko')).dy),
      );
    });

    testWidgets('a file downloaded twice shows once, the latest', (
      tester,
    ) async {
      await store.record(
        JobSucceeded(_planned(_a, 1), '/m/a-again.mp3'),
        MediaFormat.mp3,
        _monday.add(const Duration(hours: 1)),
      );
      await pumpHub(tester);

      expect(find.text('Tanalahy ny foko'), findsOneWidget);
      await tester.tap(find.text('Tanalahy ny foko'));
      await tester.pump();
      expect(backend.opened, ['/m/a-again.mp3']);
    });

    testWidgets('the same title in MP3 and MP4 shows twice', (tester) async {
      await store.record(
        JobSucceeded(_planned(_a, 1), '/v/a.mp4'),
        MediaFormat.mp4,
        _monday.add(const Duration(hours: 1)),
      );
      await pumpHub(tester);

      expect(find.text('Tanalahy ny foko'), findsNWidgets(2));
    });

    testWidgets('a tap plays it, then the titles after it', (tester) async {
      await pumpHub(tester);

      await tester.tap(find.text('Somambisamby'));
      await tester.pump();

      expect(backend.opened, ['/m/b.mp3']);
      expect(titles(), ['Somambisamby', 'Tanalahy ny foko']);
    });

    testWidgets('« Tout lire » plays them all from the first', (tester) async {
      await pumpHub(tester);

      await tester.tap(find.text('Tout lire'));
      await tester.pump();

      expect(backend.opened, ['/m/b.mp3']);
      expect(player.tracks, hasLength(2));
    });

    testWidgets('« Lecture aléatoire » shuffles them', (tester) async {
      await pumpHub(tester);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Lecture aléatoire'),
      );
      await tester.pump();

      expect(player.shuffled, isTrue);
      expect(player.tracks, hasLength(2));
    });

    testWidgets('search finds titles by their words', (tester) async {
      await pumpHub(tester);

      await tester.enterText(find.byType(TextField), 'soma');
      await tester.pumpAndSettle();

      expect(find.text('Somambisamby'), findsOneWidget);
      expect(find.text('Tanalahy ny foko'), findsNothing);
    });

    testWidgets('« Lire ensuite » puts it after the one playing', (
      tester,
    ) async {
      await pumpHub(tester);
      await tester.tap(find.text('Somambisamby'));
      await tester.pump();
      await player.jumpTo(0);

      await openMenu(tester, 'Tanalahy ny foko');
      await tester.tap(find.text('Lire ensuite'));
      await tester.pumpAndSettle();

      expect(titles(), [
        'Somambisamby',
        'Tanalahy ny foko',
        'Tanalahy ny foko',
      ]);
    });

    testWidgets('« Ajouter à la file de lecture » plays it when idle', (
      tester,
    ) async {
      await pumpHub(tester);

      await openMenu(tester, 'Tanalahy ny foko');
      await tester.tap(find.text('Ajouter à la file de lecture'));
      await tester.pumpAndSettle();

      expect(backend.opened, ['/m/a.mp3']);
    });

    testWidgets('adds a title to a new playlist', (tester) async {
      await pumpHub(tester);

      await openMenu(tester, 'Somambisamby');
      await tester.tap(find.text('Ajouter à une liste…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nouvelle liste'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Soirée');
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      final [playlist] = await store.playlists();
      expect(playlist.name, 'Soirée');
      expect(
        [for (final t in await store.playlistTracks(playlist.id)) t.path],
        ['/m/b.mp3'],
      );
    });

    testWidgets('a new download shows without reopening', (tester) async {
      await pumpHub(tester);

      await store.record(
        JobSucceeded(_planned(_c, 3), '/m/c.mp3'),
        MediaFormat.mp3,
        _monday.add(const Duration(hours: 2)),
      );
      changes.value++;
      await tester.pumpAndSettle();

      expect(find.text('Veloma Mahaleo'), findsOneWidget);
    });

    testWidgets('says how to start when nothing is downloaded', (tester) async {
      store = Ka7Store.inMemory();
      await pumpHub(tester);

      expect(find.textContaining('Rien à écouter'), findsOneWidget);
    });
  });

  group('lists', () {
    testWidgets('shows the playlists, and opens one', (tester) async {
      final id = await store.createPlaylist('Soirée');
      await store.addToPlaylist(
        id,
        const PlaylistTrack(
          videoId: 'b',
          title: 'Somambisamby',
          format: MediaFormat.mp3,
          path: '/m/b.mp3',
        ),
      );
      await pumpHub(tester);

      await tester.tap(find.text('Listes · 1'));
      await tester.pumpAndSettle();
      expect(find.text('1 titre'), findsOneWidget);

      await tester.tap(find.text('Soirée'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Tout lire'), findsOneWidget);
    });

    testWidgets('makes a new playlist', (tester) async {
      await pumpHub(tester);
      await tester.tap(find.text('Listes · 0'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nouvelle liste'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Route');
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Listes · 1'), findsOneWidget);
    });
  });

  group('now playing', () {
    testWidgets('hidden while nothing plays', (tester) async {
      await pumpHub(tester);

      expect(find.text('En cours de lecture'), findsNothing);
    });

    testWidgets('shows the track, and opens the whole player', (tester) async {
      await pumpHub(tester);
      await tester.tap(find.text('Somambisamby'));
      await tester.pumpAndSettle();

      expect(find.text('En cours de lecture'), findsOneWidget);
      await tester.tap(find.text('En cours de lecture'));

      expect(opened, 1);
    });

    /// Plays Somambisamby, then Tanalahy ny foko: two tracks in the queue.
    Future<void> playTwo(WidgetTester tester) async {
      await tester.tap(find.text('Somambisamby'));
      await tester.pumpAndSettle();
    }

    testWidgets('next plays the next track, without opening the player', (
      tester,
    ) async {
      await pumpHub(tester);
      await playTwo(tester);

      await tester.tap(find.byTooltip('Suivant'));
      await tester.pumpAndSettle();

      expect(backend.opened.last, '/m/a.mp3');
      expect(opened, 0);
    });

    testWidgets('previous goes back, without opening the player', (
      tester,
    ) async {
      await pumpHub(tester);
      await playTwo(tester);
      await tester.tap(find.byTooltip('Suivant'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Précédent'));
      await tester.pumpAndSettle();

      expect(backend.opened.last, '/m/b.mp3');
      expect(opened, 0);
    });

    testWidgets('previous and next are easy to touch (48 px)', (tester) async {
      await pumpHub(tester);
      await playTwo(tester);

      for (final label in ['Précédent', 'Suivant']) {
        final size = tester.getSize(find.byTooltip(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('fits a narrow phone with its three buttons', (tester) async {
      await pumpHub(tester, size: const Size(360, 780));
      await playTwo(tester);

      // An overflow would fail the test on its own.
      expect(find.byTooltip('Précédent'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Suivant'), findsOneWidget);
      expect(find.text('Somambisamby'), findsWidgets);
    });
  });
}
