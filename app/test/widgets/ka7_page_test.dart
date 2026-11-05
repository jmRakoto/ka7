import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/widgets/ka7_page.dart';

import '../helpers/pump_app.dart';

void main() {
  Future<void> pumpLongPage(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      Ka7Page(
        title: 'Bibliothèque',
        children: [
          for (var i = 0; i < 200; i++)
            SizedBox(key: ValueKey(i), height: 72, child: Text('Ligne $i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  double opacityOf(WidgetTester tester, String text) => tester
      .widgetList<FadeTransition>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(FadeTransition),
        ),
      )
      .fold(1, (shown, fade) => shown * fade.opacity.value);

  testWidgets('rows reached by scrolling show at once, never blank', (
    tester,
  ) async {
    await pumpLongPage(tester);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -6000));
    await tester.pump();

    final row = find.textContaining('Ligne ').first;
    final text = (tester.widget<Text>(row)).data!;
    expect(opacityOf(tester, text), 1);
  });

  testWidgets('goes back to the top from far down', (tester) async {
    await pumpLongPage(tester);
    expect(find.byTooltip('Revenir en haut'), findsNothing);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -6000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Revenir en haut'));
    await tester.pumpAndSettle();

    expect(find.text('Ligne 0'), findsOneWidget);
    expect(find.byTooltip('Revenir en haut'), findsNothing);
  });

  testWidgets('a long page has a scrollbar to drag', (tester) async {
    await pumpLongPage(tester);

    final bar = tester.widget<Scrollbar>(find.byType(Scrollbar).first);
    expect(bar.interactive, isTrue);
  });
}
