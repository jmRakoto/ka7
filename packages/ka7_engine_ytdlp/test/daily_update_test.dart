import 'dart:async';

import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:test/test.dart';

/// Tools found or not; installs are not exercised here.
final class FakeSetup implements EngineSetup {
  FakeSetup({this.ytDlp = '/data/bin/yt-dlp'});

  final String? ytDlp;

  @override
  Future<EngineStatus> check() async =>
      EngineStatus(ytDlp: ytDlp, ffmpeg: '/data/bin/ffmpeg');

  @override
  Stream<double> install(EngineTool tool) => const Stream.empty();
}

final _now = DateTime.utc(2026, 11, 2, 9);

void main() {
  late int updates;
  late List<DateTime> saved;

  setUp(() {
    updates = 0;
    saved = [];
  });

  DailyUpdate daily({
    DateTime? last,
    FakeSetup? setup,
    Future<bool> Function()? update,
  }) => DailyUpdate(
    setup ?? FakeSetup(),
    update:
        update ??
        () async {
          updates++;
          return true;
        },
    lastUpdate: () async => last,
    saveUpdate: (at) async => saved.add(at),
    now: () => _now,
    timeout: const Duration(milliseconds: 20),
  );

  test('updates yt-dlp on the first check and remembers when', () async {
    final status = await daily().check();

    expect(updates, 1);
    expect(saved, [_now]);
    expect(status.ytDlp, '/data/bin/yt-dlp');
  });

  test('skips the update when the last one is less than a day old', () async {
    await daily(last: _now.subtract(const Duration(hours: 23))).check();

    expect(updates, 0);
    expect(saved, isEmpty);
  });

  test('updates again once a day has passed', () async {
    await daily(last: _now.subtract(const Duration(days: 1))).check();

    expect(updates, 1);
  });

  test('does not update when yt-dlp is missing', () async {
    final status = await daily(setup: FakeSetup(ytDlp: null)).check();

    expect(updates, 0);
    expect(status.missing, [EngineTool.ytDlp]);
  });

  test('tries again next launch when the update fails', () async {
    final failing = [
      () async => false,
      () async => throw Exception('offline'),
      () => Completer<bool>().future,
    ];

    for (final update in failing) {
      final status = await daily(update: update).check();
      expect(status.isReady, isTrue);
    }
    expect(saved, isEmpty);
  });
}
