import 'package:flutter/widgets.dart';

/// What actually decodes and plays sound and pictures: media_kit in the app,
/// a double in tests.
abstract interface class MediaBackend {
  /// Loads [source] (a file path or an https address) and plays it from the
  /// start; [video] when its pictures will be shown.
  Future<void> open(String source, {bool video = false});
  Future<void> play();
  Future<void> pause();

  /// Stops and unloads: nothing left to resume.
  Future<void> stop();
  Future<void> seek(Duration to);

  /// 0 (silent) to 1 (full).
  Future<void> setVolume(double volume);

  Stream<Duration> get position;

  /// Length of what is loaded; zero until known.
  Stream<Duration> get duration;
  Stream<bool> get playing;

  /// What is loaded played to its end.
  Stream<void> get completed;

  /// Its pictures, for a video.
  Widget videoView();
  Future<void> dispose();
}
