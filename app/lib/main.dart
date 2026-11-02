import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_explode/ka7_engine_explode.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'platform/android_background.dart';
import 'platform/android_ytdlp.dart';
import 'platform/media_store.dart';
import 'platform/shared_links.dart';
import 'platform/user_folders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Same folder as the CLI on desktop: one archive, one history.
  final support = await getApplicationSupportDirectory();
  final store = Ka7Store.open(File('${support.path}/ka7.sqlite'));
  runApp(
    Platform.isAndroid || Platform.isIOS
        ? await _mobile(store)
        : await _desktop(store, support),
  );
}

/// yt-dlp and ffmpeg, installed by the app when missing.
Future<Ka7App> _desktop(Ka7Store store, Directory support) async {
  final home = Platform.environment['HOME'] ?? support.path;
  Future<String> folder(UserFolder kind) =>
      userFolder(kind, run: Process.run, home: home);
  return Ka7App(
    engineSetup: EngineBinaries(
      folder: '${support.path}/bin',
      run: Process.run,
      fetch: httpFetch,
    ),
    enginesFor: (status) => (
      extractor: YtDlpExtractor(run: Process.run, executable: status!.ytDlp!),
      downloader: YtDlpDownloader(
        start: Process.start,
        executable: status.ytDlp!,
        ffmpegPath: status.ffmpeg,
      ),
    ),
    store: store,
    defaultFolders: {
      MediaFormat.mp3: await folder(UserFolder.music),
      MediaFormat.mp4: await folder(UserFolder.videos),
    },
    pickFolder: FilePicker.getDirectoryPath,
    openFolder: (path) => Process.run('xdg-open', [path]),
  );
}

/// Android: yt-dlp, Python and ffmpeg embedded (youtubedl-android), then
/// youtube_explode as a fallback.
/// iOS: youtube_explode in Dart, original audio (m4a) and mp4, no ffmpeg yet.
Future<Ka7App> _mobile(Ka7Store store) async {
  // Android: the app's own external folder (then MediaStore), no permission.
  // iOS: Documents, shown in the Files app.
  final root = Platform.isAndroid
      ? (await getExternalStorageDirectory())!
      : await getApplicationDocumentsDirectory();
  final folders = {
    MediaFormat.mp3: '${root.path}/Music',
    MediaFormat.mp4: '${root.path}/Movies',
  };
  if (Platform.isAndroid) {
    final ytDlp = AndroidYtDlp();
    // youtube_explode takes over when yt-dlp breaks (m4a and mp4 only).
    final explode = ExplodeEngine(source: YoutubeExplodeSource());
    return Ka7App(
      engineSetup: AndroidEngineSetup(ytDlp),
      enginesFor: (_) => (
        extractor: FallbackExtractor([YtDlpExtractor(run: ytDlp.run), explode]),
        // Then moved to Music/Ka7 or Movies/Ka7, seen by every player.
        downloader: PublishingDownloader(
          FallbackDownloader({
            'yt-dlp': YtDlpDownloader(start: ytDlp.start),
            explode.name: explode,
          }),
          folders: (format) =>
              folders[format == MediaFormat.mp4 ? format : MediaFormat.mp3]!,
          publish: AndroidMediaStore().publish,
        ),
      ),
      store: store,
      formats: const [MediaFormat.mp3, MediaFormat.m4a, MediaFormat.mp4],
      sharedLinks: sharedLinks(),
      background: AndroidBackgroundWork(),
      // Downloaded first to the app's own folder, no picker: MediaStore files them.
      defaultFolders: folders,
    );
  }
  final engine = ExplodeEngine(source: YoutubeExplodeSource());
  return Ka7App(
    enginesFor: (_) => (extractor: engine, downloader: engine),
    store: store,
    formats: const [MediaFormat.m4a, MediaFormat.mp4],
    defaultFolders: folders,
    pickFolder: FilePicker.getDirectoryPath,
  );
}
