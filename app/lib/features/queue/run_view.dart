import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../theme/ka7_theme.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';

/// Flows 3 and 4: one run of the queue, then its summary.
class RunView extends StatelessWidget {
  const RunView({
    super.key,
    required this.run,
    required this.onCancel,
    required this.onRetry,
    this.onCancelOne,
  });

  /// Stops one video, running or waiting; the others go on.
  final ValueChanged<PlannedDownload>? onCancelOne;

  final RunProgress run;
  final VoidCallback onCancel;

  /// Called with the failed and cancelled videos to run them again.
  final ValueChanged<List<PlannedDownload>> onRetry;

  VoidCallback? _cancelOf(RunItem item) => switch (onCancelOne) {
    final cancel? => () => cancel(item.download),
    null => null,
  };

  List<RunItem> _ended(RunItemStatus status) => [
    for (final item in run.finished)
      if (item.status == status) item,
  ];

  Future<void> _copyFailed(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failed = [
      for (final item in _ended(RunItemStatus.failed))
        JobFailed(item.download, item.reason!, item.message),
    ];
    await Clipboard.setData(
      ClipboardData(text: formatFailedLinks(failed, DateTime.now())),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.copiedFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failed = _ended(RunItemStatus.failed);
    final toRetry = [...failed, ..._ended(RunItemStatus.cancelled)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (run.isDone)
          _Summary(run: run, ended: _ended)
        else
          _Overall(run: run, onCancel: onCancel),
        if (run.isDone && toRetry.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      onRetry([for (final item in toRetry) item.download]),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryButton),
                ),
                if (failed.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _copyFailed(context),
                    icon: const Icon(Icons.content_copy),
                    label: Text(l10n.copyFailed),
                  ),
              ],
            ),
          ),
        if (run.running.isNotEmpty) ...[
          SectionTitle(l10n.runRunning),
          for (final item in run.running)
            _RunningTile(item: item, onCancel: _cancelOf(item)),
        ],
        if (run.waiting.isNotEmpty) ...[
          SectionTitle(l10n.runWaiting),
          for (final item in run.waiting)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.download.item.title),
              trailing: _CancelOne(onPressed: _cancelOf(item)),
            ),
        ],
        if (run.finished.isNotEmpty) ...[
          SectionTitle(l10n.runFinished),
          for (final item in run.finished.toList().reversed)
            _FinishedTile(item: item),
        ],
      ],
    );
  }
}

const _tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// `1,5 Mo/s` or `1.5 MB/s`.
String _speedText(AppLocalizations l10n, double bytesPerSecond) {
  final value = (bytesPerSecond / 1e6).toStringAsFixed(1);
  return l10n.speed(
    l10n.localeName == 'fr' ? value.replaceAll('.', ',') : value,
  );
}

class _Overall extends StatelessWidget {
  const _Overall({required this.run, required this.onCancel});

  final RunProgress run;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.runCount(run.finished.length, run.items.length),
                    style: theme.textTheme.titleLarge?.merge(_tabular),
                  ),
                ),
                if (run.speed case final speed?)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _speedText(l10n, speed),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                          .merge(_tabular),
                    ),
                  ),
                OutlinedButton(
                  onPressed: onCancel,
                  child: Text(l10n.cancelAll),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: run.fraction,
              semanticsLabel: l10n.runTitle,
              semanticsValue: l10n.percent((run.fraction * 100).round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.run, required this.ended});

  final RunProgress run;
  final List<RunItem> Function(RunItemStatus) ended;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<Ka7StatusColors>()!;
    final counts = [
      (ended(RunItemStatus.succeeded).length, l10n.countSucceeded, PillTone.ok),
      (ended(RunItemStatus.skipped).length, l10n.countSkipped, PillTone.warn),
      (ended(RunItemStatus.failed).length, l10n.countFailed, PillTone.danger),
      (
        ended(RunItemStatus.cancelled).length,
        l10n.countCancelled,
        PillTone.neutral,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: colors.ok),
                const SizedBox(width: 8),
                Text(
                  l10n.runDone,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (count, label, tone) in counts)
                  if (count > 0) StatusPill(label(count), tone: tone),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningTile extends StatelessWidget {
  const _RunningTile({required this.item, required this.onCancel});

  final RunItem item;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = l10n.percent((item.fraction * 100).round());
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.download.item.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LinearProgressIndicator(
          value: item.fraction,
          semanticsLabel: item.download.item.title,
          semanticsValue: percent,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            percent,
            style: Theme.of(context).textTheme.bodyMedium?.merge(_tabular),
          ),
          _CancelOne(onPressed: onCancel),
        ],
      ),
    );
  }
}

/// ✕ on one video of the queue; nothing where it cannot be stopped.
class _CancelOne extends StatelessWidget {
  const _CancelOne({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: AppLocalizations.of(context).cancelOne,
      onPressed: onPressed,
      icon: const Icon(Icons.close),
    );
  }
}

class _FinishedTile extends StatelessWidget {
  const _FinishedTile({required this.item});

  final RunItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<Ka7StatusColors>()!;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (label, icon, color, tone) = switch (item.status) {
      RunItemStatus.succeeded => (
        l10n.statusSucceeded,
        Icons.check_circle,
        colors.ok,
        PillTone.ok,
      ),
      RunItemStatus.skipped => (
        l10n.statusSkipped,
        Icons.redo,
        colors.warn,
        PillTone.warn,
      ),
      RunItemStatus.failed => (
        l10n.statusFailed,
        Icons.error,
        colors.danger,
        PillTone.danger,
      ),
      _ => (l10n.statusCancelled, Icons.cancel, muted, PillTone.neutral),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(item.download.item.title),
      subtitle: item.reason == null
          ? null
          : Text(failureText(l10n, item.reason!)),
      trailing: StatusPill(label, tone: tone),
    );
  }
}
