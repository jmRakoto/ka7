import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../widgets/appear.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';

/// Flow 5: everything downloaded, searchable.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.store,
    required this.changes,
    required this.openFolder,
    this.onUpdatePlaylist,
  });

  /// Opens the preview of a playlist, so only its new videos are fetched.
  final void Function(String playlistId)? onUpdatePlaylist;

  final Ka7Store store;

  /// Ticks whenever the history changes.
  final Listenable changes;

  /// Null where the system cannot open a folder (mobile).
  final void Function(String folder)? openFolder;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  var _search = '';
  late Future<List<HistoryItem>> _items = _load();

  Future<List<HistoryItem>> _load() => widget.store.history(search: _search);

  void _reload() {
    final items = _load();
    setState(() {
      _items = items;
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

  Future<void> _forget(HistoryItem item) async {
    await widget.store.forget(item.videoId);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Ka7Page(
      title: l10n.libraryTitle,
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.librarySearch,
          ),
          onChanged: (text) {
            _search = text.trim();
            _reload();
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder(
          future: _items,
          builder: (context, snapshot) {
            final items = snapshot.data;
            if (items == null) return const SizedBox.shrink();
            if (items.isEmpty) {
              return _search.isEmpty
                  ? EmptyState(l10n.libraryEmpty)
                  : Text(
                      l10n.libraryNoMatch,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
            }
            return Column(
              children: [
                for (final (i, item) in items.indexed)
                  Appear(
                    index: i,
                    child: _HistoryTile(
                      item: item,
                      onOpen: item.path == null || widget.openFolder == null
                          ? null
                          : () => widget.openFolder!(
                              item.path!.substring(
                                0,
                                item.path!.lastIndexOf('/'),
                              ),
                            ),
                      canOpen: widget.openFolder != null,
                      onForget: () => _forget(item),
                      onUpdate:
                          item.playlistId == null ||
                              widget.onUpdatePlaylist == null
                          ? null
                          : () => widget.onUpdatePlaylist!(item.playlistId!),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onOpen,
    required this.onForget,
    required this.onUpdate,
    required this.canOpen,
  });

  /// Folders can be opened here (desktop): the slot is kept on every row.
  final bool canOpen;

  final HistoryItem item;
  final VoidCallback? onOpen;
  final VoidCallback onForget;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(l10n.localeName).format(item.at.toLocal());
    final (label, tone) = switch (item.status) {
      HistoryStatus.succeeded => (l10n.statusSucceeded, PillTone.ok),
      HistoryStatus.skipped => (l10n.statusSkipped, PillTone.warn),
      HistoryStatus.failed => (l10n.statusFailed, PillTone.danger),
      HistoryStatus.cancelled => (l10n.statusCancelled, PillTone.neutral),
    };
    final details = [
      ?item.album,
      item.format.name.toUpperCase(),
      date,
      if (item.reason case final reason?) failureText(l10n, reason),
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(label, tone: tone),
            Text(details),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed slots: an action missing on one row leaves its place
          // empty, so the same action sits at the same place on every row.
          if (onUpdate != null)
            IconButton(
              tooltip: l10n.updatePlaylist,
              onPressed: onUpdate,
              icon: const Icon(Icons.sync),
            )
          else
            const SizedBox(width: _action),
          if (onOpen != null)
            IconButton(
              tooltip: l10n.openFolder,
              onPressed: onOpen,
              icon: const Icon(Icons.folder_open),
            )
          else if (canOpen)
            const SizedBox(width: _action),
          IconButton(
            tooltip: l10n.forget,
            onPressed: onForget,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

/// Width of one icon button, for the empty slots.
const _action = 48.0;
