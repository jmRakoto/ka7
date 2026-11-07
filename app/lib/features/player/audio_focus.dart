import 'dart:async';

import 'player_controller.dart';

/// Why the system takes the sound away from Ka7 for a while.
enum Interruption {
  /// A call, or another app playing: pause; may say when it is over.
  pause,

  /// A notification sound: lower the volume for its length.
  duck,

  /// Over for good, or unknown: pause, never resume by itself.
  unknown,
}

/// What the system says about Ka7's sound (Android: audio focus).
abstract interface class FocusEvents {
  /// (began, why): a call starts, then ends.
  Stream<(bool, Interruption)> get interruptions;

  /// Headphones unplugged: sound would come out of the speaker.
  Stream<void> get unplugged;

  /// Asks for the sound; false when the system refuses (a call going on).
  Future<bool> request();
}

/// Plays nice with the phone: pauses for a call or another app, lowers the
/// volume for a notification, pauses when headphones are pulled out.
class AudioFocus {
  AudioFocus(this.player, this.events) {
    _subscriptions = [
      events.interruptions.listen((event) => unawaited(_interrupted(event))),
      events.unplugged.listen((_) => unawaited(_pause())),
    ];
    player.addListener(_playingChanged);
  }

  final PlayerController player;
  final FocusEvents events;
  late final List<StreamSubscription<Object?>> _subscriptions;

  /// Ka7 paused itself for an interruption: it plays again at its end.
  /// The user pausing, or playing, meanwhile takes that back.
  var _pausedForIt = false;
  var _wasPlaying = false;

  /// Quieter, not silent: the music still heard under a notification.
  static const _ducked = 0.3;

  Future<void> _playingChanged() async {
    final playing = player.playing;
    if (playing == _wasPlaying) return;
    _wasPlaying = playing;
    if (!playing) return;
    // Playing again, by hand or not: nothing left to resume.
    _pausedForIt = false;
    if (!await events.request()) await _pause();
  }

  Future<void> _interrupted((bool, Interruption) event) async {
    final (began, why) = event;
    switch ((began, why)) {
      case (true, Interruption.duck):
        if (player.playing) await player.backend.setVolume(_ducked);
      case (false, Interruption.duck):
        await player.backend.setVolume(1);
      case (true, _):
        if (!player.playing) return;
        await _pause();
        _pausedForIt = why == Interruption.pause;
      case (false, Interruption.pause):
        if (!_pausedForIt || player.playing) return;
        _pausedForIt = false;
        await player.toggle();
      case (false, _):
        _pausedForIt = false;
    }
  }

  Future<void> _pause() async {
    _pausedForIt = false;
    if (player.playing) await player.toggle();
  }

  void dispose() {
    player.removeListener(_playingChanged);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
  }
}
