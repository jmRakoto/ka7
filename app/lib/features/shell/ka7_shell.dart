import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../l10n/app_localizations.dart';
import '../../platform/background_work.dart';
import '../../settings/app_settings.dart';
import '../../widgets/ka7_wordmark.dart';
import '../add_links/add_links_screen.dart';
import '../library/library_screen.dart';
import '../preview/preview_screen.dart';
import '../queue/queue_screen.dart';
import '../settings/settings_screen.dart';

/// Below this width, the sections move from the sidebar to a bottom bar.
const _sidebarWidth = 720.0;

enum _Section { add, queue, library, settings }

/// Sidebar (or bottom bar) and the four sections; owns the running queues.
class Ka7Shell extends StatefulWidget {
  const Ka7Shell({
    super.key,
    required this.extractor,
    required this.downloader,
    required this.store,
    required this.settings,
    required this.pickFolder,
    required this.openFolder,
    required this.now,
    this.formats = const [MediaFormat.mp3, MediaFormat.mp4],
    this.sharedLinks,
    this.background,
  });

  final Extractor extractor;
  final Downloader downloader;
  final Ka7Store store;
  final AppSettings settings;
  final Future<String?> Function()? pickFolder;
  final void Function(String folder)? openFolder;
  final DateTime Function() now;
  final List<MediaFormat> formats;

  /// Text shared to Ka7 from another app: lands in the Add field.
  final Stream<String>? sharedLinks;

  /// Keeps downloads going with the screen off (Android).
  final BackgroundWork? background;

  @override
  State<Ka7Shell> createState() => _Ka7ShellState();
}

class _Ka7ShellState extends State<Ka7Shell> {
  var _section = _Section.add;
  final _addNavigator = GlobalKey<NavigatorState>();

  /// Newest first.
  final _runs = <QueuedRun>[];
  final _subscriptions = <StreamSubscription<JobEvent>>[];
  final _historyChanges = ValueNotifier(0);
  final _links = TextEditingController();
  StreamSubscription<String>? _shared;

  @override
  void initState() {
    super.initState();
    _shared = widget.sharedLinks?.listen(_receive);
  }

  /// A link shared from YouTube: back to Add, below what is already there.
  /// YouTube shares the title with the link: only the links are kept.
  void _receive(String text) {
    final links = [
      for (final word in text.split(RegExp(r'\s+')))
        if (parseEntry(word) is MediaEntry) word,
    ];
    final added = links.isEmpty ? text.trim() : links.join('\n');
    final current = _links.text.trimRight();
    _links.text = current.isEmpty ? added : '$current\n$added';
    _addNavigator.currentState?.popUntil((route) => route.isFirst);
    setState(() => _section = _Section.add);
  }

  @override
  void dispose() {
    for (final run in _runs) {
      run.queue.cancel();
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    widget.background?.release();
    _historyChanges.dispose();
    _shared?.cancel();
    _links.dispose();
    super.dispose();
  }

  /// Joins the running queue of [format], or starts a new one.
  void _download(List<PlannedDownload> downloads, MediaFormat format) {
    final running = _runs
        .where((run) => run.format == format && !run.progress.isDone)
        .firstOrNull;
    if (running != null && running.queue.add(downloads)) {
      setState(() {
        running.progress.add(downloads);
        _section = _Section.queue;
      });
      _keepAwake();
      return;
    }
    final folder = widget.settings.folderFor(format);
    final run = QueuedRun(
      queue: DownloadQueue(
        downloader: widget.downloader,
        folder: folder,
        format: format,
        archive: widget.store,
      ),
      progress: RunProgress(downloads),
      format: format,
      folder: folder,
    );
    _subscriptions.add(
      run.queue.run(downloads).listen((event) async {
        if (mounted) {
          setState(() => run.progress.apply(event));
          _keepAwake();
        }
        if (event is JobStarted || event is JobProgressed) return;
        await widget.store.record(event, format, widget.now());
        _historyChanges.value++;
      }),
    );
    setState(() {
      _runs.insert(0, run);
      _section = _Section.queue;
    });
    _keepAwake();
  }

  void _preview(List<MediaEntry> entries) => _addNavigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (context) => PreviewScreen(
        entries: entries,
        extractor: widget.extractor,
        formats: widget.formats,
        onDownload: (downloads, format) {
          Navigator.of(context).pop();
          _download(downloads, format);
        },
      ),
    ),
  );

  /// Asks Android to keep the app alive while something is left to do.
  void _keepAwake() {
    final background = widget.background;
    if (background == null) return;
    final active = [
      for (final run in _runs)
        if (!run.progress.isDone) run.progress,
    ];
    if (active.isEmpty) return background.release();
    background.keep(
      title: AppLocalizations.of(context).notificationTitle,
      done: active.fold(0, (sum, run) => sum + run.finished.length),
      total: active.fold(0, (sum, run) => sum + run.items.length),
    );
  }

  int get _pending => _runs.fold(
    0,
    (sum, run) =>
        sum + run.progress.running.length + run.progress.waiting.length,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = _pending;
    final sections = [
      (Icons.add_link, l10n.navAdd),
      (Icons.downloading, l10n.navQueue),
      (Icons.library_music_outlined, l10n.navLibrary),
      (Icons.settings_outlined, l10n.navSettings),
    ];
    Widget icon(int index, IconData data) =>
        index == _Section.queue.index && pending > 0
        ? Badge.count(count: pending, child: Icon(data))
        : Icon(data);

    final body = IndexedStack(
      index: _section.index,
      children: [
        Navigator(
          key: _addNavigator,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => AddLinksScreen(onPreview: _preview, links: _links),
          ),
        ),
        QueueScreen(
          runs: _runs,
          onRetry: (run, downloads) => _download(downloads, run.format),
        ),
        LibraryScreen(
          store: widget.store,
          changes: _historyChanges,
          openFolder: widget.openFolder,
        ),
        SettingsScreen(
          settings: widget.settings,
          pickFolder: widget.pickFolder,
        ),
      ],
    );
    void select(int index) => setState(() => _section = _Section.values[index]);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _sidebarWidth) {
          return Scaffold(
            body: SafeArea(child: body),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _section.index,
              onDestinationSelected: select,
              destinations: [
                for (final (i, (data, label)) in sections.indexed)
                  NavigationDestination(icon: icon(i, data), label: label),
              ],
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _section.index,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 20),
                  child: Ka7Wordmark(size: 20),
                ),
                destinations: [
                  for (final (i, (data, label)) in sections.indexed)
                    NavigationRailDestination(
                      icon: icon(i, data),
                      label: Text(label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
