import 'package:flutter/material.dart';

import '../theme/ka7_theme.dart';

/// Tone of a pill: never carries meaning alone, the label always does.
enum PillTone { neutral, accent, ok, warn, danger }

/// Small rounded label: kind of link, or how a download ended.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = Theme.of(context).extension<Ka7StatusColors>()!;
    final (foreground, background) = switch (tone) {
      PillTone.neutral => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      PillTone.accent => (scheme.onPrimaryContainer, scheme.primaryContainer),
      PillTone.ok => (status.ok, status.okSoft),
      PillTone.warn => (status.warn, status.warnSoft),
      PillTone.danger => (status.danger, status.dangerSoft),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
