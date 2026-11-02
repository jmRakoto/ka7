import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/queue/run_view.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../helpers/probes.dart';
import '../../helpers/pump_app.dart';

final _planned = [
  for (final (i, item) in ericMananaPlaylist.items.take(2).indexed)
    PlannedDownload(source: ericMananaPlaylist, item: item, index: i + 1),
  PlannedDownload(
    source: hafatraVideo,
    item: hafatraVideo.items.single,
    index: 1,
  ),
];
final _tsara = _planned[0], _tsy = _planned[1], _hafatra = _planned[2];

void main() {
  late RunProgress run;
  late List<List<PlannedDownload>> retried;
  late int cancels;
  setUp(() {
    run = RunProgress(_planned);
    retried = [];
    cancels = 0;
  });

  Future<void> pumpRun(WidgetTester tester, {Locale? locale}) {
    tester.view
      ..physicalSize = const Size(1280, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: RunView(
            run: run,
            onCancel: () => cancels++,
            onRetry: retried.add,
          ),
        ),
      ),
      locale: locale ?? const Locale('fr'),
    );
  }

  void runToEnd() => run
    ..apply(JobSucceeded(_tsara, '/music/a.mp3'))
    ..apply(JobFailed(_tsy, FailureReason.private))
    ..apply(JobSucceeded(_hafatra, '/music/b.mp3'));

  testWidgets('shows what runs, what waits, and the whole progress', (
    tester,
  ) async {
    run
      ..apply(JobStarted(_tsara))
      ..apply(
        JobProgressed(
          _tsara,
          const DownloadProgress(fraction: 0.42, speed: 1500000),
        ),
      );
    await pumpRun(tester);

    expect(find.text('En cours'), findsOneWidget);
    expect(find.text("Tsara Ny Hiran' Ny Taniko"), findsOneWidget);
    expect(find.text('42 %'), findsOneWidget);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Hafatra'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.textContaining('1,5 Mo/s'), findsOneWidget);
  });

  testWidgets('moves finished videos to the done list', (tester) async {
    run.apply(JobSucceeded(_tsara, '/music/a.mp3'));
    await pumpRun(tester);

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Traités'), findsOneWidget);
    expect(find.text('Réussi'), findsOneWidget);
  });

  testWidgets('cancels the whole run', (tester) async {
    await pumpRun(tester);

    await tester.tap(find.text('Tout annuler'));

    expect(cancels, 1);
  });

  testWidgets('sums up once done, with the reason of each failure', (
    tester,
  ) async {
    runToEnd();
    await pumpRun(tester);

    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('2 réussis'), findsOneWidget);
    expect(find.text('1 échoué'), findsOneWidget);
    expect(find.text('Vidéo privée'), findsOneWidget);
    expect(find.text('Tout annuler'), findsNothing);
  });

  testWidgets('retries the failed videos', (tester) async {
    runToEnd();
    await pumpRun(tester);

    await tester.tap(find.text('Réessayer'));

    expect(retried.single.map((d) => d.item.title), ['Tsy Ferana']);
  });

  testWidgets('copies the failed links as a failed.txt', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    runToEnd();
    await pumpRun(tester);

    await tester.tap(find.text('Copier les liens échoués'));
    await tester.pump();

    expect(copied, contains('https://www.youtube.com/watch?v=jK9lM1nO3pQ'));
    expect(parseLinks(copied!), hasLength(1));
  });

  testWidgets('offers no retry when nothing failed', (tester) async {
    for (final download in _planned) {
      run.apply(JobSucceeded(download, '/music/x.mp3'));
    }
    await pumpRun(tester);

    expect(find.text('3 réussis'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('speaks English', (tester) async {
    run.apply(
      JobProgressed(
        _tsara,
        const DownloadProgress(fraction: 0.42, speed: 1500000),
      ),
    );
    await pumpRun(tester, locale: const Locale('en'));

    expect(find.text('Downloading'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.textContaining('1.5 MB/s'), findsOneWidget);
  });
}
