import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ka7_page.dart';
import 'run_view.dart';

/// One run of the queue, with the format and folder it writes to.
class QueuedRun {
  QueuedRun({
    required this.queue,
    required this.progress,
    required this.format,
    required this.folder,
  });

  final DownloadQueue queue;
  final RunProgress progress;
  final MediaFormat format;
  final String folder;
}

/// Flow 3: every run, newest first.
class QueueScreen extends StatelessWidget {
  const QueueScreen({
    super.key,
    required this.runs,
    required this.onRetry,
    this.interrupted = 0,
    this.onResume,
    this.onDiscard,
  });

  final List<QueuedRun> runs;

  /// Runs [downloads] again, in the format of [run].
  final void Function(QueuedRun run, List<PlannedDownload> downloads) onRetry;

  /// Videos a previous launch left unfinished.
  final int interrupted;
  final VoidCallback? onResume;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Ka7Page(
      title: l10n.runTitle,
      children: [
        if (interrupted > 0)
          _Interrupted(
            count: interrupted,
            onResume: onResume,
            onDiscard: onDiscard,
          ),
        if (runs.isEmpty && interrupted == 0)
          Text(
            l10n.queueEmpty,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        for (final run in runs) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${switch (run.format) {
                MediaFormat.mp3 => l10n.formatMp3,
                MediaFormat.m4a => l10n.formatM4a,
                MediaFormat.mp4 => l10n.formatMp4,
              }} · ${run.folder}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          RunView(
            run: run.progress,
            onCancel: run.queue.cancel,
            onRetry: (downloads) => onRetry(run, downloads),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }
}

/// Flow 0: the queue stopped last time (closed, crashed, network down).
class _Interrupted extends StatelessWidget {
  const _Interrupted({
    required this.count,
    required this.onResume,
    required this.onDiscard,
  });

  final int count;
  final VoidCallback? onResume;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.interruptedTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.interruptedBody(count),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.interruptedResume),
                  ),
                  OutlinedButton(
                    onPressed: onDiscard,
                    child: Text(l10n.interruptedDiscard),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
