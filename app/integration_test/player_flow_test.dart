import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ka7/app.dart';
import 'package:ka7/features/player/media_kit_backend.dart';
import 'package:ka7/platform/folder_media.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;

/// The whole player journey in the real app on the desktop: real yt-dlp,
/// real network, real libmpv, temporary folder.
/// `cd app && fvm flutter test integration_test/player_flow_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  testWidgets('listens before downloading, then plays offline, in a list', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('ka7_play_e2e_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/ka7.sqlite');
    final store = Ka7Store.open(file);
    await store.setSetting('language', 'fr');
    await store.setSetting('onboarding.done', '1');
    await tester.pumpWidget(_realApp(store, folder.path));
    await _waitFor(tester, find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 600));

    // 1. Preview, then ▶ before downloading: it plays online.
    await tester.enterText(find.byType(TextField), 'jNQXAC9IVRw');
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));
    await _waitFor(tester, find.byTooltip('Écouter avant de télécharger'));
    await tester.tap(find.byTooltip('Écouter avant de télécharger'));
    await _waitFor(tester, find.byTooltip('Fermer le lecteur'));
    // Everything in the bar: its own slider moves, no page to open.
    await _waitPlaying(tester);
    expect(find.bySemanticsLabel('Ouvrir le lecteur'), findsNothing);
    await tester.tap(find.byTooltip('Fermer le lecteur'));
    await tester.pump(const Duration(milliseconds: 300));

    // 1b. In MP4, ▶ then the player page: the video shows, not black.
    await tester.tap(find.text('MP4 · vidéo'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byTooltip('Regarder avant de télécharger'));
    await _waitFor(tester, find.byTooltip('Fermer le lecteur'));
    await _openPlayer(tester);
    await _waitPlaying(tester);
    await _waitPicture(tester);
    await _closePlayer(tester);
    await tester.tap(find.byTooltip('Fermer le lecteur'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('MP3 · audio'));
    await tester.pump(const Duration(milliseconds: 600));

    // 2. Download it as MP3.
    await tester.tap(find.text('Télécharger'));
    await _waitFor(tester, find.text('1 réussi'), timeout: 180);
    // Filed in its channel's folder: where the history says.
    final [saved] = await store.history();
    expect(saved.path, endsWith('Me at the zoo.mp3'));
    expect(File(saved.path!).existsSync(), isTrue);

    // 3. Lecteur: a tap plays the downloaded file.
    await tester.tap(_nav('Lecteur'));
    await _waitFor(tester, find.text('Tout lire'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Me at the zoo'));
    await _waitFor(tester, find.byTooltip('Fermer le lecteur'));
    await _openPlayer(tester);
    await _waitPlaying(tester);

    // 4. Every control, on the real player.
    await tester.tap(find.byTooltip('Pause'));
    await _waitFor(tester, find.byTooltip('Lire'));
    final paused = _at(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_at(tester), paused, reason: 'paused: time stands still');
    await tester.tap(find.byTooltip('Lire'));
    await _waitFor(tester, find.byTooltip('Pause'));

    final before = _at(tester);
    await tester.tap(find.byTooltip('Avancer de 10 s'));
    await _waitUntil(tester, () => _at(tester) >= before + 9000, 'forward');
    final ahead = _at(tester);
    await tester.tap(find.byTooltip('Reculer de 10 s'));
    await _waitUntil(tester, () => _at(tester) <= ahead - 8000, 'back');

    await tester.tap(find.byTooltip('Arrêter'));
    await _waitFor(tester, find.byTooltip('Lire'));
    await _waitUntil(tester, () => _at(tester) < 500, 'stop goes to start');

    await tester.tap(find.byTooltip('Répéter : non'));
    await _waitFor(tester, find.byTooltip('Répéter la liste'));
    await tester.tap(find.byTooltip('Lecture aléatoire'));
    await tester.pump(const Duration(milliseconds: 300));
    await _closePlayer(tester);

    // 5. A playlist of my own, with the downloaded file.
    await tester.tap(find.text('Listes · 0'));
    await _waitFor(tester, find.text('Nouvelle liste'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Nouvelle liste'));
    await _waitFor(tester, find.text('Créer'));
    await tester.enterText(find.byType(TextField).last, 'Soirée');
    await tester.tap(find.text('Créer'));
    await _waitFor(tester, find.text('Soirée'));
    await tester.tap(find.text('Titres · 1'));
    await _waitFor(tester, find.text('Tout lire'));
    await tester.pump(const Duration(milliseconds: 600));

    // Its only row: the title also shows in the « now playing » card.
    await tester.tap(find.byTooltip('Actions'));
    await _waitFor(tester, find.text('Ajouter à une liste…'));
    await tester.tap(find.text('Ajouter à une liste…'));
    await _waitFor(tester, find.text('Soirée'));
    await tester.tap(find.text('Soirée'));
    await _waitFor(tester, find.text('Ajouté à « Soirée »'));

    await tester.tap(find.text('Listes · 1'));
    await _waitFor(tester, find.text('Soirée'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Soirée'));
    await _waitFor(tester, find.text('Lecture aléatoire'));
    await tester.tap(find.widgetWithText(FilledButton, 'Tout lire').last);
    await _waitFor(tester, find.byTooltip('Fermer le lecteur'));
    await _openPlayer(tester);
    await _waitPlaying(tester);
    await _closePlayer(tester);
    await tester.tap(find.byTooltip('Fermer le lecteur'));
    await tester.pump(const Duration(milliseconds: 300));

    // 6. Next launch, same store: the playlist is still there.
    await tester.pumpWidget(const SizedBox());
    await store.close();
    final again = Ka7Store.open(file);
    addTearDown(again.close);
    await tester.pumpWidget(_realApp(again, folder.path));
    await _waitFor(tester, find.byType(TextField));
    await tester.tap(_nav('Lecteur'));
    await _waitFor(tester, find.text('Listes · 1'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Listes · 1'));
    await _waitFor(tester, find.text('Soirée'));
    expect(find.text('1 titre'), findsOneWidget);
  });

  testWidgets('plays a folder of my own as a list, subfolders too', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('ka7_folder_e2e_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final music = Directory('${folder.path}/Mahaleo')..createSync();
    Future<void> tone(String path, int hz) async {
      final made = await Process.run('ffmpeg', [
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=$hz:duration=5',
        path,
      ]);
      expect(made.exitCode, 0, reason: '${made.stderr}');
    }

    await tone('${music.path}/2 Veloma.mp3', 440);
    await tone('${music.path}/10 Bonga.mp3', 550);
    Directory('${music.path}/Live').createSync();
    await tone('${music.path}/Live/1 Ny Fitiavana.flac', 660);
    File('${music.path}/cover.jpg').writeAsStringSync('not a song');

    final store = Ka7Store.open(File('${folder.path}/ka7.sqlite'));
    addTearDown(store.close);
    await store.setSetting('language', 'fr');
    await store.setSetting('onboarding.done', '1');
    await tester.pumpWidget(
      _realApp(
        store,
        folder.path,
        pickMediaFolder: (_) async =>
            (folder: music.path, label: 'Musique/Mahaleo'),
      ),
    );
    await _waitFor(tester, find.byType(TextField));
    await tester.tap(_nav('Lecteur'));
    await _waitFor(tester, find.text('Listes · 0'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Listes · 0'));
    await _waitFor(tester, find.text('Ajouter un dossier'));
    await tester.tap(find.text('Ajouter un dossier'));
    await _waitFor(tester, find.text('Musique/Mahaleo'));
    await tester.tap(find.text('Mahaleo'));
    await _waitFor(tester, find.text('2 Veloma'));

    // Files read from the disk, by their place: numbers as numbers, the
    // subfolder after; the picture left out.
    final y = [
      for (final title in ['2 Veloma', '10 Bonga', '1 Ny Fitiavana'])
        tester.getTopLeft(find.text(title)).dy,
    ];
    expect(y, orderedEquals([...y]..sort()));
    expect(find.text('cover'), findsNothing);

    // The FLAC of the subfolder plays, for real.
    await tester.tap(find.text('1 Ny Fitiavana'));
    await _waitFor(tester, find.byTooltip('Fermer le lecteur'));
    await _openPlayer(tester);
    await _waitPlaying(tester);
    expect(find.text('1 Ny Fitiavana'), findsWidgets);
  });
}

Ka7App _realApp(
  Ka7Store store,
  String folder, {
  Future<({String folder, String label})?> Function(String? from)?
  pickMediaFolder,
}) => Ka7App(
  pickMediaFolder: pickMediaFolder,
  listMediaFolder: listFolderMedia,
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
  fileExists: (path, _) => File(path).exists(),
  mediaBackend: MediaKitBackend.new,
);

Finder _nav(String label) => find.descendant(
  of: find.byType(NavigationRail),
  matching: find.text(label),
);

Future<void> _openPlayer(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Ouvrir le lecteur'));
  await _waitFor(tester, find.text('En cours de lecture'));
}

Future<void> _closePlayer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
  await tester.pump(const Duration(milliseconds: 600));
}

/// The video area of the player page carries a picture, not black.
Future<void> _waitPicture(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('video-picture')),
    );
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    for (var p = 0; p < bytes.length; p += 4) {
      if (bytes[p] + bytes[p + 1] + bytes[p + 2] > 60) return;
    }
  }
  throw TestFailure('Black screen: no picture after 20 s');
}

/// Where the full player's slider stands, in milliseconds.
double _at(WidgetTester tester) =>
    tester.widget<Slider>(find.byType(Slider)).value;

/// The real player moves: the slider leaves the start by itself.
Future<void> _waitPlaying(WidgetTester tester) =>
    _waitUntil(tester, () => _at(tester) > 1000, 'playing', timeout: 60);

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() done,
  String what, {
  int timeout = 20,
}) async {
  for (var i = 0; i < timeout * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (done()) return;
  }
  final shown = [
    for (final text in tester.widgetList<Text>(find.byType(Text))) ?text.data,
  ];
  throw TestFailure('Not $what after ${timeout}s\nOn screen: $shown');
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
