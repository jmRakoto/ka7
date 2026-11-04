import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';
import 'recognized_entry.dart';

/// Flow 1: paste links, IDs or a whole list; Ka7 recognizes each line.
class AddLinksScreen extends StatefulWidget {
  const AddLinksScreen({
    super.key,
    required this.onPreview,
    this.links,
    this.pickLinksFile,
    this.mixLimit = 50,
    this.news = const [],
    this.onShowNews,
    this.onDismissNews,
    this.update,
    this.currentVersion,
    this.onOpenUpdate,
    this.onPutOffUpdate,
    this.canShare = false,
    this.canDrop = false,
    this.recentSearches = const [],
    this.onClearRecent,
  });

  /// Links can come from « Share → Ka7 » (phone) or be dropped (desktop):
  /// said in the tips.
  final bool canShare;
  final bool canDrop;

  /// The latest searches, newest first.
  final List<String> recentSearches;
  final VoidCallback? onClearRecent;

  /// A newer Ka7, to offer above everything else.
  final AppRelease? update;
  final String? currentVersion;
  final VoidCallback? onOpenUpdate;
  final VoidCallback? onPutOffUpdate;

  /// New videos in followed playlists and channels, found at launch.
  final List<News> news;
  final VoidCallback? onShowNews;
  final VoidCallback? onDismissNews;

  /// Videos of a mix read in the preview (settings).
  final int mixLimit;

  /// Called with the downloadable entries when the user asks for a preview.
  final ValueChanged<List<MediaEntry>> onPreview;

  /// The text field, when someone else fills it too (shared links).
  final TextEditingController? links;

  /// Opens the native picker on a `links.txt` and returns its text; null
  /// when closed, or where no file can be picked.
  final Future<String?> Function()? pickLinksFile;

  @override
  State<AddLinksScreen> createState() => _AddLinksScreenState();
}

class _AddLinksScreenState extends State<AddLinksScreen> {
  late final _links = widget.links ?? TextEditingController();
  List<LinkEntry> _entries = const [];
  final _query = TextEditingController();

  /// Search mode: one field of plain words instead of links.
  var _searching = false;

  @override
  void initState() {
    super.initState();
    _links.addListener(_parse);
    _parse();
  }

  void _parse() {
    final entries = parseLinks(_links.text);
    // Links only change here from outside while searching (shared, dropped):
    // back to the links, so they are seen.
    if (mounted) {
      setState(() {
        _entries = entries;
        _searching = false;
      });
    }
  }

