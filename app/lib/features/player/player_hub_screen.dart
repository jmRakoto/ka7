import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/video_thumbnail.dart';
import '../playlists/add_to_playlist.dart';
import '../playlists/playlist_screen.dart';
import '../preview/durations.dart';
import 'player_controller.dart';
import 'player_texts.dart';
import 'track.dart';

/// The offline player: what plays, every downloaded file, the playlists.
class PlayerHubScreen extends StatefulWidget {
  const PlayerHubScreen({
    super.key,
    required this.store,
    required this.player,
    required this.changes,
    required this.onOpenPlayer,
    this.thumbnail,
    this.pickFolder,
    this.listFolder,
  });

  /// Picks a folder to play as a list; null where none can be picked.
  final Future<({String folder, String label})?> Function()? pickFolder;

  /// The playable files of a folder list, read each time it opens.
  final Future<List<MediaFile>> Function(String folder)? listFolder;

  final Ka7Store store;
  final PlayerController player;

  /// Ticks whenever the history changes.
  final Listenable changes;
  final VoidCallback onOpenPlayer;
  final ImageProvider Function(String videoId)? thumbnail;

  @override
  State<PlayerHubScreen> createState() => _PlayerHubScreenState();
}

class _PlayerHubScreenState extends State<PlayerHubScreen> {
  var _lists = false;
  var _search = '';
  late Future<(List<HistoryItem>, List<UserPlaylist>)> _loaded = _load();

  /// Downloaded files, newest first, each title and format once: the latest.
  Future<(List<HistoryItem>, List<UserPlaylist>)> _load() async {
    final seen = <(String, MediaFormat)>{};
    final files = [
      for (final item in await widget.store.history())
        if (item.status == HistoryStatus.succeeded &&
            item.path != null &&
            seen.add((item.videoId, item.format)))
          item,
    ];
    return (files, await widget.store.playlists());
  }

