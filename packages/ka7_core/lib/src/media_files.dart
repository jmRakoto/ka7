import 'plain_text.dart';

/// A sound or video file found in a folder the user picked.
final class MediaFile {
  const MediaFile({required this.path, required this.name});

  /// What the player opens: a path, or a `content://` address on Android.
  final String path;

  /// Its file name, with the extension.
  final String name;

  /// The name without its extension.
  String get title {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  bool get isVideo => _video.contains(_extension(name));
}

const _audio = {'mp3', 'm4a', 'aac', 'flac', 'ogg', 'oga', 'opus', 'wav'};
const _video = {'mp4', 'm4v', 'webm', 'mkv', 'mov', 'avi'};

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// Whether a file of this name can be played.
bool isPlayable(String name) {
  final extension = _extension(name);
  return _audio.contains(extension) || _video.contains(extension);
}

/// Playable files only, by path as a person sorts them: numbers by value
/// (2 before 10), without case or accents; a subfolder's files stay
/// together.
List<MediaFile> playableSorted(Iterable<MediaFile> files) {
  final keyed = [
    for (final file in files)
      if (isPlayable(file.name)) (file, _pieces(plainText(file.path))),
  ]..sort((a, b) => _compare(a.$2, b.$2));
  return [for (final (file, _) in keyed) file];
}

/// Runs of digits and of the rest, digits as numbers.
List<Object> _pieces(String text) => [
  for (final match in RegExp(r'\d+|\D+').allMatches(text))
    switch (int.tryParse(match[0]!)) {
      final number? => number,
      null => match[0]!,
    },
];

int _compare(List<Object> a, List<Object> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    final order = switch ((a[i], b[i])) {
      (final int x, final int y) => x.compareTo(y),
      (final int _, String _) => -1,
      (String _, final int _) => 1,
      (final x, final y) => (x as String).compareTo(y as String),
    };
    if (order != 0) return order;
  }
  return a.length.compareTo(b.length);
}
