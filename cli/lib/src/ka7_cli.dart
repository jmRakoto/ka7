import 'dart:io';

import 'package:args/args.dart';
import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_store/ka7_store.dart';

import 'messages.dart';

/// Exit codes, after BSD `sysexits`.
abstract final class ExitCode {
  static const ok = 0;

  /// Some links or videos failed: see failed.txt.
  static const someFailed = 1;
  static const usage = 64;
  static const noInput = 66;
}

const _failedFile = 'failed.txt';

Future<bool> _no(String question) async => false;

/// The `ka7` command: flows 1 to 4 without screens.
final class Ka7Cli {
  Ka7Cli({
    required this.extractor,
    required this.downloader,
    required this.store,
    required this.workingDirectory,
    required this.out,
    required this.now,
    this.language = 'en',
    this.showProgress = false,
    this.ask = _no,
  });

  final Extractor extractor;
  final Downloader downloader;
  final Ka7Store store;

  /// Where relative paths, `failed.txt` and the default `downloads/` live.
  final String workingDirectory;
  final StringSink out;
  final DateTime Function() now;

  /// System language; `--lang` wins.
  final String language;

  /// Redraws a progress bar in place: only on a terminal.
  final bool showProgress;

  /// Asks a yes / no question; `--yes` answers yes without asking.
  final Future<bool> Function(String question) ask;

  DownloadQueue? _queue;
  var _cancelled = false;

  static final _parser = ArgParser()
    ..addOption('format', allowed: ['mp3', 'm4a', 'mp4'], defaultsTo: 'mp3')
    ..addOption('out', defaultsTo: 'downloads')
    ..addOption('jobs', defaultsTo: '2')
    ..addOption('lang')
    ..addFlag('yes', abbr: 'y', negatable: false);

  Future<int> run(List<String> arguments) async {
    final ArgResults options;
    try {
      options = _parser.parse(arguments);
    } on FormatException {
      out.writeln(Messages.of(language).usage);
      return ExitCode.usage;
    }
    final say = Messages.of(options.option('lang') ?? language);
    final jobs = int.tryParse(options.option('jobs')!);
    if (options.rest.length != 1 || jobs == null || jobs < 1) {
      out.writeln(say.usage);
      return ExitCode.usage;
    }

    final path = options.rest.single == 'retry'
        ? _failedFile
        : options.rest.single;
    final links = File(_resolve(path));
    if (!links.existsSync()) {
      out.writeln(say.missingFile(path));
      return ExitCode.noInput;
    }
    // Searches need someone to pick results: left to the app.
    final entries = [
      for (final entry in parseLinks(await links.readAsString()))
        if (entry is SearchEntry)
          InvalidEntry(entry.source, reason: InvalidReason.freeText)
        else
          entry,
    ];
    final media = entries.whereType<MediaEntry>().toList();
    out.writeln(
      say.readLinks(
        media.length,
        entries.whereType<InvalidEntry>().length,
        entries.whereType<DuplicateEntry>().length,
      ),
    );
    for (final entry in entries.whereType<InvalidEntry>()) {
      out.writeln(say.invalid(entry.source, entry.reason));
    }
    if (media.isEmpty) {
      out.writeln(say.noLinks(path));
      return ExitCode.noInput;
    }

    final yes = options.flag('yes');
    final (planned, unreadable) = await _probe(
      media,
      say,
      (question) async => yes || await ask(question),
    );
    final format = MediaFormat.values.byName(options.option('format')!);
    final events = await _download(
      planned,
      DownloadQueue(
        downloader: downloader,
        folder: _resolve(options.option('out')!),
        format: format,
        archive: store,
        concurrency: jobs,
      ),
      say,
    );

    final summary = RunSummary(events);
    out.writeln(say.summary(summary, unreadable.length));
    final failedFile = File(_resolve(_failedFile));
    if (summary.failed.isEmpty && unreadable.isEmpty) {
      if (failedFile.existsSync()) await failedFile.delete();
      return ExitCode.ok;
    }
    await failedFile.writeAsString(
      formatFailedLinks(summary.failed, now(), unreadable: unreadable),
    );
    out.writeln(say.failedSaved(_failedFile));
    return ExitCode.someFailed;
  }

  /// Stops the run, as Ctrl+C does.
  void cancel() {
    _cancelled = true;
    _queue?.cancel();
  }

