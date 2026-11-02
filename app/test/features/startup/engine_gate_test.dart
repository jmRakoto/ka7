import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/startup/engine_gate.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

import '../../helpers/fake_engine_setup.dart';
import '../../helpers/pump_app.dart';

void main() {
  Future<void> pumpGate(WidgetTester tester, FakeEngineSetup setup) async {
    await pumpApp(
      tester,
      EngineGate(
        setup: setup,
        builder: (context, status) => Text('READY ${status.ytDlp}'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens the app at once when the tools are there', (tester) async {
    await pumpGate(tester, FakeEngineSetup.ready());

    expect(find.text('READY /opt/ka7/yt-dlp'), findsOneWidget);
  });

  testWidgets('says what is missing and offers to install it', (tester) async {
    await pumpGate(
      tester,
      FakeEngineSetup(missing: {EngineTool.ytDlp, EngineTool.ffmpeg}),
    );

    expect(find.text('Il manque yt-dlp et ffmpeg'), findsOneWidget);
    expect(find.text('Installer'), findsOneWidget);
    expect(find.textContaining('READY'), findsNothing);
  });

  testWidgets('installs each missing tool, then opens the app', (tester) async {
    final setup = FakeEngineSetup(missing: {EngineTool.ffmpeg});
    await pumpGate(tester, setup);
    expect(find.text('Il manque ffmpeg'), findsOneWidget);

    await tester.tap(find.text('Installer'));
    // Nothing received yet: the bar runs without end, so no settling.
    await tester.pump();
    setup.progress(EngineTool.ffmpeg, 0.4);
    await tester.pumpAndSettle();

    expect(find.text('Installation de ffmpeg… 40 %'), findsOneWidget);

    setup.finish(EngineTool.ffmpeg);
    await tester.pumpAndSettle();

    expect(find.text('READY /opt/ka7/yt-dlp'), findsOneWidget);
  });

  testWidgets('explains a failed install and lets the user retry', (
    tester,
  ) async {
    final setup = FakeEngineSetup(missing: {EngineTool.ytDlp});
    await pumpGate(tester, setup);

    await tester.tap(find.text('Installer'));
    // Nothing received yet: the bar runs without end, so no settling.
    await tester.pump();
    setup.fail(EngineTool.ytDlp);
    await tester.pumpAndSettle();

    expect(find.textContaining('Installation impossible'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    setup.finish(EngineTool.ytDlp);
    await tester.pumpAndSettle();

    expect(find.textContaining('READY'), findsOneWidget);
  });

  testWidgets('shows the Ka7 splash while getting the engine ready', (
    tester,
  ) async {
    final setup = _PendingSetup();
    await pumpApp(
      tester,
      EngineGate(
        setup: setup,
        builder: (context, status) => Text('READY ${status.ytDlp}'),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Ka7'), findsOneWidget);
    expect(find.text('Préparation du moteur…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    setup.ready.complete(
      const EngineStatus(ytDlp: '/opt/ka7/yt-dlp', ffmpeg: '/opt/ka7/ffmpeg'),
    );
    await tester.pumpAndSettle();
    expect(find.text('READY /opt/ka7/yt-dlp'), findsOneWidget);
  });
}

/// Still checking the tools until the test says so.
class _PendingSetup implements EngineSetup {
  final ready = Completer<EngineStatus>();

  @override
  Future<EngineStatus> check() => ready.future;

  @override
  Stream<double> install(EngineTool tool) => const Stream.empty();
}
