import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';

/// yt-dlp embedded in the Android app (youtubedl-android), driven through a
/// platform channel. [run] and [start] mimic [Process.run] and
/// [Process.start], so the desktop yt-dlp engine works unchanged on top.
///
/// Kotlin side: `android/app/src/main/kotlin/mg/rakoto/ka7/YtDlpChannel.kt`.
/// It calls back `line` ({id, line}) for each output line of a started
/// download, then `exit` ({id, exitCode, err}).
class AndroidYtDlp {
  AndroidYtDlp([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('mg.rakoto.ka7/ytdlp') {
    _channel.setMethodCallHandler(_onNative);
  }

  final MethodChannel _channel;
  final _running = <String, _ChannelProcess>{};
  var _nextId = 0;
  Future<void>? _init;

  /// Unpacks Python, yt-dlp and ffmpeg on first launch; tries again after a
  /// failure.
  Future<void> init() =>
      _init ??= _channel.invokeMethod<void>('init').catchError((Object error) {
        _init = null;
        throw error;
      });

  /// Fetches the latest yt-dlp: YouTube changes faster than the app ships.
  Future<void> update() => _channel.invokeMethod<void>('update');

  Future<ProcessResult> run(String executable, List<String> arguments) async {
    final result = await _invoke('run', {'args': arguments});
    return ProcessResult(
      0,
      result['exitCode']! as int,
      result['out']! as String,
      result['err']! as String,
    );
  }

  Future<Process> start(String executable, List<String> arguments) async {
    final id = '${_nextId++}';
    final process = _ChannelProcess(
      int.parse(id),
      () => _channel.invokeMethod<void>('kill', {'id': id}),
    );
    _running[id] = process;
    try {
      await _invoke('start', {'id': id, 'args': arguments});
    } on ProcessException {
      _running.remove(id);
      rethrow;
    }
    return process;
  }

  Future<Map<Object?, Object?>> _invoke(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      return await _channel.invokeMethod<Map<Object?, Object?>>(
            method,
            arguments,
          ) ??
          const {};
    } on PlatformException catch (e) {
      // The engine could not even start: the queue reports it as missing.
      throw ProcessException('yt-dlp', const [], e.message ?? e.code);
    }
  }

  Future<void> _onNative(MethodCall call) async {
    final arguments = call.arguments as Map<Object?, Object?>;
    final process = _running[arguments['id']];
    if (process == null) return;
    switch (call.method) {
      case 'line':
        process.line(arguments['line']! as String);
      case 'exit':
        _running.remove(arguments['id']);
        process.exit(
          arguments['exitCode']! as int,
          arguments['err']! as String,
        );
    }
  }
}

/// A download running on the Kotlin side, seen as a [Process].
class _ChannelProcess implements Process {
  _ChannelProcess(this.pid, this._kill);

  @override
  final int pid;

  /// Asks the Kotlin side to stop the download.
  final Future<void> Function() _kill;

  final _stdout = StreamController<List<int>>();
  final _stderr = StreamController<List<int>>();
  final _exitCode = Completer<int>();

  void line(String text) => _stdout.add(utf8.encode('$text\n'));

  void exit(int code, String err) {
    if (err.isNotEmpty) _stderr.add(utf8.encode(err));
    _stdout.close();
    _stderr.close();
    if (!_exitCode.isCompleted) _exitCode.complete(code);
  }

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    _kill();
    return true;
  }

  @override
  IOSink get stdin => throw UnsupportedError('yt-dlp reads no input');
}

/// Flow 0 on Android: the engine ships in the app, it only needs unpacking.
class AndroidEngineSetup implements EngineSetup {
  AndroidEngineSetup(this.ytDlp);

  final AndroidYtDlp ytDlp;

  /// Where the embedded tools live: Kotlin knows, Dart only needs a value.
  static const embedded = 'embedded';

  @override
  Future<EngineStatus> check() async {
    try {
      await ytDlp.init();
    } on PlatformException {
      return const EngineStatus();
    }
    return const EngineStatus(ytDlp: embedded, ffmpeg: embedded);
  }

  /// Fetches the latest yt-dlp; false when it could not (offline).
  /// Run through DailyUpdate: at most once a day, a minute at most.
  Future<bool> updateYtDlp() async {
    try {
      await ytDlp.update();
      return true;
    } on PlatformException {
      // Offline or GitHub unreachable: the embedded yt-dlp still runs.
      return false;
    }
  }

  /// Nothing to download: unpacking again is the only repair.
  @override
  Stream<double> install(EngineTool tool) async* {
    try {
      await ytDlp.init();
    } on PlatformException catch (e) {
      throw InstallFailure(e.message ?? e.code);
    }
  }
}
