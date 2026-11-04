import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/add_links/add_links_screen.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('labels each pasted line with what Ka7 recognized', (
    tester,
  ) async {
    await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));

    await tester.enterText(
      find.byType(TextField),
      'https://youtu.be/Qm7tR2vLx9A\nPLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy\nvimeo.com/123456',
    );
    await tester.pump();

    expect(find.text('Vidéo'), findsOneWidget);
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.text('Ignorée'), findsOneWidget);
    expect(find.text('Seul YouTube est pris en charge'), findsOneWidget);
  });

  testWidgets('enables the preview only once something is recognized', (
    tester,
  ) async {
    await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));
    FilledButton previewButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, "Voir l'aperçu"),
    );

    expect(find.text('Aucune entrée reconnue'), findsOneWidget);
    expect(previewButton().onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      'Qm7tR2vLx9A PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy Mahaleo',
    );
    await tester.pump();

    expect(find.text('2 entrées reconnues · 1 ignorée'), findsOneWidget);
    expect(previewButton().onPressed, isNotNull);
  });

  testWidgets('hands only downloadable entries over to the preview', (
    tester,
  ) async {
    List<MediaEntry>? handedOver;
    await pumpApp(
      tester,
      AddLinksScreen(onPreview: (entries) => handedOver = entries),
    );

    await tester.enterText(
      find.byType(TextField),
      'https://youtu.be/Qm7tR2vLx9A\nQm7tR2vLx9A\nvimeo.com/1\nOLAK5uy_kLoloSyNyTariny0',
    );
    await tester.pump();
    await tester.tap(find.text("Voir l'aperçu"));

    expect(handedOver?.map((e) => e.url), [
      'https://www.youtube.com/watch?v=Qm7tR2vLx9A',
      'https://www.youtube.com/playlist?list=OLAK5uy_kLoloSyNyTariny0',
    ]);
  });

  testWidgets('speaks English when the app language is English', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AddLinksScreen(onPreview: (_) {}),
      locale: const Locale('en'),
    );

    await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A Mahaleo');
    await tester.pump();

    expect(find.text('Video'), findsOneWidget);
    expect(
      find.text('Not a link: to search, use “YouTube search”'),
      findsOneWidget,
    );
    expect(find.text('1 recognized · 1 skipped'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });

  group('clear', () {
    testWidgets('empties the field and the recognized list', (tester) async {
      await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));
      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');
      await tester.pump();

      await tester.tap(find.text('Effacer'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Vidéo'), findsNothing);
      expect(find.text('Aucune entrée reconnue'), findsOneWidget);
    });

    testWidgets('is off while there is nothing to clear', (tester) async {
      await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));

      final clear = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Effacer'),
          matching: find.byWidgetPredicate((w) => w is TextButton),
        ),
      );
      expect(clear.onPressed, isNull);
    });
  });

  group('import', () {
    testWidgets('adds the links of the chosen file below the field', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AddLinksScreen(
          onPreview: (_) {},
          pickLinksFile: () async =>
              '# Mahaleo\nPLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy\n',
        ),
      );
      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');
      await tester.pump();

      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Qm7tR2vLx9A\n# Mahaleo\nPLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
      );
      expect(find.text('2 entrées reconnues'), findsOneWidget);
    });

    testWidgets('changes nothing when the picker is closed', (tester) async {
      await pumpApp(
        tester,
        AddLinksScreen(onPreview: (_) {}, pickLinksFile: () async => null),
      );
      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');

      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Qm7tR2vLx9A',
      );
    });

    testWidgets('is not offered where no file can be picked', (tester) async {
      await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));

      expect(find.text('Importer'), findsNothing);
    });
  });

  testWidgets('says how many videos of a mix will be read', (tester) async {
    await pumpApp(tester, AddLinksScreen(onPreview: (_) {}, mixLimit: 100));

    await tester.enterText(find.byType(TextField), 'RDHb8sJ1kP0wE');
    await tester.pump();

    expect(find.text('Mix · 100 max'), findsOneWidget);
  });

  testWidgets('ignores a pasted message, pointing to the search', (
    tester,
  ) async {
    await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));

    await tester.enterText(
      find.byType(TextField),
      'Bonsoir,\nManao point miaraka amin DG',
    );
    await tester.pump();

    expect(find.text('Recherche'), findsNothing);
    expect(find.text('Ignorée'), findsNWidgets(2));
    expect(
      find.text('Pas un lien : pour chercher, passe par « Recherche YouTube »'),
      findsNWidgets(2),
    );
    expect(find.text('Aucune entrée reconnue'), findsOneWidget);
  });

  group('search mode', () {
    testWidgets('searches YouTube for what the user types', (tester) async {
      List<MediaEntry>? handedOver;
      await pumpApp(
        tester,
        AddLinksScreen(onPreview: (entries) => handedOver = entries),
      );

      await tester.tap(find.text('Recherche YouTube'));
      await tester.pumpAndSettle();
      expect(find.text('Importer'), findsNothing);
      await tester.enterText(find.byType(TextField), '  Erick Manana ');
      await tester.pump();
      await tester.tap(find.text('Rechercher'));

      final search = handedOver!.single as SearchEntry;
      expect(search.query, 'Erick Manana');
    });

    testWidgets('searches only once something is typed', (tester) async {
      await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));
      await tester.tap(find.text('Recherche YouTube'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Rechercher'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('keeps the pasted links when switching back', (tester) async {
      await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));
      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');
      await tester.tap(find.text('Recherche YouTube'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liens'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Qm7tR2vLx9A',
      );
      expect(find.text('Vidéo'), findsOneWidget);
    });
  });

  testWidgets('is titled Add, whatever the mode', (tester) async {
    await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));

    expect(find.text('Ajouter'), findsOneWidget);
    await tester.tap(find.text('Recherche YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter'), findsOneWidget);
  });

  group('helps', () {
    testWidgets('pastes the clipboard below what is there', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? {'text': 'https://youtu.be/Qm7tR2vLx9A'}
            : null,
      );
      await pumpApp(tester, AddLinksScreen(onPreview: (_) {}));
      await tester.enterText(
        find.byType(TextField),
        'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
      );

      await tester.tap(find.text('Coller'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy\nhttps://youtu.be/Qm7tR2vLx9A',
      );
      expect(find.text('Vidéo'), findsOneWidget);
    });

    testWidgets('tells every way to add while the field is empty', (
      tester,
    ) async {
      await pumpApp(tester, AddLinksScreen(onPreview: (_) {}, canShare: true));

      expect(find.textContaining('Un lien par ligne'), findsOneWidget);
      expect(find.textContaining('Partager'), findsOneWidget);
      expect(find.textContaining('Glisse'), findsNothing, reason: 'phone');

      await tester.enterText(find.byType(TextField), 'Qm7tR2vLx9A');
      await tester.pumpAndSettle();
      expect(find.textContaining('Un lien par ligne'), findsNothing);
    });

    testWidgets('searches again in one tap', (tester) async {
      List<MediaEntry>? handedOver;
      await pumpApp(
        tester,
        AddLinksScreen(
          onPreview: (entries) => handedOver = entries,
          recentSearches: const ['Mahaleo', 'Erick Manana'],
        ),
      );
      await tester.tap(find.text('Recherche YouTube'));
      await tester.pumpAndSettle();

      expect(find.text('Recherches récentes'), findsOneWidget);
      await tester.tap(find.text('Erick Manana'));

      expect((handedOver!.single as SearchEntry).query, 'Erick Manana');
    });

    testWidgets('forgets the recent searches when asked', (tester) async {
      var cleared = false;
      await pumpApp(
        tester,
        AddLinksScreen(
          onPreview: (_) {},
          recentSearches: const ['Mahaleo'],
          onClearRecent: () => cleared = true,
        ),
      );
      await tester.tap(find.text('Recherche YouTube'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Effacer les recherches récentes'));

      expect(cleared, isTrue);
    });
  });
}
