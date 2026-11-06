import 'dart:math';

import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

PlayQueue<String> _abc({int start = 0}) =>
    PlayQueue(['a', 'b', 'c'], start: start, random: Random(7));

void main() {
  group('order', () {
    test('starts on the given track', () {
      final queue = _abc(start: 1);
      expect(queue.current, 'b');
      expect(queue.index, 1);
    });

    test('an empty queue has nothing to play', () {
      final queue = PlayQueue<String>(const []);
      expect(queue.current, isNull);
      expect(queue.next(), isFalse);
      expect(queue.previous(), isFalse);
    });

    test('next goes forward and stops at the end', () {
      final queue = _abc();
      expect(queue.next(), isTrue);
      expect(queue.current, 'b');
      expect(queue.next(), isTrue);
      expect(queue.next(), isFalse);
      expect(queue.current, 'c');
    });

    test('previous goes back and stops at the start', () {
      final queue = _abc(start: 1);
      expect(queue.previous(), isTrue);
      expect(queue.current, 'a');
      expect(queue.previous(), isFalse);
      expect(queue.current, 'a');
    });

    test('jumpTo plays the chosen track', () {
      final queue = _abc()..jumpTo(2);
      expect(queue.current, 'c');
    });
  });

  group('repeat', () {
    test('all: next wraps from the last to the first', () {
      final queue = _abc(start: 2)..repeat = Repeat.all;
      expect(queue.next(), isTrue);
      expect(queue.current, 'a');
    });

    test('all: previous wraps from the first to the last', () {
      final queue = _abc()..repeat = Repeat.all;
      expect(queue.previous(), isTrue);
      expect(queue.current, 'c');
    });

    test('off: the queue is over after the last track ends', () {
      final queue = _abc(start: 2);
      expect(queue.ended(), isFalse);
    });

    test('off: a finished track moves to the next one', () {
      final queue = _abc();
      expect(queue.ended(), isTrue);
      expect(queue.current, 'b');
    });

    test('one: a finished track plays again', () {
      final queue = _abc()..repeat = Repeat.one;
      expect(queue.ended(), isTrue);
      expect(queue.current, 'a');
    });

    test('one: next still skips to the next track', () {
      final queue = _abc()..repeat = Repeat.one;
      expect(queue.next(), isTrue);
      expect(queue.current, 'b');
    });
  });

  group('editing', () {
    test('playNext inserts right after the current track', () {
      final queue = _abc()..playNext('x');
      expect(queue.items, ['a', 'x', 'b', 'c']);
      expect(queue.current, 'a');
    });

    test('add appends at the end', () {
      final queue = _abc()..add('x');
      expect(queue.items, ['a', 'b', 'c', 'x']);
    });

    test('adding to an empty queue makes it the current track', () {
      final queue = PlayQueue<String>(const [])..add('x');
      expect(queue.current, 'x');
    });

    test('removing a track before the current one keeps playing it', () {
      final queue = _abc(start: 2)..removeAt(0);
      expect(queue.items, ['b', 'c']);
      expect(queue.current, 'c');
    });

    test('removing the current track moves to the one after it', () {
      final queue = _abc(start: 1)..removeAt(1);
      expect(queue.current, 'c');
    });

    test('removing the last track, while current, moves back one', () {
      final queue = _abc(start: 2)..removeAt(2);
      expect(queue.current, 'b');
    });

    test('removing every track empties the queue', () {
      final queue = PlayQueue(['a'])..removeAt(0);
      expect(queue.current, isNull);
      expect(queue.items, isEmpty);
    });
  });

  group('shuffle', () {
    final many = [for (var i = 0; i < 20; i++) 't$i'];

    test('keeps the current track first, then every track once', () {
      final queue = PlayQueue(many, start: 5, random: Random(7))
        ..setShuffle(true);
      expect(queue.shuffled, isTrue);
      expect(queue.current, 't5');
      expect(queue.index, 0);
      expect(queue.items.toSet(), many.toSet());
      expect(queue.items, isNot(many));
    });

    test('turning it off restores the order on the same track', () {
      final queue = PlayQueue(many, start: 5, random: Random(7))
        ..setShuffle(true)
        ..next();
      final playing = queue.current;
      queue.setShuffle(false);
      expect(queue.items, many);
      expect(queue.current, playing);
    });

    test('a track added while shuffled stays after shuffle is turned off', () {
      final queue = _abc()
        ..setShuffle(true)
        ..add('x')
        ..setShuffle(false);
      expect(queue.items, ['a', 'b', 'c', 'x']);
    });

    test('the same track twice keeps both', () {
      final queue = PlayQueue(['a', 'a', 'b'], random: Random(7))
        ..setShuffle(true)
        ..setShuffle(false);
      expect(queue.items, ['a', 'a', 'b']);
    });
  });
}
