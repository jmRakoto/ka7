import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ka7_core/ka7_core.dart';

import 'media_backend.dart';
import 'track.dart';

/// Why the current track does not play.
enum PlayerError { missingFile, offline, unavailable }

/// Past this point, « previous » starts the track again, as other players do.
const _restartAfter = Duration(seconds: 3);

/// The one player of the app: what plays, where in it, and the queue.
class PlayerController extends ChangeNotifier {
  PlayerController({required this.backend, this.streamUrl, this.locate}) {
    _subscriptions = [
      backend.position.listen((at) => _update(() => _position = at)),
      backend.duration.listen((length) => _update(() => _duration = length)),
      backend.playing.listen((on) => _update(() => _playing = on)),
      backend.completed.listen((_) => unawaited(_ended())),
    ];
  }

  final MediaBackend backend;

  /// The stream address of an online track; null where none can be asked.
  final Future<String> Function(String videoId, {required bool video})?
  streamUrl;

  /// Where a track's file is now (a path, or a `content://` address on
  /// Android, where files are moved to Music/Ka7 after downloading); null
  /// when gone. Null to play the recorded path as it is.
  final Future<String?> Function(Track track)? locate;

  late final List<StreamSubscription<Object?>> _subscriptions;
  PlayQueue<Track>? _queue;
  var _position = Duration.zero;
  var _duration = Duration.zero;
  var _playing = false;
  var _loading = false;
  PlayerError? _error;
  final _missing = <String>{};

  /// Bumped at each load: a slow stream address must not play over a newer
  /// choice.
  var _generation = 0;

  Track? get current => _queue?.current;

  /// In play order.
  List<Track> get tracks => _queue?.items ?? const [];
  int? get index => _queue?.index;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get playing => _playing;

  /// Asking for a stream address, or checking a file.
  bool get loading => _loading;
  PlayerError? get error => _error;
  Repeat get repeat => _queue?.repeat ?? Repeat.off;
  bool get shuffled => _queue?.shuffled ?? false;

  /// Files found missing this session: skipped.
  Set<String> get missing => Set.unmodifiable(_missing);

  void _update(void Function() change) {
    change();
    notifyListeners();
  }

  /// Plays [tracks] from [start], in place of what was playing.
  Future<void> playAll(List<Track> tracks, {int start = 0}) async {
    final old = _queue;
    _queue = PlayQueue(tracks, start: start)
      ..repeat = old?.repeat ?? Repeat.off;
    if (old?.shuffled ?? false) _queue!.setShuffle(true);
    await _load();
  }

  Future<void> toggle() async {
    if (current == null) return;
    if (_playing) return backend.pause();
    // Stopped, failed or never loaded: load it again.
    if (_error != null) return _load();
    await backend.play();
  }

  /// Pauses back at the start of the track.
  Future<void> stop() async {
    await backend.pause();
    await backend.seek(Duration.zero);
    _update(() => _position = Duration.zero);
  }

  /// Stops and forgets the queue: the player goes away.
  Future<void> close() async {
    _generation++;
    _queue = null;
    await backend.stop();
    _update(() {
      _position = Duration.zero;
      _duration = Duration.zero;
      _error = null;
      _loading = false;
    });
  }

  Future<void> next() async {
    if (_queue?.next() ?? false) await _load();
  }

  /// The previous track, or the start of this one after a few seconds.
  Future<void> previous() async {
    if (_position > _restartAfter) return seek(Duration.zero);
    if (_queue?.previous() ?? false) await _load();
  }

  Future<void> jumpTo(int index) async {
    _queue?.jumpTo(index);
    await _load();
  }

  Future<void> seek(Duration to) => backend.seek(to);

  /// Forward or back by [by], within the track.
  Future<void> seekBy(Duration by) {
    var to = _position + by;
    if (to < Duration.zero) to = Duration.zero;
    if (_duration > Duration.zero && to > _duration) to = _duration;
    return seek(to);
  }

  void setRepeat(Repeat repeat) {
    final queue = _queue;
    if (queue == null) return;
    _update(() => queue.repeat = repeat);
  }

  void setShuffle(bool on) {
    final queue = _queue;
    if (queue == null) return;
    _update(() => queue.setShuffle(on));
  }

  /// Right after the current track; plays it when nothing is.
  Future<void> playNext(Track track) async {
    final queue = _queue;
    if (queue == null || queue.current == null) return playAll([track]);
    _update(() => queue.playNext(track));
  }

  /// At the end of the queue; plays it when nothing is.
  Future<void> enqueue(Track track) async {
    final queue = _queue;
    if (queue == null || queue.current == null) return playAll([track]);
    _update(() => queue.add(track));
  }

  void removeAt(int index) {
    final queue = _queue;
    if (queue == null) return;
    final wasCurrent = index == queue.index;
    queue.removeAt(index);
    if (queue.current == null) {
      unawaited(close());
    } else if (wasCurrent) {
      unawaited(_load());
    } else {
      notifyListeners();
    }
  }

  Future<void> _ended() async {
    final queue = _queue;
    if (queue == null) return;
    if (queue.ended()) return _load();
    _update(() => _playing = false);
  }

  /// Plays the queue's current track; skips files gone from the disk.
  Future<void> _load() async {
    final generation = ++_generation;
    final queue = _queue;
    if (queue == null) return;
    _update(() {
      _loading = true;
      _error = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    // Each track tried once at most: a list of missing files ends.
    for (var tries = 0; tries < queue.items.length; tries++) {
      final track = queue.current!;
      final source = await _sourceOf(track);
      if (generation != _generation) return;
      if (source != null) {
        _update(() {
          _loading = false;
          _error = null;
        });
        return backend.open(source, video: track.video);
      }
      if (_error != PlayerError.missingFile || !queue.next()) break;
    }
    await backend.pause();
    _update(() {
      _loading = false;
      _playing = false;
    });
  }

  /// The file or stream address of [track]; null with [_error] set.
  Future<String?> _sourceOf(Track track) async {
    if (track.path case final path?) {
      final ask = locate;
      if (ask == null) return path;
      if (await ask(track) case final found?) return found;
      _missing.add(path);
      _error = PlayerError.missingFile;
      return null;
    }
    final ask = streamUrl;
    if (ask == null) {
      _error = PlayerError.unavailable;
      return null;
    }
    try {
      return await ask(track.videoId, video: track.video);
    } on ProbeFailure catch (failure) {
      _error = failure.reason == FailureReason.network
          ? PlayerError.offline
          : PlayerError.unavailable;
      return null;
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
