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
final _tsara = _planned[0];

void main() {
  late RunProgress run;
  late int cancels;
  ImageProvider Function(String videoId)? thumbnail;
  setUp(() {
    run = RunProgress(_planned);
    cancels = 0;
    thumbnail = null;
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
            thumbnail: thumbnail,
          ),
        ),
      ),
      locale: locale ?? const Locale('fr'),
    );
  }

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

  testWidgets('shows the thumbnail of each video', (tester) async {
    thumbnail = (_) => MemoryImage(Uint8List(0));
    run.apply(JobStarted(_tsara));
    await pumpRun(tester);

    expect(find.byType(Image), findsNWidgets(3));
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
