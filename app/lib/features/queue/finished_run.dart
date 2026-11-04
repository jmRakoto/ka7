import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../theme/ka7_theme.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/video_thumbnail.dart';

/// Flow 4: a run that ended, folded into one line (what came of it, format,
/// folder, time); unfolded, its videos and what can be done again.
class FinishedRun extends StatelessWidget {
  const FinishedRun({
    super.key,
    required this.run,
    required this.where,
    required this.endedAt,
    required this.onRetry,
    this.initiallyExpanded = false,
    this.thumbnail,
    this.retried = const {},
    this.onExpansionChanged,
  });

  final ValueChanged<bool>? onExpansionChanged;

  /// Videos sent again since: shown in their new run, not here.
  final Set<PlannedDownload> retried;

  final RunProgress run;

  /// Format and folder, as the user reads them.
  final String where;
  final DateTime? endedAt;
  final bool initiallyExpanded;
  final ImageProvider Function(String videoId)? thumbnail;

  /// Called with the failed and cancelled videos to run them again.
  final ValueChanged<List<PlannedDownload>> onRetry;

  /// What ended here and stays here: a video sent again left this run.
  List<RunItem> get _kept => [
    for (final item in run.finished)
      if (!retried.contains(item.download)) item,
  ];

  List<RunItem> _ended(RunItemStatus status) => [
    for (final item in _kept)
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
    final theme = Theme.of(context);
    final colors = theme.extension<Ka7StatusColors>()!;
    final succeeded = _ended(RunItemStatus.succeeded).length;
    final skipped = _ended(RunItemStatus.skipped).length;
    final failed = _ended(RunItemStatus.failed);
    final cancelled = _ended(RunItemStatus.cancelled);
    final toRetry = [...failed, ...cancelled];
    // The worst that happened first: a failure must not hide behind a ✓.
    final (icon, color) = failed.isNotEmpty
        ? (Icons.error, colors.danger)
        : succeeded > 0
        ? (Icons.check_circle, colors.ok)
        : skipped > 0
        ? (Icons.redo, colors.warn)
        : (Icons.cancel, theme.colorScheme.onSurfaceVariant);
    final time = switch (endedAt) {
      final at? =>
        ' · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
      null => '',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icon, color: color),
        title: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (succeeded > 0)
              StatusPill(l10n.countSucceeded(succeeded), tone: PillTone.ok),
            if (skipped > 0)
              StatusPill(l10n.countSkipped(skipped), tone: PillTone.warn),
            if (failed.isNotEmpty)
              StatusPill(
                l10n.countFailed(failed.length),
                tone: PillTone.danger,
              ),
            if (cancelled.isNotEmpty)
              StatusPill(l10n.countCancelled(cancelled.length)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$where$time',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in _kept.reversed)
            _EndedTile(
              item: item,
              thumbnail: thumbnail,
              onRetry: toRetry.contains(item)
                  ? () => onRetry([item.download])
                  : null,
            ),
          if (toRetry.isNotEmpty)
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      onRetry([for (final item in toRetry) item.download]),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryButton),
                ),
                if (failed.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _copyFailed(context),
                    icon: const Icon(Icons.content_copy),
                    label: Text(l10n.copyFailed),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One video of an ended run: picture, title, why it failed, how it ended.
class _EndedTile extends StatelessWidget {
  const _EndedTile({
    required this.item,
    required this.thumbnail,
    required this.onRetry,
  });

  final RunItem item;

  /// Sends this video alone again; null when it ended well or went again.
  final VoidCallback? onRetry;
  final ImageProvider Function(String videoId)? thumbnail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = switch (item.status) {
      RunItemStatus.succeeded => (l10n.statusSucceeded, PillTone.ok),
      RunItemStatus.skipped => (l10n.statusSkipped, PillTone.warn),
      RunItemStatus.failed => (l10n.statusFailed, PillTone.danger),
      _ => (l10n.statusCancelled, PillTone.neutral),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: switch (thumbnail) {
        final thumbnail? => VideoThumbnail(
          image: thumbnail(item.download.item.videoId),
          width: 64,
        ),
        null => null,
      },
      title: Text(
        item.download.item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.reason == null
          ? null
          : Text(failureText(l10n, item.reason!)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusPill(label, tone: tone),
          if (onRetry != null)
            IconButton(
              tooltip: l10n.retryOne,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
