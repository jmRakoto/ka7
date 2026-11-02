import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/widgets/ka7_logo.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('reads as Ka7 to screen readers, at the asked width', (
    tester,
  ) async {
    await pumpApp(tester, const Center(child: Ka7Logo(width: 48)));

    expect(find.bySemanticsLabel('Ka7'), findsOneWidget);
    expect(tester.getSize(find.byType(Ka7Logo)), const Size(48, 36));
  });
}
