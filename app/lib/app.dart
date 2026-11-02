import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/ka7_shell.dart';
import 'features/startup/engine_gate.dart';
import 'l10n/app_localizations.dart';
import 'platform/background_work.dart';
import 'platform/run_notifier.dart';
import 'settings/app_settings.dart';
import 'theme/ka7_theme.dart';

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
    this.now = DateTime.now,
  });

  /// Finds yt-dlp and ffmpeg, or installs them (flow 0); null when the
  /// engine is built into the app (mobile).
  final EngineSetup? engineSetup;

  /// [settings] are read when the engines need them (mix limit).
  final Engines Function(EngineStatus? status, AppSettings settings) enginesFor;

  /// Says when downloads end while the app is in the background.
  final RunNotifier? notifier;

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
      pickFolder: widget.pickFolder,
      openFolder: widget.openFolder,
      now: widget.now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) return const SizedBox.shrink();
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
            ? OnboardingScreen(onDone: settings.completeOnboarding)
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
