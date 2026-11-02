import 'download.dart';
import 'job_event.dart';
import 'probe.dart';

/// Where one queued video stands.
enum RunItemStatus { waiting, running, succeeded, skipped, failed, cancelled }

/// One queued video, as the screens show it.
final class RunItem {
  RunItem(this.download);

  final PlannedDownload download;
  RunItemStatus status = RunItemStatus.waiting;

  /// From 0 to 1 while running.
  double fraction = 0;
  DownloadProgress? progress;

  /// Saved file, once succeeded.
  String? path;
  FailureReason? reason;
  String message = '';
}

/// A run of downloads followed event by event (flows 3 and 4).
final class RunProgress {
  RunProgress(List<PlannedDownload> downloads)
    : items = [for (final download in downloads) RunItem(download)];

  final List<RunItem> items;

  final List<RunItem> _finished = [];

  /// Follows [downloads] too, added to the running queue.
  void add(List<PlannedDownload> downloads) =>
      items.addAll([for (final download in downloads) RunItem(download)]);

  void apply(JobEvent event) {
    final item = items.firstWhere((i) => identical(i.download, event.download));
    switch (event) {
      case JobStarted():
        item.status = RunItemStatus.running;
      case JobProgressed(:final progress):
        item
          ..status = RunItemStatus.running
          ..progress = progress
          ..fraction = progress.fraction;
      case JobSucceeded(:final path):
        _end(item, RunItemStatus.succeeded).path = path;
      case JobSkipped():
        _end(item, RunItemStatus.skipped);
      case JobFailed(:final reason, :final message):
        _end(item, RunItemStatus.failed)
          ..reason = reason
          ..message = message;
      case JobCancelled():
        _end(item, RunItemStatus.cancelled);
    }
  }

  RunItem _end(RunItem item, RunItemStatus status) {
    _finished.add(item);
    return item
      ..status = status
      ..fraction = 1
      ..progress = null;
  }

  Iterable<RunItem> get running =>
      items.where((i) => i.status == RunItemStatus.running);
  Iterable<RunItem> get waiting =>
      items.where((i) => i.status == RunItemStatus.waiting);

  /// Ended videos, in the order they ended.
  Iterable<RunItem> get finished => _finished;

  /// Whole run, from 0 to 1.
  double get fraction => items.isEmpty
      ? 1
      : items.fold(0.0, (sum, i) => sum + i.fraction) / items.length;

  /// Bytes per second of the running downloads; null when unknown.
  double? get speed {
    final speeds = [for (final item in running) ?item.progress?.speed];
    return speeds.isEmpty ? null : speeds.fold<double>(0, (a, b) => a + b);
  }

  bool get isDone => _finished.length == items.length;
}