  void _reload() {
    final loaded = _load();
    setState(() {
      _loaded = loaded;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.changes.addListener(_reload);
  }

  @override
  void dispose() {
    widget.changes.removeListener(_reload);
    super.dispose();
  }

  void _play(List<HistoryItem> files, {int start = 0, bool shuffle = false}) {
    final player = widget.player..setShuffle(false);
    player
        .playAll([
          for (final item in files) Track.ofHistory(item),
        ], start: start)
        .then((_) {
          if (shuffle) player.setShuffle(true);
        });
  }

  /// Every list, in their order, each with its tracks in theirs; a folder
  /// list as its folder holds it now.
  Future<void> _playLists(
    List<UserPlaylist> playlists, {
    bool shuffle = false,
  }) async {
    final tracks = <Track>[];
    for (final playlist in playlists) {
      if (playlist.folder case final folder?) {
        final files = await widget.listFolder?.call(folder) ?? const [];
        tracks.addAll([for (final file in files) Track.ofFile(file)]);
      } else {
        tracks.addAll([
          for (final track in await widget.store.playlistTracks(playlist.id))
            Track.ofPlaylist(track),
        ]);
      }
    }
    if (tracks.isEmpty) return;
    final player = widget.player..setShuffle(false);
    await player.playAll(tracks);
    if (shuffle) player.setShuffle(true);
  }

  /// On screen at once, then in the store.
  Future<void> _orderLists(List<UserPlaylist> playlists, int from, int to) {
    final moved = [...playlists];
    moved.insert(to, moved.removeAt(from));
    final loaded = _loaded;
    setState(() {
      _loaded = loaded.then((value) => (value.$1, moved));
    });
    return widget.store.orderPlaylists([for (final p in moved) p.id]);
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final name = await askPlaylistName(
      context,
      title: l10n.newPlaylist,
      action: l10n.createButton,
    );
    if (name == null) return;
    await widget.store.createPlaylist(name);
    if (mounted) _reload();
  }

  Future<void> _addFolder() async {
    final picked = await widget.pickFolder!();
    if (picked == null) return;
    final label = picked.label;
    final name = label.split('/').where((part) => part.isNotEmpty).lastOrNull;
    await widget.store.createFolderPlaylist(
      name ?? label,
      folder: picked.folder,
      label: label,
    );
    if (mounted) _reload();
  }

  Future<void> _open(UserPlaylist playlist) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistScreen(
          store: widget.store,
          player: widget.player,
          playlist: playlist,
          listFolder: widget.listFolder,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _addToPlaylist(HistoryItem item) async {
    await addToPlaylist(context, widget.store, PlaylistTrack.of(item));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: _loaded,
      builder: (context, snapshot) {
        final (files, playlists) =
            snapshot.data ?? (const <HistoryItem>[], const <UserPlaylist>[]);
        final shown = [
          for (final item in files)
            if (holdsWords('${item.title} ${item.album ?? ''}', _search)) item,
        ];
        return Scaffold(
          body: Ka7Page(
            title: l10n.navPlayer,
            children: [
              _NowPlaying(player: widget.player, onOpen: widget.onOpenPlayer),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.music_note_outlined),
                      label: Text(l10n.playerTitles(files.length)),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.queue_music),
                      label: Text(l10n.playerLists(playlists.length)),
                    ),
                  ],
                  selected: {_lists},
                  onSelectionChanged: (choice) =>
                      setState(() => _lists = choice.single),
                ),
              ),
              const SizedBox(height: 16),
              if (!snapshot.hasData)
                const SizedBox.shrink()
              else if (_lists) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newPlaylist),
                    ),
                    if (widget.pickFolder != null)
                      OutlinedButton.icon(
                        onPressed: _addFolder,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: Text(l10n.addFolder),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (playlists.isEmpty)
                  EmptyState(l10n.playlistsEmpty)
                else ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _playLists(playlists),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.playAll),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _playLists(playlists, shuffle: true),
                        icon: const Icon(Icons.shuffle),
                        label: Text(l10n.shuffleAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Few lists: built at once, the page scrolls them.
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorderItem: (from, to) =>
                        _orderLists(playlists, from, to),
                    children: [
                      for (final (i, playlist) in playlists.indexed)
                        Card(
                          key: ValueKey(('playlist', playlist.id)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: i,
                              child: const Icon(Icons.drag_handle),
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  playlist.isFolder
                                      ? Icons.folder_outlined
                                      : Icons.queue_music,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(playlist.name)),
                              ],
                            ),
                            subtitle: Text(
                              playlist.folderLabel ??
                                  l10n.trackCount(playlist.trackCount),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(playlist),
                          ),
                        ),
                    ],
                  ),
                ],
              ] else if (files.isEmpty)
                EmptyState(l10n.playerEmpty)
              else ...[
                TextField(
                  key: const ValueKey('player-search'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.playerSearch,
                  ),
                  onChanged: (text) => setState(() => _search = text.trim()),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: shown.isEmpty ? null : () => _play(shown),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.playAll),
                    ),
                    OutlinedButton.icon(
                      onPressed: shown.isEmpty
                          ? null
                          : () => _play(shown, shuffle: true),
                      icon: const Icon(Icons.shuffle),
                      label: Text(l10n.shuffleAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l10n.playerNoMatch),
                  ),
                for (final (i, item) in shown.indexed)
                  _FileTile(
                    key: ValueKey(('file', item.videoId, item.format)),
                    item: item,
                    thumbnail: widget.thumbnail,
                    onPlay: () => _play(shown, start: i),
                    onPlayNext: () =>
                        widget.player.playNext(Track.ofHistory(item)),
                    onEnqueue: () =>
                        widget.player.enqueue(Track.ofHistory(item)),
                    onAddToPlaylist: () => _addToPlaylist(item),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// What plays now, at the top; a tap opens the whole player.
class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.player, required this.onOpen});

  final PlayerController player;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: player,
    builder: (context, _) {
      final track = player.current;
      if (track == null) return const SizedBox.shrink();
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final total = player.duration.inMilliseconds;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          color: scheme.primaryContainer,
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Icon(
                    track.video ? Icons.movie_outlined : Icons.graphic_eq,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.playerNowPlaying,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          backgroundColor: scheme.onPrimaryContainer.withValues(
                            alpha: 0.18,
                          ),
                          value: total == 0
                              ? 0
                              : player.position.inMilliseconds / total,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText(l10n, player) ??
                              '${clock(player.position)} / ${clock(player.duration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Their own taps: they do not open the player.
                  IconButton(
                    tooltip: l10n.playerPrevious,
                    // DESIGN.md: 48 px touch targets.
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: player.previous,
                    color: scheme.onPrimaryContainer,
                    icon: const Icon(Icons.skip_previous),
                  ),
                  PlayPauseButton(player: player, big: true),
                  IconButton(
                    tooltip: l10n.playerNext,
                    // DESIGN.md: 48 px touch targets.
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: player.next,
                    color: scheme.onPrimaryContainer,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

enum _Action { playNext, enqueue, addToPlaylist }

/// One downloaded file: tap to play, the rest in a menu.
class _FileTile extends StatelessWidget {
  const _FileTile({
    super.key,
    required this.item,
    required this.thumbnail,
    required this.onPlay,
    required this.onPlayNext,
    required this.onEnqueue,
    required this.onAddToPlaylist,
  });

  final HistoryItem item;
  final ImageProvider Function(String videoId)? thumbnail;
  final VoidCallback onPlay;
  final VoidCallback onPlayNext;
  final VoidCallback onEnqueue;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final video = item.format == MediaFormat.mp4;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(4, 2, 0, 2),
      onTap: onPlay,
      leading: switch (thumbnail) {
        final thumbnail? => VideoThumbnail(
          image: thumbnail(item.videoId),
          width: 64,
        ),
        null => SizedBox(
          width: 64,
          child: Icon(video ? Icons.movie_outlined : Icons.music_note_outlined),
        ),
      },
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [?item.album, item.format.name.toUpperCase()].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: PopupMenuButton<_Action>(
        tooltip: l10n.actions,
        icon: const Icon(Icons.more_vert),
        onSelected: (action) => switch (action) {
          _Action.playNext => onPlayNext(),
          _Action.enqueue => onEnqueue(),
          _Action.addToPlaylist => onAddToPlaylist(),
        },
        itemBuilder: (context) => [
          for (final (action, icon, text) in [
            (_Action.playNext, Icons.playlist_play, l10n.playNext),
            (_Action.enqueue, Icons.queue_music, l10n.enqueue),
            (_Action.addToPlaylist, Icons.playlist_add, l10n.addToPlaylist),
          ])
            PopupMenuItem(
              value: action,
              child: ListTile(leading: Icon(icon), title: Text(text)),
            ),
        ],
      ),
    );
  }
}
