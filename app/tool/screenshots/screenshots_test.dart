// Renders Ka7's screens to PNG with real fonts, to review the design.
// Not part of the test suite:
//   KA7_SHOTS=/some/folder fvm flutter test tool/screenshots/screenshots_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/app.dart';
import 'package:ka7/features/preview/preview_screen.dart';
import 'package:ka7/l10n/app_localizations.dart';
import 'package:ka7/theme/ka7_theme.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../test/helpers/controlled_downloader.dart';
import '../../test/helpers/fake_engine_setup.dart';
import '../../test/helpers/fake_extractor.dart';
import '../../test/helpers/probes.dart';

final _out = Platform.environment['KA7_SHOTS'] ?? 'build/screenshots';
final _flutterFonts =
    '${Platform.environment['HOME']}/fvm/versions/stable/bin/cache/artifacts/material_fonts';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('$_flutterFonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

final _extractor = FakeExtractor({
  'https://www.youtube.com/watch?v=Qm7tR2vLx9A': hafatraVideo,
  'https://www.youtube.com/playlist?list=PLe7rK2mErickManana01':
      ericMananaPlaylist,
  'https://www.youtube.com/results?search_query=Erick+Manana': Probe(
    title: 'Erick Manana',
    isSearch: true,
    items: ericMananaPlaylist.items.take(2).toList(),
  ),
});

/// Never answers: the preview stays on its loading view.
class _Pending implements Extractor {
  @override
  String get name => 'pending';

  @override
  Future<Probe> probe(MediaEntry entry) => Completer<Probe>().future;
}

void main() {
  setUpAll(_loadFonts);

  // Loading never settles: pumped by hand, mid-animation.
  for (final brightness in Brightness.values) {
    testWidgets('phone loading ${brightness.name}', (tester) async {
      tester.view
        ..physicalSize = const Size(400, 860)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Directory(_out).createSync(recursive: true);
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            theme: ka7Theme(brightness),
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PreviewScreen(
                entries: const [
                  SearchEntry('Erick Manana', query: 'Erick Manana'),
                ],
                extractor: _Pending(),
                onDownload: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 400));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_out/phone-${brightness.name}-2-preview-loading.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final (name, size) in [
    ('desktop', const Size(1280, 800)),
    ('phone', const Size(400, 860)),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('$name ${brightness.name}', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final prefix = '$_out/$name-${brightness.name}';
        Directory(_out).createSync(recursive: true);

        Future<void> shot(String screen) async {
          await tester.pumpAndSettle();
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '$prefix-$screen.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        final store = Ka7Store.inMemory();
        addTearDown(store.close);
        await store.setSetting('language', 'fr');
        final setup = FakeEngineSetup(missing: {EngineTool.ffmpeg});
        final downloader = ControlledDownloader();
        await tester.pumpWidget(
          RepaintBoundary(
            child: Ka7App(
              engineSetup: setup,
              enginesFor: (_, _) =>
                  (extractor: _extractor, downloader: downloader),
              store: store,
              defaultFolders: const {
                MediaFormat.mp3: '/home/rakoto/Musique',
                MediaFormat.mp4: '/home/rakoto/Vidéos',
              },
              pickFolder: () async => null,
              openFolder: (_) {},
              acceptDrops: true,
              pickLinksFile: () async => null,
              // No network here: the neutral tile stands in for pictures.
              thumbnail: (_) => MemoryImage(Uint8List(0)),
            ),
          ),
        );
        await shot('00-welcome-0');
        await tester.tap(find.text('Suivant'));
        await shot('00-welcome-1');
        await tester.tap(find.text('Suivant'));
        await shot('00-welcome-2');
        await tester.tap(find.text('Suivant'));
        await shot('00-welcome-3');
        await tester.tap(find.text('Suivant'));
        await shot('00-welcome-4');
        await tester.tap(find.text('Commencer'));
        await shot('0-engine');
        await tester.tap(find.text('Installer'));
        await tester.pump();
        setup.progress(EngineTool.ffmpeg, 0.37);
        await shot('0-engine-installing');
        setup.finish(EngineTool.ffmpeg);
        await tester.pumpAndSettle();
        await shot('1-add-empty');

        await tester.enterText(
          find.byType(TextField),
          'PLe7rK2mErickManana01\nhttps://youtu.be/Qm7tR2vLx9A?si=x\n'
          'vimeo.com/123\nQm7tR2vLx9A',
        );
        await shot('1-add');
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'desktop_drop',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('updated', [size.width / 2, size.height / 2]),
          ),
          (_) {},
        );
        await shot('1-add-drop');
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'desktop_drop',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('exited'),
          ),
          (_) {},
        );
        await tester.tap(find.text('Recherche YouTube'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Erick Manana');
        await shot('1-add-search');
        await tester.tap(find.text('Rechercher'));
        await shot('2-preview-search');
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Liens'));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Voir l'aperçu"));
        await shot('2-preview');
        await tester.tap(find.text('Télécharger'));
        await tester.pumpAndSettle();
        downloader.progress('aB3dE5fG7hI', 0.62, speed: 1800000);
        downloader.progress('jK9lM1nO3pQ', 0.18, speed: 900000);
        await shot('3-queue');
        downloader
          ..finish('aB3dE5fG7hI')
          ..fail('jK9lM1nO3pQ', FailureReason.private);
        await tester.pumpAndSettle();
        downloader.finish('Qm7tR2vLx9A');
        await shot('4-summary');
        // A new run above the ended one, folded under « Plus tôt ».
        await tester.tap(find.text('Ajouter').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text("Voir l'aperçu"));
        await tester.pumpAndSettle();
        await tester.tap(find.text('MP4 · vidéo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Télécharger'));
        await tester.pumpAndSettle();
        downloader.progress('aB3dE5fG7hI', 0.4, speed: 2100000);
        await shot('4-queue-earlier');
        await tester.tap(find.text('Bibliothèque').last);
        await shot('5-library');
        await tester.tap(find.text('Réglages').last);
        await shot('6-settings');

        // Next launch, after a crash in the middle of the playlist.
        final relaunched = Ka7Store.inMemory();
        addTearDown(relaunched.close);
        await relaunched.setSetting('language', 'fr');
        await relaunched.setSetting('onboarding.done', '1');
        await relaunched.keepPending(
          [
            for (final (i, item) in ericMananaPlaylist.items.take(2).indexed)
              PlannedDownload(
                source: ericMananaPlaylist,
                item: item,
                index: i + 1,
              ),
          ],
          MediaFormat.mp3,
          '/home/rakoto/Musique',
        );
        await tester.pumpWidget(
          RepaintBoundary(
            child: Ka7App(
              key: const ValueKey('relaunch'),
              engineSetup: FakeEngineSetup.ready(),
              enginesFor: (_, _) =>
                  (extractor: _extractor, downloader: downloader),
              store: relaunched,
              defaultFolders: const {
                MediaFormat.mp3: '/home/rakoto/Musique',
                MediaFormat.mp4: '/home/rakoto/Vidéos',
              },
              pickFolder: () async => null,
              openFolder: (_) {},
            ),
          ),
        );
        await shot('7-interrupted');
      });
    }
  }
}
