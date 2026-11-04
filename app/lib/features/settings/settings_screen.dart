import 'package:flutter/material.dart';
import 'package:ka7_store/ka7_store.dart' show Subscription;
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../../widgets/ka7_logo.dart';
import '../../widgets/ka7_page.dart';

/// Settings, in cards: appearance, downloads, folders, subscriptions, about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.pickFolder,
    this.subscriptions = const [],
    this.onUnfollow,
    this.appVersion,
    this.pickDestination,
    this.defaultDestination,
  });

  /// Android: the system's folder picker, for where files end up.
  final Future<Destination?> Function()? pickDestination;

  /// Where files end up when nothing was chosen (Music/Ka7).
  final String Function(MediaFormat format)? defaultDestination;

  Future<void> _changeDestination(MediaFormat format) async {
    final destination = await pickDestination!();
    if (destination != null) {
      await settings.setDestination(format, destination);
    }
  }

  /// Followed playlists and channels.
  final List<Subscription> subscriptions;
  final void Function(Subscription subscription)? onUnfollow;

  final AppSettings settings;

  /// This build's version; null in development.
  final String? appVersion;

  /// Native folder picker; null when the user closes it.
  final Future<String?> Function()? pickFolder;

  Future<void> _changeFolder(MediaFormat format) async {
    final folder = await pickFolder!();
    if (folder != null) await settings.setFolder(format, folder);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Ka7Page(
        title: l10n.settingsTitle,
        children: [
          _Group(
            icon: Icons.palette_outlined,
            title: l10n.settingsAppearance,
            children: [
              _Setting(
                icon: Icons.translate,
                title: l10n.settingsLanguage,
                below: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: '', label: Text(l10n.languageSystem)),
                    const ButtonSegment(value: 'fr', label: Text('Français')),
                    const ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {settings.language ?? ''},
                  onSelectionChanged: (choice) => settings.setLanguage(
                    choice.single.isEmpty ? null : choice.single,
                  ),
                ),
              ),
              _Setting(
                icon: Icons.contrast,
                title: l10n.settingsTheme,
                below: Row(
                  children: [
                    for (final (mode, label) in [
                      (ThemeMode.system, l10n.themeSystem),
                      (ThemeMode.light, l10n.themeLight),
                      (ThemeMode.dark, l10n.themeDark),
                    ]) ...[
                      if (mode != ThemeMode.system) const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeTile(
                          mode: mode,
                          label: label,
                          selected: settings.theme == mode,
                          onTap: () => settings.setTheme(mode),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          _Group(
            icon: Icons.download_outlined,
            title: l10n.settingsDownloads,
            children: [
              _Setting(
                icon: Icons.account_tree_outlined,
                title: l10n.settingsLayout,
                help: l10n.settingsLayoutHelp,
                below: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (layout, label, folder, file) in [
                      (
                        FolderLayout.playlist,
                        l10n.layoutPlaylist,
                        'Sélection',
                        '01 - Tsara.mp3',
                      ),
                      (
                        FolderLayout.artist,
                        l10n.layoutArtist,
                        'Erick Manana',
                        'Tsara.mp3',
                      ),
                    ]) ...[
                      if (layout == FolderLayout.artist)
                        const SizedBox(width: 10),
                      Expanded(
                        child: _Choice(
                          selected: settings.layout == layout,
                          onTap: () => settings.setLayout(layout),
                          label: label,
                          child: _FolderSample(folder: folder, file: file),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _Setting(
                icon: Icons.stacked_line_chart,
                title: l10n.settingsConcurrency,
                help: l10n.settingsConcurrencyHelp,
                below: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (final count in concurrencyChoices)
                      ButtonSegment(value: count, label: Text('$count')),
                  ],
                  selected: {settings.concurrency},
                  onSelectionChanged: (choice) =>
                      settings.setConcurrency(choice.single),
                ),
              ),
              _Setting(
                icon: Icons.all_inclusive,
                title: l10n.settingsMixLimit,
                help: l10n.settingsMixLimitHelp,
                below: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (final limit in mixLimitChoices)
                      ButtonSegment(value: limit, label: Text('$limit')),
                  ],
                  selected: {settings.mixLimit},
                  onSelectionChanged: (choice) =>
                      settings.setMixLimit(choice.single),
                ),
              ),
            ],
          ),
          if (pickDestination != null)
            _Group(
              icon: Icons.folder_outlined,
              title: l10n.settingsFolders,
              children: [
                for (final (format, icon, label, tooltip) in [
                  (
                    MediaFormat.mp3,
                    Icons.music_note_outlined,
                    l10n.folderMusic,
                    l10n.changeMusicFolder,
                  ),
                  (
                    MediaFormat.mp4,
                    Icons.movie_outlined,
                    l10n.folderVideos,
                    l10n.changeVideosFolder,
                  ),
                ])
                  _Setting(
                    icon: icon,
                    title: label,
                    detail:
                        settings.destinationFor(format)?.label ??
                        defaultDestination?.call(format),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (settings.destinationFor(format) != null)
                          IconButton(
                            tooltip: l10n.resetFolder,
                            onPressed: () =>
                                settings.setDestination(format, null),
                            icon: const Icon(Icons.restart_alt),
                          ),
                        IconButton.filledTonal(
                          tooltip: tooltip,
                          onPressed: () => _changeDestination(format),
                          icon: const Icon(Icons.drive_folder_upload_outlined),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (pickFolder != null)
            _Group(
              icon: Icons.folder_outlined,
              title: l10n.settingsFolders,
              children: [
                for (final (format, icon, label, tooltip) in [
                  (
                    MediaFormat.mp3,
                    Icons.music_note_outlined,
                    l10n.folderMusic,
                    l10n.changeMusicFolder,
                  ),
                  (
                    MediaFormat.mp4,
                    Icons.movie_outlined,
                    l10n.folderVideos,
                    l10n.changeVideosFolder,
                  ),
                ])
                  _Setting(
                    icon: icon,
                    title: label,
                    detail: settings.folderFor(format),
                    trailing: IconButton.filledTonal(
                      tooltip: tooltip,
                      onPressed: () => _changeFolder(format),
                      icon: const Icon(Icons.drive_folder_upload_outlined),
                    ),
                  ),
              ],
            ),
          _Group(
            icon: Icons.notifications_none,
            title: l10n.settingsSubscriptions,
            children: [
              if (subscriptions.isEmpty)
                _Setting(
                  icon: Icons.notifications_off_outlined,
                  title: l10n.subscriptionsEmpty,
                  quiet: true,
                ),
              for (final subscription in subscriptions)
                _Setting(
                  icon: Icons.notifications_active_outlined,
                  title: subscription.title,
                  trailing: IconButton(
                    tooltip: l10n.unfollow,
                    onPressed: onUnfollow == null
                        ? null
                        : () => onUnfollow!(subscription),
                    icon: const Icon(Icons.close),
                  ),
                ),
            ],
          ),
          _Group(
            icon: Icons.info_outline,
            title: l10n.settingsAbout,
            children: [_About(version: appVersion)],
          ),
        ],
      ),
    );
  }
}

/// A titled card of settings, rows apart by a thin line.
class _Group extends StatelessWidget {
  const _Group({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 60),
                  child,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One setting: a soft icon, its name, a short help, its control.
class _Setting extends StatelessWidget {
  const _Setting({
    required this.icon,
    required this.title,
    this.help,
    this.detail,
    this.below,
    this.trailing,
    this.quiet = false,
  });

  final IconData icon;
  final String title;

  /// What it changes, in a sentence.
  final String? help;

  /// Its current value, when shown as text (a folder).
  final String? detail;

  /// The control, under the name (choices).
  final Widget? below;

  /// The control, beside the name (one action).
  final Widget? trailing;

  /// An empty state: muted, no icon tile.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: quiet
                      ? scheme.surfaceContainerHighest
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: quiet ? scheme.onSurfaceVariant : scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: quiet
                          ? theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )
                          : theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    if (detail case final detail?)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          detail,
                          style: muted,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (help case final help?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(help, style: muted),
            ),
          if (below case final below?) ...[const SizedBox(height: 12), below],
        ],
      ),
    );
  }
}

/// A choice drawn as a small card: picked, it takes the accent.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.onTap,
    required this.label,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: duration,
                      child: selected
                          ? Padding(
                              key: const ValueKey(true),
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: scheme.primary,
                              ),
                            )
                          : const SizedBox(key: ValueKey(false)),
                    ),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected ? scheme.primary : scheme.onSurface,
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A theme as a little window in its colours; system is half and half.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Ka7's own colours, light and dark (DESIGN.md).
    const light = (Color(0xFFF7F7FB), Color(0xFFFFFFFF), Color(0xFF4B3FA8));
    const dark = (Color(0xFF111120), Color(0xFF191A2C), Color(0xFFA79BFF));
    Widget window((Color, Color, Color) colors) {
      final (background, surface, accent) = colors;
      return ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                width: 26,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _Choice(
      selected: selected,
      onTap: onTap,
      label: label,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 52,
            child: switch (mode) {
              ThemeMode.light => window(light),
              ThemeMode.dark => window(dark),
              ThemeMode.system => Row(
                children: [
                  Expanded(child: window(light)),
                  Expanded(child: window(dark)),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// What a filed song looks like: its folder, then the file.
class _FolderSample extends StatelessWidget {
  const _FolderSample({required this.folder, required this.file});

  final String folder;
  final String file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodySmall;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, size: 16, color: scheme.secondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    folder,
                    style: style?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.audio_file_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      file,
                      style: style?.copyWith(color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The cassette, the name, the version.
class _About extends StatelessWidget {
  const _About({required this.version});

  final String? version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const ExcludeSemantics(child: Ka7Logo(width: 52)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ka7',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(switch (version) {
                  final version? => l10n.aboutVersion(version),
                  null => l10n.aboutDevVersion,
                }, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  l10n.aboutEngine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
