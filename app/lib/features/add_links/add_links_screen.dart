import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';
import 'recognized_entry.dart';

/// Flow 1: paste links, IDs or a whole list; Ka7 recognizes each line.
class AddLinksScreen extends StatefulWidget {
  const AddLinksScreen({super.key, required this.onPreview, this.links});

  /// Called with the downloadable entries when the user asks for a preview.
  final ValueChanged<List<MediaEntry>> onPreview;

  /// The text field, when someone else fills it too (shared links).
  final TextEditingController? links;

  @override
  State<AddLinksScreen> createState() => _AddLinksScreenState();
}

class _AddLinksScreenState extends State<AddLinksScreen> {
  late final _links = widget.links ?? TextEditingController();
  List<LinkEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _links.addListener(_parse);
    _parse();
  }

  void _parse() {
    final entries = parseLinks(_links.text);
    if (mounted) setState(() => _entries = entries);
  }

  @override
  void dispose() {
    _links.removeListener(_parse);
    if (widget.links == null) _links.dispose();
    super.dispose();
  }

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
        TextField(
          controller: _links,
          minLines: 4,
          maxLines: 10,
          decoration: InputDecoration(hintText: l10n.addHint),
        ),
        const SizedBox(height: 12),
        for (final entry in _entries) _RecognizedRow(entry: entry, l10n: l10n),
      ],
    );
  }
}

class _RecognizedRow extends StatelessWidget {
  const _RecognizedRow({required this.entry, required this.l10n});

  final LinkEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (:label, :detail) = describeEntry(entry, l10n);
    final tone = switch (entry) {
      MediaEntry() => PillTone.accent,
      DuplicateEntry() => PillTone.neutral,
      InvalidEntry() => PillTone.warn,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: StatusPill(label, tone: tone),
      title: Text(entry.source, overflow: TextOverflow.ellipsis),
      subtitle: Text(detail),
    );
  }
}
