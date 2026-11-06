import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'media_backend.dart';

/// libmpv through media_kit: audio and video, desktop and Android.
final class MediaKitBackend implements MediaBackend {
  MediaKitBackend() : _player = Player();

  final Player _player;

  /// Made only for a video, before it is opened: attached, media_kit waits
  /// for it before opening anything, so audio alone would hang; attached
  /// after, the video is already decoded without pictures (black screen).
  late final VideoController _video = VideoController(_player);

  @override
  Future<void> open(String source, {bool video = false}) {
    if (video) _video;
    return _player.open(Media(source));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration to) => _player.seek(to);

  @override
  Stream<Duration> get position => _player.stream.position;

  @override
  Stream<Duration> get duration => _player.stream.duration;

  @override
  Stream<bool> get playing => _player.stream.playing;

  @override
  Stream<void> get completed => _player.stream.completed.where((done) => done);

  /// Completes once a video frame is drawn (tests).
  Future<void> get firstFrame => _video.waitUntilFirstFrameRendered;

  @override
  Widget videoView() => Video(controller: _video, controls: NoVideoControls);

  @override
  Future<void> dispose() => _player.dispose();
}
