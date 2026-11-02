import 'dart:async';

import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

/// Engine setup double: tools present or not, installs driven by the test.
class FakeEngineSetup implements EngineSetup {
  FakeEngineSetup({Set<EngineTool> missing = const {}})
    : missing = {...missing};

  final Set<EngineTool> missing;
  final installing = <EngineTool, StreamController<double>>{};

  /// Installed everything at once, as on a machine that already has them.
  static FakeEngineSetup ready() => FakeEngineSetup();

  @override
  Future<EngineStatus> check() async => EngineStatus(
    ytDlp: missing.contains(EngineTool.ytDlp) ? null : '/opt/ka7/yt-dlp',
    ffmpeg: missing.contains(EngineTool.ffmpeg) ? null : '/opt/ka7/ffmpeg',
  );

  @override
  Stream<double> install(EngineTool tool) {
    final controller = StreamController<double>();
    installing[tool] = controller;
    return controller.stream;
  }

  void progress(EngineTool tool, double fraction) =>
      installing[tool]!.add(fraction);

  void finish(EngineTool tool) {
    missing.remove(tool);
    installing[tool]!.close();
  }

  void fail(EngineTool tool) {
    installing[tool]!
      ..addError(const InstallFailure('HTTP 503'))
      ..close();
  }
}
