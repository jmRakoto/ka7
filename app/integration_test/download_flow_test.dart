import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ka7/app.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

/// Real run on the desktop: real yt-dlp (from the PATH), real network,
/// temporary folder.
/// `cd app && fvm flutter test integration_test -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pastes a link, previews it and downloads it as MP3', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('ka7_e2e_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final store = Ka7Store.inMemory();
    addTearDown(store.close);
    await store.setSetting('language', 'fr');
    await store.setSetting('onboarding.done', '1');
    await tester.pumpWidget(
      Ka7App(
        engineSetup: EngineBinaries(
          folder: '${folder.path}/bin',
          run: Process.run,
          fetch: httpFetch,
        ),
        enginesFor: (status, _) => (
          extractor: YtDlpExtractor(
            run: Process.run,
            executable: status!.ytDlp!,
          ),
          downloader: YtDlpDownloader(
            start: Process.start,
            executable: status.ytDlp!,
            ffmpegPath: status.ffmpeg,
          ),
        ),
        store: store,
        defaultFolders: {for (final f in MediaFormat.values) f: folder.path},
        pickFolder: () async => null,
        openFolder: (_) {},
      ),
    );
    await _waitFor(tester, find.byType(TextField));
    // The page slides in: type once it has settled, as a person would.
    await tester.pump(const Duration(milliseconds: 600));

    await tester.enterText(find.byType(TextField), 'jNQXAC9IVRw');
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await _waitFor(tester, find.text('Me at the zoo'));
    await tester.tap(find.text('Télécharger'));
    await _waitFor(tester, find.text('1 réussi'), timeout: 180);

    expect(find.text('1 réussi'), findsOneWidget);
    expect(File('${folder.path}/Me at the zoo.mp3').existsSync(), isTrue);
  });

  testWidgets('resumes after a crash mid-download, from the store on disk', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('ka7_e2e_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');

    // First launch: the download starts, then the app dies without a word.
    final first = Ka7Store.open(file);
    await first.setSetting('language', 'fr');
    await first.setSetting('onboarding.done', '1');
    await tester.pumpWidget(_realApp(first, folder.path));
    await _waitFor(tester, find.byType(TextField));
    // The page slides in: type once it has settled, as a person would.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(TextField), 'jNQXAC9IVRw');
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await _waitFor(tester, find.text('Me at the zoo'));
    await tester.tap(find.text('Télécharger'));
    await _waitFor(tester, find.text('En cours'));
    await tester.pumpWidget(const SizedBox());
    await first.close();

    // Next launch, same file.
    final second = Ka7Store.open(file);
    addTearDown(second.close);
    expect(await second.pending(), hasLength(1));
    await tester.pumpWidget(_realApp(second, folder.path));
    await _waitFor(tester, find.text('File interrompue'));
    expect(find.text("1 titre n'a pas fini la dernière fois."), findsOneWidget);

    await tester.tap(find.text('Reprendre'));
    await _waitFor(tester, find.text('1 réussi'), timeout: 180);

    expect(find.text('1 réussi'), findsOneWidget);
    expect(File('${folder.path}/Me at the zoo.mp3').existsSync(), isTrue);
    expect(await second.pending(), isEmpty);
  });

  testWidgets('follows a playlist; its new videos show at the next launch', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('ka7_e2e_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');

    // First launch: follow the Mahaleo playlist from its preview.
    final first = Ka7Store.open(file);
    await first.setSetting('language', 'fr');
    await first.setSetting('onboarding.done', '1');
    await tester.pumpWidget(_realApp(first, folder.path));
    await _waitFor(tester, find.byType(TextField));
    // The page slides in: type once it has settled, as a person would.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(
      find.byType(TextField),
      'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
    );
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await _waitFor(tester, find.text('Suivre'), timeout: 120);
    await tester.tap(find.text('Suivre'));
    await _waitFor(tester, find.text('Suivi'));
    expect((await first.subscriptions()).single.title, 'Mahaleo playlist');
    await tester.pumpWidget(const SizedBox());
    await first.close();

    // Next launch: the playlist is read again in the background.
    final second = Ka7Store.open(file);
    addTearDown(second.close);
    await tester.pumpWidget(_realApp(second, folder.path));
    await _waitFor(tester, find.text('Nouveautés'), timeout: 120);
    expect(
      find.textContaining('nouveaux titres · Mahaleo playlist'),
      findsOneWidget,
    );

    // The card glides in: tap once it has stopped moving.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Voir'));
    await _waitFor(tester, find.text('Suivi'), timeout: 120);
  });

  testWidgets('an older Ka7 learns from GitHub that a newer one is out', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('ka7_e2e_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final store = Ka7Store.inMemory();
    addTearDown(store.close);
    await store.setSetting('language', 'fr');
    await store.setSetting('onboarding.done', '1');
    final opened = <String>[];

    await tester.pumpWidget(
      _realApp(
        store,
        folder.path,
        appVersion: '0.1.0',
        latestRelease: fetchLatestRelease,
        openUrl: opened.add,
      ),
    );
    await _waitFor(tester, find.textContaining('est disponible'), timeout: 60);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Télécharger la mise à jour'));
    await tester.pump();

    expect(
      opened.single,
      startsWith('https://github.com/jmRakoto/ka7/releases/tag/v'),
    );
  });
}

/// The same real engines, for every journey.
Ka7App _realApp(
  Ka7Store store,
  String folder, {
  String? appVersion,
  Future<AppRelease?> Function()? latestRelease,
  void Function(String url)? openUrl,
}) => Ka7App(
  appVersion: appVersion,
  latestRelease: latestRelease,
  openUrl: openUrl,
  engineSetup: EngineBinaries(
    folder: '$folder/bin',
    run: Process.run,
    fetch: httpFetch,
  ),
  enginesFor: (status, _) => (
    extractor: YtDlpExtractor(run: Process.run, executable: status!.ytDlp!),
    downloader: YtDlpDownloader(
      start: Process.start,
      executable: status.ytDlp!,
      ffmpegPath: status.ffmpeg,
    ),
  ),
  store: store,
  defaultFolders: {for (final f in MediaFormat.values) f: folder},
  pickFolder: () async => null,
  openFolder: (_) {},
);

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeout = 60,
}) async {
  for (var i = 0; i < timeout * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  final shown = [
    for (final text in tester.widgetList<Text>(find.byType(Text))) ?text.data,
  ];
  throw TestFailure('Not found after ${timeout}s: $finder\nOn screen: $shown');
}
