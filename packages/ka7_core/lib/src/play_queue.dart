import 'dart:math';

/// What happens at the end of the queue, or of a track.
enum Repeat { off, all, one }

/// The tracks a player goes through, in play order: next, previous, play
/// next, repeat and shuffle. Knows nothing of audio: the player asks it what
/// to play.
final class PlayQueue<T> {
  PlayQueue(List<T> items, {int start = 0, Random? random})
    : _random = random ?? Random(),
      _order = [for (final item in items) _Slot(item)] {
    _index = _order.isEmpty ? null : start.clamp(0, _order.length - 1);
  }

  final Random _random;

  /// Play order. Slots, not items, so the same track twice stays two tracks.
  List<_Slot<T>> _order;

  /// The order before shuffling, to go back to it.
  List<_Slot<T>>? _unshuffled;
  int? _index;

  /// In play order (shuffled when [shuffled]).
  List<T> get items => [for (final slot in _order) slot.item];

  /// Position of [current] in [items]; null when empty.
  int? get index => _index;

  T? get current => _index == null ? null : _order[_index!].item;

  Repeat repeat = Repeat.off;

  bool get shuffled => _unshuffled != null;

  /// On: the current track first, then the others in random order. Off: back
  /// to the order before, on the same track.
  void setShuffle(bool on) {
    if (on == shuffled) return;
    final playing = _index == null ? null : _order[_index!];
    if (on) {
      _unshuffled = _order;
      final rest = [
        for (final slot in _order)
          if (!identical(slot, playing)) slot,
      ]..shuffle(_random);
      _order = [?playing, ...rest];
    } else {
      _order = _unshuffled!;
      _unshuffled = null;
    }
    if (playing != null) _index = _order.indexOf(playing);
  }

  /// Skips to the next track; false at the end with [Repeat.off].
  bool next() {
    final at = _index;
    if (at == null) return false;
    if (at + 1 < _order.length) {
      _index = at + 1;
      return true;
    }
    if (repeat == Repeat.off) return false;
    _index = 0;
    return true;
  }

  /// Goes back one track; false at the start with [Repeat.off].
  bool previous() {
    final at = _index;
    if (at == null) return false;
    if (at > 0) {
      _index = at - 1;
      return true;
    }
    if (repeat == Repeat.off) return false;
    _index = _order.length - 1;
    return true;
  }

  /// The current track finished playing: what to play now. False when the
  /// queue is over.
  bool ended() {
    if (_index == null) return false;
    if (repeat == Repeat.one) return true;
    return next();
  }

  void jumpTo(int index) {
    RangeError.checkValidIndex(index, _order);
    _index = index;
  }

  /// Inserts [item] right after the current track.
  void playNext(T item) {
    final slot = _Slot(item);
    final at = _index;
    if (at == null) return add(item);
    _order.insert(at + 1, slot);
    _unshuffled?.insert(_unshuffled!.indexOf(_order[at]) + 1, slot);
  }

  /// Appends [item] at the end.
  void add(T item) {
    final slot = _Slot(item);
    _order.add(slot);
    _unshuffled?.add(slot);
    _index ??= 0;
  }

  void removeAt(int index) {
    final slot = _order.removeAt(index);
    _unshuffled?.remove(slot);
    final at = _index!;
    if (_order.isEmpty) {
      _index = null;
    } else if (index < at || (index == at && at == _order.length)) {
      _index = at - 1;
    }
  }
}

final class _Slot<T> {
  _Slot(this.item);
  final T item;
}
