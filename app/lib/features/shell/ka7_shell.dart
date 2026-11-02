import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import '../../l10n/app_localizations.dart';
import '../../platform/background_work.dart';
import '../../platform/link_drop.dart';
import '../../platform/run_notifier.dart';
import '../../settings/app_settings.dart';
import '../../widgets/ka7_logo.dart';
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
    this.acceptDrops = false,
    this.pickLinksFile,
    this.notifier,
    this.shownFolder,
  });

  /// Where the user finds a format's files, when not the download folder.
  final String Function(MediaFormat format)? shownFolder;

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

  /// Links, text and `.txt` files dropped on the window go to Add (desktop).
  final bool acceptDrops;

  /// Native picker on a `links.txt`, returning its text; null when closed.
  final Future<String?> Function()? pickLinksFile;

  /// Says when downloads end while the app is in the background.
  final RunNotifier? notifier;

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

  /// Something dragged over the window, not dropped yet.
  var _dragging = false;

  /// Followed playlists and channels, and their new videos found at launch.
  var _followed = <Subscription>[];
  final _news = ValueNotifier(<News>[]);

  /// Videos a previous launch left unfinished, until resumed or discarded.
  var _interrupted = <PendingDownload>[];

  /// Store id of each queued video, dropped once it ends.
  final _pendingIds = Expando<int>();

  @override
  void initState() {
    super.initState();
    _shared = widget.sharedLinks?.listen(_receive);
    _loadSubscriptions().then((_) => _checkNews());
    widget.store.pending().then((pending) {
      if (!mounted || pending.isEmpty) return;
      setState(() {
        _interrupted = pending;
        _section = _Section.queue;
      });
    });
  }

  /// A link shared from YouTube: back to Add, below what is already there.
  /// YouTube shares the title with the link: only the links are kept.
  void _receive(String text) {
    final links = [
      for (final word in text.split(RegExp(r'\s+')))
        if (parseEntry(word) is MediaEntry) word,
    ];
    _addToLinks(links.isEmpty ? text : links.join('\n'));
  }

  Future<void> _drop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    _addToLinks(await droppedText(details.files.map((file) => file.path)));
  }

  /// Below what is already in the Add field, then shows Add.
  void _addToLinks(String text) {
    if (!mounted) return;
    final added = text.trim();
    if (added.isEmpty) return;
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
    _news.dispose();
    _shared?.cancel();
    _links.dispose();
    super.dispose();
  }

  /// Joins the running queue of [format] and [folder] (by default the one
  /// chosen in Settings), or starts a new one.
  Future<void> _download(
    List<PlannedDownload> downloads,
    MediaFormat format, [
    String? folder,
  ]) async {
    folder ??= widget.settings.folderFor(format);
    // Kept before it starts: a crash from here on can be resumed.
    final ids = await widget.store.keepPending(downloads, format, folder);
    if (!mounted) return;
    for (final (i, download) in downloads.indexed) {
      _pendingIds[download] = ids[i];
    }
    final running = _runs
        .where(
          (run) =>
              run.format == format &&
              run.folder == folder &&
              !run.progress.isDone,
        )
        .firstOrNull;
    if (running != null && running.queue.add(downloads)) {
      setState(() {
        running.progress.add(downloads);
        _section = _Section.queue;
      });
      _keepAwake();
      return;
    }
    final run = QueuedRun(
      queue: DownloadQueue(
        downloader: widget.downloader,
        folder: folder,
        format: format,
        archive: widget.store,
        concurrency: widget.settings.concurrency,
        layout: widget.settings.layout,
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
          if (run.progress.isDone) _notifyEnd(run.progress);
        }
        if (event is JobStarted || event is JobProgressed) return;
        await widget.store.record(event, format, widget.now());
        if (_pendingIds[event.download] case final id?) {
          await widget.store.dropPending(id);
        }
        _historyChanges.value++;
      }),
    );
    setState(() {
      _runs.insert(0, run);
      _section = _Section.queue;
    });
    _keepAwake();
  }

  /// Queues again what a previous launch left unfinished, where it was going.
  Future<void> _resume() async {
    final interrupted = _forgetInterrupted();
    final runs = <(MediaFormat, String), List<PlannedDownload>>{};
    for (final pending in interrupted) {
      runs
          .putIfAbsent((pending.format, pending.folder), () => [])
          .add(pending.download);
    }
    for (final MapEntry(key: (format, folder), value: downloads)
        in runs.entries) {
      await _download(downloads, format, folder);
    }
    // Only now: a crash while queuing again still finds them next time.
    for (final pending in interrupted) {
      await widget.store.dropPending(pending.id);
    }
  }

  /// Gives up on what a previous launch left unfinished: cancelled in the
  /// history.
  Future<void> _discard() async {
    for (final pending in _forgetInterrupted()) {
      await widget.store.record(
        JobCancelled(pending.download),
        pending.format,
        widget.now(),
      );
      await widget.store.dropPending(pending.id);
    }
    _historyChanges.value++;
  }

  List<PendingDownload> _forgetInterrupted() {
    final interrupted = _interrupted;
    setState(() => _interrupted = []);
    return interrupted;
  }

  /// Only when the user looks elsewhere: in front, the queue says it all.
  void _notifyEnd(RunProgress progress) {
    final notifier = widget.notifier;
    final state = WidgetsBinding.instance.lifecycleState;
    if (notifier == null ||
        state == null ||
        state == AppLifecycleState.resumed) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    int count(RunItemStatus status) =>
        progress.finished.where((item) => item.status == status).length;
    notifier.finished(
      title: l10n.notifyDoneTitle,
      body: [
        for (final (status, text) in [
          (RunItemStatus.succeeded, l10n.countSucceeded),
          (RunItemStatus.skipped, l10n.countSkipped),
          (RunItemStatus.failed, l10n.countFailed),
          (RunItemStatus.cancelled, l10n.countCancelled),
        ])
          if (count(status) > 0) text(count(status)),
      ].join(' · '),
    );
  }

  Future<void> _loadSubscriptions() async {
    final subscriptions = await widget.store.subscriptions();
    if (mounted) setState(() => _followed = subscriptions);
  }

  /// Read in the background: the app is usable meanwhile.
  Future<void> _checkNews() async {
    if (_followed.isEmpty) return;
    final news = await findNews(
      [for (final s in _followed) (link: s.link, title: s.title)],
      extractor: widget.extractor,
      archive: widget.store,
      format: widget.formats.first,
    );
    if (mounted) _news.value = news;
  }

  bool _isFollowed(String link) => _followed.any((s) => s.link == link);

  Future<void> _follow(Probe probe, bool follow) async {
    final link = followLinkOf(probe)!;
    follow
        ? await widget.store.follow(link, probe.title)
        : await widget.store.unfollow(link);
    await _loadSubscriptions();
  }

  Future<void> _unfollow(Subscription subscription) async {
    await widget.store.unfollow(subscription.link);
    await _loadSubscriptions();
  }

  void _showNews() {
    final entries = [
      for (final news in _news.value)
        if (parseEntry(news.link) case final MediaEntry entry) entry,
    ];
    _news.value = const [];
    _preview(entries);
  }

  /// A playlist from the Library: its preview, with what is there unchecked.
  void _updatePlaylist(String playlistId) {
    _addNavigator.currentState?.popUntil((route) => route.isFirst);
    setState(() => _section = _Section.add);
    _preview([parseEntry(playlistId) as MediaEntry]);
  }

  void _preview(List<MediaEntry> entries) => _addNavigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (context) => PreviewScreen(
        entries: entries,
        extractor: widget.extractor,
        formats: widget.formats,
        archive: widget.store,
        isFollowed: _isFollowed,
        onFollow: _follow,
        onDownload: (downloads, format) {
          Navigator.of(context).pop();
          unawaited(_download(downloads, format));
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
            builder: (_) => ListenableBuilder(
              listenable: Listenable.merge([widget.settings, _news]),
              builder: (_, _) => AddLinksScreen(
                onPreview: _preview,
                links: _links,
                pickLinksFile: widget.pickLinksFile,
                mixLimit: widget.settings.mixLimit,
                news: _news.value,
                onShowNews: _showNews,
                onDismissNews: () => _news.value = const [],
              ),
            ),
          ),
        ),
        QueueScreen(
          runs: _runs,
          shownFolder: widget.shownFolder,
          onRetry: (run, downloads) =>
              unawaited(_download(downloads, run.format, run.folder)),
          interrupted: _interrupted.length,
          onResume: _resume,
          onDiscard: _discard,
        ),
        LibraryScreen(
          store: widget.store,
          changes: _historyChanges,
          openFolder: widget.openFolder,
          onUpdatePlaylist: _updatePlaylist,
        ),
        SettingsScreen(
          settings: widget.settings,
          pickFolder: widget.pickFolder,
          subscriptions: _followed,
          onUnfollow: _unfollow,
        ),
      ],
    );
    void select(int index) => setState(() => _section = _Section.values[index]);

    final window = LayoutBuilder(
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
                  child: Ka7Logo(width: 44),
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
    if (!widget.acceptDrops) return window;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _drop,
      child: Stack(
        children: [
          window,
          if (_dragging) const Positioned.fill(child: _DropHint()),
        ],
      ),
    );
  }
}

/// Over the whole window while links or a file are dragged over it.
class _DropHint extends StatelessWidget {
  const _DropHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return IgnorePointer(
      child: ColoredBox(
        color: colors.surface.withValues(alpha: 0.9),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_link, size: 40, color: colors.primary),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).dropHint,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
