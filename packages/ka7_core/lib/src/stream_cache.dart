import 'stream_urls.dart';

/// Stream addresses asked ahead, while the user looks at the preview, so ▶
/// starts at once instead of waiting for the engine.
final class StreamCache implements StreamUrls {
  StreamCache(
    this.engine, {
    this.maxAge = const Duration(hours: 1),
    this.parallel = 2,
    this.waiting = 6,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final StreamUrls engine;

  /// YouTube's addresses last a few hours: older ones are asked again.
  final Duration maxAge;

  /// Lookups running at once.
  final int parallel;

  /// Lookups kept waiting; the oldest go first when more come.
  final int waiting;
  final DateTime Function() _now;

  /// Known or being asked, by video and kind.
  final _found = <(String, bool), _Lookup>{};

  /// Not started yet, oldest first.
  final _queue = <(String, bool)>[];
  var _running = 0;

  /// Asks for [videoId]'s address in the background, if not known yet.
  void prefetch(String videoId, {required bool video}) {
    final key = (videoId, video);
    if (_fresh(key) != null || _queue.contains(key)) return;
    _queue.add(key);
    while (_queue.length > waiting) {
      _queue.removeAt(0);
    }
    _next();
  }

  @override
  Future<String> streamUrl(String videoId, {required bool video}) {
    final key = (videoId, video);
    if (_fresh(key) case final lookup?) return lookup.address;
    _queue.remove(key);
    return _start(key, counted: false).address;
  }

  /// A lookup running, or done less than [maxAge] ago.
  _Lookup? _fresh((String, bool) key) {
    final lookup = _found[key];
    if (lookup == null) return null;
    if (_now().difference(lookup.at) > maxAge) {
      _found.remove(key);
      return null;
    }
    return lookup;
  }

  void _next() {
    while (_running < parallel && _queue.isNotEmpty) {
      _start(_queue.removeLast(), counted: true);
    }
  }

  /// [counted]: a prefetch, holding one of the [parallel] places.
  _Lookup _start((String, bool) key, {required bool counted}) {
    final (videoId, video) = key;
    if (counted) _running++;
    final address = engine.streamUrl(videoId, video: video);
    final lookup = _found[key] = _Lookup(address, _now());
    address
        .then(
          (_) {},
          onError: (Object _) {
            // Failed: asked again next time.
            if (identical(_found[key], lookup)) _found.remove(key);
          },
        )
        .whenComplete(() {
          if (!counted) return;
          _running--;
          _next();
        });
    return lookup;
  }
}

final class _Lookup {
  _Lookup(this.address, this.at);

  final Future<String> address;

  /// When it was asked: YouTube counts the address's life from about then.
  final DateTime at;
}
