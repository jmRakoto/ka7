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
  });

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

  @override
  void initState() {
    super.initState();
    for (final entry in widget.entries) {
      widget.extractor
          .probe(entry)
          .then(
            (probe) async {
              final present = await _presentIn(probe);
              if (!mounted) return;
              setState(() {
                _probes[entry] = probe;
                _present.addAll(present);
                _selected.addAll(_wanted(probe));
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
        ..addAll(_probes.values.expand(_wanted));
    });
  }

  /// Checked videos, in the order of the entries and of each playlist.
  List<PlannedDownload> get _planned => [
    for (final entry in widget.entries)
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
        for (final entry in widget.entries)
          if (_probes[entry] case final probe?)
            _ProbeGroup(
              probe: probe,
              selected: _selected,
              present: _present,
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
  });

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
          probe.title,
          trailing: l10n.trackCount(probe.items.length),
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
