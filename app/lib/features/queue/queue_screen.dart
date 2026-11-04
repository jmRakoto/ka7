import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ka7_page.dart';
import 'finished_run.dart';
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

  /// When its last video ended; null while it runs.
  DateTime? endedAt;

  /// Unfolded in the list; set the first time it shows there, then by the
  /// user, so a new run above does not fold it.
  bool? expanded;

  /// Its videos sent again since, alone or all together.
  final Set<PlannedDownload> retried = {};
}

/// Flow 3: the runs going on, then those ended, folded, newest first.
class QueueScreen extends StatelessWidget {
  const QueueScreen({
    super.key,
    required this.runs,
    required this.onRetry,
    this.onClear,
    this.thumbnail,
    this.shownFolder,
    this.interrupted = 0,
    this.onResume,
    this.onDiscard,
  });

  final List<QueuedRun> runs;

  /// Runs [downloads] again, in the format of [run].
  final void Function(QueuedRun run, List<PlannedDownload> downloads) onRetry;

  /// Forgets the ended runs.
  final VoidCallback? onClear;

  final ImageProvider Function(String videoId)? thumbnail;

  /// Where the user finds a format's files, when not the download folder.
  final String Function(MediaFormat format)? shownFolder;

  /// Videos a previous launch left unfinished.
  final int interrupted;
  final VoidCallback? onResume;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = [
      for (final run in runs)
        if (!run.progress.isDone) run,
    ];
    final ended =
        [
          for (final run in runs)
            // Every video sent again: nothing left to show here.
            if (run.progress.isDone &&
                run.progress.finished.any(
                  (item) => !run.retried.contains(item.download),
                ))
              run,
        ]..sort(
          (a, b) =>
              (b.endedAt ?? DateTime(0)).compareTo(a.endedAt ?? DateTime(0)),
        );
    String where(QueuedRun run) =>
        '${switch (run.format) {
          MediaFormat.mp3 => l10n.formatMp3,
          MediaFormat.m4a => l10n.formatM4a,
          MediaFormat.mp4 => l10n.formatMp4,
        }} · ${shownFolder?.call(run.format) ?? run.folder}';
    return Ka7Page(
      title: l10n.runTitle,
      children: [
        if (interrupted > 0)
          _Interrupted(
            count: interrupted,
            onResume: onResume,
            onDiscard: onDiscard,
          ),
        if (runs.isEmpty && interrupted == 0) EmptyState(l10n.queueEmpty),
        for (final run in active) ...[
          RunView(
            run: run.progress,
            where: where(run),
            onCancel: run.queue.cancel,
            onCancelOne: run.queue.cancelOne,
            thumbnail: thumbnail,
          ),
          const SizedBox(height: 28),
        ],
        if (ended.isNotEmpty)
          _Earlier(
            onClear: onClear,
            children: [
              for (final (i, run) in ended.indexed)
                FinishedRun(
                  key: ObjectKey(run),
                  run: run.progress,
                  where: where(run),
                  endedAt: run.endedAt,
                  thumbnail: thumbnail,
                  // Just ended with nothing else going: show what came of it.
                  initiallyExpanded: run.expanded ??= i == 0 && active.isEmpty,
                  onExpansionChanged: (open) => run.expanded = open,
                  retried: run.retried,
                  onRetry: (downloads) {
                    run.retried.addAll(downloads);
                    onRetry(run, downloads);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// The ended runs under « Plus tôt ». « Effacer » fades them out, slides
/// them aside and folds the room they took, then forgets them.
class _Earlier extends StatefulWidget {
  const _Earlier({required this.onClear, required this.children});

  final VoidCallback? onClear;
  final List<Widget> children;

  @override
  State<_Earlier> createState() => _EarlierState();
}

class _EarlierState extends State<_Earlier>
    with SingleTickerProviderStateMixin {
  late final _leaving = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _leaving,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _curve.dispose();
    _leaving.dispose();
    super.dispose();
  }

  Future<void> _clear() async {
    if (!MediaQuery.disableAnimationsOf(context)) await _leaving.reverse();
    widget.onClear!();
    // Ready for the runs that will end next.
    _leaving.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
          ).animate(_curve),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.queueEarlier,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onClear != null)
                    Tooltip(
                      message: l10n.queueClearHint,
                      child: TextButton.icon(
                        onPressed: _leaving.isAnimating ? null : _clear,
                        icon: const Icon(Icons.clear_all),
                        label: Text(l10n.queueClear),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ...widget.children,
            ],
          ),
        ),
      ),
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
