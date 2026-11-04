import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/video_thumbnail.dart';
import 'durations.dart';
import 'loading.dart';

/// Flow 2: what each link contains, before anything is downloaded.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    required this.entries,
    required this.extractor,
    required this.onDownload,
    this.formats = const [MediaFormat.mp3, MediaFormat.mp4],
    this.archive,
    this.isFollowed,
    this.onFollow,
    this.thumbnail,
    this.queueStatus,
    this.queueChanges,
    this.onSearch,
    this.quality = Quality.standard,
  });

  /// A new search made here, to remember it.
  final ValueChanged<String>? onSearch;

  /// Where a video stands in the queue, in a format; null when not there.
  final RunItemStatus? Function(String videoId, MediaFormat format)?
  queueStatus;

  /// Ticks when anything in the queue moves.
  final Listenable? queueChanges;

  /// Picture of a video, by id (YouTube's thumbnail); none when null.
  final ImageProvider Function(String videoId)? thumbnail;

  /// Whether the link of a playlist or channel is followed.
  final bool Function(String link)? isFollowed;

  /// Follows, or stops following, what [probe] shows.
  final Future<void> Function(Probe probe, bool follow)? onFollow;

  /// Videos already downloaded: shown, unchecked.
  final Archive? archive;

  final List<MediaEntry> entries;
  final Extractor extractor;

  /// Formats the engine can make; the first one is preselected.
  final List<MediaFormat> formats;

  /// Called with the checked videos and the chosen format when the user
  /// starts the download.
  final void Function(
    List<PlannedDownload> downloads,
    MediaFormat format,
    Quality quality,
  )
  onDownload;

  /// Picked at first: the default of Settings.
  final Quality quality;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  /// Probe of each entry, in the order of [PreviewScreen.entries].
  final Map<MediaEntry, Probe> _probes = {};

  /// Entries the engine could not read.
  final Map<MediaEntry, ProbeFailure> _failures = {};

  /// Ids of the videos the user keeps.
  final Set<String> _selected = {};

  /// Ids already downloaded in the chosen format.
  final Set<String> _present = {};

  late var _format = widget.formats.first;
  late var _quality = widget.quality;

  /// The entries, then the searches made from here, newest first.
  late final List<MediaEntry> _entries = [...widget.entries];
  final _query = TextEditingController();

  /// A search preview: more searches can be made without going back.
  bool get _searching => widget.entries.any((e) => e is SearchEntry);

  @override
  void dispose() {
    widget.queueChanges?.removeListener(_queueMoved);
    _query.dispose();
    super.dispose();
  }

  void _searchAgain() {
    final query = _query.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) return;
    final entry = SearchEntry(query, query: query);
    _query.clear();
    widget.onSearch?.call(query);
    if (_entries.any((e) => e.url == entry.url)) return;
    setState(() => _entries.insert(0, entry));
    _read(entry);
  }

  /// A video ended in the queue: what is on disk may have changed too.
  Future<void> _queueMoved() async {
    final format = _format;
    final present = <String>{};
    for (final probe in _probes.values) {
      present.addAll(await _presentIn(probe));
    }
    if (!mounted || format != _format) return;
    setState(
      () => _present
        ..clear()
        ..addAll(present),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.queueChanges?.addListener(_queueMoved);
    widget.entries.forEach(_read);
  }

  void _read(MediaEntry entry) {
    widget.extractor
        .probe(entry)
        .then(
          (probe) async {
            final present = await _presentIn(probe);
            if (!mounted) return;
            setState(() {
              _probes[entry] = probe;
              _present.addAll(present);
              // Search results: the user picks, nothing is checked.
              if (!probe.isSearch) _selected.addAll(_wanted(probe));
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(
              () => _failures[entry] = error is ProbeFailure
                  ? error
                  : ProbeFailure(FailureReason.unknown, '$error'),
            );
          },
        );
  }

  /// Videos of [probe] already in the archive, in the chosen format.
  Future<Set<String>> _presentIn(Probe probe) async {
    final archive = widget.archive;
    if (archive == null) return const {};
    return {
      for (final item in probe.items)
        if (await archive.contains(item.videoId, _format)) item.videoId,
    };
  }

  /// Available videos not downloaded yet.
  Iterable<String> _wanted(Probe probe) => [
    for (final item in probe.items)
      if (item.availability == Availability.available &&
          !_present.contains(item.videoId))
        item.videoId,
  ];

  /// Another format: what is already there changes. The user's picks stay;
  /// only videos already there in the new format are unchecked, and those
  /// unchecked for being there in the old one are checked again.
  Future<void> _changeFormat(MediaFormat format) async {
    setState(() => _format = format);
    final present = <String>{};
    for (final probe in _probes.values) {
      present.addAll(await _presentIn(probe));
    }
    if (!mounted || format != _format) return;
    setState(() {
      final freed = _present.difference(present);
      _present
        ..clear()
        ..addAll(present);
      _selected
        ..removeAll(present)
        ..addAll(
          _probes.values
              .where((p) => !p.isSearch)
              .expand(_wanted)
              .where(freed.contains),
        );
    });
  }

  /// Checked videos, in the order of the entries and of each playlist.
  List<PlannedDownload> get _planned => [
    for (final entry in _entries)
      if (_probes[entry] case final probe?)
        for (final (i, item) in probe.items.indexed)
          if (_selected.contains(item.videoId))
            PlannedDownload(source: probe, item: item, index: i + 1),
  ];

  void _download() {
    widget.onDownload(_planned, _format, _quality);
    // Links: the preview closes. Search: it stays, to pick more.
    if (!_searching) return;
    setState(_selected.clear);
  }

  String _total(AppLocalizations l10n) {
    final kept = _planned;
    final duration = kept.fold(
      Duration.zero,
      (sum, planned) => sum + (planned.item.duration ?? Duration.zero),
    );
    return '${l10n.trackCount(kept.length)} · ${span(duration)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = SegmentedButton<MediaFormat>(
      showSelectedIcon: false,
      segments: [
        for (final format in widget.formats)
          ButtonSegment(
            value: format,
            label: Text(switch (format) {
              MediaFormat.mp3 => l10n.formatMp3,
              MediaFormat.m4a => l10n.formatM4a,
              MediaFormat.mp4 => l10n.formatMp4,
            }),
          ),
      ],
      selected: {_format},
      onSelectionChanged: (choice) => _changeFormat(choice.single),
    );
    final total = Text(
      _total(l10n),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final download = FilledButton(
      onPressed: _selected.isEmpty ? null : _download,
      child: Text(l10n.downloadButton),
    );
    // Beside the total, the choice the format has: bitrate, height, or none.
    final quality = _QualityMenu(
      format: _format,
      quality: _quality,
      onChanged: (quality) => setState(() => _quality = quality),
    );
    final stacked = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        format,
        const SizedBox(height: 10),
        Row(
          children: [
            // Narrow screen: the quality and the total give way, never the
            // button.
            Flexible(child: quality),
            const SizedBox(width: 8),
            Expanded(child: total),
            download,
          ],
        ),
      ],
    );
    return Ka7Page(
      title: l10n.previewTitle,
      showBack: true,
      // One line when everything fits, two otherwise (phone, long labels).
      footer: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 820
            ? stacked
            : Row(
                children: [
                  Expanded(child: total),
                  Flexible(child: quality),
                  const SizedBox(width: 12),
                  format,
                  const SizedBox(width: 12),
                  download,
                ],
              ),
      ),
      children: [
        if (_searching)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SearchGlow(
              active: _entries.any(
                (e) =>
                    e is SearchEntry &&
                    !_probes.containsKey(e) &&
                    !_failures.containsKey(e),
              ),
              child: TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchAgain(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.searchAgain,
                ),
              ),
            ),
          ),
        for (final entry in _entries)
          if (_probes[entry] case final probe?)
            _ProbeGroup(
              probe: probe,
              selected: _selected,
              present: _present,
              queued: (id) => widget.queueStatus?.call(id, _format),
              thumbnail: widget.thumbnail,
              followed: switch ((followLinkOf(probe), widget.isFollowed)) {
                (final link?, final isFollowed?) => isFollowed(link),
                _ => null,
              },
              onFollow: widget.onFollow == null
                  ? null
                  : (follow) async {
                      await widget.onFollow!(probe, follow);
                      if (mounted) setState(() {});
                    },
              onToggle: (id, keep) => setState(
                () => keep ? _selected.add(id) : _selected.remove(id),
              ),
              onToggleAll: (keep) => setState(() {
                final ids = [
                  for (final item in probe.items)
                    if (item.availability == Availability.available)
                      item.videoId,
                ];
                keep ? _selected.addAll(ids) : _selected.removeAll(ids);
              }),
            )
          else if (_failures[entry] case final failure?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.source),
              subtitle: Text(failureText(l10n, failure.reason)),
            )
          else
            LoadingRows(
              label: switch (entry) {
                SearchEntry(:final query) => l10n.loadingSearch(query),
                _ => l10n.loadingLink,
              },
            ),
      ],
    );
  }
}

