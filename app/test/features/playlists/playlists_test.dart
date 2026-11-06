import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_hub_screen.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../helpers/fake_media_backend.dart';
import '../../helpers/pump_app.dart';

const _a = PlaylistTrack(
  videoId: 'a',
  title: 'Tanalahy ny foko',
  format: MediaFormat.mp3,
  path: '/m/a.mp3',
);
const _b = PlaylistTrack(
  videoId: 'b',
  title: 'Somambisamby',
  format: MediaFormat.mp3,
  path: '/m/b.mp3',
);
const _c = PlaylistTrack(
  videoId: 'c',
  title: 'Veloma Mahaleo',
  format: MediaFormat.mp3,
  path: '/m/c.mp3',
);

void main() {
  late Ka7Store store;
  late FakeMediaBackend backend;
  late PlayerController player;

  setUp(() {
    store = Ka7Store.inMemory();
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
  });
  tearDown(() => store.close());

  /// The player section, on its playlists.
  Future<void> pumpPlaylists(
    WidgetTester tester, {
    PlayerController? other,
  }) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      PlayerHubScreen(
        store: store,
        player: other ?? player,
        changes: ValueNotifier(0),
        onOpenPlayer: () {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Listes ·'));
    await tester.pumpAndSettle();
  }

  Future<int> party() async {
    final id = await store.createPlaylist('Soirée');
    await store.setPlaylistTracks(id, [_a, _b, _c]);
    return id;
  }

  Future<void> openParty(WidgetTester tester) async {
    await pumpPlaylists(tester);
    await tester.tap(find.text('Soirée'));
    await tester.pumpAndSettle();
  }

  group('list of playlists', () {
    testWidgets('says how to start when there is none', (tester) async {
      await pumpPlaylists(tester);

      expect(find.textContaining('Aucune liste'), findsOneWidget);
    });

    testWidgets('makes a new playlist', (tester) async {
      await pumpPlaylists(tester);

      await tester.tap(find.text('Nouvelle liste'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Route');
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      expect((await store.playlists()).single.name, 'Route');
      await tester.pumpAndSettle();
      expect(find.text('Route'), findsOneWidget);
    });

    testWidgets('shows each playlist with its count', (tester) async {
      await party();
      await pumpPlaylists(tester);

      expect(find.text('Soirée'), findsOneWidget);
      expect(find.text('3 titres'), findsOneWidget);
    });
  });

  group('one playlist', () {
    testWidgets('lists its tracks in order', (tester) async {
      await party();
      await openParty(tester);

      final y = [
        for (final title in [
          'Tanalahy ny foko',
          'Somambisamby',
          'Veloma Mahaleo',
        ])
          tester.getTopLeft(find.text(title)).dy,
      ];
      expect(y, orderedEquals([...y]..sort()));
    });

    testWidgets('« Tout lire » plays it from the start, offline files', (
      tester,
    ) async {
      await party();
      await openParty(tester);

      await tester.tap(find.text('Tout lire'));
      await tester.pump();

      expect(backend.opened, ['/m/a.mp3']);
      expect(player.tracks, hasLength(3));
      expect(player.shuffled, isFalse);
    });

    testWidgets('shuffle plays it in random order', (tester) async {
      await party();
      await openParty(tester);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Lecture aléatoire'),
      );
      await tester.pump();

      expect(player.shuffled, isTrue);
      expect(player.tracks, hasLength(3));
    });

    testWidgets('a tap on a track plays from it', (tester) async {
      await party();
      await openParty(tester);

      await tester.tap(find.text('Somambisamby'));
      await tester.pump();

      expect(backend.opened, ['/m/b.mp3']);
      expect(player.index, 1);
    });

    testWidgets('removes a track', (tester) async {
      final id = await party();
      await openParty(tester);

      await tester.tap(find.byTooltip('Retirer de la liste').at(1));
      await tester.pumpAndSettle();

      expect(await store.playlistTracks(id), [_a, _c]);
      await tester.pumpAndSettle();
      expect(find.text('Somambisamby'), findsNothing);
    });

    testWidgets('moves a track by dragging its handle', (tester) async {
      final id = await party();
      await openParty(tester);

      final handle = find.byIcon(Icons.drag_handle).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect((await store.playlistTracks(id)).first, isNot(_a));
    });

    testWidgets('renames it', (tester) async {
      await party();
      await openParty(tester);

      await tester.tap(find.byTooltip('Actions de la liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renommer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fête');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect((await store.playlists()).single.name, 'Fête');
      await tester.pumpAndSettle();
      expect(find.text('Fête'), findsOneWidget);
    });

    testWidgets('deletes it, after asking', (tester) async {
      await party();
      await openParty(tester);

      await tester.tap(find.byTooltip('Actions de la liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer la liste'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer « Soirée » ?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer la liste'));
      await tester.pumpAndSettle();

      expect(await store.playlists(), isEmpty);
      await tester.pumpAndSettle();
      expect(find.textContaining('Aucune liste'), findsOneWidget);
    });

    testWidgets('marks a file found missing', (tester) async {
      await party();
      final missing = PlayerController(
        backend: backend,
        fileExists: (track) async => track.path != '/m/a.mp3',
      );
      await missing.playAll([]);
      await pumpPlaylists(tester, other: missing);
      await tester.tap(find.text('Soirée'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tout lire'));
      await tester.pumpAndSettle();

      expect(find.text('Introuvable'), findsOneWidget);
    });

    testWidgets('an empty playlist says how to fill it', (tester) async {
      await store.createPlaylist('Soirée');
      await openParty(tester);

      expect(find.textContaining('Liste vide'), findsOneWidget);
    });
  });
}
