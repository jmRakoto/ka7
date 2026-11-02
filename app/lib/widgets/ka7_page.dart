import 'package:flutter/material.dart';

/// Below this width, pages tighten their margins (phone).
const compactWidth = 600.0;

/// Content never gets wider than this: lines stay readable on a big screen.
const _maxContentWidth = 880.0;

/// A section of Ka7: a 26 px title, content at reading width, and an optional
/// sticky footer holding the one main action.
class Ka7Page extends StatelessWidget {
  const Ka7Page({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.showBack = false,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;

  /// Back arrow before the title, for a page pushed over a section.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < compactWidth;
    final side = compact ? 16.0 : 32.0;
    Widget column(Widget child) => Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(side, compact ? 16 : 28, side, 32),
          children: [
            column(
              Row(
                children: [
                  if (showBack) ...[
                    const BackButton(),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final child in children) column(child),
          ],
        ),
      ),
      bottomNavigationBar: footer == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: side, vertical: 12),
                  child: column(footer!),
                ),
              ),
            ),
    );
  }
}

/// Title of a group inside a page: more room above than below.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 6),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
