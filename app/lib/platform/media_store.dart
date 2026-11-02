import 'package:flutter/services.dart';
import 'package:ka7_core/ka7_core.dart';

/// Moves a finished file to the shared library ("Music/Ka7/…" on Android),
/// [relative] being its path under the download folder.
typedef Publish =
    Future<void> Function(String path, String relative, MediaFormat format);

/// Wraps an engine: each file it finishes is handed to [publish], so it shows
/// in the phone's music and video apps.
final class PublishingDownloader implements Downloader {
  PublishingDownloader(
    this.inner, {
    required this.folders,
    required this.publish,
  });

  final Downloader inner;

  /// Download folder of each format, the root [publish] paths are relative to.
  final String Function(MediaFormat format) folders;
  final Publish publish;

  @override
  Stream<DownloadProgress> download(DownloadRequest request) async* {
    var failed = false;
    // yield* passes errors on but carries on after them.
    yield* inner.download(request).handleError((Object error) {
      failed = true;
      throw error;
    });
    if (failed) return;
    final root = '${folders(request.format)}/';
    final path = request.destination;
    final relative = path.startsWith(root) ? path.substring(root.length) : path;
    try {
      await publish(path, relative, request.format);
    } on Object catch (error) {
      throw DownloadFailure(FailureReason.unknown, '$error');
    }
  }
}

/// Android's shared library: files land in Music/Ka7 or Movies/Ka7, where
/// every music and video app finds them. Kotlin side: `MediaStoreChannel.kt`.
class AndroidMediaStore {
  AndroidMediaStore([
    this._channel = const MethodChannel('mg.rakoto.ka7/media'),
  ]);

  final MethodChannel _channel;

  Future<void> publish(String path, String relative, MediaFormat format) {
    final slash = relative.lastIndexOf('/');
    final subfolder = slash < 0 ? '' : '/${relative.substring(0, slash)}';
    return _channel.invokeMethod<void>('publish', {
      'path': path,
      'folder':
          '${format == MediaFormat.mp4 ? 'Movies' : 'Music'}/Ka7$subfolder',
      'name': relative.substring(slash + 1),
      'mime': switch (format) {
        MediaFormat.mp3 => 'audio/mpeg',
        MediaFormat.m4a => 'audio/mp4',
        MediaFormat.mp4 => 'video/mp4',
      },
    });
  }
}
