import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/failure_text.dart';
import '../../theme/ka7_theme.dart';
import '../../widgets/appear.dart';
import '../../widgets/ka7_logo.dart';
import '../../widgets/ka7_page.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/video_thumbnail.dart';

/// Flow 3: one run of the queue while it goes; once ended, `FinishedRun`.
class RunView extends StatelessWidget {
  const RunView({
    super.key,
    required this.run,
    required this.onCancel,
    this.onCancelOne,
    this.thumbnail,
    this.where,
  });

  final ImageProvider Function(String videoId)? thumbnail;

  /// Format and folder, as the user reads them.
  final String? where;

  /// Stops one video, running or waiting; the others go on.
  final ValueChanged<PlannedDownload>? onCancelOne;

  final RunProgress run;
  final VoidCallback onCancel;

  VoidCallback? _cancelOf(RunItem item) => switch (onCancelOne) {
    final cancel? => () => cancel(item.download),
    null => null,
  };

  Widget? _picture(RunItem item) => switch (thumbnail) {
    final thumbnail? => VideoThumbnail(
      image: thumbnail(item.download.item.videoId),
      width: 64,
    ),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // One card: the run on top, its videos below, by state.
    Widget section(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SectionTitle(title), ...rows],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Overall(run: run, onCancel: onCancel, where: where),
          if (run.running.isNotEmpty)
            section(l10n.runRunning, [
              for (final item in run.running)
                Appear(
                  key: ObjectKey(item),
                  child: _RunningTile(
                    item: item,
                    picture: _picture(item),
                    onCancel: _cancelOf(item),
                  ),
                ),
            ]),
          if (run.waiting.isNotEmpty)
            section(l10n.runWaiting, [
              for (final item in run.waiting)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  // Not started yet: quieter.
                  leading: switch (_picture(item)) {
                    final picture? => Opacity(opacity: 0.55, child: picture),
                    null => null,
                  },
                  title: _TwoLines(item.download.item.title),
                  textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  trailing: _CancelOne(onPressed: _cancelOf(item)),
                ),
            ]),
          if (run.finished.isNotEmpty)
            section(l10n.runFinished, [
              for (final item in run.finished.toList().reversed)
                Appear(
                  key: ObjectKey(item),
                  child: _FinishedTile(item: item, picture: _picture(item)),
                ),
            ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TwoLines extends StatelessWidget {
  const _TwoLines(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
}

const _tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// `1,5 Mo/s` or `1.5 MB/s`.
String _speedText(AppLocalizations l10n, double bytesPerSecond) {
  final value = (bytesPerSecond / 1e6).toStringAsFixed(1);
  return l10n.speed(
    l10n.localeName == 'fr' ? value.replaceAll('.', ',') : value,
  );
}

/// The run itself: the cassette turning with it, what it is, how far.
class _Overall extends StatelessWidget {
  const _Overall({
    required this.run,
    required this.onCancel,
    required this.where,
  });

  final RunProgress run;
  final VoidCallback onCancel;
  final String? where;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    return DecoratedBox(
      // A soft violet wash, fading into the card.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surfaceContainerLowest],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // The tape turns as the run moves on.
                TweenAnimationBuilder<double>(
                  tween: Tween(end: run.fraction * 6),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, turns, _) => ExcludeSemantics(
                    child: Ka7Logo(width: 52, reelTurns: turns),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.runActive,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (where case final where?)
                        Text(
                          where,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  Text(
                    l10n.runCount(run.finished.length, run.items.length),
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)
                        .merge(_tabular),
                  ),
                  const SizedBox(width: 10),
                  if (run.speed case final speed?)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, size: 15, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            _speedText(l10n, speed),
                            style: theme.textTheme.labelMedium?.merge(_tabular),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(l10n.cancelAll),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: run.fraction,
                  minHeight: 8,
                  semanticsLabel: l10n.runTitle,
                  semanticsValue: l10n.percent((run.fraction * 100).round()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningTile extends StatelessWidget {
  const _RunningTile({
    required this.item,
    required this.picture,
    required this.onCancel,
  });

  final RunItem item;
  final Widget? picture;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = l10n.percent((item.fraction * 100).round());
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: picture,
      title: _TwoLines(item.download.item.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: item.fraction,
            minHeight: 4,
            semanticsLabel: item.download.item.title,
            semanticsValue: percent,
          ),
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
  const _FinishedTile({required this.item, required this.picture});

  final RunItem item;
  final Widget? picture;

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
      leading: picture ?? Icon(icon, color: color),
      title: _TwoLines(item.download.item.title),
      subtitle: item.reason == null
          ? null
          : Text(failureText(l10n, item.reason!)),
      trailing: StatusPill(label, tone: tone),
    );
  }
}
