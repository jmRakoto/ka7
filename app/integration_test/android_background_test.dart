import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ka7/features/player/audio_focus.dart';
import 'package:ka7/features/player/media_kit_backend.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_session.dart';
import 'package:ka7/features/player/track.dart';
import 'package:ka7/platform/android_audio_focus.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;
import 'package:path_provider/path_provider.dart';

/// Android, screen off. Driven from outside by tool/android/check_background.sh
/// (headset buttons, Home, screen off), as a person with a phone would:
///   tool/android/check_background.sh
/// This side plays, and says what it hears (« KA7 … » lines).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  testWidgets('plays on in the background, driven from outside', (
    tester,
  ) async {
    final folder = await getTemporaryDirectory();
    final first = File('${folder.path}/ka7-tone-440.wav')
      ..writeAsBytesSync(_tone(440));
    final second = File('${folder.path}/ka7-tone-660.wav')
      ..writeAsBytesSync(_tone(660));
    final backend = MediaKitBackend();
    final player = PlayerController(backend: backend);
    // As main.dart does on Android: focus first, then the session.
    final focus = AudioFocus(player, await AndroidFocusEvents.start());
    addTearDown(focus.dispose);
    await AudioService.init(
      builder: () => PlayerSession(
        player,
        cover: (_) =>
            Uri.parse('https://i.ytimg.com/vi/jNQXAC9IVRw/hqdefault.jpg'),
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'mg.rakoto.ka7.playback',
        androidNotificationChannelName: 'Lecture',
        androidNotificationIcon: 'drawable/ic_notification',
        androidStopForegroundOnPause: false,
      ),
    );

    Future<void> until(bool Function() done, String what) async {
      final end = DateTime.now().add(const Duration(seconds: 60));
      while (!done()) {
        if (DateTime.now().isAfter(end)) fail('timed out: $what');
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    await player.playAll([
      Track(title: 'Ka7 tone 440', videoId: '440', path: first.path),
      Track(title: 'Ka7 tone 660', videoId: '660', path: second.path),
    ]);
    await until(
      () => player.position > const Duration(seconds: 1),
      'starts playing',
    );
    _say('PLAYING');

    await until(() => !player.playing, 'paused by the headset button');
    _say('PAUSED');
    await until(() => player.playing, 'played by the headset button');
    _say('RESUMED');

    // Home, then screen off (about 15 s): the first tone must go on.
    final from = player.position;
    var last = from;
    await until(() {
      if (player.current?.title == 'Ka7 tone 440') last = player.position;
      return player.current?.title == 'Ka7 tone 660';
    }, 'next, pressed with the screen off');
    final played = last - from;
    _say('NEXT; the first tone went on ${played.inSeconds} s');
    expect(
      played,
      greaterThanOrEqualTo(const Duration(seconds: 10)),
      reason: 'it stopped in the background',
    );
    await until(
      () => player.position > const Duration(seconds: 5),
      'the next one plays on, screen off',
    );
    _say('BACKGROUND OK at ${player.position.inSeconds} s');

    // A phone call rings: Ka7 pauses; hung up: it plays on by itself.
    await until(() => !player.playing, 'paused for the call');
    _say('CALL PAUSED');
    await until(() => player.playing, 'played again after the call');
    _say('CALL RESUMED');
    await player.close();
  });
}

void _say(String what) {
  // ignore: avoid_print
  print('KA7 $what');
}

/// 60 s of a sine tone, 8 kHz mono WAV: a file to play, without network.
Uint8List _tone(int hertz) {
  const rate = 8000, seconds = 60;
  const samples = rate * seconds;
  final bytes = ByteData(44 + samples * 2);
  void ascii(int at, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + samples * 2, Endian.little);
  ascii(8, 'WAVEfmt ');
  bytes
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, rate, Endian.little)
    ..setUint32(28, rate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, samples * 2, Endian.little);
  for (var i = 0; i < samples; i++) {
    final value = (sin(2 * pi * hertz * i / rate) * 8000).round();
    bytes.setInt16(44 + i * 2, value, Endian.little);
  }
  return bytes.buffer.asUint8List();
}