class _ProbeGroup extends StatelessWidget {
  const _ProbeGroup({
    required this.probe,
    required this.selected,
    required this.present,
    required this.queued,
    required this.onToggle,
    required this.onToggleAll,
    required this.followed,
    required this.onFollow,
    required this.thumbnail,
  });

  final ImageProvider Function(String videoId)? thumbnail;

  /// Null when this cannot be followed (video, search, mix).
  final bool? followed;
  final void Function(bool follow)? onFollow;

  /// Every available video of the playlist, checked or not.
  final void Function(bool keep) onToggleAll;

  final Probe probe;
  final Set<String> selected;
  final Set<String> present;

  /// Where a video stands in the queue, in the chosen format.
  final RunItemStatus? Function(String videoId) queued;
  final void Function(String videoId, bool keep) onToggle;

  /// Duration, with what became of the video in the queue (« Dans la
  /// file », « Réussi », « Échoué »…), or « Déjà là » when downloaded before
  /// in this format. Cancelled: nothing, it can be picked again.
  Widget? _details(BuildContext context, ProbeItem item) {
    final duration = item.duration;
    final l10n = AppLocalizations.of(context);
    final pill = switch (queued(item.videoId)) {
      RunItemStatus.waiting || RunItemStatus.running => StatusPill(
        l10n.statusQueued,
        tone: PillTone.accent,
      ),
      // Made here, unless the file was deleted since.
      RunItemStatus.succeeded =>
        present.contains(item.videoId)
            ? StatusPill(l10n.statusSucceeded, tone: PillTone.ok)
            : null,
      RunItemStatus.failed => StatusPill(
        l10n.statusFailed,
        tone: PillTone.danger,
      ),
      RunItemStatus.skipped => StatusPill(
        l10n.statusSkipped,
        tone: PillTone.warn,
      ),
      RunItemStatus.cancelled || null =>
        present.contains(item.videoId)
            ? StatusPill(l10n.statusSkipped, tone: PillTone.warn)
            : null,
    };
    if (pill == null) {
      return duration == null ? null : Text(clock(duration));
    }
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [pill, if (duration != null) Text(clock(duration))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final available = [
      for (final item in probe.items)
        if (item.availability == Availability.available) item.videoId,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          probe.isSearch ? l10n.searchResults(probe.title) : probe.title,
          trailing: l10n.trackCount(probe.items.length),
        ),
        if (followed case final followed? when onFollow != null)
          Align(
            alignment: Alignment.centerLeft,
            child: followed
                ? FilledButton.tonalIcon(
                    onPressed: () => onFollow!(false),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(l10n.following),
                  )
                : OutlinedButton.icon(
                    onPressed: () => onFollow!(true),
                    icon: const Icon(Icons.notifications_none),
                    label: Text(l10n.follow),
                  ),
          ),
        if (available.length > 1)
          CheckboxListTile(
            tristate: true,
            value: switch (available.where(selected.contains).length) {
              0 => false,
              final n when n == available.length => true,
              _ => null,
            },
            // Partly checked: a tap checks everything.
            onChanged: (_) => onToggleAll(!available.every(selected.contains)),
            title: Text(
              l10n.selectAll,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        for (final item in probe.items)
          if (item.availability == Availability.available)
            CheckboxListTile(
              value: selected.contains(item.videoId),
              onChanged: (keep) => onToggle(item.videoId, keep ?? false),
              title: _Title(
                item.title,
                onLongPress: () =>
                    _showVideo(context, item, thumbnail?.call(item.videoId)),
              ),
              subtitle: _details(context, item),
              secondary: switch (thumbnail) {
                final thumbnail? => VideoThumbnail(
                  image: thumbnail(item.videoId),
                  onLongPress: () =>
                      _showVideo(context, item, thumbnail(item.videoId)),
                ),
                null => null,
              },
            )
          else
            CheckboxListTile(
              value: false,
              onChanged: null,
              title: Text(switch (item.availability) {
                Availability.private => l10n.itemPrivate,
                Availability.unavailable => l10n.itemUnavailable,
                _ => l10n.itemDeleted,
              }),
            ),
      ],
    );
  }
}

/// The video's picture, 16:9; a neutral tile when it cannot load.
/// Two lines at most; the whole title on a long press (phone) or under the
/// pointer (desktop). Screen readers read it whole either way.
class _Title extends StatelessWidget {
  const _Title(this.text, {required this.onLongPress});

