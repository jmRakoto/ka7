import 'dart:io';

import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

/// Kind of folder, as `xdg-user-dir` names it.
enum UserFolder {
  music('MUSIC', 'Music'),
  videos('VIDEOS', 'Videos');

  const UserFolder(this.xdgName, this.fallback);

  final String xdgName;

  /// Folder under home when the system names none.
  final String fallback;
}

/// The user's Music or Videos folder, localized by the system (Linux).
Future<String> userFolder(
  UserFolder kind, {
  required RunProcess run,
  required String home,
}) async {
  final fallback = '$home/${kind.fallback}';
  try {
    final result = await run('xdg-user-dir', [kind.xdgName]);
    final path = (result.stdout as String).trim();
    // xdg-user-dir answers home itself for a folder it does not know.
    final known =
        result.exitCode == 0 &&
        path.isNotEmpty &&
        path != home &&
        path != '$home/';
    return known ? path : fallback;
  } on ProcessException {
    return fallback;
  }
}
