import 'dart:async';
import 'dart:math';

import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

const _first = ProbeItem(
  videoId: 'aB3dE5fG7hI',
  title: "Tsara Ny Hiran' Ny Taniko",
  channel: 'Erick Manana',
);
const _second = ProbeItem(videoId: 'jK9lM1nO3pQ', title: 'Tsy Ferana');
const _third = ProbeItem(videoId: 'rS5tU7vW9xY', title: 'Lasa');
const _playlist = Probe(
  title: 'Erick Manana · Sélection',
  playlistId: 'PLe7rK2mErickManana01',
  items: [_first, _second, _third],
);

List<PlannedDownload> _planned(List<ProbeItem> items) => [
  for (final item in items)
    PlannedDownload(
      source: _playlist,
      item: item,
      index: _playlist.items.indexOf(item) + 1,
    ),
];

/// Engine double: answers at once, unless told to fail or to hang.
final class FakeDownloader implements Downloader {
  FakeDownloader({this.failures = const {}, this.hanging = const {}});

  final Map<String, Object> failures;
  final Set<String> hanging;
  final requests = <DownloadRequest>[];
  final stopped = <String>[];
  var _active = 0;
  var maxActive = 0;

  @override
  Stream<DownloadProgress> download(DownloadRequest request) {
    requests.add(request);
    final id = request.videoId;
    late final StreamController<DownloadProgress> controller;
    controller = StreamController(
      onListen: () async {
        maxActive = max(maxActive, ++_active);
        controller.add(const DownloadProgress(fraction: 0.5));
        if (hanging.contains(id)) return;
        await Future<void>.delayed(Duration.zero);
        if (failures[id] case final error?) controller.addError(error);
        _active--;
        await controller.close();
      },
      onCancel: () {
        if (hanging.contains(id)) {
          stopped.add(id);
          _active--;
        }
      },
    );
    return controller.stream;
  }
}

final class MemoryArchive implements Archive {
  MemoryArchive([Iterable<String> ids = const []]) : ids = {...ids};

  final Set<String> ids;

  @override
  Future<bool> contains(String videoId, MediaFormat format) async =>
      ids.contains('$videoId.${format.name}');

  @override
  Future<void> add(String videoId, MediaFormat format) async =>
      ids.add('$videoId.${format.name}');
}

DownloadQueue _queue(
  Downloader downloader, {
  Archive? archive,
  int concurrency = 1,
  FolderLayout layout = FolderLayout.playlist,
  Quality quality = Quality.standard,
}) => DownloadQueue(
  layout: layout,
  quality: quality,
  downloader: downloader,
  folder: '/music',
  format: MediaFormat.mp3,
  archive: archive,
  concurrency: concurrency,
);

String _describe(JobEvent event) =>
    '${event.runtimeType} ${event.download.item.videoId}';

