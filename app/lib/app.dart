import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

import 'features/onboarding/onboarding_screen.dart';
import 'features/player/media_backend.dart';
import 'features/player/player_controller.dart';
import 'features/shell/ka7_shell.dart';
import 'features/startup/engine_gate.dart';
import 'l10n/app_localizations.dart';
import 'platform/background_work.dart';
import 'platform/run_notifier.dart';
import 'settings/app_settings.dart';
import 'theme/ka7_theme.dart';
import 'widgets/ka7_splash.dart';

/// The engines built once yt-dlp and ffmpeg are found.
typedef Engines = ({Extractor extractor, Downloader downloader});

/// Root of Ka7.
class Ka7App extends StatefulWidget {
  const Ka7App({
    super.key,
    this.engineSetup,
    required this.enginesFor,
    required this.store,
    required this.defaultFolders,
    this.pickFolder,
    this.openFolder,
    this.formats = const [MediaFormat.mp3, MediaFormat.mp4],
    this.sharedLinks,
    this.background,
    this.acceptDrops = false,
    this.pickLinksFile,
    this.notifier,
    this.shownFolder,
    this.askNotifications,
    this.thumbnail,
    this.picture,
    this.appVersion,
    this.latestRelease,
    this.openUrl,
    this.fileExists,
    this.pickDestination,
    this.mediaBackend,
    this.pickMediaFolder,
    this.listMediaFolder,
    this.onPlayer,
    this.now = DateTime.now,
  });

  /// Picks a folder to play as a list (its address and how to show it);
  /// null where none can be picked.
  /// [from]: where it opens, the music folder of Settings (a path, or a
  /// `content://` tree on Android).
  final Future<({String folder, String label})?> Function(String? from)?
  pickMediaFolder;

  /// Handed the player once it exists: the system's media session
  /// (Android notification, lock screen); null where there is none.
  final void Function(PlayerController player, AppLocalizations l10n)? onPlayer;

  /// The playable files of a folder, read each time its list opens.
  final Future<List<MediaFile>> Function(String folder)? listMediaFolder;

  /// Makes the player's backend; null where nothing can be played.
  final MediaBackend Function()? mediaBackend;

  /// Android: the system's folder picker, for where files are filed in the
  /// end; null where the download folder is the final one (desktop) or none
  /// can be chosen.
  final Future<Destination?> Function()? pickDestination;

  /// Whether a downloaded file is still there; null to trust the archive.
  final FileExists? fileExists;

  /// This build's version (`0.2.0`); null where unknown (tests, debug).
  final String? appVersion;

  /// The latest published Ka7 (GitHub); null to never ask.
  final Future<AppRelease?> Function()? latestRelease;

  /// Opens a web page in the browser.
  final void Function(String url)? openUrl;

  /// Picture of a video in the preview, by id; none when null (tests).
  final ImageProvider Function(String videoId)? thumbnail;

  /// A picture from the web by address (channel avatars); none when null.
  final ImageProvider Function(String url)? picture;

  /// Finds yt-dlp and ffmpeg, or installs them (flow 0); null when the
  /// engine is built into the app (mobile).
  final EngineSetup? engineSetup;

  /// [settings] are read when the engines need them (mix limit).
  final Engines Function(EngineStatus? status, AppSettings settings) enginesFor;

  /// Says when downloads end while the app is in the background.
  final RunNotifier? notifier;

  /// Where the user finds a format's files, when not the download folder
  /// (Android: moved to Music/Ka7 or Movies/Ka7 afterwards).
  final String Function(MediaFormat format)? shownFolder;

  /// Asks the system for notifications, once the welcome pages are done
  /// (Android 13+), rather than in the middle of a first download.
  final VoidCallback? askNotifications;

  /// Keeps downloads going with the screen off (Android).
  final BackgroundWork? background;

  /// Links, text and `.txt` files dropped on the window go to Add (desktop).
  final bool acceptDrops;

  /// Native picker on a `links.txt`, returning its text; null when closed.
  final Future<String?> Function()? pickLinksFile;

  /// Text shared to Ka7 from another app (YouTube's share menu).
  final Stream<String>? sharedLinks;

  /// Formats the engine can make; the first one is preselected.
  final List<MediaFormat> formats;

  /// Archive, history and settings, shared with the CLI.
  final Ka7Store store;

  /// Music and Videos folders of the system, until the user picks others.
  final Map<MediaFormat, String> defaultFolders;

  /// Native folder picker; null where the system files downloads itself
  /// (Android: Music and Movies, through MediaStore).
  final Future<String?> Function()? pickFolder;

  /// Opens a folder in the file manager; null where the system cannot.
  final void Function(String folder)? openFolder;
  final DateTime Function() now;

  @override
  State<Ka7App> createState() => _Ka7AppState();
}

class _Ka7AppState extends State<Ka7App> {
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    AppSettings.load(widget.store, widget.defaultFolders).then((settings) {
      if (mounted) setState(() => _settings = settings);
    });
  }

  @override
  void dispose() {
    _settings?.dispose();
    super.dispose();
  }

  Widget _shell(AppSettings settings, EngineStatus? status) {
    final engines = widget.enginesFor(status, settings);
    return Ka7Shell(
      extractor: engines.extractor,
      downloader: engines.downloader,
      store: widget.store,
      settings: settings,
      formats: widget.formats,
      sharedLinks: widget.sharedLinks,
      background: widget.background,
      acceptDrops: widget.acceptDrops,
      pickLinksFile: widget.pickLinksFile,
      notifier: widget.notifier,
      shownFolder: widget.shownFolder,
      thumbnail: widget.thumbnail,
      picture: widget.picture,
      appVersion: widget.appVersion,
      latestRelease: widget.latestRelease,
      openUrl: widget.openUrl,
      fileExists: widget.fileExists,
      pickDestination: widget.pickDestination,
      mediaBackend: widget.mediaBackend,
      pickMediaFolder: widget.pickMediaFolder,
      listMediaFolder: widget.listMediaFolder,
      onPlayer: widget.onPlayer,
      pickFolder: widget.pickFolder,
      openFolder: widget.openFolder,
      now: widget.now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    // A moment, while the saved choices load: the splash, in system colours.
    if (settings == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ka7Theme(Brightness.light),
        darkTheme: ka7Theme(Brightness.dark),
        home: const Ka7Splash(),
      );
    }
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Ka7',
        debugShowCheckedModeBanner: false,
        theme: ka7Theme(Brightness.light),
        darkTheme: ka7Theme(Brightness.dark),
        themeMode: settings.theme,
        locale: switch (settings.language) {
          final language? => Locale(language),
          null => null,
        },
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: _resolveLocale,
        home: !settings.onboarded
            ? OnboardingScreen(
                onDone: () {
                  settings.completeOnboarding();
                  widget.askNotifications?.call();
                },
                settings: settings,
                canDrop: widget.acceptDrops,
                canShare: widget.sharedLinks != null,
              )
            : switch (widget.engineSetup) {
                final setup? => EngineGate(
                  setup: setup,
                  builder: (context, status) => _shell(settings, status),
                ),
                null => _shell(settings, null),
              },
      ),
    );
  }
}

/// French unless the requested language is one Ka7 speaks.
Locale _resolveLocale(Locale? requested, Iterable<Locale> supported) =>
    supported.firstWhere(
      (l) => l.languageCode == requested?.languageCode,
      orElse: () => const Locale('fr'),
    );
