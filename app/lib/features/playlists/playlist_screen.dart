import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../player/player_controller.dart';
import '../player/track.dart';
import 'add_to_playlist.dart';

/// One playlist: play it, reorder, remove, rename, delete.
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({
    super.key,
    required this.store,
    required this.player,
    required this.playlist,
    this.listFolder,
  });

  /// The playable files of a folder list, read each time it opens.
  final Future<List<MediaFile>> Function(String folder)? listFolder;

  final Ka7Store store;
  final PlayerController player;
  final UserPlaylist playlist;

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

enum _Action { rename, delete }

class _PlaylistScreenState extends State<PlaylistScreen> {
  late var _name = widget.playlist.name;
  List<PlaylistTrack>? _tracks;

  /// A folder list: the files found in it on opening.
  List<MediaFile>? _files;

  int get _id => widget.playlist.id;

  @override
  void initState() {
    super.initState();
    if (widget.playlist.folder case final folder?) {
      final list = widget.listFolder;
      (list == null ? Future.value(const <MediaFile>[]) : list(folder)).then((
        files,
      ) {
        if (mounted) setState(() => _files = files);
      });
      return;
    }
    widget.store.playlistTracks(_id).then((tracks) {
      if (mounted) setState(() => _tracks = tracks);
    });
  }

  List<Track> get _playable => switch (_files) {
    final files? => [for (final file in files) Track.ofFile(file)],
    null => [for (final track in _tracks!) Track.ofPlaylist(track)],
  };

  /// On screen at once, then in the store.
  Future<void> _save(List<PlaylistTrack> tracks) async {
    setState(() => _tracks = tracks);
    await widget.store.setPlaylistTracks(_id, tracks);
  }

  void _play({int start = 0, bool shuffle = false}) {
    final player = widget.player..setShuffle(false);
    player.playAll(_playable, start: start).then((_) {
      if (shuffle) player.setShuffle(true);
    });
  }

  Future<void> _rename() async {
    final l10n = AppLocalizations.of(context);
    final name = await askPlaylistName(
      context,
      title: l10n.renamePlaylist,
      action: l10n.saveButton,
      initial: _name,
    );
    if (name == null) return;
    setState(() => _name = name);
    await widget.store.renamePlaylist(_id, name);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlaylistTitle(_name)),
        content: Text(l10n.deletePlaylistBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deletePlaylist),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await widget.store.deletePlaylist(_id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tracks = _tracks;
    final files = _files;
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          PopupMenuButton<_Action>(
            tooltip: l10n.playlistActions,
            onSelected: (action) => switch (action) {
              _Action.rename => _rename(),
              _Action.delete => _delete(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _Action.rename,
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.renamePlaylist),
                ),
              ),
              PopupMenuItem(
                value: _Action.delete,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.deletePlaylist),
                ),
              ),
            ],
          ),
        ],
      ),
      body: files != null
          ? _FolderFiles(files: files, player: widget.player, onPlay: _play)
          : tracks == null
          ? const SizedBox.shrink()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: tracks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: EmptyState(l10n.playlistEmpty),
                      )
                    : ListenableBuilder(
                        listenable: widget.player,
                        builder: (context, _) => ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                          header: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _play,
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(l10n.playAll),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _play(shuffle: true),
                                  icon: const Icon(Icons.shuffle),
                                  label: Text(l10n.shuffleAll),
                                ),
                              ],
                            ),
                          ),
                          itemCount: tracks.length,
                          onReorderItem: (from, to) {
                            final moved = [...tracks];
                            final track = moved.removeAt(from);
                            moved.insert(to, track);
                            _save(moved);
                          },
                          itemBuilder: (context, i) {
                            final track = tracks[i];
                            final missing = widget.player.missing.contains(
                              track.path,
                            );
                            return ListTile(
                              key: ValueKey(('track', i, track.path)),
                              leading: ReorderableDragStartListener(
                                index: i,
                                child: const Icon(Icons.drag_handle),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                missing
                                    ? l10n.playerMissingBadge
                                    : track.format.name.toUpperCase(),
                                style: missing
                                    ? TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      )
                                    : null,
                              ),
                              onTap: () => _play(start: i),
                              trailing: IconButton(
                                tooltip: l10n.removeFromPlaylist,
                                onPressed: () =>
                                    _save([...tracks]..removeAt(i)),
                                icon: const Icon(Icons.close),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
    );
  }
}

/// A folder list: its files as found on disk, played in this order; the
/// folder decides what is in it, not the user.
class _FolderFiles extends StatelessWidget {
  const _FolderFiles({
    required this.files,
    required this.player,
    required this.onPlay,
  });

  final List<MediaFile> files;
  final PlayerController player;
  final void Function({int start, bool shuffle}) onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: files.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(l10n.folderEmpty),
              )
            : ListenableBuilder(
                listenable: player,
                builder: (context, _) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                  itemCount: files.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: () => onPlay(),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l10n.playAll),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => onPlay(shuffle: true),
                              icon: const Icon(Icons.shuffle),
                              label: Text(l10n.shuffleAll),
                            ),
                          ],
                        ),
                      );
                    }
                    final file = files[i - 1];
                    final missing = player.missing.contains(file.path);
                    return ListTile(
                      key: ValueKey(('file', file.path)),
                      leading: Icon(
                        file.isVideo
                            ? Icons.movie_outlined
                            : Icons.music_note_outlined,
                      ),
                      title: Text(
                        file.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        missing
                            ? l10n.playerMissingBadge
                            : file.name
                                  .substring(file.name.lastIndexOf('.') + 1)
                                  .toUpperCase(),
                      ),
                      onTap: () => onPlay(start: i - 1),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
