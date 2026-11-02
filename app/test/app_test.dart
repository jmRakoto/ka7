import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/app.dart';
import 'package:ka7/features/add_links/add_links_screen.dart';
import 'package:ka7/features/queue/run_view.dart';
import 'package:ka7/platform/background_work.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

import 'helpers/controlled_downloader.dart';
import 'helpers/fake_engine_setup.dart';
import 'helpers/fake_extractor.dart';
import 'helpers/probes.dart';

final _extractor = FakeExtractor({
  'https://www.youtube.com/watch?v=Qm7tR2vLx9A': hafatraVideo,
  'https://www.youtube.com/playlist?list=PLe7rK2mErickManana01':
      ericMananaPlaylist,
});

void main() {
  late Ka7Store store;
  late ControlledDownloader downloader;
  late List<String> opened;
  late String? picked;

  setUp(() async {
    store = Ka7Store.inMemory();
    await store.setSetting('language', 'fr');
    downloader = ControlledDownloader();
    opened = [];
    picked = null;
  });
  tearDown(() => store.close());

  Future<void> pumpKa7(
    WidgetTester tester, {
    EngineSetup? setup,
    bool builtInEngine = false,
    bool canOpenFolders = true,
    bool canPickFolders = true,
    List<MediaFormat> formats = const [MediaFormat.mp3, MediaFormat.mp4],
    Stream<String>? shared,
    BackgroundWork? background,
    Size size = const Size(1280, 900),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Ka7App(
        engineSetup: builtInEngine ? null : setup ?? FakeEngineSetup.ready(),
        formats: formats,
        sharedLinks: shared,
        background: background,
        enginesFor: (status) => (extractor: _extractor, downloader: downloader),
        store: store,
        defaultFolders: const {
          MediaFormat.mp3: '/home/me/Musique',
          MediaFormat.mp4: '/home/me/Vidéos',
        },
        pickFolder: canPickFolders ? () async => picked : null,
        openFolder: canOpenFolders ? opened.add : null,
        now: () => DateTime(2026, 10, 30, 14, 5),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pastes [links], opens the preview, then starts the download.
  Future<void> download(WidgetTester tester, String links) async {
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), links);
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Télécharger'));
    await tester.pumpAndSettle();
  }

  group('navigation', () {
    testWidgets('opens on Add, with every section in the sidebar', (
      tester,
    ) async {
      await pumpKa7(tester);

      expect(find.byType(AddLinksScreen), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      for (final label in ['Ajouter', 'File', 'Bibliothèque', 'Réglages']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
    });

    testWidgets('moves the sections to a bottom bar on a narrow window', (
      tester,
    ) async {
      await pumpKa7(tester, size: const Size(400, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('says the queue is empty before any download', (tester) async {
      await pumpKa7(tester);

      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();

      expect(find.text('Aucun téléchargement en cours.'), findsOneWidget);
    });
  });

  group('download', () {
    testWidgets('goes from the preview to the queue, into the music folder', (
      tester,
    ) async {
      await pumpKa7(tester);

      await download(tester, 'Qm7tR2vLx9A');

      expect(find.byType(RunView), findsOneWidget);
      expect(
        downloader.requests.single.destination,
        '/home/me/Musique/Hafatra.mp3',
      );
    });

    testWidgets('adds links to the queue that is running', (tester) async {
      await pumpKa7(tester);

      await download(tester, 'Qm7tR2vLx9A');
      await download(tester, 'PLe7rK2mErickManana01');

      expect(find.byType(RunView), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
    });

    testWidgets('skips what the archive already holds', (tester) async {
      await store.add('Qm7tR2vLx9A', MediaFormat.mp3);
      await pumpKa7(tester);

      await download(tester, 'Qm7tR2vLx9A');

      expect(downloader.requests, isEmpty);
      expect(find.text('1 déjà là'), findsOneWidget);
    });

    testWidgets('retries the failed videos', (tester) async {
      await pumpKa7(tester);
      await download(tester, 'Qm7tR2vLx9A');

      downloader.fail('Qm7tR2vLx9A', FailureReason.network);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(downloader.requests, hasLength(2));
    });
  });

  group('library', () {
    Future<void> downloadHafatra(WidgetTester tester) async {
      await download(tester, 'Qm7tR2vLx9A');
      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bibliothèque'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists what was downloaded, with format and date', (
      tester,
    ) async {
      await pumpKa7(tester);

      await downloadHafatra(tester);

      expect(find.text('Hafatra'), findsOneWidget);
      expect(find.text('MP3 · 30 oct. 2026'), findsOneWidget);
      expect(find.text('Réussi'), findsOneWidget);
    });

    testWidgets('finds an entry by its title', (tester) async {
      await pumpKa7(tester);
      await downloadHafatra(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Aucun résultat.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hafa');
      await tester.pumpAndSettle();
      expect(find.text('Hafatra'), findsOneWidget);
    });

    testWidgets('opens the folder of a file', (tester) async {
      await pumpKa7(tester);
      await downloadHafatra(tester);

      await tester.tap(find.byTooltip('Ouvrir le dossier'));

      expect(opened, ['/home/me/Musique']);
    });

    testWidgets('forgets an entry, so it can be downloaded again', (
      tester,
    ) async {
      await pumpKa7(tester);
      await downloadHafatra(tester);

      await tester.tap(find.byTooltip('Oublier'));
      await tester.pumpAndSettle();

      expect(find.text("Rien n'a encore été téléchargé."), findsOneWidget);
      expect(await store.contains('Qm7tR2vLx9A', MediaFormat.mp3), isFalse);
    });
  });

  group('settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
    }

    testWidgets('switches the language at once and remembers it', (
      tester,
    ) async {
      await pumpKa7(tester);
      await openSettings(tester);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(await store.setting('language'), 'en');
    });

    testWidgets('follows the system language when asked to', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('de')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await store.setSetting('language', null);

      await pumpKa7(tester);

      expect(find.text('Réglages'), findsWidgets, reason: 'French fallback');
    });

    testWidgets('changes the music folder for the next downloads', (
      tester,
    ) async {
      await pumpKa7(tester);
      await openSettings(tester);
      picked = '/data/Mozika';

      await tester.tap(find.byTooltip('Changer le dossier de la musique'));
      await tester.pumpAndSettle();
      await download(tester, 'Qm7tR2vLx9A');

      expect(
        downloader.requests.single.destination,
        '/data/Mozika/Hafatra.mp3',
      );
      expect(await store.setting('folder.mp3'), '/data/Mozika');
    });

    testWidgets('keeps the folder when the picker is closed', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);

      await tester.tap(find.byTooltip('Changer le dossier de la musique'));
      await tester.pumpAndSettle();

      expect(find.text('/home/me/Musique'), findsOneWidget);
    });
  });

  group('share', () {
    testWidgets('opens Add with the shared link, ready to preview', (
      tester,
    ) async {
      final shared = StreamController<String>();
      addTearDown(shared.close);
      await pumpKa7(tester, shared: shared.stream);
      await tester.tap(find.text('Bibliothèque'));
      await tester.pumpAndSettle();

      shared.add('Me at the zoo https://youtu.be/Qm7tR2vLx9A?si=abc');
      await tester.pumpAndSettle();

      expect(find.byType(AddLinksScreen), findsOneWidget);
      expect(find.text('1 entrée reconnue'), findsOneWidget);
      await tester.tap(find.text("Voir l'aperçu"));
      await tester.pumpAndSettle();
      expect(find.text('Hafatra'), findsWidgets);
    });

    testWidgets('adds a second shared link below the first', (tester) async {
      final shared = StreamController<String>();
      addTearDown(shared.close);
      await pumpKa7(tester, shared: shared.stream);

      shared
        ..add('https://youtu.be/Qm7tR2vLx9A')
        ..add('PLe7rK2mErickManana01');
      await tester.pumpAndSettle();

      expect(find.text('2 entrées reconnues'), findsOneWidget);
    });
  });

  group('screen off', () {
    testWidgets('keeps the app alive while downloads run, then lets go', (
      tester,
    ) async {
      final background = _FakeBackground();
      await pumpKa7(tester, background: background);

      await download(tester, 'PLe7rK2mErickManana01');
      expect(background.log.last, 'keep Téléchargement · 0/2');

      downloader.finish('aB3dE5fG7hI');
      await tester.pumpAndSettle();
      expect(background.log.last, 'keep Téléchargement · 1/2');

      downloader.finish('jK9lM1nO3pQ');
      await tester.pumpAndSettle();
      expect(background.log.last, 'release');
    });
  });

  group('mobile', () {
    testWidgets('opens at once when the engine is built in', (tester) async {
      await pumpKa7(tester, builtInEngine: true, size: const Size(400, 800));

      expect(find.byType(AddLinksScreen), findsOneWidget);
    });

    testWidgets('downloads in the formats the engine can make', (tester) async {
      await pumpKa7(
        tester,
        builtInEngine: true,
        formats: const [MediaFormat.m4a, MediaFormat.mp4],
      );

      await download(tester, 'Qm7tR2vLx9A');

      expect(
        downloader.requests.single.destination,
        '/home/me/Musique/Hafatra.m4a',
      );
    });

    testWidgets('hides the folder settings where the system files music', (
      tester,
    ) async {
      await pumpKa7(tester, canPickFolders: false);

      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();

      expect(find.text('Langue'), findsOneWidget);
      expect(find.text('Dossier de la musique (MP3)'), findsNothing);
    });

    testWidgets('offers no folder to open where the system cannot', (
      tester,
    ) async {
      await pumpKa7(tester, canOpenFolders: false);
      await download(tester, 'Qm7tR2vLx9A');
      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bibliothèque'));
      await tester.pumpAndSettle();

      expect(find.text('Hafatra'), findsOneWidget);
      expect(find.byTooltip('Ouvrir le dossier'), findsNothing);
    });
  });

  testWidgets('asks to install missing tools before anything else', (
    tester,
  ) async {
    await pumpKa7(tester, setup: FakeEngineSetup(missing: {EngineTool.ffmpeg}));

    expect(find.text('Il manque ffmpeg'), findsOneWidget);
    expect(find.byType(AddLinksScreen), findsNothing);
  });
}

final class _FakeBackground implements BackgroundWork {
  final log = <String>[];

  @override
  void keep({required String title, required int done, required int total}) =>
      log.add('keep $title · $done/$total');

  @override
  void release() => log.add('release');
}
