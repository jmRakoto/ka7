import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_hub_screen.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../helpers/fake_media_backend.dart';
import '../../helpers/pump_app.dart';

PlaylistTrack _t(String title) => PlaylistTrack(
  videoId: title,
  title: title,
  format: MediaFormat.mp3,
  path: '/m/$title.mp3',
);

void main() {
  late Ka7Store store;
  late FakeMediaBackend backend;
  late PlayerController player;

  setUp(() async {
    store = Ka7Store.inMemory();
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
    final a = await store.createPlaylist('playA');
    await store.setPlaylistTracks(a, [_t('a1'), _t('a2')]);
    final b = await store.createPlaylist('playB');
    await store.setPlaylistTracks(b, [_t('b1')]);
    await store.createFolderPlaylist('playC', folder: '/c', label: 'c');
  });
  tearDown(() => store.close());

  Future<void> pumpLists(WidgetTester tester) async {
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
        listFolder: (folder) async => const [
          MediaFile(path: '/c/c1.flac', name: 'c1.flac'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Listes ·'));
    await tester.pumpAndSettle();
  }

  List<String> names() => [for (final t in player.tracks) t.title];

  Future<void> drag(WidgetTester tester, String name, double dy) async {
    final handle = find.descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
      matching: find.byIcon(Icons.drag_handle),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(Offset(0, dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('« Tout lire » plays every list, one after the other', (
    tester,
  ) async {
    await pumpLists(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Tout lire'));
    await tester.pumpAndSettle();

    expect(names(), ['a1', 'a2', 'b1', 'c1']);
    expect(backend.opened, ['/m/a1.mp3']);
    expect(player.shuffled, isFalse);
  });

  testWidgets('a list dragged to the top plays first, and stays there', (
    tester,
  ) async {
    await pumpLists(tester);

    await drag(tester, 'playB', -200);

    expect(
      [for (final p in await store.playlists()) p.name],
      ['playB', 'playA', 'playC'],
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tout lire'));
    await tester.pumpAndSettle();
    expect(names(), ['b1', 'a1', 'a2', 'c1']);
  });

  testWidgets('« Lecture aléatoire » mixes every list', (tester) async {
    await pumpLists(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Lecture aléatoire'));
    await tester.pumpAndSettle();

    expect(player.shuffled, isTrue);
    expect(names().toSet(), {'a1', 'a2', 'b1', 'c1'});
  });

  testWidgets('a tap on a list still opens it', (tester) async {
    await pumpLists(tester);

    await tester.tap(find.text('playB'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Actions de la liste'), findsOneWidget);
  });
}
