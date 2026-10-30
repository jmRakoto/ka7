import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import 'recognized_entry.dart';

/// Flow 1: paste links, IDs or a whole list; Ka7 recognizes each line.
class AddLinksScreen extends StatefulWidget {
  const AddLinksScreen({super.key});

  @override
  State<AddLinksScreen> createState() => _AddLinksScreenState();
}

class _AddLinksScreenState extends State<AddLinksScreen> {
  final _links = TextEditingController();
  List<LinkEntry> _entries = const [];

  @override
  void dispose() {
    _links.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: _links,
            maxLines: null,
            onChanged: (text) => setState(() => _entries = parseLinks(text)),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final entry in _entries)
                  _RecognizedRow(entry: entry, l10n: l10n),
              ],
            ),
          ),
        ],
      ),
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
    return ListTile(
      leading: Text(label),
      title: Text(entry.source),
      subtitle: Text(detail),
    );
  }
}
