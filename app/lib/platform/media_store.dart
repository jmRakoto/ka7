import 'package:flutter/services.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart' show FileExists;

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
    final path = request.destination;
    final relative = _relative(folders(request.format), path);
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

  /// Whether files made under [folders] are still in the shared library
  /// (or still in the app's folder, [stillLocal], when they were not moved).
  FileExists existsFor(
    String Function(MediaFormat format) folders, {
    required Future<bool> Function(String path) stillLocal,
    String? Function(MediaFormat format)? tree,
  }) => (path, format) async {
    if (await stillLocal(path)) return true;
    final relative = _relative(folders(format), path);
    if (tree?.call(format) case final tree?) {
      return await _channel.invokeMethod<bool>('existsTree', {
            'tree': tree,
            ..._inFolder(relative),
          }) ??
          false;
    }
    final where = _place(relative, format);
    return await _channel.invokeMethod<bool>('exists', where) ?? false;
  };

  /// Where to play a file made under [folders] from: still in the app's
  /// folder, or its address in the shared library (`content://`, read by
  /// the player); null when it is in neither.
  Future<String?> Function(String path, MediaFormat format) locateFor(
    String Function(MediaFormat format) folders, {
    required Future<bool> Function(String path) stillLocal,
    String? Function(MediaFormat format)? tree,
  }) => (path, format) async {
    if (await stillLocal(path)) return path;
    final relative = _relative(folders(format), path);
    if (tree?.call(format) case final tree?) {
      return _channel.invokeMethod<String>('locateTree', {
        'tree': tree,
        ..._inFolder(relative),
      });
    }
    return _channel.invokeMethod<String>('locate', _place(relative, format));
  };

  Future<void> publish(
    String path,
    String relative,
    MediaFormat format, {
    String? tree,
  }) => tree == null
      ? _channel.invokeMethod<void>('publish', {
          'path': path,
          ..._place(relative, format),
        })
      // A folder the user chose: subfolders kept, under it.
      : _channel.invokeMethod<void>('publishTree', {
          'path': path,
          'tree': tree,
          ..._inFolder(relative),
        });

  /// Subfolder and name of [relative].
  static Map<String, String> _inFolder(String relative) {
    final slash = relative.lastIndexOf('/');
    return {
      'folder': slash < 0 ? '' : relative.substring(0, slash),
      'name': relative.substring(slash + 1),
    };
  }

  /// Folder, name and type in the shared library of a file filed under
  /// [relative] in the app's folder.
  static Map<String, String> _place(String relative, MediaFormat format) {
    final slash = relative.lastIndexOf('/');
    final subfolder = slash < 0 ? '' : '/${relative.substring(0, slash)}';
    return {
      'folder':
          '${format == MediaFormat.mp4 ? 'Movies' : 'Music'}/Ka7$subfolder',
      'name': relative.substring(slash + 1),
      'mime': switch (format) {
        MediaFormat.mp3 => 'audio/mpeg',
        MediaFormat.m4a => 'audio/mp4',
        MediaFormat.mp4 => 'video/mp4',
      },
    };
  }
}

/// [path] under [root], or [path] itself when elsewhere.
String _relative(String root, String path) =>
    path.startsWith('$root/') ? path.substring(root.length + 1) : path;
