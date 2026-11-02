import 'dart:async';
import 'dart:io';

import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_explode/ka7_engine_explode.dart';
import 'package:test/test.dart';

const _zoo = SourceVideo(
  id: 'jNQXAC9IVRw',
  title: 'Me at the zoo',
  author: 'jawed',
  duration: Duration(seconds: 19),
);
const _tanalahy = SourceVideo(
  id: 'yXs506QBhJY',
  title: 'Tanalahy ny foko_Mahaleo',
  author: 'MAFYBE61',
  duration: Duration(seconds: 296),
);

const _m4a = SourceStream(
  kind: StreamKind.audio,
  container: 'mp4',
  bitrate: 128000,
  size: 6,
);
const _webm = SourceStream(
  kind: StreamKind.audio,
  container: 'webm',
  bitrate: 160000,
  size: 6,
);
const _muxed = SourceStream(
  kind: StreamKind.muxed,
  container: 'mp4',
  bitrate: 500000,
  size: 6,
);

/// youtube_explode double: fixed answers, records what was asked.
final class FakeSource implements ExplodeSource {
  final videos = <String, Object>{'jNQXAC9IVRw': _zoo};
  final lists = <String, SourceList>{};
  List<SourceStream> available = [_m4a, _webm, _muxed];
  final asked = <String>[];
  SourceStream? opened;

  /// Bytes served by [open], in two chunks; null keeps the stream open.
  List<int>? bytes = [1, 2, 3, 4, 5, 6];

  @override
  Future<SourceVideo> video(String id) async {
    asked.add('video $id');
    return switch (videos[id]) {
      final SourceVideo video => video,
      final Object error => throw error,
      null => throw const ProbeFailure(FailureReason.unavailable),
    };
  }

  @override
  Future<SourceList> playlist(String id, {int? limit}) async {
    asked.add('playlist $id limit $limit');
    return lists[id]!;
  }

  @override
  Future<SourceList> channel(String channel) async {
    asked.add('channel $channel');
    return lists[channel]!;
  }

  @override
  Future<List<SourceStream>> streams(String videoId) async => available;

  @override
  Stream<List<int>> open(String videoId, SourceStream stream) {
    opened = stream;
    final served = bytes;
    if (served == null) return StreamController<List<int>>().stream;
    return Stream.fromIterable([served.sublist(0, 3), served.sublist(3)]);
  }
}

