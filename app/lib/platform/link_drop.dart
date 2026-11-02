import 'dart:io';

/// What a drop on the window brings to Add: dropped text and links as they
/// are, `.txt` files read, every other file left out.
Future<String> droppedText(Iterable<String> items) async {
  final parts = <String>[];
  for (final item in items) {
    if (FileSystemEntity.typeSync(item) == FileSystemEntityType.notFound) {
      parts.add(item);
    } else if (item.toLowerCase().endsWith('.txt')) {
      try {
        parts.add(await File(item).readAsString());
      } on FileSystemException {
        // Unreadable: left out, like any file that is not text.
      }
    }
  }
  return parts.map((part) => part.trim()).where((p) => p.isNotEmpty).join('\n');
}
