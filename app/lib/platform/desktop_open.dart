import 'dart:io';

import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

/// Opens a folder in the file manager, or a link in the browser.
/// Linux: `xdg-open`. Windows: Explorer, which hands links to the browser
/// and wants backslashes in folders.
Future<ProcessResult> openOnDesktop(
  String target, {
  required RunProcess run,
  required bool windows,
}) {
  if (!windows) return run('xdg-open', [target]);
  final isLink = target.startsWith(RegExp('https?://'));
  return run('explorer', [isLink ? target : target.replaceAll('/', r'\')]);
}