  void _search() {
    final query = _query.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) return;
    widget.onPreview([SearchEntry(query, query: query)]);
    // The results keep it; back from them, the field is ready for another.
    _query.clear();
  }

  @override
  void dispose() {
    _links.removeListener(_parse);
    if (widget.links == null) _links.dispose();
    _query.dispose();
    super.dispose();
  }

  /// Below what is already in the field.
  Future<void> _import() async {
    final text = (await widget.pickLinksFile!())?.trim();
    if (!mounted || text == null || text.isEmpty) return;
    final current = _links.text.trimRight();
    _links.text = current.isEmpty ? text : '$current\n$text';
  }

  /// One tap instead of a long press and a menu (phone).
  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (!mounted || text == null || text.isEmpty) return;
    final current = _links.text.trimRight();
    _links.text = current.isEmpty ? text : '$current\n$text';
  }

  void _searchFor(String query) =>
      widget.onPreview([SearchEntry(query, query: query)]);

  Iterable<MediaEntry> get _media => _entries.whereType<MediaEntry>();

  String _summary(AppLocalizations l10n) {
    final recognized = _media.length;
    if (recognized == 0) return l10n.summaryNone;
    final skipped = _entries.length - recognized;
    final text = l10n.summaryRecognized(recognized);
    return skipped == 0 ? text : '$text · ${l10n.summarySkipped(skipped)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = SegmentedButton<bool>(
      segments: [
        ButtonSegment(
          value: false,
          icon: const Icon(Icons.link),
          label: Text(l10n.modeLinks),
        ),
        ButtonSegment(
          value: true,
          icon: const Icon(Icons.search),
          label: Text(l10n.modeSearch),
        ),
      ],
      selected: {_searching},
      onSelectionChanged: (choice) =>
          setState(() => _searching = choice.single),
    );
    if (_searching) {
      return Ka7Page(
        title: l10n.addTitle,
        footer: Row(
          children: [
            Expanded(
              child: Text(
                l10n.searchFooter,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _query,
              builder: (context, _) => FilledButton(
                onPressed: _query.text.trim().isEmpty ? null : _search,
                child: Text(l10n.searchButton),
              ),
            ),
          ],
        ),
        children: [
          mode,
          const SizedBox(height: 16),
          TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchHint,
            ),
          ),
          if (widget.recentSearches.isNotEmpty)
            _RecentSearches(
              searches: widget.recentSearches,
              onSearch: _searchFor,
              onClear: widget.onClearRecent,
            ),
        ],
      );
    }
    return Ka7Page(
      title: l10n.addTitle,
      footer: Row(
        children: [
          Expanded(
            child: Text(
              _summary(l10n),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: _media.isEmpty
                ? null
                : () => widget.onPreview(_media.toList()),
            child: Text(l10n.previewButton),
          ),
        ],
      ),
      children: [
        // Always there, so the field below glides down instead of jumping.
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: widget.news.isEmpty && widget.update == null
                ? const SizedBox(width: double.infinity)
                : Column(
                    key: ValueKey((widget.update, widget.news)),
                    children: [
                      if (widget.update case final update?)
                        _UpdateCard(
                          update: update,
                          current: widget.currentVersion,
                          onOpen: widget.onOpenUpdate,
                          onPutOff: widget.onPutOffUpdate,
                        ),
                      if (widget.news.isNotEmpty)
                        _NewsCard(
                          news: widget.news,
                          onShow: widget.onShowNews,
                          onDismiss: widget.onDismissNews,
                        ),
                    ],
                  ),
          ),
        ),
        mode,
        const SizedBox(height: 16),
        TextField(
          controller: _links,
          minLines: 4,
          maxLines: 10,
          decoration: InputDecoration(hintText: l10n.addHint),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste),
              label: Text(l10n.pasteLinks),
            ),
            if (widget.pickLinksFile != null)
              OutlinedButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.importFile),
              ),
            TextButton.icon(
              onPressed: _links.text.isEmpty ? null : _links.clear,
              icon: const Icon(Icons.clear),
              label: Text(l10n.clearLinks),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: _entries.isEmpty
              ? _Tips(
                  key: const ValueKey('tips'),
                  canShare: widget.canShare,
                  canDrop: widget.canDrop,
                  canImport: widget.pickLinksFile != null,
                )
              : Card(
                  key: const ValueKey('recognized'),
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, entry) in _entries.indexed) ...[
                        if (i > 0) const Divider(height: 1, indent: 60),
                        _RecognizedRow(
                          entry: entry,
                          l10n: l10n,
                          mixLimit: widget.mixLimit,
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _RecognizedRow extends StatelessWidget {
  const _RecognizedRow({
    required this.entry,
    required this.l10n,
    required this.mixLimit,
  });

  final LinkEntry entry;
  final AppLocalizations l10n;
  final int mixLimit;

  @override
  Widget build(BuildContext context) {
    final (:label, :detail) = describeEntry(entry, l10n, mixLimit: mixLimit);
    final tone = switch (entry) {
      MediaEntry() => PillTone.accent,
      DuplicateEntry() => PillTone.neutral,
      InvalidEntry() => PillTone.warn,
    };
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (entry) {
      SearchEntry() => Icons.search,
      VideoEntry() => Icons.smart_display_outlined,
      PlaylistEntry(isMix: true) => Icons.all_inclusive,
      PlaylistEntry() => Icons.playlist_play,
      VideoInPlaylistEntry() => Icons.video_library_outlined,
      ChannelEntry() => Icons.account_circle_outlined,
      DuplicateEntry() => Icons.content_copy,
      InvalidEntry() => Icons.link_off,
    };
    final usable = entry is MediaEntry;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: usable
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 20,
          color: usable ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
      title: Text(entry.source, overflow: TextOverflow.ellipsis, maxLines: 1),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(label, tone: tone),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// While nothing is pasted: every way to add, in a few words.
class _Tips extends StatelessWidget {
  const _Tips({
    super.key,
    required this.canShare,
    required this.canDrop,
    required this.canImport,
  });

  final bool canShare;
  final bool canDrop;
  final bool canImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tips = [
      (Icons.format_list_bulleted, l10n.addTipLines),
      if (canShare) (Icons.share_outlined, l10n.addTipShare),
      if (canDrop) (Icons.move_to_inbox_outlined, l10n.addTipDrop),
      if (canImport) (Icons.upload_file, l10n.addTipImport),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (icon, text)) in tips.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The latest searches, to run again in one tap.
class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.searches,
    required this.onSearch,
    required this.onClear,
  });

  final List<String> searches;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.recentSearches,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: l10n.clearRecent,
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final search in searches)
                ActionChip(
                  avatar: const Icon(Icons.search, size: 18),
                  label: Text(search),
                  onPressed: () => onSearch(search),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Flow 0: followed playlists and channels have new videos.
class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.news,
    required this.onShow,
    required this.onDismiss,
  });

  final List<News> news;
  final VoidCallback? onShow;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = news.fold(0, (sum, n) => sum + n.count);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.newsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.newsLater,
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                '${l10n.newTracks(count)} · '
                '${news.map((n) => n.title).join(', ')}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onShow, child: Text(l10n.newsShow)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A newer Ka7 is out: its page has the file to install.
class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.update,
    required this.current,
    required this.onOpen,
    required this.onPutOff,
  });

  final AppRelease update;
  final String? current;
  final VoidCallback? onOpen;
  final VoidCallback? onPutOff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.system_update_alt,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.updateAvailable(update.version),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.newsLater,
                    onPressed: onPutOff,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (current case final current?)
                Text(
                  l10n.updateCurrent(current),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.download),
                label: Text(l10n.updateDownload),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
