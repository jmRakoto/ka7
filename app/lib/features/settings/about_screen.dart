import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ka7_logo.dart';
import '../../widgets/ka7_page.dart';

/// About Ka7: what it is, its version, what it does, who makes it.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.version});

  /// This build's version; null in development.
  final String? version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Ka7Page(
      title: l10n.aboutTitle,
      showBack: true,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              children: [
                const ExcludeSemantics(child: Ka7Logo(width: 112)),
                const SizedBox(height: 20),
                Text(
                  'Ka7',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(switch (version) {
                  final version? => l10n.aboutVersion(version),
                  null => l10n.aboutDevVersion,
                }, style: muted),
                const SizedBox(height: 16),
                Text(
                  l10n.aboutTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(
                    l10n.aboutDescription,
                    textAlign: TextAlign.center,
                    style: muted?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _Heading(icon: Icons.auto_awesome_outlined, text: l10n.aboutFeatures),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (icon, title, body)) in [
                (Icons.add_link, l10n.featureAddTitle, l10n.featureAddBody),
                (
                  Icons.checklist,
                  l10n.featurePreviewTitle,
                  l10n.featurePreviewBody,
                ),
                (Icons.tune, l10n.featureFormatTitle, l10n.featureFormatBody),
                (
                  Icons.folder_outlined,
                  l10n.featureFilesTitle,
                  l10n.featureFilesBody,
                ),
                (
                  Icons.downloading,
                  l10n.featureQueueTitle,
                  l10n.featureQueueBody,
                ),
                (
                  Icons.library_music_outlined,
                  l10n.featureLibraryTitle,
                  l10n.featureLibraryBody,
                ),
                (
                  Icons.notifications_none,
                  l10n.featureFollowTitle,
                  l10n.featureFollowBody,
                ),
              ].indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 62),
                _Line(icon: icon, title: title, text: body),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Line(icon: Icons.person_outline, text: l10n.aboutMadeBy),
              const Divider(height: 1, indent: 62),
              _Line(icon: Icons.lock_outline, text: l10n.aboutPrivate),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '© 2026 Rakoto Ketrika',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A section title above a card, like the Settings groups.
class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line in a card: a soft icon, an optional bold title, its text.
class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.title});

  final IconData icon;
  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = this.title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: title == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 19, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: title == null
                ? Text(text)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
