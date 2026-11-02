import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';
import 'durations.dart';

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
  });

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
  final void Function(List<PlannedDownload> downloads, MediaFormat format)
  onDownload;

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

  /// The entries, then the searches made from here, newest first.
  late final List<MediaEntry> _entries = [...widget.entries];
  final _query = TextEditingController();

  /// A search preview: more searches can be made without going back.
  bool get _searching => widget.entries.any((e) => e is SearchEntry);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _searchAgain() {
    final query = _query.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) return;
    final entry = SearchEntry(query, query: query);
    _query.clear();
    if (_entries.any((e) => e.url == entry.url)) return;
    setState(() => _entries.insert(0, entry));
    _read(entry);
  }

  @override
  void initState() {
    super.initState();
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

  /// Another format: what is already there changes, so does the selection.
  Future<void> _changeFormat(MediaFormat format) async {
    setState(() => _format = format);
    final present = <String>{};
    for (final probe in _probes.values) {
      present.addAll(await _presentIn(probe));
    }
    if (!mounted || format != _format) return;
    setState(() {
      _present
        ..clear()
        ..addAll(present);
      _selected
        ..clear()
        ..addAll(_probes.values.where((p) => !p.isSearch).expand(_wanted));
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
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final download = FilledButton(
      onPressed: _selected.isEmpty
          ? null
          : () => widget.onDownload(_planned, _format),
      child: Text(l10n.downloadButton),
    );
    final stacked = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        format,
        const SizedBox(height: 10),
        Row(
          children: [
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
        for (final entry in _entries)
          if (_probes[entry] case final probe?)
            _ProbeGroup(
              probe: probe,
              selected: _selected,
              present: _present,
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
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
    required this.onToggle,
    required this.onToggleAll,
    required this.followed,
    required this.onFollow,
  });

  /// Null when this cannot be followed (video, search, mix).
  final bool? followed;
  final void Function(bool follow)? onFollow;

  /// Every available video of the playlist, checked or not.
  final void Function(bool keep) onToggleAll;

  final Probe probe;
  final Set<String> selected;
  final Set<String> present;
  final void Function(String videoId, bool keep) onToggle;

  /// Duration, and « Déjà là » when downloaded before in this format.
  Widget? _details(BuildContext context, ProbeItem item) {
    final duration = item.duration;
    if (!present.contains(item.videoId)) {
      return duration == null ? null : Text(clock(duration));
    }
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusPill(
          AppLocalizations.of(context).statusSkipped,
          tone: PillTone.warn,
        ),
        if (duration != null) Text(clock(duration)),
      ],
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
              title: Text(item.title),
              subtitle: _details(context, item),
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
