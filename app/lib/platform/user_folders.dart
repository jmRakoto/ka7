import 'dart:io';

import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

/// Kind of folder, as `xdg-user-dir` (Linux) and .NET (Windows) name it.
enum UserFolder {
  music('MUSIC', 'MyMusic', 'Music'),
  videos('VIDEOS', 'MyVideos', 'Videos');

  const UserFolder(this.xdgName, this.windowsName, this.fallback);

  final String xdgName;

  /// `Environment.SpecialFolder` name: follows a folder moved to OneDrive.
  final String windowsName;

  /// Folder under home when the system names none.
  final String fallback;
}

/// The user's Music or Videos folder, localized by the system.
/// Linux: `xdg-user-dir`. Windows: asked to PowerShell.
Future<String> userFolder(
  UserFolder kind, {
  required RunProcess run,
  required String home,
  bool windows = false,
}) async {
  final fallback = windows
      ? '$home\\${kind.fallback}'
      : '$home/${kind.fallback}';
  try {
    final result = windows
        ? await run('powershell', [
            '-NoProfile',
            '-Command',
            "[Environment]::GetFolderPath('${kind.windowsName}')",
          ])
        : await run('xdg-user-dir', [kind.xdgName]);
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

/// Where Ka7 files by default: a Ka7 folder in the user's Music or Videos,
/// as Music/Ka7 and Movies/Ka7 on the phone.
Future<String> ka7Folder(
  UserFolder kind, {
  required RunProcess run,
  required String home,
  bool windows = false,
}) async {
  final folder = await userFolder(kind, run: run, home: home, windows: windows);
  return windows ? '$folder\\Ka7' : '$folder/Ka7';
}
