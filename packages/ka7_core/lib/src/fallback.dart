import 'dart:async';

import 'download.dart';
import 'link_entry.dart';
import 'probe.dart';
import 'search_channels.dart';

/// Failures every engine would agree on: no point asking the next one.
const _final = {FailureReason.private, FailureReason.unavailable};

/// Reads a link with the first engine that manages to (flow 3: "another
/// engine exists").
final class FallbackExtractor implements Extractor, ChannelPictures {
  FallbackExtractor(this.engines);

  /// From the first engine able to find one; a failure is just no picture.
  @override
  Future<String?> pictureOf(String channelId) async {
    for (final engine in engines.whereType<ChannelPictures>()) {
      try {
        if (await engine.pictureOf(channelId) case final picture?) {
          return picture;
        }
      } on Object {
        continue;
      }
    }
    return null;
  }

  /// In the order to try them.
  final List<Extractor> engines;

  @override
  String get name => engines.map((e) => e.name).join(' → ');

  @override
  Future<Probe> probe(MediaEntry entry) async {
    final failures = <(String, ProbeFailure)>[];
    for (final engine in engines) {
      try {
        return await engine.probe(entry);
      } on ProbeFailure catch (failure) {
        if (_final.contains(failure.reason)) rethrow;
        failures.add((engine.name, failure));
      } on Object catch (error) {
        failures.add((
          engine.name,
          ProbeFailure(FailureReason.unknown, '$error'),
        ));
      }
    }
    throw ProbeFailure(
      _firstReason([for (final (_, f) in failures) f.reason]),
      _joined([for (final (name, f) in failures) (name, f.message)]),
    );
  }
}

/// Downloads with the first engine that manages to.
final class FallbackDownloader implements Downloader {
  FallbackDownloader(this.engines);

  /// Engine name → downloader, in the order to try them.
  final Map<String, Downloader> engines;

  @override
  Stream<DownloadProgress> download(DownloadRequest request) {
    StreamSubscription<DownloadProgress>? current;
    late final StreamController<DownloadProgress> progress;
    progress = StreamController(
      onListen: () async {
        final failures = <(String, DownloadFailure)>[];
        for (final MapEntry(key: name, value: engine) in engines.entries) {
          final done = Completer<DownloadFailure?>();
          current = engine
              .download(request)
              .listen(
                progress.add,
                onError: (Object error) => done.complete(
                  error is DownloadFailure
                      ? error
                      : DownloadFailure(FailureReason.unknown, '$error'),
                ),
                onDone: () {
                  if (!done.isCompleted) done.complete(null);
                },
                cancelOnError: true,
              );
          final failure = await done.future;
          if (failure == null) return progress.close();
          failures.add((name, failure));
          if (_final.contains(failure.reason)) break;
        }
        progress.addError(
          DownloadFailure(
            _firstReason([for (final (_, f) in failures) f.reason]),
            _joined([for (final (name, f) in failures) (name, f.message)]),
          ),
        );
        await progress.close();
      },
      onCancel: () => current?.cancel(),
    );
    return progress.stream;
  }
}

/// The most telling reason: "this engine cannot make the format" says less
/// than why the engine that could make it failed.
FailureReason _firstReason(List<FailureReason> reasons) => reasons.firstWhere(
  (r) => r != FailureReason.formatUnsupported,
  orElse: () => reasons.firstOrNull ?? FailureReason.unknown,
);

String _joined(List<(String, String)> messages) =>
    [for (final (name, message) in messages) '$name: $message'].join('\n');
