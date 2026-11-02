import 'package:flutter/material.dart';
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
  });

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
          spacing: 12,
          runSpacing: 8,
          children: [
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
        const SizedBox(height: 12),
        for (final entry in _entries)
          _RecognizedRow(entry: entry, l10n: l10n, mixLimit: widget.mixLimit),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: StatusPill(label, tone: tone),
      title: Text(entry.source, overflow: TextOverflow.ellipsis),
      subtitle: Text(detail),
    );
  }
}
