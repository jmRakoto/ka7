import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ka7/features/player/media_backend.dart';

/// Stands in for media_kit: records what it is asked, plays nothing.
class FakeMediaBackend implements MediaBackend {
  /// Sources opened, in order.
  final opened = <String>[];

  /// Every order received: `open`, `play`, `pause`, `stop`, `seek 0:00:10…`.
  final calls = <String>[];
  var isPlaying = false;

  final _position = StreamController<Duration>.broadcast(sync: true);
  final _duration = StreamController<Duration>.broadcast(sync: true);
  final _playing = StreamController<bool>.broadcast(sync: true);
  final _completed = StreamController<void>.broadcast(sync: true);

  /// Where the playing track is, as the real player would say.
  void at(Duration position) => _position.add(position);

  /// The loaded track's length becomes known.
  void lasts(Duration duration) => _duration.add(duration);

  /// The loaded track plays to its end.
  void finish() => _completed.add(null);

  void _set(bool playing) {
    isPlaying = playing;
    _playing.add(playing);
  }

  /// Whether each opened source was a video.
  final openedVideo = <bool>[];

  @override
  Future<void> open(String source, {bool video = false}) async {
    opened.add(source);
    openedVideo.add(video);
    calls.add('open');
    _set(true);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _set(true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _set(false);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _set(false);
  }

  @override
  Future<void> seek(Duration to) async {
    calls.add('seek $to');
    _position.add(to);
  }

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration> get duration => _duration.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Widget videoView() => const SizedBox(key: Key('fake-video'));

  @override
  Future<void> dispose() async {}
}
