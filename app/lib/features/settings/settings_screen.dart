import 'package:flutter/material.dart';
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
  });

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
        ],
      ),
    );
  }
}
