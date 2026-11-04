import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/preview/loading.dart';
import 'package:ka7/features/preview/preview_screen.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../helpers/fake_extractor.dart';
import '../../helpers/probes.dart';
import '../../helpers/pump_app.dart';

MediaEntry entryOf(String input) => parseEntry(input) as MediaEntry;

/// Videos already downloaded, per format.
class _Archive implements Archive {
  _Archive(this.kept);

  final Set<(String, MediaFormat)> kept;

  @override
  Future<bool> contains(String videoId, MediaFormat format) async =>
      kept.contains((videoId, format));

  @override
  Future<void> add(String videoId, MediaFormat format) async =>
      kept.add((videoId, format));
}

/// Answers only when told to.
class _Pending implements Extractor {
  final answers = <String, Completer<Probe>>{};

  @override
  String get name => 'pending';

  @override
  Future<Probe> probe(MediaEntry entry) =>
      (answers[entry.url] = Completer<Probe>()).future;
}

void main() {
  final playlist = entryOf('PLe7rK2mErickManana01');
  final video = entryOf('Qm7tR2vLx9A');
  final extractor = FakeExtractor({
    playlist.url: ericMananaPlaylist,
    video.url: hafatraVideo,
  });

  testWidgets('lists what each link contains, with durations', (tester) async {
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [playlist, video],
        extractor: extractor,
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Erick Manana · Sélection'), findsOneWidget);
    expect(find.text("Tsara Ny Hiran' Ny Taniko"), findsOneWidget);
    expect(find.text('4:12'), findsOneWidget);
    expect(find.text('Tsy Ferana'), findsOneWidget);
    expect(find.text('Hafatra'), findsNWidgets(2));
    expect(find.text('3:12'), findsOneWidget);
  });

  testWidgets('checks available videos and locks out unreachable ones', (
    tester,
  ) async {
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [playlist],
        extractor: extractor,
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();
    CheckboxListTile row(String text) =>
        tester.widget(find.widgetWithText(CheckboxListTile, text));

    expect(find.text('[Private video]'), findsNothing);
    expect(row('Tsy Ferana').value, isTrue);
    expect(row('Vidéo privée').value, isFalse);
    expect(row('Vidéo privée').onChanged, isNull);
    expect(row('Vidéo indisponible').value, isFalse);
    expect(row('Vidéo indisponible').onChanged, isNull);
  });

  testWidgets('totals the checked videos and follows the checkboxes', (
    tester,
  ) async {
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [playlist, video],
        extractor: extractor,
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 titres · 13 min'), findsOneWidget);

    await tester.tap(find.text('Tsy Ferana'));
    await tester.pump();

    expect(find.text('2 titres · 7 min'), findsOneWidget);
  });

  testWidgets('shows why a link could not be read, without blocking others', (
    tester,
  ) async {
    final broken = entryOf('zA1bC3dE5fG');
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [broken, video],
        extractor: FakeExtractor({
          broken.url: const ProbeFailure(FailureReason.network),
          video.url: hafatraVideo,
        }),
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('zA1bC3dE5fG'), findsOneWidget);
    expect(find.text('Pas de connexion à YouTube'), findsOneWidget);
    expect(find.text('3:12'), findsOneWidget);
  });

  testWidgets('hands the checked videos over with their source and position', (
    tester,
  ) async {
    List<PlannedDownload>? planned;
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [playlist, video],
        extractor: extractor,
        onDownload: (downloads, _) => planned = downloads,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Tsara Ny Hiran' Ny Taniko"));
    await tester.pump();
    await tester.tap(find.text('Télécharger'));

    expect(planned?.map((p) => (p.source.title, p.index, p.item.title)), [
      ('Erick Manana · Sélection', 2, 'Tsy Ferana'),
      ('Hafatra', 1, 'Hafatra'),
    ]);
  });

  testWidgets('downloads as MP3 unless the user picks MP4', (tester) async {
    final formats = <MediaFormat>[];
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [video],
        extractor: extractor,
        onDownload: (_, format) => formats.add(format),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Télécharger'));
    await tester.tap(find.text('MP4 · vidéo'));
    await tester.pump();
    await tester.tap(find.text('Télécharger'));

    expect(formats, [MediaFormat.mp3, MediaFormat.mp4]);
  });

  testWidgets('offers only the formats the engine can make', (tester) async {
    final formats = <MediaFormat>[];
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [video],
        extractor: extractor,
        formats: const [MediaFormat.m4a, MediaFormat.mp4],
        onDownload: (_, format) => formats.add(format),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MP3 · audio'), findsNothing);
    await tester.tap(find.text('Télécharger'));

    expect(formats, [MediaFormat.m4a]);
    expect(find.text("M4A · d'origine"), findsOneWidget);
  });

  testWidgets('never drops a link silently, even on an unexpected error', (
    tester,
  ) async {
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [video],
        extractor: FakeExtractor({video.url: StateError('engine bug')}),
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Qm7tR2vLx9A'), findsOneWidget);
    expect(find.text('Lecture impossible'), findsOneWidget);
  });

  testWidgets('follows what becomes of each video sent to the queue', (
    tester,
  ) async {
    final statuses = <String, RunItemStatus>{};
    final archive = _Archive({});
    final changes = ValueNotifier(0);
    addTearDown(changes.dispose);
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [playlist],
        extractor: extractor,
        archive: archive,
        queueStatus: (id, format) =>
            format == MediaFormat.mp3 ? statuses[id] : null,
        queueChanges: changes,
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();
    Future<void> becomes(RunItemStatus status) async {
      statuses['aB3dE5fG7hI'] = status;
      changes.value++;
      await tester.pumpAndSettle();
    }

    await becomes(RunItemStatus.running);
    expect(find.text('Dans la file'), findsOneWidget);
    await becomes(RunItemStatus.failed);
    expect(find.text('Dans la file'), findsNothing);
    expect(find.text('Échoué'), findsOneWidget);
    await archive.add('aB3dE5fG7hI', MediaFormat.mp3);
    await becomes(RunItemStatus.succeeded);
    await tester.pumpAndSettle();
    expect(find.text('Réussi'), findsOneWidget);
    archive.kept.clear();
    changes.value++;
    await tester.pumpAndSettle();
    expect(find.text('Réussi'), findsNothing, reason: 'file deleted since');
    await becomes(RunItemStatus.cancelled);
    expect(find.text('Réussi'), findsNothing);
    expect(find.text('Annulé'), findsNothing, reason: 'free to pick again');

    await tester.tap(find.text('MP4 · vidéo'));
    await tester.pumpAndSettle();
    await becomes(RunItemStatus.running);
    expect(find.text('Dans la file'), findsNothing, reason: 'other format');
  });

  group('loading', () {
    testWidgets('shows what is being read, with rows to come', (tester) async {
      final pending = _Pending();
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [video],
          extractor: pending,
          onDownload: (_, _) {},
        ),
      );
      await tester.pump();

      expect(find.text('Lecture du lien…'), findsOneWidget);
      expect(find.byType(LoadingRows), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      pending.answers[video.url]!.complete(hafatraVideo);
      await tester.pumpAndSettle();
      expect(find.byType(LoadingRows), findsNothing);
      expect(find.text('Hafatra'), findsNWidgets(2));
    });

    testWidgets('a search glows around its field while it runs', (
      tester,
    ) async {
      const search = SearchEntry('Hafatra', query: 'Hafatra');
      final pending = _Pending();
      await pumpApp(
        tester,
        PreviewScreen(
          entries: const [search],
          extractor: pending,
          onDownload: (_, _) {},
        ),
      );
      await tester.pump();

      expect(find.text('Recherche de « Hafatra »…'), findsOneWidget);
      bool glowing() =>
          tester.widget<SearchGlow>(find.byType(SearchGlow)).active;
      expect(glowing(), isTrue);

      pending.answers[search.url]!.complete(
        Probe(title: 'Hafatra', isSearch: true, items: hafatraVideo.items),
      );
      await tester.pumpAndSettle();
      expect(glowing(), isFalse);
    });
  });

  group('already downloaded', () {
    CheckboxListTile row(WidgetTester tester, String text) =>
        tester.widget(find.widgetWithText(CheckboxListTile, text));

    testWidgets('unchecks videos already there in the chosen format', (
      tester,
    ) async {
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [playlist],
          extractor: extractor,
          archive: _Archive({('aB3dE5fG7hI', MediaFormat.mp3)}),
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(row(tester, "Tsara Ny Hiran' Ny Taniko").value, isFalse);
      expect(find.text('Déjà là'), findsOneWidget);
      expect(row(tester, 'Tsy Ferana').value, isTrue);
      expect(find.text('1 titre · 6 min'), findsOneWidget);
    });

    testWidgets('checks them again in a format not downloaded yet', (
      tester,
    ) async {
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [playlist],
          extractor: extractor,
          archive: _Archive({('aB3dE5fG7hI', MediaFormat.mp3)}),
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('MP4 · vidéo'));
      await tester.pumpAndSettle();

      expect(row(tester, "Tsara Ny Hiran' Ny Taniko").value, isTrue);
      expect(find.text('Déjà là'), findsNothing);
    });

    testWidgets('keeps what the user unchecked when the format changes', (
      tester,
    ) async {
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [playlist],
          extractor: extractor,
          archive: _Archive({}),
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tsy Ferana'));
      await tester.pump();
      await tester.tap(find.text('MP4 · vidéo'));
      await tester.pumpAndSettle();

      expect(row(tester, 'Tsy Ferana').value, isFalse);
      expect(row(tester, "Tsara Ny Hiran' Ny Taniko").value, isTrue);
    });

    testWidgets('keeps checked search results when the format changes', (
      tester,
    ) async {
      const search = SearchEntry('Hafatra', query: 'Hafatra');
      List<PlannedDownload>? planned;
      MediaFormat? chosen;
      await pumpApp(
        tester,
        PreviewScreen(
          entries: const [search],
          extractor: FakeExtractor({
            search.url: Probe(
              title: 'Hafatra',
              isSearch: true,
              items: [...hafatraVideo.items, ...ericMananaPlaylist.items],
            ),
          }),
          archive: _Archive({}),
          onDownload: (kept, format) {
            planned = kept;
            chosen = format;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tsy Ferana'));
      await tester.pump();
      await tester.tap(find.text('MP4 · vidéo'));
      await tester.pumpAndSettle();

      expect(row(tester, 'Tsy Ferana').value, isTrue);
      await tester.tap(find.textContaining('Télécharger'));
      await tester.pump();
      expect(planned!.map((p) => p.item.title), ['Tsy Ferana']);
      expect(chosen, MediaFormat.mp4);
    });

    testWidgets('unchecks a picked video already there in the new format', (
      tester,
    ) async {
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [playlist],
          extractor: extractor,
          archive: _Archive({('aB3dE5fG7hI', MediaFormat.mp4)}),
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('MP4 · vidéo'));
      await tester.pumpAndSettle();

      expect(row(tester, "Tsara Ny Hiran' Ny Taniko").value, isFalse);
      expect(find.text('Déjà là'), findsOneWidget);
    });
  });

  testWidgets('one box checks or unchecks every video of a playlist', (
    tester,
  ) async {
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [playlist],
        extractor: extractor,
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();
    bool? checked(String text) => tester
        .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, text))
        .value;

    expect(checked('Tout sélectionner'), isTrue);

    await tester.tap(find.text('Tout sélectionner'));
    await tester.pump();
    expect(checked("Tsara Ny Hiran' Ny Taniko"), isFalse);
    expect(checked('Tsy Ferana'), isFalse);
    expect(checked('Tout sélectionner'), isFalse);
    expect(find.textContaining('0 titre'), findsOneWidget);

    await tester.tap(find.text('Tsy Ferana'));
    await tester.pump();
    expect(checked('Tout sélectionner'), isNull, reason: 'partly checked');

    await tester.tap(find.text('Tout sélectionner'));
    await tester.pump();
    expect(checked("Tsara Ny Hiran' Ny Taniko"), isTrue);
    expect(checked('Tsy Ferana'), isTrue);
    expect(checked('Vidéo privée'), isFalse);
  });

  testWidgets('lists search results unchecked, for the user to pick', (
    tester,
  ) async {
    const search = SearchEntry('Hafatra', query: 'Hafatra');
    await pumpApp(
      tester,
      PreviewScreen(
        entries: const [search],
        extractor: FakeExtractor({
          search.url: Probe(
            title: 'Hafatra',
            isSearch: true,
            items: [...hafatraVideo.items, ...ericMananaPlaylist.items.take(2)],
          ),
        }),
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recherche : Hafatra'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Tsy Ferana'),
          )
          .value,
      isFalse,
    );
    expect(find.textContaining('0 titre'), findsOneWidget);
  });

  testWidgets('tells each new search, to remember it', (tester) async {
    const first = SearchEntry('Hafatra', query: 'Hafatra');
    final searched = <String>[];
    await pumpApp(
      tester,
      PreviewScreen(
        entries: const [first],
        extractor: FakeExtractor({
          first.url: Probe(
            title: 'Hafatra',
            isSearch: true,
            items: hafatraVideo.items,
          ),
        }),
        onSearch: searched.add,
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Tsy   Ferana ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(searched, ['Tsy Ferana']);
  });

  testWidgets('searches again from the preview, keeping what is checked', (
    tester,
  ) async {
    const first = SearchEntry('Hafatra', query: 'Hafatra');
    const second = SearchEntry('Tsy Ferana', query: 'Tsy Ferana');
    List<PlannedDownload>? planned;
    await pumpApp(
      tester,
      PreviewScreen(
        entries: const [first],
        extractor: FakeExtractor({
          first.url: Probe(
            title: 'Hafatra',
            isSearch: true,
            items: hafatraVideo.items,
          ),
          second.url: Probe(
            title: 'Tsy Ferana',
            isSearch: true,
            items: [ericMananaPlaylist.items[1]],
          ),
        }),
        onDownload: (downloads, _) => planned = downloads,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Hafatra'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Tsy Ferana');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Tsy Ferana'));
    await tester.pump();
    await tester.tap(find.text('Télécharger'));

    expect(find.text('Recherche : Tsy Ferana'), findsOneWidget);
    expect(find.text('Recherche : Hafatra'), findsOneWidget);
    expect(planned!.map((p) => p.item.videoId).toSet(), {
      'Qm7tR2vLx9A',
      'jK9lM1nO3pQ',
    });
  });

  testWidgets('offers no search field when previewing links', (tester) async {
    await pumpApp(
      tester,
      PreviewScreen(
        entries: [playlist],
        extractor: extractor,
        onDownload: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });

  group('thumbnails', () {
    /// A 1×1 transparent PNG: no network in tests.
    final pixel = Uint8List.fromList(const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);

    testWidgets('shows each available video with its thumbnail', (
      tester,
    ) async {
      final asked = <String>[];
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [playlist],
          extractor: extractor,
          thumbnail: (videoId) {
            asked.add(videoId);
            return MemoryImage(pixel);
          },
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(asked, ['aB3dE5fG7hI', 'jK9lM1nO3pQ']);
      expect(
        find.descendant(
          of: find.widgetWithText(CheckboxListTile, 'Tsy Ferana'),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
    });

    testWidgets('opens a larger view on a long press on the picture', (
      tester,
    ) async {
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [playlist],
          extractor: extractor,
          thumbnail: (_) => MemoryImage(pixel),
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();
      final picture = find.descendant(
        of: find.widgetWithText(CheckboxListTile, 'Tsy Ferana'),
        matching: find.byType(Image),
      );

      await tester.longPress(picture);
      await tester.pumpAndSettle();

      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Tsy Ferana')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('5:41')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Tsy Ferana'),
            )
            .value,
        isTrue,
        reason: 'looking does not uncheck',
      );

      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
    });

    testWidgets('shows none where no thumbnail is given', (tester) async {
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [playlist],
          extractor: extractor,
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
    });
  });

  group('long titles', () {
    const long =
        "SAO DIA ATAON'IALAHY HOE Mahaleo Live @ Olympia, Paris, 19 novembre "
        '2011, version intégrale avec le public';
    final entry = entryOf('Xy7zA9bC1dE');

    Future<void> pumpLong(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(400, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(
        tester,
        PreviewScreen(
          entries: [entry],
          extractor: FakeExtractor({
            entry.url: const Probe(
              title: 'Olympia',
              items: [ProbeItem(videoId: 'Xy7zA9bC1dE', title: long)],
            ),
          }),
          onDownload: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('cuts a long title at two lines', (tester) async {
      await pumpLong(tester);

      final title = tester.widget<Text>(find.text(long));
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('a long press on the title opens the larger view', (
      tester,
    ) async {
      await pumpLong(tester);

      await tester.longPress(find.text(long));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text(long)),
        findsOneWidget,
        reason: 'the same view as a long press on the picture',
      );
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      final box = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(box.value, isTrue, reason: 'a long press does not uncheck');
    });
  });
}
