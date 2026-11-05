import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../theme/ka7_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/video_thumbnail.dart';

/// Which entries the library shows.
enum _Filter { all, succeeded, failed }

/// Flow 5: everything downloaded, by day, searchable, filtered by outcome.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.store,
    required this.changes,
    required this.openFolder,
    this.onUpdatePlaylist,
    this.thumbnail,
    this.now = DateTime.now,
  });

  /// Opens the preview of a playlist, so only its new videos are fetched.
  final void Function(String playlistId)? onUpdatePlaylist;

  final Ka7Store store;

  /// Ticks whenever the history changes.
  final Listenable changes;

  /// Null where the system cannot open a folder (mobile).
  final void Function(String folder)? openFolder;

  final ImageProvider Function(String videoId)? thumbnail;

  /// Today, for « Aujourd'hui » and « Hier ».
  final DateTime Function() now;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  var _search = '';
  var _filter = _Filter.all;
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

  /// Forgotten on screen at once; in the store only once the message closes
  /// without « Annuler ». Quick swipes gather in one message, called back
  /// together.
  final Map<String, String> _batch = {};

  /// Forgotten for good: kept out of sight without reloading the list.
  final Set<String> _gone = {};

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _message;

  void _forget(HistoryItem item) {
    final l10n = AppLocalizations.of(context);
    setState(() => _batch[item.videoId] = item.title);
    final batch = {..._batch};
    final messenger = ScaffoldMessenger.of(context);
    // The previous message makes way; its entries stay in this batch.
    _message?.close();
    final message = _message = messenger.showSnackBar(
      SnackBar(
        // Closes by itself, even with its action: then the entries go.
        persist: false,
        content: Text(
          batch.length == 1
              ? l10n.entryForgotten(batch.values.single)
              : l10n.entriesForgotten(batch.length),
        ),
        action: SnackBarAction(label: l10n.cancelButton, onPressed: () {}),
      ),
    );
    message.closed.then((reason) async {
      // Made way for the next one: the batch goes on.
      if (!identical(message, _message)) return;
      _message = null;
      final ids = {..._batch.keys};
      _batch.clear();
      if (reason == SnackBarClosedReason.action) {
        if (mounted) setState(() {});
        return;
      }
      if (mounted) setState(() => _gone.addAll(ids));
      for (final id in ids) {
        await widget.store.forget(id);
      }
      // Once the store has them gone, so can this list: downloaded again
      // later, they show.
      if (!mounted) return;
      final fresh = _load();
      setState(() {
        _items = fresh;
      });
      await fresh;
      if (mounted) setState(() => _gone.removeAll(ids));
    });
  }

  /// Videos picked for removal; null when not picking.
  Set<String>? _picked;

  void _pick(String videoId, bool keep) =>
      setState(() => keep ? _picked!.add(videoId) : _picked!.remove(videoId));

  /// Asks first: several entries go at once.
  Future<void> _removePicked() async {
    final l10n = AppLocalizations.of(context);
    final picked = {..._picked!};
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeTitle(picked.length)),
        content: Text(l10n.removeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.removeButton),
          ),
        ],
      ),
    );
    if (sure != true) return;
    for (final videoId in picked) {
      await widget.store.forget(videoId);
    }
    if (!mounted) return;
    setState(() => _picked = null);
    _reload();
  }

  bool _shown(HistoryItem item) => switch (_filter) {
    _Filter.all => true,
    _Filter.succeeded => item.status == HistoryStatus.succeeded,
    _Filter.failed => item.status == HistoryStatus.failed,
  };

  /// « Aujourd'hui », « Hier », or the date (with its year when another).
  String _dayOf(DateTime at, AppLocalizations l10n) {
    final now = widget.now();
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(day).inDays;
    if (days == 0) return l10n.today;
    if (days == 1) return l10n.yesterday;
    return (at.year == now.year
            ? DateFormat.MMMMEEEEd(l10n.localeName)
            : DateFormat.yMMMMEEEEd(l10n.localeName))
        .format(at);
  }

  Widget _filters(List<HistoryItem> items) {
    final l10n = AppLocalizations.of(context);
    int count(HistoryStatus status) =>
        items.where((item) => item.status == status).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (filter, label) in [
            (_Filter.all, l10n.filterAll(items.length)),
            (
              _Filter.succeeded,
              l10n.filterSucceeded(count(HistoryStatus.succeeded)),
            ),
            (_Filter.failed, l10n.filterFailed(count(HistoryStatus.failed))),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: _filter == filter,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = filter),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pickBar(List<HistoryItem> items) {
    final l10n = AppLocalizations.of(context);
    final picked = _picked;
    if (picked == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => setState(() => _picked = {}),
          icon: const Icon(Icons.checklist),
          label: Text(l10n.selectEntries),
        ),
      );
    }
    final all = {for (final item in items) item.videoId};
    return Row(
      children: [
        IconButton(
          tooltip: l10n.stopSelecting,
          onPressed: () => setState(() => _picked = null),
          icon: const Icon(Icons.close),
        ),
        Expanded(
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            tristate: true,
            value: switch (all.where(picked.contains).length) {
              0 => false,
              final n when n == all.length => true,
              _ => null,
            },
            // Partly picked: a tap picks everything.
            onChanged: (_) => setState(() {
              all.every(picked.contains)
                  ? picked.removeAll(all)
                  : picked.addAll(all);
            }),
            title: Text(l10n.selectAll),
            subtitle: Text(l10n.selectedCount(picked.length)),
          ),
        ),
        FilledButton.icon(
          onPressed: picked.isEmpty ? null : _removePicked,
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.removeButton),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final search = TextField(
      key: const ValueKey('search'),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: l10n.librarySearch,
      ),
      onChanged: (text) {
        _search = text.trim();
        _reload();
      },
    );
    return FutureBuilder(
      future: _items,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        // Forgotten or about to be: out of the list and the counts.
        final items = [
          for (final item in loaded ?? const <HistoryItem>[])
            if (!_batch.containsKey(item.videoId) &&
                !_gone.contains(item.videoId))
              item,
        ];
        final shown = items.where(_shown).toList();
        // Newest first already: each day in its own card.
        final days = <String, List<HistoryItem>>{};
        for (final item in shown) {
          days.putIfAbsent(_dayOf(item.at.toLocal(), l10n), () => []).add(item);
        }
        final picked = _picked;
        // One child of the page per row: a long library is built as it
        // scrolls, and a row that goes does not rebuild the others.
        return Ka7Page(
          title: l10n.libraryTitle,
          children: [
            search,
            const SizedBox(height: 12),
            if (loaded == null)
              const SizedBox.shrink()
            else if (items.isEmpty && _search.isEmpty)
              EmptyState(l10n.libraryEmpty)
            else ...[
              _filters(items),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(picked == null),
                  child: _pickBar(shown),
                ),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.libraryNoMatch,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              for (final MapEntry(key: day, value: entries)
                  in days.entries) ...[
                Padding(
                  key: ValueKey(('day', day)),
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      day,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                for (final (i, item) in entries.indexed)
                  _CardSlice(
                    key: ValueKey((item.videoId, item.format, item.at)),
                    first: i == 0,
                    last: i == entries.length - 1,
                    child: _Forgettable(
                      key: ValueKey((
                        'row',
                        item.videoId,
                        item.format,
                        item.at,
                      )),
                      // Picking: the boxes take the gestures.
                      onForget: picked != null ? null : () => _forget(item),
                      child: _HistoryTile(
                        item: item,
                        thumbnail: widget.thumbnail,
                        picked: picked?.contains(item.videoId),
                        onPick: picked == null
                            ? null
                            : (keep) => _pick(item.videoId, keep),
                        onLongPress: picked != null
                            ? null
                            : () => setState(() => _picked = {item.videoId}),
                        onOpen: item.path == null || widget.openFolder == null
                            ? null
                            : () => widget.openFolder!(
                                item.path!.substring(
                                  0,
                                  item.path!.lastIndexOf('/'),
                                ),
                              ),
                        onForget: () => _forget(item),
                        onUpdate:
                            item.playlistId == null ||
                                widget.onUpdatePlaylist == null
                            ? null
                            : () => widget.onUpdatePlaylist!(item.playlistId!),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// One row of a day's card: the card's border and background, rounded at
/// its first and last row, a thin line between rows.
class _CardSlice extends StatelessWidget {
  const _CardSlice({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = Radius.circular(12);
    final side = BorderSide(color: scheme.outlineVariant);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(
          top: first ? radius : Radius.zero,
          bottom: last ? radius : Radius.zero,
        ),
        border: Border(
          left: side,
          right: side,
          top: first ? side : BorderSide.none,
          bottom: last ? side : BorderSide.none,
        ),
      ),
      // Ripples of the row show on the card's background.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [if (!first) const Divider(height: 1, indent: 88), child],
        ),
      ),
    );
  }
}

/// Forgets an entry the way the device does it: slid away on a touch
/// screen, a 🗑 button under the pointer on desktop.
class _Forgettable extends StatefulWidget {
  const _Forgettable({
    required super.key,
    required this.onForget,
    required this.child,
  });

  final VoidCallback? onForget;
  final Widget child;

  @override
  State<_Forgettable> createState() => _ForgettableState();
}

class _ForgettableState extends State<_Forgettable> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final forget = widget.onForget;
    if (forget == null) return widget.child;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final desktop = switch (Theme.of(context).platform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
    if (desktop) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            widget.child,
            // Left of the ⋮ menu, only while the pointer is on the row.
            Positioned(
              right: 48,
              child: AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: IgnorePointer(
                  ignoring: !_hovered,
                  child: IconButton(
                    tooltip: l10n.forget,
                    onPressed: forget,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget behind(Alignment alignment) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      color: scheme.surfaceContainerHighest,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(l10n.forget, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
    return Dismissible(
      key: widget.key!,
      // The gap closes quickly: the next row is ready for the next swipe.
      resizeDuration: const Duration(milliseconds: 160),
      background: behind(Alignment.centerLeft),
      secondaryBackground: behind(Alignment.centerRight),
      onDismissed: (_) => forget(),
      child: widget.child,
    );
  }
}

enum _Action { update, open, forget }

/// One entry: its picture, title, how it ended, and its actions in a menu.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.thumbnail,
    required this.onOpen,
    required this.onForget,
    required this.onUpdate,
    this.picked,
    this.onPick,
    this.onLongPress,
  });

  final HistoryItem item;
  final ImageProvider Function(String videoId)? thumbnail;
  final VoidCallback? onOpen;
  final VoidCallback onForget;
  final VoidCallback? onUpdate;

  /// Whether it is picked for removal; null when not picking.
  final bool? picked;
  final ValueChanged<bool>? onPick;

  /// Starts picking, with this entry.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<Ka7StatusColors>()!;
    final (label, tone, icon, color) = switch (item.status) {
      HistoryStatus.succeeded => (
        l10n.statusSucceeded,
        PillTone.ok,
        Icons.check_circle,
        colors.ok,
      ),
      HistoryStatus.skipped => (
        l10n.statusSkipped,
        PillTone.warn,
        Icons.redo,
        colors.warn,
      ),
      HistoryStatus.failed => (
        l10n.statusFailed,
        PillTone.danger,
        Icons.error,
        colors.danger,
      ),
      HistoryStatus.cancelled => (
        l10n.statusCancelled,
        PillTone.neutral,
        Icons.cancel,
        scheme.onSurfaceVariant,
      ),
    };
    final time = DateFormat.Hm(l10n.localeName).format(item.at.toLocal());
    final details = [
      ?item.album,
      time,
      if (item.reason case final reason?) failureText(l10n, reason),
    ].join(' · ');
    final picked = this.picked;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      onLongPress: onLongPress,
      onTap: picked == null ? null : () => onPick!(!picked),
      leading: picked != null
          ? Checkbox(value: picked, onChanged: (keep) => onPick!(keep!))
          : switch (thumbnail) {
              final thumbnail? => VideoThumbnail(
                image: thumbnail(item.videoId),
                width: 64,
              ),
              // No picture (tests): how it ended, in a soft tile.
              null => Container(
                width: 64,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            },
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(label, tone: tone),
            _FormatBadge(item.format.name.toUpperCase()),
            Text(details, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      // Picking: the boxes say it all, no actions.
      trailing: picked != null
          ? null
          : PopupMenuButton<_Action>(
              tooltip: l10n.actions,
              icon: const Icon(Icons.more_vert),
              onSelected: (action) => switch (action) {
                _Action.update => onUpdate!(),
                _Action.open => onOpen!(),
                _Action.forget => onForget(),
              },
              itemBuilder: (context) => [
                if (onUpdate != null)
                  PopupMenuItem(
                    value: _Action.update,
                    child: ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text(l10n.updatePlaylist),
                    ),
                  ),
                if (onOpen != null)
                  PopupMenuItem(
                    value: _Action.open,
                    child: ListTile(
                      leading: const Icon(Icons.folder_open),
                      title: Text(l10n.openFolder),
                    ),
                  ),
                PopupMenuItem(
                  value: _Action.forget,
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l10n.forget),
                  ),
                ),
              ],
            ),
    );
  }
}

/// MP3, M4A, MP4: a small outlined tag.
class _FormatBadge extends StatelessWidget {
  const _FormatBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
