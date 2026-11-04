import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/queue/finished_run.dart';
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
  setUp(() {
    run = RunProgress(_planned);
    retried = [];
  });

  Future<void> pumpRun(
    WidgetTester tester, {
    bool expanded = false,
    ImageProvider Function(String videoId)? thumbnail,
    Set<PlannedDownload> retriedAlready = const {},
  }) {
    tester.view
      ..physicalSize = const Size(1280, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: FinishedRun(
            run: run,
            where: 'MP3 · audio · Music/Ka7',
            endedAt: DateTime(2026, 10, 30, 14, 5),
            initiallyExpanded: expanded,
            thumbnail: thumbnail,
            retried: retriedAlready,
            onRetry: retried.add,
          ),
        ),
      ),
    );
  }

  void runToEnd() => run
    ..apply(JobSucceeded(_tsara, '/music/a.mp3'))
    ..apply(JobFailed(_tsy, FailureReason.private))
    ..apply(JobSucceeded(_hafatra, '/music/b.mp3'));

  testWidgets('sums a run up in one line, with its format and time', (
    tester,
  ) async {
    runToEnd();
    await pumpRun(tester);

    expect(find.text('2 réussis'), findsOneWidget);
    expect(find.text('1 échoué'), findsOneWidget);
    expect(find.text('MP3 · audio · Music/Ka7 · 14:05'), findsOneWidget);
    expect(find.text('Tsy Ferana'), findsNothing, reason: 'folded');
  });

  testWidgets('unfolds on its videos, with the reason of each failure', (
    tester,
  ) async {
    runToEnd();
    await pumpRun(tester);

    await tester.tap(find.text('2 réussis'));
    await tester.pumpAndSettle();

    expect(find.text('Tsy Ferana'), findsOneWidget);
    expect(find.text('Vidéo privée'), findsOneWidget);
    expect(find.text('Réussi'), findsNWidgets(2));
  });

  testWidgets('tells a failed run, a done one and a cancelled one apart', (
    tester,
  ) async {
    runToEnd();
    await pumpRun(tester);
    expect(find.byIcon(Icons.error), findsOneWidget);

    run = RunProgress(_planned);
    for (final download in _planned) {
      run.apply(JobSucceeded(download, '/music/x.mp3'));
    }
    await pumpRun(tester);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    run = RunProgress(_planned);
    for (final download in _planned) {
      run.apply(JobCancelled(download));
    }
    await pumpRun(tester);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });

  testWidgets('retries the failed and cancelled videos', (tester) async {
    run
      ..apply(JobSucceeded(_tsara, '/music/a.mp3'))
      ..apply(JobFailed(_tsy, FailureReason.private))
      ..apply(JobCancelled(_hafatra));
    await pumpRun(tester, expanded: true);

    await tester.tap(find.text('Tout réessayer'));

    expect(retried.single.map((d) => d.item.title), ['Tsy Ferana', 'Hafatra']);
  });

  testWidgets('offers to retry everything without unfolding', (tester) async {
    run
      ..apply(JobSucceeded(_tsara, '/music/a.mp3'))
      ..apply(JobFailed(_tsy, FailureReason.private))
      ..apply(JobCancelled(_hafatra));
    await pumpRun(tester);

    expect(find.text('Tsy Ferana'), findsNothing, reason: 'folded');
    expect(find.text("2 titres n'ont pas abouti"), findsOneWidget);
    await tester.tap(find.text('Tout réessayer'));

    expect(retried.single.map((d) => d.item.title), ['Tsy Ferana', 'Hafatra']);
  });

  testWidgets('retries one video at a time', (tester) async {
    run
      ..apply(JobSucceeded(_tsara, '/music/a.mp3'))
      ..apply(JobFailed(_tsy, FailureReason.private))
      ..apply(JobCancelled(_hafatra));
    await pumpRun(tester, expanded: true);

    expect(find.byTooltip('Réessayer ce titre'), findsNWidgets(2));
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Hafatra'),
        matching: find.byTooltip('Réessayer ce titre'),
      ),
    );

    expect(retried.single.map((d) => d.item.title), ['Hafatra']);
  });

  testWidgets('leaves out what was retried, from the list and the counts', (
    tester,
  ) async {
    run
      ..apply(JobSucceeded(_tsara, '/music/a.mp3'))
      ..apply(JobFailed(_tsy, FailureReason.private))
      ..apply(JobCancelled(_hafatra));
    await pumpRun(tester, expanded: true, retriedAlready: {_hafatra});

    expect(find.text('Hafatra'), findsNothing);
    expect(find.text('1 annulé'), findsNothing);
    expect(find.byTooltip('Réessayer ce titre'), findsOneWidget);
    await tester.tap(find.text('Tout réessayer'));
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
    await pumpRun(tester, expanded: true);

    await tester.tap(find.byTooltip('Copier les liens échoués'));
    await tester.pump();

    expect(copied, contains('https://www.youtube.com/watch?v=jK9lM1nO3pQ'));
    expect(parseLinks(copied!), hasLength(1));
  });

  testWidgets('offers no retry when nothing failed', (tester) async {
    for (final download in _planned) {
      run.apply(JobSucceeded(download, '/music/x.mp3'));
    }
    await pumpRun(tester, expanded: true);

    expect(find.text('3 réussis'), findsOneWidget);
    expect(find.text('Tout réessayer'), findsNothing);
  });

  testWidgets('shows the thumbnail of each video', (tester) async {
    runToEnd();
    await pumpRun(
      tester,
      expanded: true,
      thumbnail: (_) => MemoryImage(Uint8List(0)),
    );

    expect(find.byType(Image), findsNWidgets(3));
  });
}
