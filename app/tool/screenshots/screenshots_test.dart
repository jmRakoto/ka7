// Renders Ka7's screens to PNG with real fonts, to review the design.
// Not part of the test suite:
//   KA7_SHOTS=/some/folder fvm flutter test tool/screenshots/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/app.dart';
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
});

void main() {
  setUpAll(_loadFonts);

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
            File('$prefix-$screen.png').writeAsBytesSync(
              png!.buffer.asUint8List(),
            );
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
              enginesFor: (_) =>
                  (extractor: _extractor, downloader: downloader),
              store: store,
              defaultFolders: const {
                MediaFormat.mp3: '/home/rakoto/Musique',
                MediaFormat.mp4: '/home/rakoto/Vidéos',
              },
              pickFolder: () async => null,
              openFolder: (_) {},
            ),
          ),
        );
        await shot('0-engine');
        await tester.tap(find.text('Installer'));
        await tester.pump();
        setup.progress(EngineTool.ffmpeg, 0.37);
        await shot('0-engine-installing');
        setup.finish(EngineTool.ffmpeg);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'PLe7rK2mErickManana01\nhttps://youtu.be/Qm7tR2vLx9A?si=x\n'
          'vimeo.com/123\nQm7tR2vLx9A',
        );
        await shot('1-add');
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
        await tester.tap(find.text('Bibliothèque').last);
        await shot('5-library');
        await tester.tap(find.text('Réglages').last);
        await shot('6-settings');
      });
    }
  }
}
