import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

const _a = ProbeItem(videoId: 'yXs506QBhJY', title: 'Tanalahy ny foko');
const _b = ProbeItem(videoId: 'YW-QLSPY8Ew', title: 'Somambisamby');
const _c = ProbeItem(videoId: 'tXfQdfIY2qg', title: 'Veloma Mahaleo');
const _playlist = Probe(
  title: 'Mahaleo playlist',
  playlistId: 'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
  items: [_a, _b, _c],
);
const _da = PlannedDownload(source: _playlist, item: _a, index: 1);
const _db = PlannedDownload(source: _playlist, item: _b, index: 2);
const _dc = PlannedDownload(source: _playlist, item: _c, index: 3);

List<String> _titles(Iterable<RunItem> items) => [
  for (final item in items) item.download.item.title,
];

void main() {
  late RunProgress run;
  setUp(() => run = RunProgress([_da, _db, _dc]));

  test('starts with every video waiting', () {
    expect(_titles(run.waiting), [
      'Tanalahy ny foko',
      'Somambisamby',
      'Veloma Mahaleo',
    ]);
    expect(run.running, isEmpty);
    expect(run.fraction, 0);
    expect(run.isDone, isFalse);
  });

  test('moves a video to running, with its progress', () {
    run
      ..apply(const JobStarted(_db))
      ..apply(
        const JobProgressed(_db, DownloadProgress(fraction: 0.5, speed: 2000)),
      );

    expect(_titles(run.running), ['Somambisamby']);
    expect(_titles(run.waiting), ['Tanalahy ny foko', 'Veloma Mahaleo']);
    expect(run.running.single.fraction, 0.5);
    expect(run.fraction, closeTo(0.5 / 3, 1e-9));
    expect(run.speed, 2000);
  });

  test('adds up the speed of parallel downloads', () {
    run
      ..apply(
        const JobProgressed(_da, DownloadProgress(fraction: 0.1, speed: 1000)),
      )
      ..apply(
        const JobProgressed(_db, DownloadProgress(fraction: 0.1, speed: 500)),
      )
      ..apply(const JobProgressed(_dc, DownloadProgress(fraction: 0.1)));

    expect(run.speed, 1500);
  });

  test('keeps how each video ended, in the order it ended', () {
    run
      ..apply(const JobFailed(_db, FailureReason.private, 'Private video'))
      ..apply(const JobSucceeded(_da, '/music/01.mp3'))
      ..apply(const JobSkipped(_dc));

    expect(_titles(run.finished), [
      'Somambisamby',
      'Tanalahy ny foko',
      'Veloma Mahaleo',
    ]);
    final [failed, succeeded, skipped] = run.finished.toList();
    expect(failed.status, RunItemStatus.failed);
    expect(failed.reason, FailureReason.private);
    expect(failed.message, 'Private video');
    expect(succeeded.status, RunItemStatus.succeeded);
    expect(succeeded.path, '/music/01.mp3');
    expect(skipped.status, RunItemStatus.skipped);
    expect(run.fraction, 1);
    expect(run.speed, isNull);
    expect(run.isDone, isTrue);
  });

  test('counts a cancelled video as ended', () {
    run
      ..apply(const JobCancelled(_da))
      ..apply(const JobCancelled(_db))
      ..apply(const JobCancelled(_dc));

    expect(run.finished.map((i) => i.status).toSet(), {
      RunItemStatus.cancelled,
    });
    expect(run.isDone, isTrue);
  });

  test('follows videos added while it runs', () {
    final run = RunProgress([_da])..apply(const JobSucceeded(_da, '/m/a.mp3'));
    expect(run.isDone, isTrue);

    run.add([_db]);

    expect(run.isDone, isFalse);
    expect(_titles(run.waiting), ['Somambisamby']);
    expect(run.fraction, 0.5);
  });
}
