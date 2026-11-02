import 'probe.dart';

/// Output file kind the user picks in the preview.
enum MediaFormat {
  mp3('mp3'),

  /// Original audio, without re-encoding: the default where ffmpeg is missing.
  m4a('m4a'),
  mp4('mp4');

  const MediaFormat(this.extension);

  final String extension;
}

/// Readable stand-ins for characters some system forbids in file names.
const _replacements = {
  '/': '-',
  r'\': '-',
  ':': ' -',
  '<': '(',
  '>': ')',
  '"': "'",
  '?': '',
  '*': '',
  '|': '',
};

final _controls = RegExp(r'[\x00-\x1f\x7f]');
final _spaces = RegExp(r'\s+');
final _trailingDotsOrSpaces = RegExp(r'[. ]+$');
final _reservedOnWindows = RegExp(
  r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$',
  caseSensitive: false,
);

/// Room left for the number, extension and folder in a 255-byte path segment.
const _maxLength = 150;

/// [name] made safe as one path segment on every system.
String safeFileName(String name) {
  var safe = name.replaceAll(_controls, ' ');
  for (final MapEntry(key: forbidden, value: replacement)
      in _replacements.entries) {
    safe = safe.replaceAll(forbidden, replacement);
  }
  safe = safe.replaceAll(_spaces, ' ').trim();
  if (safe.runes.length > _maxLength) {
    safe = String.fromCharCodes(safe.runes.take(_maxLength));
  }
  safe = safe.replaceAll(_trailingDotsOrSpaces, '');
  if (safe.isEmpty) return 'untitled';
  return _reservedOnWindows.hasMatch(safe) ? '_$safe' : safe;
}

/// Where [download] lands, relative to the download folder.
String relativePathOf(PlannedDownload download, MediaFormat format) {
  final title = safeFileName(download.item.title);
  final source = download.source;
  if (source.playlistId == null) return '$title.${format.extension}';
  final folder = safeFileName(source.title);
  if (source.isChannel) return '$folder/$title.${format.extension}';
  final width = source.items.length > 99 ? 3 : 2;
  final number = '${download.index}'.padLeft(width, '0');
  return '$folder/$number - $title.${format.extension}';
}
