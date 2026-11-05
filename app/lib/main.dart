import 'dart:convert';
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
import 'platform/desktop_notifier.dart';
import 'platform/desktop_open.dart';
import 'platform/media_store.dart';
import 'platform/open_url.dart';
import 'platform/shared_links.dart';
import 'platform/android_folders.dart';
import 'platform/user_folders.dart';
import 'settings/app_settings.dart';

/// This build's version, given by the packaging scripts
/// (`--dart-define=KA7_VERSION=…`); none in `flutter run`, so no update
/// check while developing.
String? get _appVersion =>
    switch (const String.fromEnvironment('KA7_VERSION')) {
      '' => null,
      final version => version,
    };

/// YouTube's own picture of a video, 320×180.
ImageProvider _thumbnail(String videoId) =>
    NetworkImage('https://i.ytimg.com/vi/$videoId/mqdefault.jpg');

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
  final windows = Platform.isWindows;
  final home =
      Platform.environment[windows ? 'USERPROFILE' : 'HOME'] ?? support.path;
  // ~/Musique/Ka7 and ~/Vidéos/Ka7: Ka7's own folders, as on the phone.
  Future<String> folder(UserFolder kind) =>
      ka7Folder(kind, run: Process.run, home: home, windows: windows);
  Future<void> open(String target) =>
      openOnDesktop(target, run: Process.run, windows: windows);
  final binaries = EngineBinaries(
    folder: '${support.path}/bin',
    run: Process.run,
    fetch: httpFetch,
    windows: windows,
  );
  return Ka7App(
    thumbnail: _thumbnail,
    picture: NetworkImage.new,
    engineSetup: _daily(store, binaries, (b) => b.updateYtDlp()),
    enginesFor: (status, settings) => (
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
    openFolder: open,
    acceptDrops: true,
    appVersion: _appVersion,
    latestRelease: fetchLatestRelease,
    openUrl: open,
    pickLinksFile: _pickLinksFile,
    // Linux only (notify-send); Windows: nothing yet.
    notifier: windows ? null : DesktopNotifier(run: Process.run),
    // Original audio too (no re-encoding), as on Android.
    formats: const [MediaFormat.mp3, MediaFormat.m4a, MediaFormat.mp4],
    // Deleted by hand: no longer « already there ».
    fileExists: (path, _) => File(path).exists(),
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
    final notifier = AndroidRunNotifier();
    final mediaStore = AndroidMediaStore();
    // Loaded by Ka7App, handed over with the engines, before any download.
    AppSettings? destinations;
    String folderOf(MediaFormat format) =>
        folders[format == MediaFormat.mp4 ? format : MediaFormat.mp3]!;
    return Ka7App(
      thumbnail: _thumbnail,
      picture: NetworkImage.new,
      engineSetup: _daily(
        store,
        AndroidEngineSetup(ytDlp),
        (s) => s.updateYtDlp(),
      ),
      enginesFor: (_, settings) {
        destinations = settings;
        return (
          extractor: FallbackExtractor([
            YtDlpExtractor(run: ytDlp.run),
            explode,
          ]),
          // Then moved to Music/Ka7 or Movies/Ka7, seen by every player.
          downloader: PublishingDownloader(
            FallbackDownloader({
              'yt-dlp': YtDlpDownloader(start: ytDlp.start),
              explode.name: explode,
            }),
            folders: folderOf,
            // Where the user chose, or Music/Ka7 and Movies/Ka7.
            publish: (path, relative, format) => mediaStore.publish(
              path,
              relative,
              format,
              tree: settings.destinationFor(format)?.uri,
            ),
          ),
        );
      },
      store: store,
      formats: const [MediaFormat.mp3, MediaFormat.m4a, MediaFormat.mp4],
      sharedLinks: sharedLinks(),
      background: AndroidBackgroundWork(),
      notifier: notifier,
      askNotifications: notifier.askPermission,
      appVersion: _appVersion,
      latestRelease: fetchLatestRelease,
      openUrl: openUrlOnAndroid,
      // Downloaded to the app's own folder, then moved by MediaStore.
      shownFolder: (format) =>
          format == MediaFormat.mp4 ? 'Movies/Ka7' : 'Music/Ka7',
      pickLinksFile: _pickLinksFile,
      // Deleted by hand from Music/Ka7: no longer « already there ».
      fileExists: mediaStore.existsFor(
        folderOf,
        stillLocal: (path) => File(path).exists(),
        tree: (format) => destinations?.destinationFor(format)?.uri,
      ),
      pickDestination: pickAndroidFolder,
      // Downloaded first to the app's own folder, no picker: MediaStore files them.
      defaultFolders: folders,
    );
  }
  final engine = ExplodeEngine(source: YoutubeExplodeSource());
  return Ka7App(
    thumbnail: _thumbnail,
    picture: NetworkImage.new,
    enginesFor: (_, settings) => (extractor: engine, downloader: engine),
    store: store,
    formats: const [MediaFormat.m4a, MediaFormat.mp4],
    defaultFolders: folders,
    pickLinksFile: _pickLinksFile,
    pickFolder: FilePicker.getDirectoryPath,
  );
}

/// When the app's own yt-dlp last updated itself (ISO 8601, UTC).
const _ytDlpUpdatedKey = 'ytdlp.updated';

/// Native picker on a `links.txt` (flow 1, import a file).
Future<String?> _pickLinksFile() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['txt'],
  );
  if (files.isEmpty) return null;
  return utf8.decode(await files.first.readAsBytes(), allowMalformed: true);
}

/// [setup], with yt-dlp updated at most once a day when the tools are
/// checked (desktop: the app's own copy; Android: the embedded one).
DailyUpdate _daily<S extends EngineSetup>(
  Ka7Store store,
  S setup,
  Future<bool> Function(S setup) update,
) => DailyUpdate(
  setup,
  update: () => update(setup),
  lastUpdate: () async =>
      DateTime.tryParse(await store.setting(_ytDlpUpdatedKey) ?? ''),
  saveUpdate: (at) =>
      store.setSetting(_ytDlpUpdatedKey, at.toUtc().toIso8601String()),
  now: DateTime.now,
);
