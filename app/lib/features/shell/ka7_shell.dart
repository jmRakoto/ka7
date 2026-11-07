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
import '../player/media_backend.dart';
import '../player/mini_player.dart';
import '../player/player_controller.dart';
import '../player/player_hub_screen.dart';
import '../player/player_screen.dart';
import '../player/track.dart';
import '../preview/preview_screen.dart';
import '../queue/queue_screen.dart';
import '../settings/settings_screen.dart';

/// Below this width, the sections move from the sidebar to a bottom bar.
const _sidebarWidth = 720.0;

enum _Section { add, queue, library, player, settings }

/// Sidebar (or bottom bar) and the sections (Lecteur only with a player);
/// owns the running queues.
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
    this.thumbnail,
    this.picture,
    this.fileExists,
    this.pickDestination,
    this.mediaBackend,
    this.pickMediaFolder,
    this.listMediaFolder,
    this.onPlayer,
    this.appVersion,
    this.latestRelease,
    this.openUrl,
  });

  /// This build's version; null where unknown.
  final String? appVersion;

  /// The latest published Ka7; null to never ask.
  final Future<AppRelease?> Function()? latestRelease;
  final void Function(String url)? openUrl;

  /// Picture of a video in the preview, by id; none when null (tests).
  final ImageProvider Function(String videoId)? thumbnail;

  /// A picture from the web by address (channel avatars).
  final ImageProvider Function(String url)? picture;

  /// Where the user finds a format's files, when not the download folder.
  final String Function(MediaFormat format)? shownFolder;

  final Extractor extractor;
  final Downloader downloader;
  final Ka7Store store;

  /// Whether a downloaded file is still there; null to trust the archive.
  final FileExists? fileExists;

  /// Makes the player's backend; null where nothing can be played.
  final MediaBackend Function()? mediaBackend;

  /// Picks a folder to play as a list; null where none can be picked.
  /// [from]: where it opens, the music folder of Settings (a path, or a
  /// `content://` tree on Android).
  final Future<({String folder, String label})?> Function(String? from)?
  pickMediaFolder;

  /// Handed the player once it exists: the system's media session
  /// (Android notification, lock screen); null where there is none.
  final void Function(PlayerController player, AppLocalizations l10n)? onPlayer;

  /// The playable files of a folder list.
  final Future<List<MediaFile>> Function(String folder)? listMediaFolder;

  /// Android: picks where files are filed in the end.
  final Future<Destination?> Function()? pickDestination;

  /// The folder the user finds a format's files in: the one they chose, or
  /// the system's default.
  String Function(MediaFormat format)? get _shownFolder =>
      switch (shownFolder) {
        final shown? =>
          (format) => settings.destinationFor(format)?.label ?? shown(format),
        null => null,
      };
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
  final _settingsNavigator = GlobalKey<NavigatorState>();
  final _playerNavigator = GlobalKey<NavigatorState>();

  /// Stream addresses asked while the preview shows, so ▶ starts at once;
  /// null without a player or an engine that gives them.
  late final StreamCache? _streams = switch ((
    widget.mediaBackend,
    widget.extractor,
  )) {
    (_?, final StreamUrls engine) => StreamCache(engine),
    _ => null,
  };

  /// The one player; null where nothing can be played.
  late final PlayerController? _player = switch (widget.mediaBackend) {
    final backend? => PlayerController(
      backend: backend(),
      streamUrl: _streams?.streamUrl,
      fileExists: switch (widget.fileExists) {
        // A folder's own files (FLAC…) have no Ka7 format: there, as read
        // when the list opened.
        final exists? => (track) => switch (track.format) {
          final format? => exists(track.path!, format),
          null => Future.value(true),
        },
        null => null,
      },
    ),
    null => null,
  };

  void _openPlayer() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PlayerScreen(player: _player!)),
  );

  /// Newest first.
  final _runs = <QueuedRun>[];
  final _subscriptions = <StreamSubscription<JobEvent>>[];
  final _historyChanges = ValueNotifier(0);

  /// « Already there » only while the file is: deleted, it can come again.
  late final Archive _archive = switch (widget.fileExists) {
    final exists? => VerifiedArchive(widget.store, exists: exists),
    null => widget.store,
  };

  /// Ticks when anything in the queue moves, for the open preview.
  final _queueChanges = ValueNotifier(0);
  final _links = TextEditingController();
  StreamSubscription<String>? _shared;

  /// Something dragged over the window, not dropped yet.
  var _dragging = false;

  /// Followed playlists and channels, and their new videos found at launch.
  final _followed = ValueNotifier(<Subscription>[]);
  final _news = ValueNotifier(<News>[]);

  /// A newer Ka7 to offer, until downloaded or put off.
  final _update = ValueNotifier<AppRelease?>(null);

  /// Videos a previous launch left unfinished, until resumed or discarded.
  var _interrupted = <PendingDownload>[];

  /// Store id of each queued video, dropped once it ends.
  final _pendingIds = Expando<int>();

  @override
  void initState() {
    super.initState();
    _shared = widget.sharedLinks?.listen(_receive);
    _loadSubscriptions().then((_) => _checkNews());
    _checkUpdate();
    _loadRecent();
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

  /// Handed to the system once, with the language it was first shown in.
  var _handedPlayer = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final player = _player;
    if (_handedPlayer || player == null) return;
    _handedPlayer = true;
    widget.onPlayer?.call(player, AppLocalizations.of(context));
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
    if (_player case final player?) {
      player.dispose();
      unawaited(player.backend.dispose());
    }
    _historyChanges.dispose();
    _followed.dispose();
    _queueChanges.dispose();
    _recent.dispose();
    _news.dispose();
    _update.dispose();
    _shared?.cancel();
    _links.dispose();
    super.dispose();
  }

  /// Joins the running queue of [format] and [folder] (by default the one
  /// chosen in Settings), or starts a new one.
  Future<void> _download(
    List<PlannedDownload> downloads,
    MediaFormat format, {
    String? folder,
    Quality? quality,
  }) async {
    folder ??= widget.settings.folderFor(format);
    quality ??= widget.settings.quality;
    // Kept before it starts: a crash from here on can be resumed.
    final ids = await widget.store.keepPending(
      downloads,
      format,
      folder,
      quality: quality,
    );
    if (!mounted) return;
    for (final (i, download) in downloads.indexed) {
      _pendingIds[download] = ids[i];
    }
    final running = _runs
        .where(
          (run) =>
              run.format == format &&
              run.folder == folder &&
              run.quality.audio == quality!.audio &&
              run.quality.video == quality.video &&
              !run.progress.isDone,
        )
        .firstOrNull;
    if (running != null && running.queue.add(downloads)) {
      setState(() {
        running.progress.add(downloads);
        _section = _Section.queue;
      });
      _keepAwake();
      _queueChanges.value++;
      return;
    }
    final run = QueuedRun(
      queue: DownloadQueue(
        downloader: widget.downloader,
        folder: folder,
        format: format,
        archive: _archive,
        concurrency: widget.settings.concurrency,
        quality: quality,
        layout: widget.settings.layout,
      ),
      progress: RunProgress(downloads),
      format: format,
      folder: folder,
      quality: quality,
    );
    _subscriptions.add(
      run.queue.run(downloads).listen((event) async {
        if (mounted) {
          setState(() {
            run.progress.apply(event);
            if (run.progress.isDone) run.endedAt ??= widget.now();
          });
          // A video moved to another state; progress alone changes nothing.
          if (event is! JobProgressed) _queueChanges.value++;
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
    _queueChanges.value++;
  }

  /// Queues again what a previous launch left unfinished, where it was going.
  Future<void> _resume() async {
    final interrupted = _forgetInterrupted();
    final runs =
        <
          (MediaFormat, String, AudioQuality, VideoQuality),
          List<PlannedDownload>
        >{};
    for (final pending in interrupted) {
      final q = pending.quality;
      runs
          .putIfAbsent((
            pending.format,
            pending.folder,
            q.audio,
            q.video,
          ), () => [])
          .add(pending.download);
    }
    for (final MapEntry(key: (format, folder, audio, video), value: downloads)
        in runs.entries) {
      await _download(
        downloads,
        format,
        folder: folder,
        quality: Quality(audio: audio, video: video),
      );
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
    if (mounted) _followed.value = subscriptions;
  }

  /// Read in the background: the app is usable meanwhile.
  /// At most once a day: each followed link is a YouTube read.
  Future<void> _checkNews() async {
    if (_followed.value.isEmpty) return;
    final now = widget.now();
    final last = DateTime.tryParse(
      await widget.store.setting(_newsCheckedKey) ?? '',
    );
    if (last != null && now.difference(last) < const Duration(days: 1)) {
      return;
    }
    await widget.store.setSetting(
      _newsCheckedKey,
      now.toUtc().toIso8601String(),
    );
    final news = await findNews(
      [for (final s in _followed.value) (link: s.link, title: s.title)],
      extractor: widget.extractor,
      archive: _archive,
      format: widget.formats.first,
    );
    if (mounted) _news.value = news;
  }

  /// GitHub is asked at most once a day; its answer is kept in between.
  Future<void> _checkUpdate() async {
    final current = widget.appVersion;
    final ask = widget.latestRelease;
    if (current == null || ask == null) return;
    final store = widget.store;
    final now = widget.now();
    final checked = DateTime.tryParse(
      await store.setting(_updateCheckedKey) ?? '',
    );
    if (checked == null || now.difference(checked) >= const Duration(days: 1)) {
      try {
        final latest = await ask();
        await store.setSetting(
          _updateCheckedKey,
          now.toUtc().toIso8601String(),
        );
        await store.setSetting(_updateLatestKey, latest?.version);
        await store.setSetting(_updateUrlKey, latest?.url);
      } on Object {
        return; // Offline: maybe next launch.
      }
    }
    final version = await store.setting(_updateLatestKey);
    final url = await store.setting(_updateUrlKey);
    if (version == null || url == null || !isNewer(version, current)) return;
    if (await store.setting(_updateDismissedKey) == version) return;
    if (mounted) _update.value = AppRelease(version: version, url: url);
  }

  Future<void> _putOffUpdate() async {
    final update = _update.value;
    _update.value = null;
    if (update != null) {
      await widget.store.setSetting(_updateDismissedKey, update.version);
    }
  }

  bool _isFollowed(String link) => _followed.value.any((s) => s.link == link);

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

  /// Channel pictures asked this session: once each.
  final _pictures = <String, Future<String?>>{};

  /// Latest searches, newest first (setting `search.recent`, one a line).
  final _recent = ValueNotifier<List<String>>(const []);

  Future<void> _loadRecent() async {
    final saved = await widget.store.setting(_recentKey);
    if (!mounted || saved == null) return;
    _recent.value = saved.split('\n');
  }

  Future<void> _remember(String query) async {
    final recent = [
      query,
      for (final old in _recent.value)
        if (old.toLowerCase() != query.toLowerCase()) old,
    ].take(_recentMax).toList();
    _recent.value = recent;
    await widget.store.setSetting(_recentKey, recent.join('\n'));
  }

  Future<void> _clearRecent() async {
    _recent.value = const [];
    await widget.store.setSetting(_recentKey, null);
  }

  void _preview(List<MediaEntry> entries) {
    for (final entry in entries) {
      if (entry is SearchEntry) unawaited(_remember(entry.query));
    }
    _push(entries);
  }

  void _push(
    List<MediaEntry> entries, {
    bool pickByHand = false,
  }) => _addNavigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (context) => PreviewScreen(
        entries: entries,
        pickByHand: pickByHand,
        extractor: widget.extractor,
        formats: widget.formats,
        archive: _archive,
        isFollowed: _isFollowed,
        thumbnail: widget.thumbnail,
        quality: widget.settings.quality,
        queueStatus: _queueStatus,
        onSearch: (query) => unawaited(_remember(query)),
        picture: widget.picture,
        openUrl: widget.openUrl,
        // A channel found by a search: all its videos, in a new preview.
        // Picked by hand: hundreds of videos, the user finds the ones wanted.
        onOpenChannel: (channel) => _push([
          ChannelEntry(channel.link, channel: 'channel/${channel.channelId}'),
        ], pickByHand: true),
        channelPicture: switch (widget.extractor) {
          final ChannelPictures engine => (id) => _pictures.putIfAbsent(
            id,
            () => engine.pictureOf(id),
          ),
          _ => null,
        },
        queueChanges: _queueChanges,
        onPlay: switch (_player) {
          final player? => (item, {required video}) => player.playAll([
            Track.online(item, video: video),
          ]),
          null => null,
        },
        onPrefetch: switch (_streams) {
          final streams? => (item, {required video}) => streams.prefetch(
            item.videoId,
            video: video,
          ),
          null => null,
        },
        onFollow: _follow,
        onDownload: (downloads, format, quality) {
          // A search stays open: back on Add, the results are still there.
          if (!entries.any((e) => e is SearchEntry)) {
            Navigator.of(context).pop();
          }
          unawaited(_download(downloads, format, quality: quality));
        },
      ),
    ),
  );

  /// Slid away in the queue: gone, with a moment to bring it back.
  void _removeRun(QueuedRun run) {
    final at = _runs.indexOf(run);
    setState(() => _runs.remove(run));
    _queueChanges.value++;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text(l10n.runRemoved),
          action: SnackBarAction(
            label: l10n.cancelButton,
            onPressed: () {
              if (!mounted) return;
              setState(() => _runs.insert(at.clamp(0, _runs.length), run));
              _queueChanges.value++;
            },
          ),
        ),
      );
  }

  /// The latest run holding [videoId] in [format] says where it stands.
  RunItemStatus? _queueStatus(String videoId, MediaFormat format) {
    for (final run in _runs) {
      if (run.format != format) continue;
      for (final item in run.progress.items) {
        if (item.download.item.videoId == videoId) return item.status;
      }
    }
    return null;
  }

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
      (_Section.add, Icons.add_link, l10n.navAdd),
      (_Section.queue, Icons.downloading, l10n.navQueue),
      (_Section.library, Icons.library_music_outlined, l10n.navLibrary),
      if (_player != null)
        (_Section.player, Icons.headphones_outlined, l10n.navPlayer),
      (_Section.settings, Icons.settings_outlined, l10n.navSettings),
    ];
    final selected = sections.indexWhere((s) => s.$1 == _section);
    Widget icon(_Section section, IconData data) =>
        section == _Section.queue && pending > 0
        ? Badge.count(count: pending, child: Icon(data))
        : Icon(data);

    final body = _SectionFade(
      section: _section.index,
      child: IndexedStack(
        index: _section.index,
        children: [
          Navigator(
            key: _addNavigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => ListenableBuilder(
                listenable: Listenable.merge([
                  widget.settings,
                  _news,
                  _update,
                  _recent,
                ]),
                builder: (_, _) => AddLinksScreen(
                  onPreview: _preview,
                  links: _links,
                  pickLinksFile: widget.pickLinksFile,
                  mixLimit: widget.settings.mixLimit,
                  news: _news.value,
                  onShowNews: _showNews,
                  onDismissNews: () => _news.value = const [],
                  update: _update.value,
                  currentVersion: widget.appVersion,
                  onOpenUpdate: widget.openUrl == null
                      ? null
                      : () => widget.openUrl!(_update.value!.url),
                  onPutOffUpdate: _putOffUpdate,
                  canShare: widget.sharedLinks != null,
                  canDrop: widget.acceptDrops,
                  recentSearches: _recent.value,
                  onClearRecent: _clearRecent,
                ),
              ),
            ),
          ),
          QueueScreen(
            runs: _runs,
            shownFolder: widget._shownFolder,
            thumbnail: widget.thumbnail,
            onRemove: _removeRun,
            onClear: () {
              setState(() => _runs.removeWhere((run) => run.progress.isDone));
              _queueChanges.value++;
            },
            onRetry: (run, downloads) => unawaited(
              _download(
                downloads,
                run.format,
                folder: run.folder,
                quality: run.quality,
              ),
            ),
            interrupted: _interrupted.length,
            onResume: _resume,
            onDiscard: _discard,
          ),
          LibraryScreen(
            store: widget.store,
            changes: _historyChanges,
            openFolder: widget.openFolder,
            onUpdatePlaylist: _updatePlaylist,
            thumbnail: widget.thumbnail,
            now: widget.now,
          ),
          // Its own navigator: playlists open beside the sidebar.
          switch (_player) {
            final player? => Navigator(
              key: _playerNavigator,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => PlayerHubScreen(
                  store: widget.store,
                  player: player,
                  changes: _historyChanges,
                  onOpenPlayer: _openPlayer,
                  thumbnail: widget.thumbnail,
                  pickFolder: switch (widget.pickMediaFolder) {
                    // Opens where Ka7 files music: the Android destination
                    // chosen, or the music folder of Settings.
                    final pick? => () => pick(
                      widget.settings.destinationFor(MediaFormat.mp3)?.uri ??
                          widget.settings.folderFor(MediaFormat.mp3),
                    ),
                    null => null,
                  },
                  listFolder: widget.listMediaFolder,
                ),
              ),
            ),
            null => const SizedBox.shrink(),
          },
          // Its own navigator: the About page opens beside the sidebar.
          Navigator(
            key: _settingsNavigator,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => ValueListenableBuilder(
                valueListenable: _followed,
                builder: (_, followed, _) => SettingsScreen(
                  settings: widget.settings,
                  pickFolder: widget.pickFolder,
                  subscriptions: followed,
                  onUnfollow: _unfollow,
                  appVersion: widget.appVersion,
                  pickDestination: widget.pickDestination,
                  defaultDestination: widget.shownFolder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    void select(int index) => setState(() => _section = sections[index].$1);
    // Under every section while something plays; in the Scaffold's bottom
    // bar, so messages show above it instead of over it.
    final player = _player;
    final mini = player == null
        ? null
        : MiniPlayer(player: player, onOpen: _openPlayer);

    final window = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _sidebarWidth) {
          return Scaffold(
            body: SafeArea(child: body),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?mini,
                NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: select,
                  destinations: [
                    for (final (section, data, label) in sections)
                      NavigationDestination(
                        icon: icon(section, data),
                        label: label,
                      ),
                  ],
                ),
              ],
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selected,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 20),
                  child: Ka7Logo(width: 44),
                ),
                destinations: [
                  for (final (section, data, label) in sections)
                    NavigationRailDestination(
                      icon: icon(section, data),
                      label: Text(label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
          bottomNavigationBar: mini,
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

/// Each section comes in with a short fade and rise, instead of a cut.
class _SectionFade extends StatefulWidget {
  const _SectionFade({required this.section, required this.child});

  final int section;
  final Widget child;

  @override
  State<_SectionFade> createState() => _SectionFadeState();
}

class _SectionFadeState extends State<_SectionFade>
    with SingleTickerProviderStateMixin {
  late final _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final _shown = CurvedAnimation(parent: _in, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(_SectionFade old) {
    super.didUpdateWidget(old);
    if (old.section == widget.section) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _in.forward(from: 0);
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.0, end: 1.0).animate(_shown),
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.015),
        end: Offset.zero,
      ).animate(_shown),
      child: widget.child,
    ),
  );
}

/// When the followed playlists and channels were last read (UTC).
const _newsCheckedKey = 'news.checked';

/// When GitHub was last asked for the latest Ka7, and what it said.
const _updateCheckedKey = 'update.checked';
const _updateLatestKey = 'update.latest';
const _updateUrlKey = 'update.url';

/// The version the user put off: not offered again, a newer one will be.
const _updateDismissedKey = 'update.dismissed';

const _recentKey = 'search.recent';
const _recentMax = 8;
