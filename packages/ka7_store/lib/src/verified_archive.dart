import 'package:ka7_core/ka7_core.dart';

import 'ka7_store.dart';

/// Whether the file a download produced is still there.
typedef FileExists = Future<bool> Function(String path, MediaFormat format);

/// The archive of [store], checked against the files: a video whose file
/// was deleted is not « already there » any more.
final class VerifiedArchive implements Archive {
  VerifiedArchive(this.store, {required this.exists});

  final Ka7Store store;
  final FileExists exists;

  @override
  Future<bool> contains(String videoId, MediaFormat format) async {
    if (!await store.contains(videoId, format)) return false;
    final path = await store.lastPath(videoId, format);
    if (path == null || await exists(path, format)) return true;
    await store.unarchive(videoId, format);
    return false;
  }

  @override
  Future<void> add(String videoId, MediaFormat format) =>
      store.add(videoId, format);
}