  final String text;

  /// Opens the larger view, like a long press on the picture.
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: onLongPress,
    // Pointer over it (desktop): the whole title in a bubble.
    child: Tooltip(
      message: text,
      triggerMode: TooltipTriggerMode.manual,
      waitDuration: const Duration(milliseconds: 500),
      excludeFromSemantics: true,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
  );
}

/// The video in large, its whole title, length and channel: to be sure it
/// is the right one before downloading it.
Future<void> _showVideo(
  BuildContext context,
  ProbeItem item,
  ImageProvider? image,
) => showDialog<void>(
  context: context,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_video_outlined,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final details = [
      if (item.duration case final duration?) clock(duration),
      ?item.channel?.trim(),
    ].join(' · ');
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: switch (image) {
                final image? => Image(
                  image: image,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (context, _, _) => placeholder,
                ),
                null => placeholder,
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(item.title, style: theme.textTheme.titleMedium),
            ),
            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  details,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// The quality of the chosen format, as a small menu: « 192 kbit/s ▾ » for
/// MP3, « 1080p ▾ » for MP4; M4A is the original sound, nothing to pick.
class _QualityMenu extends StatelessWidget {
  const _QualityMenu({
    required this.format,
    required this.quality,
    required this.onChanged,
  });

  final MediaFormat format;
  final Quality quality;
  final ValueChanged<Quality> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String height(VideoQuality video) => switch (video.height) {
      final h? => '${h}p',
      null => l10n.qualityBest,
    };
    final List<(String, Quality)> choices = switch (format) {
      MediaFormat.mp3 => [
        for (final audio in AudioQuality.values)
          (
            l10n.qualityKbps(audio.kbps),
            Quality(audio: audio, video: quality.video),
          ),
      ],
      MediaFormat.mp4 => [
        for (final video in VideoQuality.values)
          (height(video), Quality(audio: quality.audio, video: video)),
      ],
      MediaFormat.m4a => const [],
    };
    if (choices.isEmpty) {
      return Text(
        l10n.qualityOriginal,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final current = format == MediaFormat.mp3
        ? l10n.qualityKbps(quality.audio.kbps)
        : height(quality.video);
    return PopupMenuButton<Quality>(
      tooltip: l10n.settingsQuality,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final (label, choice) in choices)
          CheckedPopupMenuItem(
            value: choice,
            checked: label == current,
            child: Text(label),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                current,
                style: theme.textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
