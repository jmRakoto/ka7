import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/l10n/app_localizations.dart';
import 'package:ka7/theme/ka7_theme.dart';

/// Pumps [child] inside a MaterialApp with Ka7's theme and translations.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('fr'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ka7Theme(Brightness.light),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
