import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/widgets/appear.dart';

void main() {
  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byType(Appear),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;

  testWidgets('fades in, then stays', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Appear(index: 3, child: Text('Hafatra')),
      ),
    );
    expect(opacity(tester), 0);

    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets('shows at once when the system asks for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Appear(index: 3, child: Text('Hafatra')),
        ),
      ),
    );

    expect(opacity(tester), 1);
  });
}
