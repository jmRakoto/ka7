import 'dart:async';

import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

const _zoo = Probe(
  title: 'Me at the zoo',
  items: [ProbeItem(videoId: 'jNQXAC9IVRw', title: 'Me at the zoo')],
);

final class FakeExtractor implements Extractor {
  FakeExtractor(this.name, this.answer);

  @override
  final String name;
  final Object answer;
  var calls = 0;

  @override
  Future<Probe> probe(MediaEntry entry) async {
    calls++;
    return switch (answer) {
      final Probe probe => probe,
      final Object error => throw error,
    };
  }
}

final class FakeDownloader implements Downloader {
  FakeDownloader({this.failure, this.progress = const [1]});

  final Object? failure;
  final List<double> progress;
  var calls = 0;

  @override
  Stream<DownloadProgress> download(DownloadRequest request) async* {
    calls++;
    for (final fraction in progress) {
      yield DownloadProgress(fraction: fraction);
    }
    if (failure case final error?) throw error;
  }
}

const _request = DownloadRequest(
  videoId: 'jNQXAC9IVRw',
  format: MediaFormat.mp3,
  destination: '/music/Me at the zoo.mp3',
  tags: TrackTags(title: 'Me at the zoo'),
);

MediaEntry get _entry => parseEntry('jNQXAC9IVRw') as MediaEntry;

void main() {
  group('reading', () {
    test('uses the first engine when it works', () async {
      final second = FakeExtractor('explode', _zoo);

      final probe = await FallbackExtractor([
        FakeExtractor('yt-dlp', _zoo),
        second,
      ]).probe(_entry);

      expect(probe.title, 'Me at the zoo');
      expect(second.calls, 0);
    });

    test('tries the next engine when one breaks', () async {
      final probe = await FallbackExtractor([
        FakeExtractor(
          'yt-dlp',
          const ProbeFailure(FailureReason.unknown, 'SABR'),
        ),
        FakeExtractor('explode', _zoo),
      ]).probe(_entry);

      expect(probe.title, 'Me at the zoo');
    });

    test(
      'trusts a private or unavailable answer: any engine would agree',
      () async {
        final second = FakeExtractor('explode', _zoo);

        await expectLater(
          FallbackExtractor([
            FakeExtractor('yt-dlp', const ProbeFailure(FailureReason.private)),
            second,
          ]).probe(_entry),
          throwsA(isA<ProbeFailure>()),
        );
        expect(second.calls, 0);
      },
    );

    test('names every engine when all fail', () async {
      await expectLater(
        FallbackExtractor([
          FakeExtractor(
            'yt-dlp',
            const ProbeFailure(FailureReason.network, 'a'),
          ),
          FakeExtractor('explode', StateError('b')),
        ]).probe(_entry),
        throwsA(
          isA<ProbeFailure>()
              .having((f) => f.reason, 'reason', FailureReason.network)
              .having(
                (f) => f.message,
                'message',
                'yt-dlp: a\nexplode: Bad state: b',
              ),
        ),
      );
    });
  });

  group('downloading', () {
    test('passes progress through from the first engine', () async {
      final second = FakeDownloader();

      final progress = await FallbackDownloader({
        'yt-dlp': FakeDownloader(progress: [0.5, 1]),
        'explode': second,
      }).download(_request).toList();

      expect(progress.map((p) => p.fraction), [0.5, 1]);
      expect(second.calls, 0);
    });

    test('starts over with the next engine when one fails', () async {
      final progress = await FallbackDownloader({
        'yt-dlp': FakeDownloader(
          progress: [0.3],
          failure: const DownloadFailure(FailureReason.unknown, 'ffmpeg'),
        ),
        'explode': FakeDownloader(progress: [0.6, 1]),
      }).download(_request).toList();

      expect(progress.map((p) => p.fraction), [0.3, 0.6, 1]);
    });

    test(
      'keeps the first reason when the next engine cannot make the format',
      () async {
        await expectLater(
          FallbackDownloader({
            'yt-dlp': FakeDownloader(
              failure: const DownloadFailure(
                FailureReason.network,
                'timed out',
              ),
            ),
            'explode': FakeDownloader(
              failure: const DownloadFailure(FailureReason.formatUnsupported),
            ),
          }).download(_request),
          emitsThrough(
            emitsError(
              isA<DownloadFailure>()
                  .having((f) => f.reason, 'reason', FailureReason.network)
                  .having(
                    (f) => f.message,
                    'message',
                    contains('yt-dlp: timed out'),
                  ),
            ),
          ),
        );
      },
    );

    test('does not retry a private video', () async {
      final second = FakeDownloader();

      await FallbackDownloader({
        'yt-dlp': FakeDownloader(
          failure: const DownloadFailure(FailureReason.private),
        ),
        'explode': second,
      }).download(_request).handleError((Object _) {}).drain<void>();

      expect(second.calls, 0);
    });

    test('cancelling stops the engine at work', () async {
      var cancelled = false;
      final hanging = _Hanging(() => cancelled = true);

      final subscription = FallbackDownloader({
        'yt-dlp': hanging,
      }).download(_request).listen(null);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(cancelled, isTrue);
    });
  });
}

final class _Hanging implements Downloader {
  _Hanging(this.onCancel);

  final void Function() onCancel;

  @override
  Stream<DownloadProgress> download(DownloadRequest request) =>
      StreamController<DownloadProgress>(onCancel: onCancel).stream;
}
