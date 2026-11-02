import 'dart:io';

import 'run_notifier.dart';

/// Runs a program and waits for its result; [Process.run] in production.
typedef RunProcess =
    Future<ProcessResult> Function(String executable, List<String> arguments);

/// Linux: `notify-send` (libnotify), shown by the desktop's notifications.
class DesktopNotifier implements RunNotifier {
  DesktopNotifier({required this.run});

  final RunProcess run;

  @override
  void finished({required String title, required String body}) {
    run('notify-send', [
      '--app-name=Ka7',
      '--icon=mg.rakoto.ka7',
      title,
      body,
    ]).ignore();
  }
}
