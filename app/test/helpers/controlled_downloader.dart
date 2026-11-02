import 'dart:async';

import 'package:ka7_core/ka7_core.dart';

/// Engine double driven by the test: each download waits for its orders.
class ControlledDownloader implements Downloader {
  /// Video id → the stream the queue is listening to.
  final controllers = <String, StreamController<DownloadProgress>>{};
  final stopped = <String>[];
  final requests = <DownloadRequest>[];

  @override
  Stream<DownloadProgress> download(DownloadRequest request) {
    requests.add(request);
    final controller = StreamController<DownloadProgress>(
      onCancel: () => stopped.add(request.videoId),
    );
    controllers[request.videoId] = controller;
    return controller.stream;
  }

  void progress(String videoId, double fraction, {double? speed}) =>
      controllers[videoId]!.add(
        DownloadProgress(fraction: fraction, speed: speed),
      );

  void finish(String videoId) => controllers[videoId]!.close();

  void fail(String videoId, FailureReason reason) {
    controllers[videoId]!
      ..addError(DownloadFailure(reason))
      ..close();
  }
}