void main() {
  test('downloads each video to its place, reporting progress', () async {
    final events = await _queue(
      FakeDownloader(),
    ).run(_planned([_first, _second])).toList();

    expect(events.map(_describe), [
      'JobStarted aB3dE5fG7hI',
      'JobProgressed aB3dE5fG7hI',
      'JobSucceeded aB3dE5fG7hI',
      'JobStarted jK9lM1nO3pQ',
      'JobProgressed jK9lM1nO3pQ',
      'JobSucceeded jK9lM1nO3pQ',
    ]);
    expect(
      (events[2] as JobSucceeded).path,
      "/music/Erick Manana · Sélection/01 - Tsara Ny Hiran' Ny Taniko.mp3",
    );
  });

  test('asks the engine for the right file, with tags', () async {
    final downloader = FakeDownloader();

    await _queue(downloader).run(_planned([_first])).drain<void>();

    final request = downloader.requests.single;
    expect(request.videoId, 'aB3dE5fG7hI');
    expect(request.format, MediaFormat.mp3);
    expect(
      request.destination,
      "/music/Erick Manana · Sélection/01 - Tsara Ny Hiran' Ny Taniko.mp3",
    );
    expect(request.tags.title, "Tsara Ny Hiran' Ny Taniko");
    expect(request.tags.artist, 'Erick Manana');
    expect(request.tags.album, 'Erick Manana · Sélection');
    expect(request.tags.trackNumber, 1);
  });

  test('asks for 192 kbit/s and 1080p unless told otherwise', () async {
    final downloader = FakeDownloader();

    await _queue(downloader).run(_planned([_first])).drain<void>();

    final request = downloader.requests.single;
    expect(request.quality.audio, AudioQuality.kbps192);
    expect(request.quality.video, VideoQuality.p1080);
  });

  test('asks the engine for the chosen quality', () async {
    final downloader = FakeDownloader();

    await _queue(
      downloader,
      quality: const Quality(
        audio: AudioQuality.kbps320,
        video: VideoQuality.best,
      ),
    ).run(_planned([_first])).drain<void>();

    expect(downloader.requests.single.quality.audio.kbps, 320);
    expect(downloader.requests.single.quality.video.height, isNull);
  });

  test('files by artist when asked to', () async {
    final downloader = FakeDownloader();

    await _queue(
      downloader,
      layout: FolderLayout.artist,
    ).run(_planned([_first])).drain<void>();

    expect(
      downloader.requests.single.destination,
      "/music/Erick Manana/Tsara Ny Hiran' Ny Taniko.mp3",
    );
  });

  test('leaves album and track number out for a single video', () async {
    final downloader = FakeDownloader();
    const video = Probe(title: 'Tsy Ferana', items: [_second]);

    await _queue(downloader).run(const [
      PlannedDownload(source: video, item: _second, index: 1),
    ]).drain<void>();

    final tags = downloader.requests.single.tags;
    expect(tags.album, isNull);
    expect(tags.trackNumber, isNull);
  });

  test('tags a channel video with the channel, without track number', () async {
    final downloader = FakeDownloader();
    const channel = Probe(
      title: 'Erick Manana',
      playlistId: 'UC0HN8Wq3EEzK3GF6qKHkdkA',
      isChannel: true,
      items: [_second],
    );

    await _queue(downloader).run(const [
      PlannedDownload(source: channel, item: _second, index: 1),
    ]).drain<void>();

    final tags = downloader.requests.single.tags;
    expect(tags.album, 'Erick Manana');
    expect(tags.trackNumber, isNull);
  });

  test('reports a failure with its reason and goes on with the rest', () async {
    final events = await _queue(
      FakeDownloader(
        failures: {
          'aB3dE5fG7hI': const DownloadFailure(
            FailureReason.private,
            'Private video',
          ),
          'jK9lM1nO3pQ': StateError('engine crashed'),
        },
      ),
    ).run(_planned([_first, _second, _third])).toList();

    final failed = events.whereType<JobFailed>().toList();
    expect(failed.map((f) => f.reason), [
      FailureReason.private,
      FailureReason.unknown,
    ]);
    expect(failed.first.message, 'Private video');
    expect(failed.last.message, contains('engine crashed'));
    expect(events.last, isA<JobSucceeded>());
  });

  test('skips archived videos and archives the new ones', () async {
    final downloader = FakeDownloader();
    final archive = MemoryArchive(['aB3dE5fG7hI.mp3']);

    final events = await _queue(
      downloader,
      archive: archive,
    ).run(_planned([_first, _second])).toList();

    expect(events.first, isA<JobSkipped>());
    expect(downloader.requests.map((r) => r.videoId), ['jK9lM1nO3pQ']);
    expect(archive.ids, {'aB3dE5fG7hI.mp3', 'jK9lM1nO3pQ.mp3'});
  });

  test('does not archive a failed video', () async {
    final archive = MemoryArchive();

    await _queue(
      FakeDownloader(
        failures: {'aB3dE5fG7hI': const DownloadFailure(FailureReason.network)},
      ),
      archive: archive,
    ).run(_planned([_first])).drain<void>();

    expect(archive.ids, isEmpty);
  });

  test('runs no more downloads at once than allowed', () async {
    final downloader = FakeDownloader();

    final events = await _queue(
      downloader,
      concurrency: 2,
    ).run(_planned([_first, _second, _third])).toList();

    expect(downloader.maxActive, 2);
    expect(events.whereType<JobSucceeded>(), hasLength(3));
  });

  test('cancel stops the running download and drops waiting ones', () async {
    final downloader = FakeDownloader(hanging: {'aB3dE5fG7hI'});
    final queue = _queue(downloader);

    final events = await queue.run(_planned([_first, _second])).map((event) {
      if (event is JobProgressed) queue.cancel();
      return event;
    }).toList();

    expect(downloader.stopped, ['aB3dE5fG7hI']);
    expect(downloader.requests, hasLength(1));
    expect(events.whereType<JobCancelled>().map(_describe), [
      'JobCancelled aB3dE5fG7hI',
      'JobCancelled jK9lM1nO3pQ',
    ]);
  });

  test('cancelOne stops one running video, the next ones go on', () async {
    final downloader = FakeDownloader(hanging: {'aB3dE5fG7hI'});
    final queue = _queue(downloader);
    final planned = _planned([_first, _second]);

    final events = await queue.run(planned).map((event) {
      if (event is JobProgressed && event.download == planned.first) {
        queue.cancelOne(planned.first);
      }
      return event;
    }).toList();

    expect(downloader.stopped, ['aB3dE5fG7hI']);
    expect(events.whereType<JobCancelled>().map(_describe), [
      'JobCancelled aB3dE5fG7hI',
    ]);
    expect(events.whereType<JobSucceeded>().map(_describe), [
      'JobSucceeded jK9lM1nO3pQ',
    ]);
  });

  test('cancelOne drops a waiting video before it starts', () async {
    final downloader = FakeDownloader(hanging: {'aB3dE5fG7hI'});
    final queue = _queue(downloader);
    final planned = _planned([_first, _second, _third]);
    final events = <JobEvent>[];
    final done = queue.run(planned).listen(events.add).asFuture<void>();
    await Future<void>.delayed(Duration.zero);

    queue.cancelOne(planned[1]);
    queue.cancelOne(planned.first);
    await done;

    expect(downloader.requests.map((r) => r.videoId), [
      'aB3dE5fG7hI',
      'rS5tU7vW9xY',
    ]);
    expect(events.whereType<JobCancelled>().map(_describe), [
      'JobCancelled jK9lM1nO3pQ',
      'JobCancelled aB3dE5fG7hI',
    ]);
  });

  test('takes more videos while it runs', () async {
    final downloader = FakeDownloader(hanging: {'aB3dE5fG7hI'});
    final queue = _queue(downloader);
    final events = <JobEvent>[];
    final done = queue.run(_planned([_first])).forEach(events.add);
    await Future<void>.delayed(Duration.zero);

    expect(queue.add(_planned([_second, _third])), isTrue);
    await Future<void>.delayed(Duration.zero);
    queue.cancel();
    await done;

    expect(downloader.requests.map((r) => r.videoId), ['aB3dE5fG7hI']);
    expect(events.whereType<JobCancelled>(), hasLength(3));
  });

  test('starts added videos at once when a worker is free', () async {
    final downloader = FakeDownloader(hanging: {'aB3dE5fG7hI'});
    final queue = _queue(downloader, concurrency: 2);
    final done = queue.run(_planned([_first])).drain<void>();
    await Future<void>.delayed(Duration.zero);

    queue.add(_planned([_second]));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(downloader.requests.map((r) => r.videoId), [
      'aB3dE5fG7hI',
      'jK9lM1nO3pQ',
    ]);
    queue.cancel();
    await done;
  });

  test('refuses more videos once the run is over', () async {
    final queue = _queue(FakeDownloader());

    await queue.run(_planned([_first])).drain<void>();

    expect(queue.add(_planned([_second])), isFalse);
  });

  test('summary sorts how each video ended', () async {
    final events = await _queue(
      FakeDownloader(
        failures: {'jK9lM1nO3pQ': const DownloadFailure(FailureReason.network)},
      ),
      archive: MemoryArchive(['rS5tU7vW9xY.mp3']),
    ).run(_planned([_first, _second, _third])).toList();

    final summary = RunSummary(events);
    expect(summary.succeeded, hasLength(1));
    expect(summary.failed, hasLength(1));
    expect(summary.skipped, hasLength(1));
    expect(summary.cancelled, isEmpty);
  });
}
