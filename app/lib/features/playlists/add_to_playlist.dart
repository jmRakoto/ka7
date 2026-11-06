import 'package:flutter/material.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../l10n/app_localizations.dart';

/// Picks one of the user's playlists, or makes a new one, and adds [track]
/// at its end.
Future<void> addToPlaylist(
  BuildContext context,
  Ka7Store store,
  PlaylistTrack track,
) async {
  final l10n = AppLocalizations.of(context);
  // A folder list follows its folder: nothing to add by hand.
  final playlists = [
    for (final playlist in await store.playlists())
      if (!playlist.isFolder) playlist,
  ];
  if (!context.mounted) return;
  final chosen = await showDialog<Object>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.addToPlaylist),
      children: [
        for (final playlist in playlists)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(playlist),
            child: ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(playlist.name),
              subtitle: Text(l10n.trackCount(playlist.trackCount)),
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(_newPlaylist),
          child: ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.newPlaylist),
          ),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  final (int, String)? target = switch (chosen) {
    final UserPlaylist playlist => (playlist.id, playlist.name),
    _newPlaylist => await _create(context, store),
    _ => null,
  };
  if (target == null) return;
  final (id, name) = target;
  await store.addToPlaylist(id, track);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.addedToPlaylist(name))));
}

const _newPlaylist = #newPlaylist;

Future<(int, String)?> _create(BuildContext context, Ka7Store store) async {
  final l10n = AppLocalizations.of(context);
  final name = await askPlaylistName(
    context,
    title: l10n.newPlaylist,
    action: l10n.createButton,
  );
  if (name == null) return null;
  return (await store.createPlaylist(name), name);
}

/// A playlist's name, typed in a dialog; null when cancelled or empty.
Future<String?> askPlaylistName(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) =>
        _NameDialog(title: title, action: action, initial: initial),
  );
  final trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Owns its field: disposed with the dialog, after its closing animation.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.action,
    required this.initial,
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _field = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _field,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.playlistName),
        onSubmitted: (text) => Navigator.of(context).pop(text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_field.text),
          child: Text(widget.action),
        ),
      ],
    );
  }
}
