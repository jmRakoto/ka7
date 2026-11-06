import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_hub_screen.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../helpers/fake_media_backend.dart';
import '../../helpers/pump_app.dart';

const _mahaleo = (folder: '/home/me/Musique/Mahaleo', label: 'Musique/Mahaleo');

MediaFile _f(String name, {String dir = '/home/me/Musique/Mahaleo'}) =>
    MediaFile(path: '$dir/$name', name: name);

void main() {
  late Ka7Store store;
  late FakeMediaBackend backend;
  late PlayerController player;
  late Map<String, List<MediaFile>> disk;
  late List<String> listed;
  ({String folder, String label})? picked;

  setUp(() {
    store = Ka7Store.inMemory();
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
    disk = {
      _mahaleo.folder: [_f('1 Bonga.mp3'), _f('2 Veloma.flac'), _f('Clip.mp4')],
    };
    listed = [];
    picked = _mahaleo;
  });
  tearDown(() => store.close());

  Future<void> pumpLists(WidgetTester tester, {bool canPick = true}) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      PlayerHubScreen(
        store: store,
        player: player,
        changes: ValueNotifier(0),
        onOpenPlayer: () {},
        pickFolder: canPick ? () async => picked : null,
        listFolder: (folder) async {
          listed.add(folder);
          return disk[folder] ?? const [];
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Listes ·'));
    await tester.pumpAndSettle();
  }

  Future<void> openMahaleo(WidgetTester tester) async {
    await store.createFolderPlaylist(
      'Mahaleo',
      folder: _mahaleo.folder,
      label: _mahaleo.label,
    );
    await pumpLists(tester);
    await tester.tap(find.text('Mahaleo'));
    await tester.pumpAndSettle();
  }

  group('adding a folder', () {
    testWidgets('makes a list named after the folder', (tester) async {
      await pumpLists(tester);

      await tester.tap(find.text('Ajouter un dossier'));
      await tester.pumpAndSettle();

      final [playlist] = await store.playlists();
      expect(playlist.name, 'Mahaleo');
      expect(playlist.folder, _mahaleo.folder);
      expect(find.text('Mahaleo'), findsOneWidget);
      expect(find.text('Musique/Mahaleo'), findsOneWidget);
    });

    testWidgets('nothing when the picker is closed', (tester) async {
      picked = null;
      await pumpLists(tester);

      await tester.tap(find.text('Ajouter un dossier'));
      await tester.pumpAndSettle();

      expect(await store.playlists(), isEmpty);
    });

    testWidgets('no button where no folder can be picked', (tester) async {
      await pumpLists(tester, canPick: false);

      expect(find.text('Ajouter un dossier'), findsNothing);
    });
  });

  group('a folder list', () {
    testWidgets('shows the files read from the folder', (tester) async {
      await openMahaleo(tester);

      expect(listed, [_mahaleo.folder]);
      expect(find.text('1 Bonga'), findsOneWidget);
      expect(find.text('2 Veloma'), findsOneWidget);
      expect(find.text('Clip'), findsOneWidget);
    });

    testWidgets('« Tout lire » plays them, video included', (tester) async {
      await openMahaleo(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Tout lire'));
      await tester.pump();

      expect(backend.opened, ['${_mahaleo.folder}/1 Bonga.mp3']);
      expect(player.tracks, hasLength(3));
      expect(player.tracks.last.video, isTrue);
    });

    testWidgets('a tap plays from that file', (tester) async {
      await openMahaleo(tester);

      await tester.tap(find.text('2 Veloma'));
      await tester.pump();

      expect(backend.opened, ['${_mahaleo.folder}/2 Veloma.flac']);
    });

    testWidgets('follows the folder: no hand reordering or removing', (
      tester,
    ) async {
      await openMahaleo(tester);

      expect(find.byIcon(Icons.drag_handle), findsNothing);
      expect(find.byTooltip('Retirer de la liste'), findsNothing);
    });

    testWidgets('a file added on disk shows the next time', (tester) async {
      await openMahaleo(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      disk[_mahaleo.folder] = [
        ...disk[_mahaleo.folder]!,
        _f('3 Ry Lanitra.mp3'),
      ];

      await tester.tap(find.text('Mahaleo'));
      await tester.pumpAndSettle();

      expect(find.text('3 Ry Lanitra'), findsOneWidget);
    });

    testWidgets('says so when the folder is empty or gone', (tester) async {
      disk.clear();
      await openMahaleo(tester);

      expect(find.textContaining('Aucun fichier à lire'), findsOneWidget);
    });

    testWidgets('can be renamed and deleted, the files stay', (tester) async {
      await openMahaleo(tester);

      await tester.tap(find.byTooltip('Actions de la liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer la liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer la liste'));
      await tester.pumpAndSettle();

      expect(await store.playlists(), isEmpty);
    });
  });

  testWidgets('« Ajouter à une liste… » offers only the lists made by hand', (
    tester,
  ) async {
    await store.createFolderPlaylist(
      'Mahaleo',
      folder: _mahaleo.folder,
      label: _mahaleo.label,
    );
    await store.createPlaylist('Soirée');
    await store.record(
      const JobSucceeded(
        PlannedDownload(
          source: Probe(title: 'x', items: []),
          item: ProbeItem(videoId: 'a', title: 'Tanalahy'),
          index: 1,
        ),
        '/m/a.mp3',
      ),
      MediaFormat.mp3,
      DateTime(2026, 11, 2),
    );
    await pumpLists(tester);
    await tester.tap(find.textContaining('Titres ·'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter à une liste…'));
    await tester.pumpAndSettle();

    expect(find.text('Soirée'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('Mahaleo'),
      ),
      findsNothing,
    );
  });
}
