import 'download.dart';
import 'probe.dart';

/// What happens to one queued video (flow 3), read by the app and the CLI.
sealed class JobEvent {
  const JobEvent(this.download);

  final PlannedDownload download;
}

final class JobStarted extends JobEvent {
  const JobStarted(super.download);
}

final class JobProgressed extends JobEvent {
  const JobProgressed(super.download, this.progress);

  final DownloadProgress progress;
}

final class JobSucceeded extends JobEvent {
  const JobSucceeded(super.download, this.path);

  /// Absolute path of the saved file.
  final String path;
}

/// Already in the archive: not downloaded again.
final class JobSkipped extends JobEvent {
  const JobSkipped(super.download);
}

final class JobFailed extends JobEvent {
  const JobFailed(super.download, this.reason, [this.message = '']);

  final FailureReason reason;
  final String message;
}

/// Stopped by the user, or never started because the run was cancelled.
final class JobCancelled extends JobEvent {
  const JobCancelled(super.download);
}

/// How a run ended, for the summary (flow 4).
final class RunSummary {
  RunSummary(Iterable<JobEvent> events) {
    for (final event in events) {
      switch (event) {
        case JobSucceeded():
          succeeded.add(event);
        case JobSkipped():
          skipped.add(event);
        case JobFailed():
          failed.add(event);
        case JobCancelled():
          cancelled.add(event);
        case JobStarted() || JobProgressed():
          break;
      }
    }
  }

  final List<JobSucceeded> succeeded = [];
  final List<JobSkipped> skipped = [];
  final List<JobFailed> failed = [];
  final List<JobCancelled> cancelled = [];
}
