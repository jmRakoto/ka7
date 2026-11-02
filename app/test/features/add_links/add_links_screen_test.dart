import 'package:flutter/material.dart';
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
    expect(find.text('Free text: search is not available yet'), findsOneWidget);
    expect(find.text('1 recognized · 1 skipped'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });
}
