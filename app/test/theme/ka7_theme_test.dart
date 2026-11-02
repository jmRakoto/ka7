import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/theme/ka7_theme.dart';

import '../helpers/contrast.dart';

void main() {
  test('uses the Nuit d\'encre accent as primary color', () {
    expect(
      ka7Theme(Brightness.light).colorScheme.primary,
      const Color(0xFF4B3FA8),
    );
    expect(
      ka7Theme(Brightness.dark).colorScheme.primary,
      const Color(0xFFA79BFF),
    );
  });

  for (final brightness in Brightness.values) {
    test('keeps every text readable (4.5:1) in ${brightness.name} mode', () {
      final theme = ka7Theme(brightness);
      final scheme = theme.colorScheme;
      final status = theme.extension<Ka7StatusColors>()!;
      final pairs = {
        'text on background': (scheme.onSurface, scheme.surface),
        'muted text on background': (scheme.onSurfaceVariant, scheme.surface),
        'button label on accent': (scheme.onPrimary, scheme.primary),
        'succeeded': (status.ok, status.okSoft),
        'skipped': (status.warn, status.warnSoft),
        'failed': (status.danger, status.dangerSoft),
      };

      pairs.forEach((name, pair) {
        expect(
          contrastRatio(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: name,
        );
      });
    });
  }
}
