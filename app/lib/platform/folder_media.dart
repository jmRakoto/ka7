import 'dart:io';

import 'package:ka7_core/ka7_core.dart';

/// The playable files in [folder] and its subfolders, sorted; empty when the
/// folder is gone or cannot be read.
Future<List<MediaFile>> listFolderMedia(String folder) async {
  final directory = Directory(folder);
  if (!await directory.exists()) return const [];
  final files = <MediaFile>[];
  try {
    await for (final entry in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      files.add(MediaFile(path: entry.path, name: name));
    }
  } on FileSystemException {
    // A subfolder that cannot be read: what was found so far.
  }
  return playableSorted(files);
}

/// How the folder is shown: under the home folder, from there.
String folderLabel(String path, {required String home}) {
  final prefix = home.endsWith('/') ? home : '$home/';
  if (!path.startsWith(prefix)) return path;
  final rest = path.substring(prefix.length).replaceAll(RegExp(r'/+$'), '');
  return rest.isEmpty ? home : rest;
}
