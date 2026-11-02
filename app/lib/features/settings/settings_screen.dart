import 'package:flutter/material.dart';
import 'package:ka7_store/ka7_store.dart' show Subscription;
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../../widgets/ka7_page.dart';

/// Language and download folders.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.pickFolder,
    this.subscriptions = const [],
    this.onUnfollow,
  });

  /// Followed playlists and channels.
  final List<Subscription> subscriptions;
  final void Function(Subscription subscription)? onUnfollow;

  final AppSettings settings;

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
          SectionTitle(l10n.settingsLanguage),
          const SizedBox(height: 4),
          SegmentedButton<String>(
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
          const SizedBox(height: 16),
          SectionTitle(l10n.settingsTheme),
          const SizedBox(height: 4),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
            ],
            selected: {settings.theme},
            onSelectionChanged: (choice) => settings.setTheme(choice.single),
          ),
          const SizedBox(height: 16),
          SectionTitle(l10n.settingsLayout),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.settingsLayoutHelp,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SegmentedButton<FolderLayout>(
            segments: [
              ButtonSegment(
                value: FolderLayout.playlist,
                label: Text(l10n.layoutPlaylist),
              ),
              ButtonSegment(
                value: FolderLayout.artist,
                label: Text(l10n.layoutArtist),
              ),
            ],
            selected: {settings.layout},
            onSelectionChanged: (choice) => settings.setLayout(choice.single),
          ),
          const SizedBox(height: 16),
          SectionTitle(l10n.settingsConcurrency),
          const SizedBox(height: 4),
          SegmentedButton<int>(
            segments: [
              for (final count in concurrencyChoices)
                ButtonSegment(value: count, label: Text('$count')),
            ],
            selected: {settings.concurrency},
            onSelectionChanged: (choice) =>
                settings.setConcurrency(choice.single),
          ),
          const SizedBox(height: 16),
          SectionTitle(l10n.settingsMixLimit),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.settingsMixLimitHelp,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SegmentedButton<int>(
            segments: [
              for (final limit in mixLimitChoices)
                ButtonSegment(value: limit, label: Text('$limit')),
            ],
            selected: {settings.mixLimit},
            onSelectionChanged: (choice) => settings.setMixLimit(choice.single),
          ),
          const SizedBox(height: 16),
          if (pickFolder != null)
            for (final (format, label, tooltip) in [
              (MediaFormat.mp3, l10n.folderMusic, l10n.changeMusicFolder),
              (MediaFormat.mp4, l10n.folderVideos, l10n.changeVideosFolder),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                subtitle: Text(settings.folderFor(format)),
                trailing: IconButton(
                  tooltip: tooltip,
                  onPressed: () => _changeFolder(format),
                  icon: const Icon(Icons.drive_folder_upload),
                ),
              ),
          const SizedBox(height: 16),
          SectionTitle(l10n.settingsSubscriptions),
          if (subscriptions.isEmpty)
            Text(
              l10n.subscriptionsEmpty,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          for (final subscription in subscriptions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(subscription.title),
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
    );
  }
}
