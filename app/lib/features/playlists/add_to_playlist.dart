import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
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

/// Downloaded files, newest first, each title and format once.
Future<List<PlaylistTrack>> libraryTracks(Ka7Store store) async {
  final seen = <(String, MediaFormat)>{};
  return [
    for (final item in await store.history())
      if (item.status == HistoryStatus.succeeded &&
          item.path != null &&
          seen.add((item.videoId, item.format)))
        PlaylistTrack.of(item),
  ];
}

/// A file of a folder, as a playlist keeps it: no YouTube id, its address
/// stands for one.
PlaylistTrack trackOfFile(MediaFile file) {
  final extension = file.name.split('.').last.toLowerCase();
  return PlaylistTrack(
    videoId: file.path,
    title: file.title,
    format: file.isVideo
        ? MediaFormat.mp4
        : extension == 'm4a'
        ? MediaFormat.m4a
        : MediaFormat.mp3,
    path: file.path,
  );
}

/// Lets the user tick tracks to add, from the downloaded [library] or from
/// a folder they pick; null when cancelled. Tracks whose path is in
/// [present] are left out.
Future<List<PlaylistTrack>?> pickTracks(
  BuildContext context, {
  required List<PlaylistTrack> library,
  Set<String> present = const {},
  Future<({String folder, String label})?> Function()? pickFolder,
  Future<List<MediaFile>> Function(String folder)? listFolder,
}) => showDialog<List<PlaylistTrack>>(
  context: context,
  builder: (context) => _TrackPicker(
    library: [
      for (final track in library)
        if (!present.contains(track.path)) track,
    ],
    present: present,
    pickFolder: listFolder == null ? null : pickFolder,
    listFolder: listFolder,
  ),
);

enum _Source { library, folder }

class _TrackPicker extends StatefulWidget {
  const _TrackPicker({
    required this.library,
    required this.present,
    required this.pickFolder,
    required this.listFolder,
  });

  final List<PlaylistTrack> library;
  final Set<String> present;
  final Future<({String folder, String label})?> Function()? pickFolder;
  final Future<List<MediaFile>> Function(String folder)? listFolder;

  @override
  State<_TrackPicker> createState() => _TrackPickerState();
}

class _TrackPickerState extends State<_TrackPicker> {
  var _source = _Source.library;
  var _search = '';

  /// In the order they were shown, whatever the source or the search.
  final _ticked = <PlaylistTrack>{};

  String? _folderLabel;
  List<PlaylistTrack> _folderTracks = const [];

  Future<void> _chooseFolder() async {
    final picked = await widget.pickFolder!();
    if (picked == null) return;
    final files = await widget.listFolder!(picked.folder);
    if (!mounted) return;
    setState(() {
      _folderLabel = picked.label;
      _folderTracks = [
        for (final file in files)
          if (!widget.present.contains(file.path)) trackOfFile(file),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = [...widget.library, ..._folderTracks];
    final shown = [
      for (final track in switch (_source) {
        _Source.library => widget.library,
        _Source.folder => _folderTracks,
      })
        if (holdsWords(track.title, _search)) track,
    ];
    return AlertDialog(
      title: Text(l10n.addTracksTitle),
      content: SizedBox(
        width: 480,
        height: 460,
        child: Column(
          children: [
            if (widget.pickFolder != null) ...[
              SegmentedButton<_Source>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _Source.library,
                    icon: const Icon(Icons.library_music_outlined),
                    label: Text(l10n.addTracksLibrary),
                  ),
                  ButtonSegment(
                    value: _Source.folder,
                    icon: const Icon(Icons.folder_outlined),
                    label: Text(l10n.addTracksFolder),
                  ),
                ],
                selected: {_source},
                onSelectionChanged: (value) =>
                    setState(() => _source = value.single),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              onChanged: (text) => setState(() => _search = text),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.playerSearch,
              ),
            ),
            if (_source == _Source.folder) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _chooseFolder,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: Text(_folderLabel ?? l10n.addTracksChooseFolder),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(switch ((_source, _search.isEmpty)) {
                        (_Source.folder, _) when _folderLabel == null => '',
                        (_, false) => l10n.playerNoMatch,
                        _ => l10n.addTracksNone,
                      }, textAlign: TextAlign.center),
                    )
                  : ListView(
                      children: [
                        for (final track in shown)
                          CheckboxListTile(
                            key: ValueKey(('pick', track.path)),
                            value: _ticked.contains(track),
                            onChanged: (on) => setState(
                              () => on == true
                                  ? _ticked.add(track)
                                  : _ticked.remove(track),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(track.format.name.toUpperCase()),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _ticked.isEmpty
              ? null
              : () => Navigator.of(context).pop([
                  for (final track in all)
                    if (_ticked.contains(track)) track,
                ]),
          child: Text(l10n.addTracksButton(_ticked.length)),
        ),
      ],
    );
  }
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
