import 'dart:async';

import 'engine_binaries.dart';

/// Updates yt-dlp at most once a day, silently, when the tools are checked:
/// YouTube changes faster than the app ships.
final class DailyUpdate implements EngineSetup {
  DailyUpdate(
    this.setup, {
    required this.update,
    required this.lastUpdate,
    required this.saveUpdate,
    required this.now,
    this.timeout = const Duration(minutes: 1),
  });

  final EngineSetup setup;

  /// Runs the update; true when it succeeded.
  final Future<bool> Function() update;

  /// When the last update succeeded; null if never.
  final Future<DateTime?> Function() lastUpdate;
  final Future<void> Function(DateTime at) saveUpdate;
  final DateTime Function() now;

  /// Past this, the app opens with the yt-dlp it has.
  final Duration timeout;

  @override
  Future<EngineStatus> check() async {
    final status = await setup.check();
    if (status.ytDlp != null && await _due()) {
      try {
        if (await update().timeout(timeout)) await saveUpdate(now());
      } on Object {
        // Offline or GitHub unreachable: the current yt-dlp still runs.
      }
    }
    return status;
  }

  Future<bool> _due() async {
    final last = await lastUpdate();
    return last == null || now().difference(last) >= const Duration(days: 1);
  }

  @override
  Stream<double> install(EngineTool tool) => setup.install(tool);
}