  /// Reads each link: the videos to download, and the links that failed.
  Future<(List<PlannedDownload>, Map<MediaEntry, ProbeFailure>)> _probe(
    List<MediaEntry> media,
    Messages say,
    Future<bool> Function(String question) confirm,
  ) async {
    final planned = <PlannedDownload>[];
    final unreadable = <MediaEntry, ProbeFailure>{};

    Future<Probe?> read(MediaEntry entry) async {
      try {
        return await extractor.probe(entry);
      } on ProbeFailure catch (failure) {
        unreadable[entry] = failure;
        out.writeln(say.unreadable(entry.source, failure.reason));
        return null;
      }
    }

    for (final entry in media) {
      if (_cancelled) break;
      final probe = entry is VideoInPlaylistEntry
          ? await _videoOrPlaylist(entry, say, confirm) ??
                await read(VideoEntry(entry.source, videoId: entry.videoId))
          : await read(entry);
      if (probe == null) continue;
      if (probe.isChannel &&
          !await confirm(say.confirmChannel(probe.title, probe.items.length))) {
        out.writeln(say.leftOut(probe.title));
        continue;
      }
      final available = [
        for (final (index, item) in probe.items.indexed)
          if (item.availability == Availability.available)
            PlannedDownload(source: probe, item: item, index: index + 1),
      ];
      out.writeln(
        say.probed(
          probe.title,
          probe.items.length,
          probe.items.length - available.length,
        ),
      );
      planned.addAll(available);
    }
    return (planned, unreadable);
  }

  /// The whole playlist if the user wants it; null to keep the video alone.
  Future<Probe?> _videoOrPlaylist(
    VideoInPlaylistEntry entry,
    Messages say,
    Future<bool> Function(String question) confirm,
  ) async {
    final Probe playlist;
    try {
      playlist = await extractor.probe(
        PlaylistEntry(entry.source, playlistId: entry.playlistId),
      );
    } on ProbeFailure {
      return null;
    }
    final whole = await confirm(
      say.wholePlaylist(playlist.title, playlist.items.length),
    );
    return whole ? playlist : null;
  }

  Future<List<JobEvent>> _download(
    List<PlannedDownload> planned,
    DownloadQueue queue,
    Messages say,
  ) async {
    if (_cancelled) return planned.map(JobCancelled.new).toList();
    _queue = queue;
    final events = <JobEvent>[];
    final bar = _ProgressBar(out, say, planned.length, enabled: showProgress);
    var position = 0;
    void announce(PlannedDownload download) =>
        bar.line(say.started(++position, planned.length, download.item.title));
    await for (final event in queue.run(planned)) {
      events.add(event);
      await store.record(event, queue.format, now());
      final title = event.download.item.title;
      switch (event) {
        case JobStarted():
          announce(event.download);
        case JobProgressed():
          bar.update(event);
        case JobSucceeded():
          bar.line(say.succeeded(event.path));
        case JobSkipped():
          announce(event.download);
          bar.line(say.skipped(title));
        case JobFailed():
          bar.line(say.failed(title, event.reason));
        case JobCancelled():
          bar.line(say.cancelled(title));
      }
      if (event is! JobStarted && event is! JobProgressed) bar.ended(event);
    }
    bar.clear();
    _queue = null;
    return events;
  }

  String _resolve(String path) =>
      File(path).isAbsolute ? path : '$workingDirectory/$path';
}

/// One line redrawn in place: overall progress and current speed.
final class _ProgressBar {
  _ProgressBar(this.out, this.say, this.total, {required this.enabled});

  final StringSink out;
  final Messages say;
  final int total;
  final bool enabled;

  final _fractions = <String, double>{};
  final _speeds = <String, double>{};
  var _done = 0;
  var _shown = false;

  static const _width = 20;

  void update(JobProgressed event) {
    if (!enabled) return;
    final id = event.download.item.videoId;
    _fractions[id] = event.progress.fraction;
    if (event.progress.speed case final speed?) _speeds[id] = speed;
    final running = _fractions.values.fold(0.0, (sum, f) => sum + f);
    final fraction = ((_done + running) / total).clamp(0.0, 1.0);
    final full = (fraction * _width).round();
    final speed = _speeds.isEmpty
        ? null
        : _speeds.values.fold(0.0, (sum, s) => sum + s);
    out.write(
      '\r\x1b[K  ▕${'█' * full}${'░' * (_width - full)}▏ '
      '${say.progress((fraction * 100).round(), _done, total, speed)}',
    );
    _shown = true;
  }

  /// [event] closed one download: it now counts as done.
  void ended(JobEvent event) {
    final id = event.download.item.videoId;
    _fractions.remove(id);
    _speeds.remove(id);
    _done++;
  }

  /// Prints [text] on its own line, over the bar if it is shown.
  void line(String text) {
    clear();
    out.writeln(text);
  }

  void clear() {
    if (!_shown) return;
    out.write('\r\x1b[K');
    _shown = false;
  }
}
