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
    await tester.pumpWidget(
      Ka7App(
        engineSetup: EngineBinaries(
          folder: '${folder.path}/bin',
          run: Process.run,
          fetch: httpFetch,
        ),
        enginesFor: (status) => (
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

    await tester.enterText(find.byType(TextField), 'jNQXAC9IVRw');
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await _waitFor(tester, find.text('Me at the zoo'));
    await tester.tap(find.text('Télécharger'));
    await _waitFor(tester, find.text('Terminé'), timeout: 180);

    expect(find.text('1 réussi'), findsOneWidget);
    expect(File('${folder.path}/Me at the zoo.mp3').existsSync(), isTrue);
  });
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeout = 60,
}) async {
  for (var i = 0; i < timeout * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Not found after ${timeout}s: $finder');
}
