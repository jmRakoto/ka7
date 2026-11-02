import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'download.dart';
import 'file_naming.dart';
import 'job_event.dart';
import 'probe.dart';

/// Runs planned downloads with one engine, a few at a time (flow 3).
final class DownloadQueue {
  DownloadQueue({
    required this.downloader,
    required this.folder,
    required this.format,
    this.archive,
    this.concurrency = 2,
  });

  final Downloader downloader;

  /// Absolute download folder.
  final String folder;
  final MediaFormat format;
  final Archive? archive;
  final int concurrency;

  final _running = <_RunningJob>{};
  var _cancelled = false;

  /// The run in progress: its events and the videos still waiting.
  StreamController<JobEvent>? _events;
  final _waiting = Queue<PlannedDownload>();
  var _workers = 0;

  /// Downloads [downloads]; the stream closes once each one has ended,
  /// including those [add]ed meanwhile.
  Stream<JobEvent> run(List<PlannedDownload> downloads) {
    final events = StreamController<JobEvent>();
    _events = events;
    _waiting
      ..clear()
      ..addAll(downloads);
    _cancelled = false;
    events.onListen = () {
      _spawnWorkers();
      if (_workers == 0) _finish();
    };
    return events.stream;
  }

  /// Adds [downloads] to the running queue; false once the run is over.
  bool add(List<PlannedDownload> downloads) {
    if (_events == null || _cancelled) return false;
    _waiting.addAll(downloads);
    if (_events!.hasListener) _spawnWorkers();
    return true;
  }

  void _spawnWorkers() {
    final idle = min(concurrency - _workers, _waiting.length);
    for (var i = 0; i < idle; i++) {
      _workers++;
      _work();
    }
  }

  Future<void> _work() async {
    final events = _events!;
    while (_waiting.isNotEmpty && !_cancelled) {
      await _runOne(_waiting.removeFirst(), events.add);
    }
    if (--_workers == 0) _finish();
  }

  void _finish() {
    final events = _events!;
    _waiting.map(JobCancelled.new).forEach(events.add);
    _waiting.clear();
    _events = null;
    events.close();
  }

  /// Stops the running downloads and drops the waiting ones.
  void cancel() {
    _cancelled = true;
    for (final job in _running) {
      job.subscription.cancel();
      job.end(JobCancelled(job.download));
    }
  }

  Future<void> _runOne(
    PlannedDownload download,
    void Function(JobEvent) emit,
  ) async {
    final videoId = download.item.videoId;
    if (await archive?.contains(videoId, format) ?? false) {
      return emit(JobSkipped(download));
    }
    if (_cancelled) return emit(JobCancelled(download));

    emit(JobStarted(download));
    final destination = '$folder/${relativePathOf(download, format)}';
    final ended = Completer<JobEvent>();
    final job = _RunningJob(download, ended);
    job.subscription = downloader
        .download(_requestFor(download, destination))
        .listen(
          (progress) => emit(JobProgressed(download, progress)),
          onError: (Object error) => job.end(_failureOf(download, error)),
          onDone: () => job.end(JobSucceeded(download, destination)),
          cancelOnError: true,
        );
    _running.add(job);
    final event = await ended.future;
    _running.remove(job);
    if (event is JobSucceeded) await archive?.add(videoId, format);
    emit(event);
  }

  DownloadRequest _requestFor(PlannedDownload download, String destination) {
    final inPlaylist = download.source.playlistId != null;
    return DownloadRequest(
      videoId: download.item.videoId,
      format: format,
      destination: destination,
      tags: TrackTags(
        title: download.item.title,
        artist: download.item.channel,
        album: inPlaylist ? download.source.title : null,
        trackNumber: inPlaylist && !download.source.isChannel
            ? download.index
            : null,
      ),
    );
  }
}

JobFailed _failureOf(PlannedDownload download, Object error) =>
    error is DownloadFailure
    ? JobFailed(download, error.reason, error.message)
    : JobFailed(download, FailureReason.unknown, '$error');

/// A download in progress, which ends once: done, failed or cancelled.
final class _RunningJob {
  _RunningJob(this.download, this._ended);

  final PlannedDownload download;
  final Completer<JobEvent> _ended;
  late final StreamSubscription<DownloadProgress> subscription;

  void end(JobEvent event) {
    if (!_ended.isCompleted) _ended.complete(event);
  }
}
