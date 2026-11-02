import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