void main() {
  late FakeSource source;
  late ExplodeEngine engine;
  late Directory folder;
  setUp(() {
    source = FakeSource();
    engine = ExplodeEngine(source: source);
    folder = Directory.systemTemp.createTempSync('ka7_explode_');
  });
  tearDown(() => folder.deleteSync(recursive: true));

  MediaEntry entryOf(String input) => parseEntry(input) as MediaEntry;

  DownloadRequest request(MediaFormat format, {String name = 'zoo'}) =>
      DownloadRequest(
        videoId: 'jNQXAC9IVRw',
        format: format,
        destination: '${folder.path}/sub/$name.${format.extension}',
        tags: const TrackTags(title: 'Me at the zoo'),
      );

  group('probe', () {
    test('reads a single video', () async {
      final probe = await engine.probe(entryOf('jNQXAC9IVRw'));

      expect(probe.title, 'Me at the zoo');
      expect(probe.playlistId, isNull);
      final item = probe.items.single;
      expect(item.videoId, 'jNQXAC9IVRw');
      expect(item.channel, 'jawed');
      expect(item.duration, const Duration(seconds: 19));
    });

    test('reads a playlist with its videos', () async {
      source.lists['PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy'] = const SourceList(
        title: 'Mahaleo playlist',
        videos: [_tanalahy, _zoo],
      );

      final probe = await engine.probe(
        entryOf('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy'),
      );

      expect(probe.title, 'Mahaleo playlist');
      expect(probe.playlistId, 'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy');
      expect(probe.items.map((i) => i.videoId), ['yXs506QBhJY', 'jNQXAC9IVRw']);
      expect(source.asked.single, endsWith('limit null'));
    });

    test('caps a YouTube mix at 50 videos', () async {
      source.lists['RDHb8sJ1kP0wE'] = const SourceList(
        title: 'Mix',
        videos: [_zoo],
      );

      await engine.probe(entryOf('RDHb8sJ1kP0wE'));

      expect(source.asked.single, 'playlist RDHb8sJ1kP0wE limit 50');
    });

    test('caps a mix at the limit chosen in the settings', () async {
      source.lists['RDHb8sJ1kP0wE'] = const SourceList(
        title: 'Mix',
        videos: [_zoo],
      );

      await ExplodeEngine(
        source: source,
        mixLimit: () => 200,
      ).probe(entryOf('RDHb8sJ1kP0wE'));

      expect(source.asked.single, 'playlist RDHb8sJ1kP0wE limit 200');
    });

    test('reads a video opened from a playlist as that video', () async {
      final probe = await engine.probe(
        entryOf(
          'https://www.youtube.com/watch?v=jNQXAC9IVRw&list=PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
        ),
      );

      expect(probe.items.single.videoId, 'jNQXAC9IVRw');
    });

    test('reads a channel under its name, unnumbered', () async {
      source.lists['@jawed'] = const SourceList(title: 'jawed', videos: [_zoo]);

      final probe = await engine.probe(
        entryOf('https://www.youtube.com/@jawed'),
      );

      expect(probe.title, 'jawed');
      expect(probe.isChannel, isTrue);
      expect(probe.playlistId, '@jawed');
    });

    test('fails instead of returning an empty list', () async {
      source.lists['PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy'] = const SourceList(
        title: 'Mahaleo playlist',
        videos: [],
      );

      await expectLater(
        engine.probe(entryOf('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy')),
        throwsA(
          isA<ProbeFailure>()
              .having((f) => f.reason, 'reason', FailureReason.unknown)
              .having((f) => f.message, 'message', contains('no video')),
        ),
      );
    });

    test('passes a readable failure through', () async {
      source.videos['jNQXAC9IVRw'] = const ProbeFailure(
        FailureReason.private,
        'private',
      );

      await expectLater(
        engine.probe(entryOf('jNQXAC9IVRw')),
        throwsA(
          isA<ProbeFailure>().having(
            (f) => f.reason,
            'reason',
            FailureReason.private,
          ),
        ),
      );
    });
  });

  group('download', () {
    test('saves the m4a audio stream with progress', () async {
      final target = request(MediaFormat.m4a);

      final progress = await engine.download(target).toList();

      expect(source.opened, _m4a);
      expect(File(target.destination).readAsBytesSync(), [1, 2, 3, 4, 5, 6]);
      expect(progress.map((p) => p.fraction), [0.5, 1.0]);
      expect(
        folder.listSync(recursive: true).whereType<File>().map((f) => f.path),
        [target.destination],
        reason: 'no .part left behind',
      );
    });

    test('takes the best audio in an mp4 container', () async {
      source.available = [
        _webm,
        const SourceStream(
          kind: StreamKind.audio,
          container: 'mp4',
          bitrate: 48000,
          size: 6,
        ),
        _m4a,
      ];

      await engine.download(request(MediaFormat.m4a)).drain<void>();

      expect(source.opened, _m4a);
    });

    test('saves an mp4 from the muxed stream', () async {
      await engine.download(request(MediaFormat.mp4)).drain<void>();

      expect(source.opened, _muxed);
    });

    test('refuses mp3, which needs ffmpeg', () async {
      await expectLater(
        engine.download(request(MediaFormat.mp3)),
        emitsError(
          isA<DownloadFailure>().having(
            (f) => f.reason,
            'reason',
            FailureReason.formatUnsupported,
          ),
        ),
      );
    });

    test('fails readably when no stream fits', () async {
      source.available = [_webm];

      await expectLater(
        engine.download(request(MediaFormat.m4a)),
        emitsError(
          isA<DownloadFailure>().having(
            (f) => f.reason,
            'reason',
            FailureReason.unavailable,
          ),
        ),
      );
    });

    test('cancelling removes the partial file', () async {
      source.bytes = null;
      final target = request(MediaFormat.m4a);

      final subscription = engine.download(target).listen(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subscription.cancel();

      expect(folder.listSync(recursive: true).whereType<File>(), isEmpty);
    });
  });
}
