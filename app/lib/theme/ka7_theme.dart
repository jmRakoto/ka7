import 'package:flutter/material.dart';

/// Ka7 theme for [brightness] (palette Nuit d'encre, see DESIGN.md).
ThemeData ka7Theme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: light ? const Color(0xFF4B3FA8) : const Color(0xFFA79BFF),
    onPrimary: light ? const Color(0xFFFFFFFF) : const Color(0xFF15122E),
    primaryContainer: light ? const Color(0xFFECEBFA) : const Color(0xFF25234A),
    onPrimaryContainer: light
        ? const Color(0xFF4B3FA8)
        : const Color(0xFFB9AFFF),
    secondary: light ? const Color(0xFF9B8CF0) : const Color(0xFF6C5FD6),
    onSecondary: light ? const Color(0xFF1B1B2F) : const Color(0xFFECECF6),
    error: light ? const Color(0xFFA3333F) : const Color(0xFFF2919C),
    onError: light ? const Color(0xFFFFFFFF) : const Color(0xFF3A1F26),
    surface: light ? const Color(0xFFF7F7FB) : const Color(0xFF111120),
    onSurface: light ? const Color(0xFF1B1B2F) : const Color(0xFFECECF6),
    onSurfaceVariant: light ? const Color(0xFF5C5C78) : const Color(0xFFA6A6C4),
    surfaceContainerLowest: light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF191A2C),
    surfaceContainerHighest: light
        ? const Color(0xFFEEEEF6)
        : const Color(0xFF212238),
    outline: light ? const Color(0xFFCFCFE2) : const Color(0xFF3A3C5C),
    outlineVariant: light ? const Color(0xFFE2E2EE) : const Color(0xFF2C2D46),
  );
  const controls = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(9)),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [light ? _statusLight : _statusDark],
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 6,
      borderRadius: const BorderRadius.all(Radius.circular(3)),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(controls),
        padding: WidgetStatePropertyAll(buttonPadding),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(controls),
        padding: WidgetStatePropertyAll(buttonPadding),
      ),
    ),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(controls)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(9)),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(9)),
        borderSide: BorderSide(color: scheme.outline),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

const _statusLight = Ka7StatusColors(
  ok: Color(0xFF2D6B4F),
  okSoft: Color(0xFFE0F1E8),
  warn: Color(0xFF8A5A12),
  warnSoft: Color(0xFFFBEFD6),
  danger: Color(0xFFA3333F),
  dangerSoft: Color(0xFFFBE5E8),
);

const _statusDark = Ka7StatusColors(
  ok: Color(0xFF86D1AA),
  okSoft: Color(0xFF1C3128),
  warn: Color(0xFFE8BF73),
  warnSoft: Color(0xFF352C1B),
  danger: Color(0xFFF2919C),
  dangerSoft: Color(0xFF3A1F26),
);

/// Colors of the report states: succeeded, skipped, failed.
@immutable
class Ka7StatusColors extends ThemeExtension<Ka7StatusColors> {
  const Ka7StatusColors({
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
  });

  final Color ok, okSoft, warn, warnSoft, danger, dangerSoft;

  @override
  Ka7StatusColors copyWith({
    Color? ok,
    Color? okSoft,
    Color? warn,
    Color? warnSoft,
    Color? danger,
    Color? dangerSoft,
  }) => Ka7StatusColors(
    ok: ok ?? this.ok,
    okSoft: okSoft ?? this.okSoft,
    warn: warn ?? this.warn,
    warnSoft: warnSoft ?? this.warnSoft,
    danger: danger ?? this.danger,
    dangerSoft: dangerSoft ?? this.dangerSoft,
  );

  @override
  Ka7StatusColors lerp(Ka7StatusColors? other, double t) {
    if (other == null) return this;
    return Ka7StatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      okSoft: Color.lerp(okSoft, other.okSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
    );
  }
}
