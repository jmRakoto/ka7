import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/add_links/add_links_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('labels each pasted line with what Ka7 recognized', (
    tester,
  ) async {
    await pumpApp(tester, const AddLinksScreen());

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
    await pumpApp(tester, const AddLinksScreen());
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
}
