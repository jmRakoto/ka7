import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/l10n/app_localizations.dart';

/// Pumps [child] inside a MaterialApp with Ka7's translations.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('fr'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
