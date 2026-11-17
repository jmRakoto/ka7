import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ka7/app.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

/// Real run on the desktop: a mix link follows the « mix » setting, then
/// reads further as the list is scrolled to its end.
/// `cd app && fvm flutter test integration_test/mix_flow_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a mix follows the setting, then loads more on scroll', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('ka7_e2e_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final store = Ka7Store.inMemory();
    addTearDown(store.close);
    await store.setSetting('language', 'fr');
    await store.setSetting('onboarding.done', '1');
    await store.setSetting('mix.limit', '25');
    await tester.pumpWidget(
      Ka7App(
        engineSetup: EngineBinaries(
          folder: '${folder.path}/bin',
          run: Process.run,
          fetch: httpFetch,
        ),
        enginesFor: (status, settings) => (
          extractor: YtDlpExtractor(
            run: Process.run,
            executable: status!.ytDlp!,
            mixLimit: () => settings.mixLimit,
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
    await tester.pump(const Duration(milliseconds: 600));

    await tester.enterText(
      find.byType(TextField),
      'https://www.youtube.com/watch?v=f4fnM0A3sVo&list=RDf4fnM0A3sVo&start_radio=1',
    );
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await _waitFor(tester, find.text('25 titres'), timeout: 90);

    await _waitFor(tester, find.text('Tout sélectionner'));
    // Scroll to the end: the next page is read by itself.
    // The preview is the page on top: its list is the last one built.
    final list = find.byType(ListView).last;
    // Down to the end, long enough for yt-dlp to read the next page.
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -3000));
      await tester.pump(const Duration(seconds: 1));
    }
    // Back to the top, where the count is.
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, 5000));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));
    var count = 25;
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final match = RegExp(r'^(\d+) titres$').firstMatch(text.data ?? '');
      if (match != null) count = int.parse(match.group(1)!);
    }
    final shown = [
      for (final text in tester.widgetList<Text>(find.byType(Text))) ?text.data,
    ];
    expect(
      count,
      greaterThan(25),
      reason:
          'scrollables: ${find.byType(Scrollable).evaluate().length}\n$shown',
    );
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
  final shown = [
    for (final text in tester.widgetList<Text>(find.byType(Text))) ?text.data,
  ];
  throw TestFailure('Not found after ${timeout}s: $finder\nOn screen: $shown');
}
