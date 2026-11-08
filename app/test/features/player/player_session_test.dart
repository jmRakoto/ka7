import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/player_session.dart';
import 'package:ka7/features/player/track.dart';

import '../../helpers/fake_media_backend.dart';

const _a = Track(title: 'Tanalahy ny foko', videoId: 'a', path: '/m/a.mp3');
const _b = Track(title: 'Somambisamby', videoId: 'b', path: '/m/b.mp3');

void main() {
  late FakeMediaBackend backend;
  late PlayerController player;
  late PlayerSession session;

  setUp(() {
    backend = FakeMediaBackend();
    player = PlayerController(backend: backend);
    session = PlayerSession(player);
  });
  tearDown(() => session.dispose());

  PlaybackState state() => session.playbackState.value;

  group('what the system shows', () {
    test('nothing playing: nothing to show', () {
      expect(state().processingState, AudioProcessingState.idle);
      expect(session.mediaItem.value, isNull);
    });

    test('the track playing, with its length', () async {
      await player.playAll([_a, _b]);
      backend.lasts(const Duration(minutes: 4));

      final item = session.mediaItem.value!;
      expect(item.title, 'Tanalahy ny foko');
      expect(item.duration, const Duration(minutes: 4));
      expect(item.album, 'Ka7');
      expect(state().processingState, AudioProcessingState.ready);
      expect(state().playing, isTrue);
      expect(state().queueIndex, 0);
    });

    test('previous, pause, next and stop while playing', () async {
      await player.playAll([_a, _b]);

      expect(state().controls, [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.stop,
      ]);
      // The three shown when the notification is folded.
      expect(state().androidCompactActionIndices, [0, 1, 2]);
      expect(state().systemActions, contains(MediaAction.seek));
    });

    test('play instead of pause once paused, where it stopped', () async {
      await player.playAll([_a]);
      backend.at(const Duration(seconds: 42));
      await player.toggle();

      expect(state().playing, isFalse);
      expect(state().controls[1], MediaControl.play);
      expect(state().updatePosition, const Duration(seconds: 42));
    });

    test('the cover, when the track has one', () async {
      session.dispose();
      session = PlayerSession(
        player,
        cover: (track) => track.videoId == 'a'
            ? Uri.parse('https://i.ytimg.com/vi/a/hqdefault.jpg')
            : null,
      );
      await player.playAll([_a, _b]);
      expect(
        session.mediaItem.value!.artUri,
        Uri.parse('https://i.ytimg.com/vi/a/hqdefault.jpg'),
      );

      await player.next();
      expect(session.mediaItem.value!.artUri, isNull);
    });

    test('follows the next track', () async {
      await player.playAll([_a, _b]);
      await player.next();

      expect(session.mediaItem.value!.title, 'Somambisamby');
      expect(state().queueIndex, 1);
    });

    test('a track that cannot play shows an error, with its reason', () async {
      await player.playAll([const Track(title: 'Me at the zoo', videoId: 'z')]);

      expect(state().processingState, AudioProcessingState.error);
      expect(state().errorMessage, isNotEmpty);
    });

    test('closing the player removes the notification', () async {
      await player.playAll([_a]);
      await player.close();

      expect(state().processingState, AudioProcessingState.idle);
      expect(session.mediaItem.value, isNull);
    });
  });

  group('presses on the notification, lock screen, headset', () {
    test('pause and play', () async {
      await player.playAll([_a]);

      await session.pause();
      expect(backend.isPlaying, isFalse);
      await session.play();
      expect(backend.isPlaying, isTrue);
    });

    test('play while playing does not pause', () async {
      await player.playAll([_a]);

      await session.play();

      expect(backend.isPlaying, isTrue);
    });

    test('next and previous', () async {
      await player.playAll([_a, _b]);

      await session.skipToNext();
      expect(backend.opened.last, '/m/b.mp3');
      await session.skipToPrevious();
      expect(backend.opened.last, '/m/a.mp3');
    });

    test('seek, and 10 s forward and back', () async {
      await player.playAll([_a]);
      backend
        ..lasts(const Duration(minutes: 3))
        ..at(const Duration(seconds: 30));

      await session.seek(const Duration(minutes: 1));
      expect(backend.calls.last, 'seek 0:01:00.000000');
      await session.fastForward();
      expect(backend.calls.last, 'seek 0:01:10.000000');
      await session.rewind();
      expect(backend.calls.last, 'seek 0:01:00.000000');
    });

    test('a jump shows where it lands at once', () async {
      await player.playAll([_a]);
      backend.lasts(const Duration(minutes: 3));

      await session.seek(const Duration(minutes: 2));

      expect(state().updatePosition, const Duration(minutes: 2));
    });

    test('stop goes back to the start, the track kept', () async {
      await player.playAll([_a]);
      backend.at(const Duration(minutes: 1));

      await session.stop();

      expect(player.current, _a);
      expect(backend.isPlaying, isFalse);
      expect(player.position, Duration.zero);
    });

    test('stop shows the start on the lock screen', () async {
      await player.playAll([_a]);
      backend.at(const Duration(minutes: 1));

      await session.stop();

      expect(state().playing, isFalse);
      expect(state().updatePosition, Duration.zero);
    });

    test('the app\'s own stop shows the start too', () async {
      await player.playAll([_a]);
      backend.at(const Duration(minutes: 1));

      await player.stop();

      expect(state().updatePosition, Duration.zero);
    });

    test('a jump made in the app shows where it lands', () async {
      await player.playAll([_a]);
      backend.lasts(const Duration(minutes: 4));

      await player.seek(const Duration(minutes: 3));

      expect(state().updatePosition, const Duration(minutes: 3));
    });

    test('play after stop plays again (lock screen)', () async {
      await player.playAll([_a]);
      await session.stop();

      await session.play();

      expect(backend.isPlaying, isTrue);
      expect(state().playing, isTrue);
    });
  });
}
