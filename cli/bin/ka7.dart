import 'dart:async';
import 'dart:io';

import 'package:ka7_cli/ka7_cli.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:ka7_store/ka7_store.dart';

Future<void> main(List<String> arguments) async {
  final folder = _dataFolder()..createSync(recursive: true);
  final store = Ka7Store.open(File('${folder.path}/ka7.sqlite'));
  final cli = Ka7Cli(
    extractor: YtDlpExtractor(run: Process.run),
    downloader: YtDlpDownloader(start: Process.start),
    store: store,
    workingDirectory: Directory.current.path,
    out: stdout,
    now: DateTime.now,
    language: Platform.localeName,
    showProgress: stdioType(stdout) == StdioType.terminal,
    ask: _ask,
  );
  final interrupt = ProcessSignal.sigint.watch().listen((_) => cli.cancel());
  exitCode = await cli.run(arguments);
  await interrupt.cancel();
  await store.close();
}

/// Same folder as the app (path_provider's application support directory),
/// so both share one archive and one history.
Directory _dataFolder() {
  const id = 'mg.rakoto.ka7';
  final env = Platform.environment;
  if (Platform.isWindows) return Directory('${env['APPDATA']}\\$id');
  final home = env['HOME']!;
  if (Platform.isMacOS) {
    return Directory('$home/Library/Application Support/$id');
  }
  final data = env['XDG_DATA_HOME'] ?? '$home/.local/share';
  return Directory('$data/$id');
}

/// Asks on the terminal; without one (script, pipe) the answer is no.
Future<bool> _ask(String question) async {
  if (stdioType(stdin) != StdioType.terminal) return false;
  stdout.write(question);
  final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  return const {'y', 'yes', 'o', 'oui'}.contains(answer);
}
