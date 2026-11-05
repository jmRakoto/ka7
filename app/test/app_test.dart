import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/app.dart';
import 'package:ka7/features/add_links/add_links_screen.dart';
import 'package:ka7/features/queue/finished_run.dart';
import 'package:ka7/features/queue/run_view.dart';
import 'package:ka7/platform/background_work.dart';
import 'package:ka7/platform/run_notifier.dart';
import 'package:ka7/settings/app_settings.dart';
import 'package:ka7/features/preview/preview_screen.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

import 'helpers/controlled_downloader.dart';
import 'helpers/fake_engine_setup.dart';
import 'helpers/fake_extractor.dart';
import 'helpers/probes.dart';

const _sungByErick = Probe(
  title: 'Tsara',
  items: [
    ProbeItem(
      videoId: 'Xy7zA9bC1dE',
      title: 'Tsara',
      channel: 'Erick Manana',
      duration: Duration(minutes: 3),
    ),
  ],
);

const _erickSearch = SearchEntry('Erick', query: 'Erick');

final _extractor = FakeExtractor({
  _erickSearch.url: Probe(
    title: 'Erick',
    isSearch: true,
    items: [..._sungByErick.items, ...hafatraVideo.items],
  ),
  'https://www.youtube.com/watch?v=Xy7zA9bC1dE': _sungByErick,
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
    await store.setSetting('onboarding.done', '1');
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
    bool acceptDrops = false,
    RunNotifier? notifier,
    void Function(AppSettings settings)? onEngines,
    String Function(MediaFormat format)? shownFolder,
    VoidCallback? askNotifications,
    String? appVersion,
    Future<AppRelease?> Function()? latestRelease,
    void Function(String url)? openUrl,
    FileExists? fileExists,
    Future<Destination?> Function()? pickDestination,
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
        acceptDrops: acceptDrops,
        notifier: notifier,
        shownFolder: shownFolder,
        askNotifications: askNotifications,
        appVersion: appVersion,
        latestRelease: latestRelease,
        openUrl: openUrl,
        fileExists: fileExists,
        pickDestination: pickDestination,
        enginesFor: (status, settings) {
          onEngines?.call(settings);
          return (extractor: _extractor, downloader: downloader);
        },
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
    await tester.tap(_nav('Ajouter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), links);
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Télécharger'));
    await tester.pumpAndSettle();
  }

  group('search', () {
    Future<void> searchAndDownload(WidgetTester tester) async {
      await tester.tap(_nav('Ajouter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recherche YouTube'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Erick');
      await tester.pump();
      await tester.tap(find.text('Rechercher'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tsara'));
      await tester.pump();
      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();
    }

    testWidgets('Add shows the last results again after a download', (
      tester,
    ) async {
      await pumpKa7(tester);
      await searchAndDownload(tester);
      expect(find.text('Tsara'), findsWidgets, reason: 'in the queue');

      await tester.tap(_nav('Ajouter'));
      await tester.pumpAndSettle();

      expect(find.text('Recherche : Erick'), findsOneWidget);
      final sent = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Tsara'),
      );
      expect(sent.value, isFalse);
      expect(find.text('Dans la file'), findsOneWidget);
    });

    testWidgets('the results tell when a video sent failed', (tester) async {
      await pumpKa7(tester);
      await searchAndDownload(tester);
      downloader.fail('Xy7zA9bC1dE', FailureReason.network);
      await tester.pumpAndSettle();

      await tester.tap(_nav('Ajouter'));
      await tester.pumpAndSettle();

      expect(find.text('Dans la file'), findsNothing);
      expect(find.text('Échoué'), findsOneWidget);
    });

    testWidgets('remembers the searches, newest first, across launches', (
      tester,
    ) async {
      await pumpKa7(tester);
      await searchAndDownload(tester);
      await tester.tap(_nav('Ajouter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Erick'), findsOneWidget, reason: 'a chip');
      expect(await store.setting('search.recent'), 'Erick');

      await tester.tap(find.byTooltip('Effacer les recherches récentes'));
      await tester.pumpAndSettle();
      expect(find.text('Recherches récentes'), findsNothing);
      expect(await store.setting('search.recent'), isNull);
    });

    testWidgets('leaving the results gives an empty search field', (
      tester,
    ) async {
      await pumpKa7(tester);
      await searchAndDownload(tester);
      await tester.tap(_nav('Ajouter'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Rechercher'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });
  });

  group('welcome', () {
    testWidgets('presents Ka7 on first launch, then opens on Add', (
      tester,
    ) async {
      await store.setSetting('onboarding.done', null);
      await pumpKa7(tester);

      for (final title in [
        'Avant de commencer',
        'Bienvenue dans Ka7',
        'Ajoute de toutes les façons',
        'Vérifie avant de télécharger',
      ]) {
        expect(find.text(title), findsOneWidget);
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Rien ne se perd'), findsOneWidget);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      expect(find.byType(AddLinksScreen), findsOneWidget);
      expect(await store.setting('onboarding.done'), '1');
    });

    testWidgets('tells how links come in, on this kind of device', (
      tester,
    ) async {
      await store.setSetting('onboarding.done', null);
      await pumpKa7(tester, acceptDrops: true);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(
        find.text('Cherche sur YouTube et coche les résultats'),
        findsOneWidget,
      );
      expect(
        find.text('Glisse un lien ou un fichier sur la fenêtre'),
        findsOneWidget,
      );
      expect(find.text("Partage depuis l'app YouTube vers Ka7"), findsNothing);
    });

    testWidgets('says a notification tells when downloads end', (tester) async {
      await store.setSetting('onboarding.done', null);
      await pumpKa7(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(
        find.text('Une notification te prévient quand tout est fini'),
        findsOneWidget,
      );
    });

    testWidgets('asks for notifications as soon as the pages are done', (
      tester,
    ) async {
      var asked = 0;
      await store.setSetting('onboarding.done', null);
      await pumpKa7(tester, askNotifications: () => asked++);
      expect(asked, 0);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(asked, 1);
    });

    testWidgets('does not ask again on later launches', (tester) async {
      var asked = 0;
      await pumpKa7(tester, askNotifications: () => asked++);

      expect(asked, 0);
    });

    testWidgets('goes back a page with Previous', (tester) async {
      await store.setSetting('onboarding.done', null);
      await pumpKa7(tester);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Précédent'));
      await tester.pumpAndSettle();

      expect(find.text('Avant de commencer'), findsOneWidget);
    });

    testWidgets('starts with the language and the theme, applied at once', (
      tester,
    ) async {
      await store.setSetting('onboarding.done', null);
      await pumpKa7(tester);
      ThemeMode mode() =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Before we start'), findsOneWidget);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(mode(), ThemeMode.dark);
      expect(await store.setting('language'), 'en');
      expect(await store.setting('theme'), 'dark');
    });

    testWidgets('can be skipped at once', (tester) async {
      await store.setSetting('onboarding.done', null);
      await pumpKa7(tester);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.byType(AddLinksScreen), findsOneWidget);
      expect(await store.setting('onboarding.done'), '1');
    });

    testWidgets('is not shown again', (tester) async {
      await pumpKa7(tester);

      expect(find.text('Bienvenue dans Ka7'), findsNothing);
      expect(find.byType(AddLinksScreen), findsOneWidget);
    });

    testWidgets('comes before installing the missing tools', (tester) async {
      await store.setSetting('onboarding.done', null);
      await pumpKa7(
        tester,
        setup: FakeEngineSetup(missing: {EngineTool.ffmpeg}),
      );

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.text('Il manque ffmpeg'), findsOneWidget);
    });
  });

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

    testWidgets('skips what the archive holds, even checked again', (
      tester,
    ) async {
      await store.add('Qm7tR2vLx9A', MediaFormat.mp3);
      await pumpKa7(tester);
      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');
      await tester.pump();
      await tester.tap(find.text("Voir l'aperçu"));
      await tester.pumpAndSettle();

      expect(find.text('Déjà là'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();

      expect(downloader.requests, isEmpty);
      expect(find.text('1 déjà là'), findsOneWidget);
    });

    testWidgets('cancels one running video, the other goes on', (tester) async {
      await pumpKa7(tester);
      await download(tester, 'PLe7rK2mErickManana01');

      await tester.tap(find.byTooltip('Annuler ce titre').first);
      await tester.pumpAndSettle();
      expect(downloader.stopped, ['aB3dE5fG7hI']);
      downloader.finish('jK9lM1nO3pQ');
      await tester.pumpAndSettle();

      expect(find.text('1 réussi'), findsOneWidget);
      expect(find.text('1 annulé'), findsOneWidget);
    });

    testWidgets('drops one waiting video before it starts', (tester) async {
      await store.setSetting('downloads.concurrency', '1');
      await pumpKa7(tester);
      await download(tester, 'PLe7rK2mErickManana01');

      await tester.tap(find.byTooltip('Annuler ce titre').last);
      await tester.pumpAndSettle();
      downloader.finish('aB3dE5fG7hI');
      await tester.pumpAndSettle();

      expect(downloader.requests.map((r) => r.videoId), ['aB3dE5fG7hI']);
      expect(find.text('1 annulé'), findsOneWidget);
    });

    testWidgets('retries the failed videos', (tester) async {
      await pumpKa7(tester);
      await download(tester, 'Qm7tR2vLx9A');

      downloader.fail('Qm7tR2vLx9A', FailureReason.network);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tout réessayer'));
      await tester.pumpAndSettle();

      expect(downloader.requests, hasLength(2));
    });
  });

  group('deleted files', () {
    Future<void> previewHafatraAgain(WidgetTester tester) async {
      await download(tester, 'Qm7tR2vLx9A');
      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();
      await tester.tap(_nav('Ajouter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');
      await tester.pump();
      await tester.tap(find.text("Voir l'aperçu"));
      await tester.pumpAndSettle();
    }

    testWidgets('a video whose file is there is already there', (tester) async {
      await pumpKa7(tester, fileExists: (_, _) async => true);
      await previewHafatraAgain(tester);

      expect(find.text('Réussi'), findsOneWidget, reason: 'this session');
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    });

    testWidgets('a video whose file was deleted is offered again', (
      tester,
    ) async {
      await pumpKa7(tester, fileExists: (_, _) async => false);
      await previewHafatraAgain(tester);

      expect(find.text('Déjà là'), findsNothing);
      expect(find.text('Réussi'), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });
  });

  group('earlier runs', () {
    testWidgets('retry one video, then it is not offered again', (
      tester,
    ) async {
      await pumpKa7(tester);
      await download(tester, 'PLe7rK2mErickManana01');
      downloader
        ..fail('aB3dE5fG7hI', FailureReason.network)
        ..fail('jK9lM1nO3pQ', FailureReason.network);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Réessayer ce titre').first);
      await tester.pumpAndSettle();

      expect(downloader.requests, hasLength(3));
      expect(find.byTooltip('Réessayer ce titre'), findsOneWidget);
      expect(find.text('1 échoué'), findsOneWidget, reason: 'one left');
    });

    testWidgets('a run whose videos all went again leaves the list', (
      tester,
    ) async {
      await pumpKa7(tester);
      await download(tester, 'Qm7tR2vLx9A');
      downloader.fail('Qm7tR2vLx9A', FailureReason.network);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Réessayer ce titre'));
      await tester.pumpAndSettle();

      expect(find.text('Plus tôt'), findsNothing);
      expect(find.text('0 / 1'), findsOneWidget);
    });

    testWidgets('fold under Earlier once done, the running one above', (
      tester,
    ) async {
      await pumpKa7(tester);
      await download(tester, 'Qm7tR2vLx9A');
      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();
      await download(tester, 'PLe7rK2mErickManana01');

      expect(find.text('Plus tôt'), findsOneWidget);
      expect(find.text('1 réussi'), findsOneWidget);
      expect(
        find.text('MP3 · audio · /home/me/Musique · 14:05'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('0 / 2')).dy,
        lessThan(tester.getTopLeft(find.text('Plus tôt')).dy),
      );
    });

    testWidgets('one is removed by sliding it away, and can come back', (
      tester,
    ) async {
      await pumpKa7(tester);
      await download(tester, 'Qm7tR2vLx9A');
      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();
      await download(tester, 'Xy7zA9bC1dE');
      downloader.finish('Xy7zA9bC1dE');
      await tester.pumpAndSettle();
      expect(find.byType(FinishedRun), findsNWidgets(2));

      await tester.fling(
        find.byType(FinishedRun).first,
        const Offset(-600, 0),
        1500,
      );
      await tester.pumpAndSettle();

      expect(find.byType(FinishedRun), findsOneWidget);
      expect(find.text('File retirée'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(FinishedRun), findsNWidgets(2));
    });

    testWidgets('fade away when cleared, instead of vanishing', (tester) async {
      await pumpKa7(tester);
      await download(tester, 'Qm7tR2vLx9A');
      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Retirer les files terminées'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final opacities = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.text('1 réussi'),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((fade) => fade.opacity.value);
      expect(opacities, contains(inExclusiveRange(0, 1)));
      await tester.pumpAndSettle();
      expect(find.text('1 réussi'), findsNothing);
    });

    testWidgets('are cleared, the running one stays', (tester) async {
      await pumpKa7(tester);
      await download(tester, 'Qm7tR2vLx9A');
      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();
      await download(tester, 'PLe7rK2mErickManana01');

      await tester.tap(find.byTooltip('Retirer les files terminées'));
      await tester.pumpAndSettle();

      expect(find.text('Plus tôt'), findsNothing);
      expect(find.text('1 réussi'), findsNothing);
      expect(find.text('0 / 2'), findsOneWidget);
    });
  });

  group('library', () {
    /// Hafatra, Tsara and Tsy Ferana, already downloaded, in the library.
    Future<void> openLibraryOfThreeForSwipes(WidgetTester tester) async {
      for (final (i, (source, item)) in [
        (hafatraVideo, hafatraVideo.items.single),
        (_sungByErick, _sungByErick.items.single),
        (ericMananaPlaylist, ericMananaPlaylist.items[1]),
      ].indexed) {
        await store.add(item.videoId, MediaFormat.mp3);
        await store.record(
          JobSucceeded(
            PlannedDownload(source: source, item: item, index: 1),
            '/home/me/Musique/${item.title}.mp3',
          ),
          MediaFormat.mp3,
          DateTime(2026, 10, 30, 9 + i),
        );
      }
      await pumpKa7(tester);
      await tester.tap(_nav('Bibliothèque'));
      await tester.pumpAndSettle();
    }

    /// Opens the ⋮ menu of the row titled [title].
    Future<void> openActions(WidgetTester tester, String title) async {
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, title),
          matching: find.byTooltip('Actions'),
        ),
      );
      await tester.pumpAndSettle();
    }

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
      expect(find.text("Aujourd'hui"), findsOneWidget);
      expect(find.text('MP3'), findsOneWidget);
      expect(find.text('Réussi'), findsOneWidget);
    });

    testWidgets('groups what was downloaded by day', (tester) async {
      for (final (i, at) in [
        DateTime(2026, 10, 30, 9),
        DateTime(2026, 10, 29, 20),
        DateTime(2026, 10, 1, 8),
      ].indexed) {
        await store.record(
          JobSucceeded(
            PlannedDownload(
              source: ericMananaPlaylist,
              item: ericMananaPlaylist.items[i],
              index: i + 1,
            ),
            '/home/me/Musique/$i.mp3',
          ),
          MediaFormat.mp3,
          at,
        );
      }
      await pumpKa7(tester);
      await tester.tap(_nav('Bibliothèque'));
      await tester.pumpAndSettle();

      final today = tester.getTopLeft(find.text("Aujourd'hui")).dy;
      final yesterday = tester.getTopLeft(find.text('Hier')).dy;
      final october = tester.getTopLeft(find.text('jeudi 1 octobre')).dy;
      expect(today, lessThan(yesterday));
      expect(yesterday, lessThan(october));
    });

    testWidgets('shows only the failed ones, counted', (tester) async {
      PlannedDownload song(int i) => PlannedDownload(
        source: ericMananaPlaylist,
        item: ericMananaPlaylist.items[i],
        index: i + 1,
      );
      await store.record(
        JobSucceeded(song(0), '/home/me/Musique/a.mp3'),
        MediaFormat.mp3,
        DateTime(2026, 10, 30, 9),
      );
      await store.record(
        JobFailed(song(1), FailureReason.private),
        MediaFormat.mp3,
        DateTime(2026, 10, 30, 10),
      );
      await pumpKa7(tester);
      await tester.tap(_nav('Bibliothèque'));
      await tester.pumpAndSettle();
      expect(find.text('Tout · 2'), findsOneWidget);
      expect(find.text('Réussis · 1'), findsOneWidget);

      await tester.tap(find.text('Échoués · 1'));
      await tester.pumpAndSettle();

      expect(find.text('Tsy Ferana'), findsOneWidget);
      expect(find.text("Tsara Ny Hiran' Ny Taniko"), findsNothing);
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

      await openActions(tester, 'Hafatra');
      await tester.tap(find.text('Ouvrir le dossier'));

      expect(opened, ['/home/me/Musique']);
    });

    testWidgets('forgets an entry, so it can be downloaded again', (
      tester,
    ) async {
      await pumpKa7(tester);
      await downloadHafatra(tester);

      await openActions(tester, 'Hafatra');
      await tester.tap(find.text('Oublier'));
      await tester.pumpAndSettle();
      expect(find.text('Hafatra'), findsNothing, reason: 'gone at once');
      expect(find.text('Annuler'), findsOneWidget);
      // Done once the message is gone without « Annuler ».
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text("Rien n'a encore été téléchargé."), findsOneWidget);
      expect(await store.contains('Qm7tR2vLx9A', MediaFormat.mp3), isFalse);

      await downloadHafatra(tester);
      expect(find.text('Hafatra'), findsOneWidget, reason: 'downloaded again');
    });

    testWidgets('forgets an entry slid away, unless called back', (
      tester,
    ) async {
      await pumpKa7(tester);
      await downloadHafatra(tester);

      await tester.fling(find.text('Hafatra'), const Offset(-600, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Hafatra'), findsNothing);
      expect(find.text('« Hafatra » oublié'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Hafatra'), findsOneWidget);
      expect(await store.contains('Qm7tR2vLx9A', MediaFormat.mp3), isTrue);
    });

    testWidgets('several slid away quickly come back together', (tester) async {
      await openLibraryOfThreeForSwipes(tester);

      await tester.fling(find.text('Hafatra'), const Offset(-600, 0), 1500);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.fling(find.text('Tsara'), const Offset(-600, 0), 1500);
      await tester.pumpAndSettle();

      expect(find.text('Hafatra'), findsNothing);
      expect(find.text('Tsara'), findsNothing);
      expect(find.text('2 titres oubliés'), findsOneWidget);
      expect(
        await store.contains('Qm7tR2vLx9A', MediaFormat.mp3),
        isTrue,
        reason: 'nothing forgotten while it can be called back',
      );

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Hafatra'), findsOneWidget);
      expect(find.text('Tsara'), findsOneWidget);
    });

    testWidgets('several slid away are forgotten once the message goes', (
      tester,
    ) async {
      await openLibraryOfThreeForSwipes(tester);

      await tester.fling(find.text('Hafatra'), const Offset(-600, 0), 1500);
      await tester.pumpAndSettle();
      await tester.fling(find.text('Tsara'), const Offset(-600, 0), 1500);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(await store.contains('Qm7tR2vLx9A', MediaFormat.mp3), isFalse);
      expect(await store.contains('Xy7zA9bC1dE', MediaFormat.mp3), isFalse);
      expect(find.text('Tsy Ferana'), findsOneWidget);
    });

    testWidgets('on desktop, forgets with a button instead of a slide', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pumpKa7(tester);
      await downloadHafatra(tester);

      expect(find.byType(Dismissible), findsNothing);
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getCenter(find.text('Hafatra')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Oublier'));
      await tester.pumpAndSettle();
      expect(find.text('Hafatra'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(await store.contains('Qm7tR2vLx9A', MediaFormat.mp3), isFalse);
      await pointer.removePointer();
      debugDefaultTargetPlatformOverride = null;
    });

    group('selection', () {
      /// Hafatra, Tsara and Tsy Ferana, already downloaded.
      Future<void> openLibraryOfThree(WidgetTester tester) async {
        for (final (source, item) in [
          (hafatraVideo, hafatraVideo.items.single),
          (_sungByErick, _sungByErick.items.single),
          (ericMananaPlaylist, ericMananaPlaylist.items[1]),
        ]) {
          final planned = PlannedDownload(source: source, item: item, index: 1);
          await store.add(item.videoId, MediaFormat.mp3);
          await store.record(
            JobSucceeded(planned, '/home/me/Musique/${item.title}.mp3'),
            MediaFormat.mp3,
            DateTime(2026, 10, 30),
          );
        }
        await pumpKa7(tester);
        await tester.tap(_nav('Bibliothèque'));
        await tester.pumpAndSettle();
      }

      Finder boxOf(String title) => find.descendant(
        of: find.widgetWithText(ListTile, title),
        matching: find.byType(Checkbox),
      );

      testWidgets('removes the chosen entries together, once confirmed', (
        tester,
      ) async {
        await openLibraryOfThree(tester);

        await tester.tap(find.text('Sélectionner'));
        await tester.pumpAndSettle();
        await tester.tap(boxOf('Hafatra'));
        await tester.tap(boxOf('Tsara'));
        await tester.pump();
        expect(find.text('2 sélectionnés'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Retirer'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Les fichiers restent'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Retirer').last);
        await tester.pumpAndSettle();

        expect(find.text('Hafatra'), findsNothing);
        expect(find.text('Tsara'), findsNothing);
        expect(find.text('Tsy Ferana'), findsOneWidget);
        expect(await store.contains('Qm7tR2vLx9A', MediaFormat.mp3), isFalse);
        expect(find.text('Sélectionner'), findsOneWidget, reason: 'done');
      });

      testWidgets('keeps everything when the removal is called off', (
        tester,
      ) async {
        await openLibraryOfThree(tester);
        await tester.tap(find.text('Sélectionner'));
        await tester.pumpAndSettle();
        await tester.tap(boxOf('Hafatra'));
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, 'Retirer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();

        expect(find.text('Hafatra'), findsOneWidget);
      });

      testWidgets('one box picks all, or none', (tester) async {
        await openLibraryOfThree(tester);
        await tester.tap(find.text('Sélectionner'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tout sélectionner'));
        await tester.pump();
        expect(find.text('3 sélectionnés'), findsOneWidget);
        await tester.tap(find.text('Tout sélectionner'));
        await tester.pump();
        expect(find.text('0 sélectionné'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Retirer'),
              )
              .onPressed,
          isNull,
        );
      });

      testWidgets('a long press starts picking with that entry', (
        tester,
      ) async {
        await openLibraryOfThree(tester);

        await tester.longPress(find.text('Tsara'));
        await tester.pumpAndSettle();

        expect(find.text('1 sélectionné'), findsOneWidget);
        expect(tester.widget<Checkbox>(boxOf('Tsara')).value, isTrue);
        await tester.tap(find.byTooltip('Arrêter la sélection'));
        await tester.pumpAndSettle();
        expect(find.byType(Checkbox), findsNothing);
      });
    });

    testWidgets('updates a playlist: only its new videos are checked', (
      tester,
    ) async {
      final first = PlannedDownload(
        source: ericMananaPlaylist,
        item: ericMananaPlaylist.items.first,
        index: 1,
      );
      await store.record(
        JobSucceeded(first, '/home/me/Musique/x.mp3'),
        MediaFormat.mp3,
        DateTime(2026, 10, 1),
      );
      await store.add('aB3dE5fG7hI', MediaFormat.mp3);
      await pumpKa7(tester);
      await tester.tap(find.text('Bibliothèque'));
      await tester.pumpAndSettle();

      await openActions(tester, "Tsara Ny Hiran' Ny Taniko");
      await tester.tap(find.text('Mettre à jour la playlist'));
      await tester.pumpAndSettle();

      expect(find.byType(PreviewScreen), findsOneWidget);
      expect(find.text('Déjà là'), findsOneWidget);
      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();
      expect(downloader.requests.map((r) => r.videoId), ['jK9lM1nO3pQ']);
    });

    testWidgets('keeps the actions of every row in line', (tester) async {
      PlannedDownload song(int i) => PlannedDownload(
        source: ericMananaPlaylist,
        item: ericMananaPlaylist.items[i],
        index: i + 1,
      );
      await store.record(
        JobSucceeded(song(0), '/home/me/Musique/a.mp3'),
        MediaFormat.mp3,
        DateTime(2026, 10, 1),
      );
      await store.record(
        JobFailed(song(1), FailureReason.private),
        MediaFormat.mp3,
        DateTime(2026, 10, 2),
      );
      await pumpKa7(tester);
      await tester.tap(find.text('Bibliothèque'));
      await tester.pumpAndSettle();

      final actions = find.byTooltip('Actions');
      expect(actions, findsNWidgets(2));
      expect(
        tester.getCenter(actions.at(0)).dx,
        tester.getCenter(actions.at(1)).dx,
      );
    });

    testWidgets('offers no update for a single video', (tester) async {
      await pumpKa7(tester);
      await downloadHafatra(tester);
      await openActions(tester, 'Hafatra');

      expect(find.text('Mettre à jour la playlist'), findsNothing);
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

      await tester.scrollUntilVisible(
        find.byTooltip('Changer le dossier de la musique'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(
        find.byTooltip('Changer le dossier de la musique'),
      );
      await tester.pumpAndSettle();
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

      await tester.scrollUntilVisible(
        find.byTooltip('Changer le dossier de la musique'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(
        find.byTooltip('Changer le dossier de la musique'),
      );
      await tester.pumpAndSettle();
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

  group('download settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
    }

    testWidgets('downloads one video at a time when asked to', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);

      await tester.ensureVisible(find.text('1').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      await download(tester, 'PLe7rK2mErickManana01');

      expect(downloader.requests.map((r) => r.videoId), ['aB3dE5fG7hI']);
      downloader.finish('aB3dE5fG7hI');
      await tester.pumpAndSettle();
      expect(downloader.requests, hasLength(2));
      expect(await store.setting('downloads.concurrency'), '1');
    });

    testWidgets('tells which version of Ka7 runs', (tester) async {
      await pumpKa7(tester, appVersion: '0.3.0');
      await openSettings(tester);
      await tester.scrollUntilVisible(find.text('Version 0.3.0'), 200);

      expect(find.text('À propos'), findsOneWidget);
      expect(find.text('Version 0.3.0'), findsOneWidget);
    });

    testWidgets('says when it is a development build', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.text('Version de développement'),
        200,
      );

      expect(find.text('Version de développement'), findsOneWidget);
    });

    testWidgets('downloads in the default quality chosen here', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.text('320 kbit/s'),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.text('320 kbit/s'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('720p'));
      await tester.pumpAndSettle();

      expect(await store.setting('quality.audio'), 'kbps320');
      expect(await store.setting('quality.video'), 'p720');
      await download(tester, 'Qm7tR2vLx9A');
      expect(downloader.requests.single.quality.audio, AudioQuality.kbps320);
      expect(downloader.requests.single.quality.video, VideoQuality.p720);
    });

    testWidgets('explains what a YouTube mix is', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);

      expect(
        find.textContaining('playlist sans fin que YouTube compose'),
        findsOneWidget,
      );
    });

    testWidgets('switches the theme at once and remembers it', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);
      ThemeMode mode() =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
      expect(mode(), ThemeMode.system);

      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();

      expect(mode(), ThemeMode.dark);
      expect(await store.setting('theme'), 'dark');
    });

    testWidgets('files by artist when asked to', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);

      expect(
        find.textContaining('chaîne YouTube qui a publié'),
        findsOneWidget,
      );
      await tester.tap(find.text('Par artiste'));
      await tester.pumpAndSettle();
      await download(tester, 'Xy7zA9bC1dE');

      expect(
        downloader.requests.single.destination,
        '/home/me/Musique/Erick Manana/Tsara.mp3',
      );
      expect(await store.setting('folders.layout'), 'artist');
    });

    testWidgets('downloads two at a time by default', (tester) async {
      await pumpKa7(tester);

      await download(tester, 'PLe7rK2mErickManana01');

      expect(downloader.requests, hasLength(2));
    });

    testWidgets('reads as many videos of a mix as chosen', (tester) async {
      late AppSettings seen;
      await pumpKa7(tester, onEngines: (settings) => seen = settings);
      await openSettings(tester);

      await tester.ensureVisible(find.text('100'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('100'));
      await tester.pumpAndSettle();

      expect(seen.mixLimit, 100);
      expect(await store.setting('mix.limit'), '100');
      await tester.tap(_nav('Ajouter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'RDHb8sJ1kP0wE');
      await tester.pump();
      expect(find.text('Mix · 100 max'), findsOneWidget);
    });
  });

  group('subscriptions', () {
    Future<void> openPreview(WidgetTester tester, String links) async {
      await tester.enterText(find.byType(TextField), links);
      await tester.pump();
      await tester.tap(find.text("Voir l'aperçu"));
      await tester.pumpAndSettle();
    }

    testWidgets('follows a playlist from its preview, stops in Settings', (
      tester,
    ) async {
      await pumpKa7(tester);
      await openPreview(tester, 'PLe7rK2mErickManana01');

      await tester.tap(find.text('Suivre'));
      await tester.pumpAndSettle();

      expect(find.text('Suivi'), findsOneWidget);
      expect(
        (await store.subscriptions()).single.title,
        'Erick Manana · Sélection',
      );
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Ne plus suivre'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Erick Manana · Sélection'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Ne plus suivre'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ne plus suivre'));
      await tester.pumpAndSettle();
      expect(await store.subscriptions(), isEmpty);
      expect(find.text('Erick Manana · Sélection'), findsNothing);
    });

    testWidgets('offers no following for a single video', (tester) async {
      await pumpKa7(tester);
      await openPreview(tester, 'Qm7tR2vLx9A');

      expect(find.text('Suivre'), findsNothing);
    });

    testWidgets('offers the new videos of what is followed, at launch', (
      tester,
    ) async {
      await store.follow('PLe7rK2mErickManana01', 'Erick Manana · Sélection');
      await store.add('aB3dE5fG7hI', MediaFormat.mp3);
      await pumpKa7(tester);

      expect(find.text('Nouveautés'), findsOneWidget);
      expect(
        find.text('1 nouveau titre · Erick Manana · Sélection'),
        findsOneWidget,
      );
      await tester.tap(find.text('Voir'));
      await tester.pumpAndSettle();

      expect(find.byType(PreviewScreen), findsOneWidget);
      expect(find.text('Déjà là'), findsOneWidget);
      await tester.tap(find.text('Télécharger'));
      await tester.pumpAndSettle();
      expect(downloader.requests.map((r) => r.videoId), ['jK9lM1nO3pQ']);
    });

    testWidgets('reads the followed at most once a day', (tester) async {
      await store.follow('PLe7rK2mErickManana01', 'Erick Manana · Sélection');
      await store.setSetting(
        'news.checked',
        DateTime(2026, 10, 30, 9).toUtc().toIso8601String(),
      );
      await pumpKa7(tester);

      expect(find.text('Nouveautés'), findsNothing);
    });

    testWidgets('reads them again the next day, and notes when', (
      tester,
    ) async {
      await store.follow('PLe7rK2mErickManana01', 'Erick Manana · Sélection');
      await store.setSetting(
        'news.checked',
        DateTime(2026, 10, 29, 9).toUtc().toIso8601String(),
      );
      await pumpKa7(tester);

      expect(find.text('Nouveautés'), findsOneWidget);
      expect(
        DateTime.parse(
          (await store.setting('news.checked'))!,
        ).isAtSameMomentAs(DateTime(2026, 10, 30, 14, 5)),
        isTrue,
      );
    });

    testWidgets('says nothing when the followed have nothing new', (
      tester,
    ) async {
      await store.follow('PLe7rK2mErickManana01', 'Erick Manana · Sélection');
      await store.add('aB3dE5fG7hI', MediaFormat.mp3);
      await store.add('jK9lM1nO3pQ', MediaFormat.mp3);
      await pumpKa7(tester);

      expect(find.text('Nouveautés'), findsNothing);
    });
  });

  group('new version', () {
    const next = AppRelease(
      version: '0.3.0',
      url: 'https://github.com/jmRakoto/ka7/releases/tag/v0.3.0',
    );

    testWidgets('offers a newer Ka7 and opens its page', (tester) async {
      final opened = <String>[];
      await pumpKa7(
        tester,
        appVersion: '0.2.0',
        latestRelease: () async => next,
        openUrl: opened.add,
      );

      expect(find.text('Ka7 0.3.0 est disponible'), findsOneWidget);
      expect(find.text('Tu as la 0.2.0.'), findsOneWidget);
      await tester.tap(find.text('Télécharger la mise à jour'));
      await tester.pumpAndSettle();

      expect(opened, [next.url]);
    });

    testWidgets('says nothing when Ka7 is up to date', (tester) async {
      await pumpKa7(
        tester,
        appVersion: '0.3.0',
        latestRelease: () async => next,
      );

      expect(find.textContaining('est disponible'), findsNothing);
    });

    testWidgets('later hides it until a newer one comes out', (tester) async {
      await pumpKa7(
        tester,
        appVersion: '0.2.0',
        latestRelease: () async => next,
      );

      await tester.tap(find.byTooltip('Plus tard'));
      await tester.pumpAndSettle();

      expect(find.textContaining('est disponible'), findsNothing);
      expect(await store.setting('update.dismissed'), '0.3.0');
    });

    testWidgets('asks GitHub at most once a day, remembers the answer', (
      tester,
    ) async {
      var asked = 0;
      await store.setSetting(
        'update.checked',
        DateTime(2026, 10, 30, 9).toUtc().toIso8601String(),
      );
      await store.setSetting('update.latest', '0.3.0');
      await store.setSetting('update.url', next.url);
      await pumpKa7(
        tester,
        appVersion: '0.2.0',
        latestRelease: () async {
          asked++;
          return next;
        },
      );

      expect(asked, 0);
      expect(find.text('Ka7 0.3.0 est disponible'), findsOneWidget);
    });

    testWidgets('stays quiet when GitHub cannot be reached', (tester) async {
      await pumpKa7(
        tester,
        appVersion: '0.2.0',
        latestRelease: () async => throw const SocketException('offline'),
      );

      expect(find.textContaining('est disponible'), findsNothing);
    });
  });

  group('end notification', () {
    tearDown(
      () => TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    testWidgets('tells the system once downloads end in the background', (
      tester,
    ) async {
      final notifier = _FakeNotifier();
      await pumpKa7(tester, notifier: notifier);
      await download(tester, 'PLe7rK2mErickManana01');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);

      downloader.finish('aB3dE5fG7hI');
      await tester.pumpAndSettle();
      expect(notifier.log, isEmpty);
      downloader.fail('jK9lM1nO3pQ', FailureReason.private);
      await tester.pumpAndSettle();

      expect(notifier.log, ['Téléchargements terminés | 1 réussi · 1 échoué']);
    });

    testWidgets('stays quiet while the app is in front', (tester) async {
      final notifier = _FakeNotifier();
      await pumpKa7(tester, notifier: notifier);
      await download(tester, 'Qm7tR2vLx9A');

      downloader.finish('Qm7tR2vLx9A');
      await tester.pumpAndSettle();

      expect(notifier.log, isEmpty);
    });
  });

  group('interrupted queue', () {
    List<String> ids(List<PendingDownload> pending) => [
      for (final p in pending) p.download.item.videoId,
    ];

    /// The two playable songs of the playlist, queued by a previous launch.
    Future<void> interrupted() => store.keepPending(
      [
        for (final (i, item) in ericMananaPlaylist.items.take(2).indexed)
          PlannedDownload(source: ericMananaPlaylist, item: item, index: i + 1),
      ],
      MediaFormat.mp3,
      '/data/Mozika',
      quality: const Quality(
        audio: AudioQuality.kbps320,
        video: VideoQuality.p1080,
      ),
    );

    testWidgets('keeps queued videos until they end, to resume them later', (
      tester,
    ) async {
      await pumpKa7(tester);

      await download(tester, 'PLe7rK2mErickManana01');
      expect(ids(await store.pending()), ['aB3dE5fG7hI', 'jK9lM1nO3pQ']);

      downloader.finish('aB3dE5fG7hI');
      await tester.pumpAndSettle();
      expect(ids(await store.pending()), ['jK9lM1nO3pQ']);

      downloader.fail('jK9lM1nO3pQ', FailureReason.network);
      await tester.pumpAndSettle();
      expect(await store.pending(), isEmpty);
    });

    testWidgets('leaves nothing to resume once the user cancels all', (
      tester,
    ) async {
      await pumpKa7(tester);
      await download(tester, 'PLe7rK2mErickManana01');

      await tester.tap(find.text('Tout annuler'));
      await tester.pumpAndSettle();

      expect(await store.pending(), isEmpty);
    });

    testWidgets('opens on the queue and offers to resume', (tester) async {
      await interrupted();

      await pumpKa7(tester);

      expect(find.text('File interrompue'), findsOneWidget);
      expect(
        find.text("2 titres n'ont pas fini la dernière fois."),
        findsOneWidget,
      );
      expect(downloader.requests, isEmpty);
    });

    testWidgets('resumes into the folder they were queued to', (tester) async {
      await interrupted();
      await pumpKa7(tester);

      await tester.tap(find.text('Reprendre'));
      await tester.pumpAndSettle();

      expect(find.text('File interrompue'), findsNothing);
      expect(downloader.requests.map((r) => r.destination), [
        "/data/Mozika/Erick Manana · Sélection/01 - Tsara Ny Hiran' Ny Taniko.mp3",
        '/data/Mozika/Erick Manana · Sélection/02 - Tsy Ferana.mp3',
      ]);
      expect(ids(await store.pending()), ['aB3dE5fG7hI', 'jK9lM1nO3pQ']);
      expect(
        downloader.requests.map((r) => r.quality.audio),
        everyElement(AudioQuality.kbps320),
        reason: 'the quality they were queued in',
      );
    });

    testWidgets('discards into the history as cancelled', (tester) async {
      await interrupted();
      await pumpKa7(tester);

      await tester.tap(find.text('Abandonner'));
      await tester.pumpAndSettle();

      expect(find.text('File interrompue'), findsNothing);
      expect(downloader.requests, isEmpty);
      expect(await store.pending(), isEmpty);
      expect((await store.history()).map((h) => h.status), [
        HistoryStatus.cancelled,
        HistoryStatus.cancelled,
      ]);
    });
  });

  group('drop', () {
    /// What GTK sends while something is dragged over, then dropped on, the
    /// middle of the window.
    Future<void> native(WidgetTester tester, String method, [String? text]) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'desktop_drop',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, switch (method) {
              'performOperation_linux' => [
                text,
                [640.0, 450.0],
              ],
              'updated' => [640.0, 450.0],
              _ => null,
            }),
          ),
          (_) {},
        );

    Future<void> drop(WidgetTester tester, String text) async {
      await native(tester, 'updated');
      await native(tester, 'performOperation_linux', text);
      await tester.pumpAndSettle();
    }

    testWidgets('adds dropped links to Add, below what is there', (
      tester,
    ) async {
      await pumpKa7(tester, acceptDrops: true);
      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');

      await drop(tester, 'https://youtu.be/aB3dE5fG7hI\nPLe7rK2mErickManana01');

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Qm7tR2vLx9A\nhttps://youtu.be/aB3dE5fG7hI\nPLe7rK2mErickManana01',
      );
      expect(find.text('3 entrées reconnues'), findsOneWidget);
    });

    testWidgets('goes back to Add from any section', (tester) async {
      await pumpKa7(tester, acceptDrops: true);
      await tester.tap(find.text('Bibliothèque'));
      await tester.pumpAndSettle();

      await drop(tester, 'Qm7tR2vLx9A');

      expect(find.byType(AddLinksScreen), findsOneWidget);
      expect(find.text('1 entrée reconnue'), findsOneWidget);
    });

    testWidgets('says where to let go while something is dragged over', (
      tester,
    ) async {
      await pumpKa7(tester, acceptDrops: true);

      await native(tester, 'updated');
      await tester.pump();
      expect(find.text('Dépose tes liens ou un fichier .txt'), findsOneWidget);

      await native(tester, 'exited');
      await tester.pump();
      expect(find.text('Dépose tes liens ou un fichier .txt'), findsNothing);
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

    testWidgets('shows the folder the system files music in', (tester) async {
      await pumpKa7(
        tester,
        builtInEngine: true,
        canPickFolders: false,
        formats: const [MediaFormat.m4a, MediaFormat.mp4],
        shownFolder: (format) =>
            format == MediaFormat.mp4 ? 'Movies/Ka7' : 'Music/Ka7',
      );

      await download(tester, 'Qm7tR2vLx9A');

      expect(find.text("M4A · d'origine · Music/Ka7"), findsOneWidget);
      expect(find.textContaining('/home/me/Musique'), findsNothing);
    });

    group('chosen folder', () {
      Destination? chosen;
      Future<void> pumpPhone(WidgetTester tester) => pumpKa7(
        tester,
        builtInEngine: true,
        canPickFolders: false,
        formats: const [MediaFormat.m4a, MediaFormat.mp4],
        shownFolder: (format) =>
            format == MediaFormat.mp4 ? 'Movies/Ka7' : 'Music/Ka7',
        pickDestination: () async => chosen,
      );
      Future<void> scrollToMusic(WidgetTester tester) async {
        await tester.tap(_nav('Réglages'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byTooltip('Changer le dossier de la musique'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.ensureVisible(
          find.byTooltip('Changer le dossier de la musique'),
        );
        await tester.pumpAndSettle();
      }

      setUp(() => chosen = null);

      testWidgets('files music where the user chose, and says so', (
        tester,
      ) async {
        chosen = (uri: 'content://tree/1234%3AMozika', label: 'SD/Mozika');
        await pumpPhone(tester);
        await scrollToMusic(tester);
        expect(find.text('Music/Ka7'), findsOneWidget, reason: 'default');

        await tester.tap(find.byTooltip('Changer le dossier de la musique'));
        await tester.pumpAndSettle();

        expect(find.text('SD/Mozika'), findsOneWidget);
        expect(
          await store.setting('destination.mp3'),
          'content://tree/1234%3AMozika',
        );
        await download(tester, 'Qm7tR2vLx9A');
        expect(find.text("M4A · d'origine · SD/Mozika"), findsOneWidget);
      });

      testWidgets('keeps the folder when the picker is closed', (tester) async {
        await pumpPhone(tester);
        await scrollToMusic(tester);

        await tester.tap(find.byTooltip('Changer le dossier de la musique'));
        await tester.pumpAndSettle();

        expect(find.text('Music/Ka7'), findsOneWidget);
        expect(await store.setting('destination.mp3'), isNull);
      });

      testWidgets('goes back to the default folder', (tester) async {
        await store.setSetting('destination.mp3', 'content://tree/x');
        await store.setSetting('destination.mp3.label', 'SD/Mozika');
        await pumpPhone(tester);
        await scrollToMusic(tester);
        expect(find.text('SD/Mozika'), findsOneWidget);

        await tester.tap(find.byTooltip('Revenir au dossier par défaut').first);
        await tester.pumpAndSettle();

        expect(find.text('Music/Ka7'), findsOneWidget);
        expect(await store.setting('destination.mp3'), isNull);
      });
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

      expect(find.text('Hafatra'), findsWidgets);
      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();
      expect(find.text('Ouvrir le dossier'), findsNothing);
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

class _FakeNotifier implements RunNotifier {
  final log = <String>[];

  @override
  void finished({required String title, required String body}) =>
      log.add('$title | $body');
}

/// A section in the sidebar or the bottom bar, not a title that says the same.
Finder _nav(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar),
  matching: find.text(label),
);
