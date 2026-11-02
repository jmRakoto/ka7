import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../widgets/ka7_page.dart';
import 'durations.dart';

/// Flow 2: what each link contains, before anything is downloaded.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    required this.entries,
    required this.extractor,
    required this.onDownload,
    this.formats = const [MediaFormat.mp3, MediaFormat.mp4],
  });

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

  late var _format = widget.formats.first;

  @override
  void initState() {
    super.initState();
    for (final entry in widget.entries) {
      widget.extractor
          .probe(entry)
          .then(
            (probe) {
              if (!mounted) return;
              setState(() {
                _probes[entry] = probe;
                _selected.addAll([
                  for (final item in probe.items)
                    if (item.availability == Availability.available)
                      item.videoId,
                ]);
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
      onSelectionChanged: (choice) => setState(() => _format = choice.single),
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
              onToggle: (id, keep) => setState(
                () => keep ? _selected.add(id) : _selected.remove(id),
              ),
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
    required this.onToggle,
  });

  final Probe probe;
  final Set<String> selected;
  final void Function(String videoId, bool keep) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          probe.title,
          trailing: l10n.trackCount(probe.items.length),
        ),
        for (final item in probe.items)
          if (item.availability == Availability.available)
            CheckboxListTile(
              value: selected.contains(item.videoId),
              onChanged: (keep) => onToggle(item.videoId, keep ?? false),
              title: Text(item.title),
              subtitle: item.duration == null
                  ? null
                  : Text(clock(item.duration!)),
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
