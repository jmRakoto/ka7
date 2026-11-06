import 'package:flutter/services.dart';
import 'package:ka7_core/ka7_core.dart';

import '../settings/app_settings.dart';

const _channel = MethodChannel('mg.rakoto.ka7/folders');

/// Android's folder picker (any folder, SD card included); Ka7 keeps the
/// right to write there. Null when closed. Kotlin side: `FolderPicker.kt`.
///
/// [from]: where it opens, a folder picked before (`content://` tree);
/// otherwise Music/Ka7.
Future<Destination?> pickAndroidFolder({String? from}) async {
  final picked = await _channel.invokeMapMethod<String, String>(
    'pick',
    from == null ? null : {'from': from},
  );
  return switch (picked) {
    {'uri': final uri, 'label': final label} => (uri: uri, label: label),
    _ => null,
  };
}

/// The playable files under [tree] (a folder from [pickAndroidFolder]),
/// subfolders too, sorted by their place in it; empty when it cannot be read.
Future<List<MediaFile>> listAndroidFolder(String tree) async {
  final List<Map<Object?, Object?>> found;
  try {
    found =
        await _channel.invokeListMethod<Map<Object?, Object?>>('list', {
          'uri': tree,
        }) ??
        const [];
  } on PlatformException {
    return const [];
  }
  // Sorted by the place in the folder: `content://` addresses do not say it.
  final byPlace = {
    for (final file in found)
      file['path']! as String: MediaFile(
        path: file['uri']! as String,
        name: file['name']! as String,
      ),
  };
  return [
    for (final place in playableSorted([
      for (final path in byPlace.keys) MediaFile(path: path, name: path),
    ]))
      byPlace[place.path]!,
  ];
}
