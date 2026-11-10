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
import 'package:ka7/widgets/ka7_page.dart';
import 'package:ka7/features/preview/preview_screen.dart';
import 'package:ka7/l10n/app_localizations.dart';
import 'package:ka7/theme/ka7_theme.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../test/helpers/controlled_downloader.dart';
import '../../test/helpers/fake_engine_setup.dart';
import '../../test/helpers/fake_extractor.dart';
import '../../test/helpers/fake_media_backend.dart';
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
    channels: const [
      ChannelRef(name: 'Erick Manana', channelId: 'UCx7eYvXnFq3o2Erick00001'),
    ],
    items: ericMananaPlaylist.items.take(2).toList(),
  ),
});

/// Reads like [_extractor], and gives stream addresses.
class _Streams implements Extractor, StreamUrls {
  @override
  String get name => 'streams';

  @override
  Future<Probe> probe(MediaEntry entry) => _extractor.probe(entry);

  @override
  Future<String> streamUrl(String videoId, {required bool video}) async =>
      'https://stream/$videoId';
}

/// Never answers: the preview stays on its loading view.
class _Pending implements Extractor {
  @override
  String get name => 'pending';

  @override
  Future<Probe> probe(MediaEntry entry) => Completer<Probe>().future;
}

void main() {
  setUpAll(_loadFonts);

  // A channel opened from a search: header card, filter, titles.
  for (final brightness in Brightness.values) {
    testWidgets('phone channel ${brightness.name}', (tester) async {
      tester.view
        ..physicalSize = const Size(400, 860)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Directory(_out).createSync(recursive: true);
      const entry = ChannelEntry(
        'https://www.youtube.com/channel/UCEpStQu-C7FCCv1-P5UyClg',
        channel: 'channel/UCEpStQu-C7FCCv1-P5UyClg',
      );
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            theme: ka7Theme(brightness),
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PreviewScreen(
                entries: const [entry],
                pickByHand: true,
                extractor: FakeExtractor({
                  entry.url: Probe(
                    title: 'Denise',
                    playlistId: 'UCEpStQu-C7FCCv1-P5UyClg',
                    isChannel: true,
                    items: [
                      for (var i = 1; i <= 40; i++)
                        ProbeItem(
                          videoId: 'aaaaaaaa${i.toString().padLeft(3, '0')}',
                          title: i.isEven ? 'Jalousie (Live $i)' : 'Chanson $i',
                          duration: Duration(seconds: 180 + i),
                        ),
                    ],
                  ),
                }),
                isFollowed: (_) => false,
                onFollow: (_, _) async {},
                openUrl: (_) {},
                thumbnail: (_) => MemoryImage(Uint8List(0)),
                onDownload: (_, _, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'jalousie');
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$_out/phone-${brightness.name}-2-preview-channel.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }

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
                onDownload: (_, _, _) {},
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
        final aboutCard = find.text('Version de développement');
        await tester.scrollUntilVisible(
          aboutCard,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.ensureVisible(aboutCard);
        await tester.pumpAndSettle();
        await shot('6b-settings-about');
        await tester.tap(aboutCard);
        await shot('6c-about');

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

  // The player: Library with its buttons, mini player, whole player,
  // playlists, and ▶ in the preview.
  for (final (name, size) in [
    ('desktop', const Size(1280, 800)),
    ('phone', const Size(400, 860)),
    // A phone held sideways: the sidebar, scrolling (KA-4).
    ('phone-sideways', const Size(780, 360)),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('player $name ${brightness.name}', (tester) async {
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
        await store.setSetting('onboarding.done', '1');
        for (final (i, item) in ericMananaPlaylist.items.take(2).indexed) {
          await store.record(
            JobSucceeded(
              PlannedDownload(
                source: ericMananaPlaylist,
                item: item,
                index: i + 1,
              ),
              '/home/rakoto/Musique/Ka7/${item.title}.mp3',
            ),
            MediaFormat.mp3,
            DateTime.now().subtract(Duration(minutes: 10 - i)),
          );
        }
        await store.createFolderPlaylist(
          'Mahaleo',
          folder: '/home/rakoto/Musique/Mahaleo',
          label: 'Musique/Mahaleo',
        );
        final party = await store.createPlaylist('Soirée');
        for (final item in await store.history()) {
          await store.addToPlaylist(party, PlaylistTrack.of(item));
        }
        final backend = FakeMediaBackend();
        await tester.pumpWidget(
          RepaintBoundary(
            child: Ka7App(
              engineSetup: FakeEngineSetup.ready(),
              enginesFor: (_, _) =>
                  (extractor: _Streams(), downloader: ControlledDownloader()),
              store: store,
              defaultFolders: const {
                MediaFormat.mp3: '/home/rakoto/Musique',
                MediaFormat.mp4: '/home/rakoto/Vidéos',
              },
              pickFolder: () async => null,
              openFolder: (_) {},
              mediaBackend: () => backend,
              pickMediaFolder: (_) async => null,
              listMediaFolder: (folder) async => const [
                MediaFile(path: '/m/1 Bonga.mp3', name: '1 Bonga.mp3'),
                MediaFile(path: '/m/2 Veloma.flac', name: '2 Veloma.flac'),
                MediaFile(path: '/m/Live/Hafatra.mp4', name: 'Hafatra.mp4'),
              ],
              thumbnail: (_) => MemoryImage(Uint8List(0)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lecteur').last);
        await shot('8-player-hub');
        await tester.tap(find.text('Tsy Ferana'));
        await tester.pumpAndSettle();
        backend
          ..lasts(const Duration(minutes: 5, seconds: 41))
          ..at(const Duration(minutes: 1, seconds: 12));
        await shot('8b-mini-player');
        await tester.tap(find.bySemanticsLabel('Ouvrir le lecteur'));
        await shot('8c-player');
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pumpAndSettle();
        await shot('8b-player-hub-playing');
        // Real fonts here (unit tests draw every letter as a square): the
        // card's « En cours de lecture » fits whole on one line (KA-2).
        final label = tester.renderObject<RenderParagraph>(
          find.text('En cours de lecture'),
        );
        expect(label.didExceedMaxLines, isFalse, reason: 'cut with « … »');
        expect(
          label.size.height,
          // Its height on one endless line.
          label.getMaxIntrinsicHeight(double.infinity),
          reason: 'wrapped',
        );
        await tester.tap(find.textContaining('Listes ·'));
        await shot('8d-playlists');
        // A phone held sideways shows only the top of the page: go to its
        // end without a drag, which could start on the card and open the
        // player.
        Future<void> toPageEnd() async {
          final page = tester.state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(Ka7Page).last,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          page.position.jumpTo(page.position.maxScrollExtent);
          await tester.pumpAndSettle();
        }

        await toPageEnd();
        await tester.tap(find.text('Mahaleo'));
        await shot('8h-folder-list');
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        await toPageEnd();
        await tester.tap(find.text('Soirée'));
        await shot('8e-playlist');
        await tester.tap(find.byType(BackButton).last);
        await tester.pumpAndSettle();
        // Sideways, the preview's bottom bar leaves no room for its list:
        // nothing to tap there yet.
        if (name == 'phone-sideways') {
          // The sidebar scrolled to its end: Réglages in reach (KA-4).
          final rail = tester.state<ScrollableState>(
            find
                .ancestor(
                  of: find.byType(NavigationRail),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          rail.position.jumpTo(rail.position.maxScrollExtent);
          await shot('8i-menu-scrolled');
          return;
        }
        await tester.tap(find.text('Ajouter').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'PLe7rK2mErickManana01');
        await tester.pump();
        await tester.tap(find.text("Voir l'aperçu"));
        await shot('8f-preview-play');
        await tester.tap(find.byTooltip('Écouter avant de télécharger').first);
        await tester.pumpAndSettle();
        backend
          ..lasts(const Duration(minutes: 4, seconds: 12))
          ..at(const Duration(seconds: 47));
        await shot('8g-preview-listening');
      });
    }
  }
}
