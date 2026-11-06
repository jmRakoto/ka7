import 'dart:async';

import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

/// Answers each lookup only when told to.
final class _Engine implements StreamUrls {
  final asked = <String>[];
  final _answers = <String, Completer<String>>{};

  @override
  Future<String> streamUrl(String videoId, {required bool video}) {
    final key = '$videoId${video ? '/video' : ''}';
    asked.add(key);
    return (_answers[key] = Completer<String>()).future;
  }

  void answer(String key) => _answers[key]!.complete('https://stream/$key');
  void fail(String key) => _answers[key]!.completeError(
    const ProbeFailure(FailureReason.network, 'down'),
  );
}

void main() {
  late _Engine engine;
  late DateTime now;
  late StreamCache cache;

  setUp(() {
    engine = _Engine();
    now = DateTime(2026, 11, 6, 10);
    cache = StreamCache(engine, now: () => now);
  });

  test('playing a prefetched video reuses its lookup', () async {
    cache.prefetch('a', video: false);
    final played = cache.streamUrl('a', video: false);
    engine.answer('a');

    expect(await played, 'https://stream/a');
    expect(engine.asked, ['a']);
  });

  test('prefetching twice asks once', () async {
    cache
      ..prefetch('a', video: false)
      ..prefetch('a', video: false);

    expect(engine.asked, ['a']);
  });

  test('audio and video addresses are apart', () async {
    cache
      ..prefetch('a', video: false)
      ..prefetch('a', video: true);

    expect(engine.asked, ['a', 'a/video']);
  });

  test('an address older than an hour is asked again', () async {
    cache.prefetch('a', video: false);
    engine.answer('a');
    await pumpEventQueue();
    now = now.add(const Duration(hours: 1, minutes: 1));

    unawaited(cache.streamUrl('a', video: false));

    expect(engine.asked, ['a', 'a']);
  });

  test('a failed lookup is not kept', () async {
    cache.prefetch('a', video: false);
    engine.fail('a');
    await pumpEventQueue();

    unawaited(cache.streamUrl('a', video: false));

    expect(engine.asked, ['a', 'a']);
  });

  test('a failed lookup still fails the play that waited for it', () async {
    cache.prefetch('a', video: false);
    final played = cache.streamUrl('a', video: false);
    engine.fail('a');

    await expectLater(played, throwsA(isA<ProbeFailure>()));
  });

  test('runs two lookups at once, the newest waiting first', () async {
    for (final id in ['a', 'b', 'c', 'd']) {
      cache.prefetch(id, video: false);
    }
    expect(engine.asked, ['a', 'b']);

    engine.answer('a');
    await pumpEventQueue();

    expect(engine.asked, ['a', 'b', 'd']);
  });

  test('keeps only the latest waiting lookups', () async {
    cache = StreamCache(engine, now: () => now, parallel: 1, waiting: 2);
    for (final id in ['a', 'b', 'c', 'd']) {
      cache.prefetch(id, video: false);
    }
    engine.answer('a');
    await pumpEventQueue();
    engine.answer('d');
    await pumpEventQueue();
    engine.answer('c');
    await pumpEventQueue();

    expect(engine.asked, ['a', 'd', 'c']);
  });

  test('playing a waiting video asks for it at once', () async {
    cache = StreamCache(engine, now: () => now, parallel: 1);
    cache
      ..prefetch('a', video: false)
      ..prefetch('b', video: false);

    final played = cache.streamUrl('b', video: false);
    engine.answer('b');

    expect(await played, 'https://stream/b');
    // b is not asked a second time once a ends.
    engine.answer('a');
    await pumpEventQueue();
    expect(engine.asked, ['a', 'b']);
  });
}
