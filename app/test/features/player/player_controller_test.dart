import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/player/player_controller.dart';
import 'package:ka7/features/player/track.dart';
import 'package:ka7_core/ka7_core.dart';

import '../../helpers/fake_media_backend.dart';

const _a = Track(title: 'Tanalahy ny foko', videoId: 'a', path: '/m/a.mp3');
const _b = Track(title: 'Somambisamby', videoId: 'b', path: '/m/b.mp3');
const _c = Track(title: 'Veloma Mahaleo', videoId: 'c', path: '/m/c.mp3');
const _zoo = Track(title: 'Me at the zoo', videoId: 'jNQXAC9IVRw');

void main() {
  late FakeMediaBackend backend;
  late PlayerController player;
  var gone = <String>{};
  var online = true;

  setUp(() {
    backend = FakeMediaBackend();
    gone = {};
    online = true;
    player = PlayerController(
      backend: backend,
      fileExists: (track) async => !gone.contains(track.path),
      streamUrl: (videoId, {required video}) async {
        if (!online) {
          throw const ProbeFailure(FailureReason.network, 'offline');
        }
        return 'https://stream/$videoId${video ? '/video' : ''}';
      },
    );
  });

  group('playing', () {
    test('plays the chosen file of a list', () async {
      await player.playAll([_a, _b, _c], start: 1);

      expect(backend.opened, ['/m/b.mp3']);
      expect(player.current, _b);
      expect(player.playing, isTrue);
    });

    test('plays an online video from its stream address', () async {
      await player.playAll([_zoo]);

      expect(backend.opened, ['https://stream/jNQXAC9IVRw']);
    });

    test('asks for the video stream of a video', () async {
      await player.playAll([
        const Track(title: 'Me at the zoo', videoId: 'z', video: true),
      ]);

      expect(backend.opened, ['https://stream/z/video']);
    });

    test('tells the backend a video is coming, not a song', () async {
      await player.playAll([
        const Track(title: 'Me at the zoo', videoId: 'z', video: true),
        _a,
      ]);
      await player.next();

      expect(backend.openedVideo, [true, false]);
    });

    test('says when an online track cannot be read', () async {
      online = false;
      await player.playAll([_zoo]);

      expect(player.error, PlayerError.offline);
      expect(player.playing, isFalse);
      expect(backend.opened, isEmpty);
    });

    test('toggle pauses, then plays again', () async {
      await player.playAll([_a]);
      await player.toggle();
      expect(player.playing, isFalse);
      await player.toggle();
      expect(player.playing, isTrue);
      expect(backend.calls, ['open', 'pause', 'play']);
    });

    test('follows position and length from the backend', () async {
      await player.playAll([_a]);
      backend
        ..lasts(const Duration(minutes: 4))
        ..at(const Duration(seconds: 30));

      expect(player.duration, const Duration(minutes: 4));
      expect(player.position, const Duration(seconds: 30));
    });

    test('stop pauses back at the start, the track still there', () async {
      await player.playAll([_a, _b]);
      backend.at(const Duration(minutes: 1));
      await player.stop();

      expect(player.playing, isFalse);
      expect(player.position, Duration.zero);
      expect(player.current, _a);
      expect(
        backend.calls,
        containsAllInOrder(['pause', 'seek 0:00:00.000000']),
      );
    });

    test('close empties the player', () async {
      await player.playAll([_a, _b]);
      await player.close();

      expect(player.current, isNull);
      expect(player.tracks, isEmpty);
      expect(backend.calls.last, 'stop');
    });
  });

  group('moving', () {
    test('next and previous play the next and previous tracks', () async {
      await player.playAll([_a, _b, _c]);
      await player.next();
      await player.next();
      await player.previous();

      expect(backend.opened, ['/m/a.mp3', '/m/b.mp3', '/m/c.mp3', '/m/b.mp3']);
    });

    test('previous after a few seconds starts the track again', () async {
      await player.playAll([_a, _b], start: 1);
      backend.at(const Duration(seconds: 12));
      await player.previous();

      expect(player.current, _b);
      expect(backend.calls.last, 'seek 0:00:00.000000');
    });

    test('a finished track goes on to the next one', () async {
      await player.playAll([_a, _b]);
      backend.finish();
      await pumpEventQueue();

      expect(player.current, _b);
      expect(backend.opened.last, '/m/b.mp3');
    });

    test('the queue ends on its last track, paused', () async {
      await player.playAll([_a]);
      backend.finish();
      await pumpEventQueue();

      expect(player.playing, isFalse);
      expect(player.current, _a);
    });

    test('repeat one plays a finished track again', () async {
      await player.playAll([_a, _b]);
      player.setRepeat(Repeat.one);
      backend.finish();
      await pumpEventQueue();

      expect(backend.opened, ['/m/a.mp3', '/m/a.mp3']);
    });

    test('jumpTo plays a track of the queue', () async {
      await player.playAll([_a, _b, _c]);
      await player.jumpTo(2);

      expect(backend.opened.last, '/m/c.mp3');
    });

    test('seekBy jumps forward and back, within the track', () async {
      await player.playAll([_a]);
      backend
        ..lasts(const Duration(seconds: 30))
        ..at(const Duration(seconds: 25));
      await player.seekBy(const Duration(seconds: 10));
      expect(backend.calls.last, 'seek 0:00:30.000000');

      backend.at(const Duration(seconds: 4));
      await player.seekBy(const Duration(seconds: -10));
      expect(backend.calls.last, 'seek 0:00:00.000000');
    });
  });

  group('missing files', () {
    test('a deleted file is skipped and remembered', () async {
      gone = {'/m/a.mp3'};
      await player.playAll([_a, _b]);

      expect(backend.opened, ['/m/b.mp3']);
      expect(player.missing, {'/m/a.mp3'});
    });

    test('says so when every file is gone', () async {
      gone = {'/m/a.mp3', '/m/b.mp3'};
      await player.playAll([_a, _b]);

      expect(backend.opened, isEmpty);
      expect(player.error, PlayerError.missingFile);
      expect(player.playing, isFalse);
    });
  });

  group('queue', () {
    test('play next lands right after the current track', () async {
      await player.playAll([_a, _b]);
      await player.playNext(_c);

      expect(player.tracks, [_a, _c, _b]);
      expect(backend.opened, ['/m/a.mp3']);
    });

    test('enqueue adds at the end', () async {
      await player.playAll([_a]);
      await player.enqueue(_b);

      expect(player.tracks, [_a, _b]);
    });

    test('enqueue on an empty player starts playing', () async {
      await player.enqueue(_b);

      expect(backend.opened, ['/m/b.mp3']);
    });

    test('shuffle keeps the current track playing', () async {
      await player.playAll([_a, _b, _c]);
      player.setShuffle(true);

      expect(player.shuffled, isTrue);
      expect(player.current, _a);
      expect(player.tracks.toSet(), {_a, _b, _c});
    });

    test('removing the current track plays the next one', () async {
      await player.playAll([_a, _b, _c]);
      player.removeAt(0);
      await pumpEventQueue();

      expect(player.tracks, [_b, _c]);
      expect(backend.opened.last, '/m/b.mp3');
    });

    test('tells listeners when something changes', () async {
      var changes = 0;
      player.addListener(() => changes++);
      await player.playAll([_a]);

      expect(changes, greaterThan(0));
    });
  });
}
