import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/app.dart';
import 'package:ka7/features/add_links/add_links_screen.dart';
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

final _extractor = FakeExtractor({
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

      await tester.tap(find.byTooltip('Mettre à jour la playlist'));
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

      final update = find.byTooltip('Mettre à jour la playlist');
      expect(update, findsNWidgets(2));
      expect(
        tester.getCenter(update.at(0)).dx,
        tester.getCenter(update.at(1)).dx,
      );
    });

    testWidgets('offers no update for a single video', (tester) async {
      await pumpKa7(tester);
      await downloadHafatra(tester);

      expect(find.byTooltip('Mettre à jour la playlist'), findsNothing);
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

  group('download settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
    }

    testWidgets('downloads one video at a time when asked to', (tester) async {
      await pumpKa7(tester);
      await openSettings(tester);

      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      await download(tester, 'PLe7rK2mErickManana01');

      expect(downloader.requests.map((r) => r.videoId), ['aB3dE5fG7hI']);
      downloader.finish('aB3dE5fG7hI');
      await tester.pumpAndSettle();
      expect(downloader.requests, hasLength(2));
      expect(await store.setting('downloads.concurrency'), '1');
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
