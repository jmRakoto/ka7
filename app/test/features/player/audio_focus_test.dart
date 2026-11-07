import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/audio_focus.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/track.dart';

import '../../helpers/fake_media_backend.dart';

const _a = Track(title: 'Tanalahy ny foko', videoId: 'a', path: '/m/a.mp3');

class _FakeEvents implements FocusEvents {
  final interrupt = StreamController<(bool, Interruption)>.broadcast(
    sync: true,
  );
  final unplug = StreamController<void>.broadcast(sync: true);
  var granted = true;
  var requests = 0;

  @override
  Stream<(bool, Interruption)> get interruptions => interrupt.stream;

  @override
  Stream<void> get unplugged => unplug.stream;

  @override
  Future<bool> request() async {
    requests++;
    return granted;
  }
}

void main() {
  late FakeMediaBackend backend;
  late PlayerController player;
  late _FakeEvents events;
  late AudioFocus focus;

  setUp(() {
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
    events = _FakeEvents();
    focus = AudioFocus(player, events);
  });
  tearDown(() => focus.dispose());

  test('asks the system for the sound when it starts playing', () async {
    await player.playAll([_a]);
    await pumpEventQueue();

    expect(events.requests, 1);
  });

  test('refused (a call going on): does not play', () async {
    events.granted = false;
    await player.playAll([_a]);
    await pumpEventQueue();

    expect(backend.isPlaying, isFalse);
  });

  test('a call pauses, and its end plays again', () async {
    await player.playAll([_a]);
    events.interrupt.add((true, Interruption.pause));
    await pumpEventQueue();
    expect(backend.isPlaying, isFalse);

    events.interrupt.add((false, Interruption.pause));
    await pumpEventQueue();
    expect(backend.isPlaying, isTrue);
  });

  test('paused by hand before the call: stays paused after it', () async {
    await player.playAll([_a]);
    await player.toggle();
    events.interrupt
      ..add((true, Interruption.pause))
      ..add((false, Interruption.pause));
    await pumpEventQueue();

    expect(backend.isPlaying, isFalse);
  });

  test('paused by hand during the call: stays paused after it', () async {
    await player.playAll([_a]);
    events.interrupt.add((true, Interruption.pause));
    await pumpEventQueue();
    // Played, then paused again by hand while the call goes on.
    await player.toggle();
    await pumpEventQueue();
    await player.toggle();
    events.interrupt.add((false, Interruption.pause));
    await pumpEventQueue();

    expect(backend.isPlaying, isFalse);
  });

  test('another app taking the sound for good: pause, no resume', () async {
    await player.playAll([_a]);
    events.interrupt
      ..add((true, Interruption.unknown))
      ..add((false, Interruption.unknown));
    await pumpEventQueue();

    expect(backend.isPlaying, isFalse);
  });

  test('a notification sound lowers the volume, then restores it', () async {
    await player.playAll([_a]);
    events.interrupt.add((true, Interruption.duck));
    await pumpEventQueue();
    expect(backend.volume, lessThan(0.5));
    expect(backend.isPlaying, isTrue);

    events.interrupt.add((false, Interruption.duck));
    await pumpEventQueue();
    expect(backend.volume, 1.0);
  });

  test('headphones pulled out: pause', () async {
    await player.playAll([_a]);
    events.unplug.add(null);
    await pumpEventQueue();

    expect(backend.isPlaying, isFalse);
  });

  test('nothing to do while nothing plays', () async {
    events.unplug.add(null);
    events.interrupt.add((false, Interruption.pause));
    await pumpEventQueue();

    expect(backend.calls, isEmpty);
  });
}
