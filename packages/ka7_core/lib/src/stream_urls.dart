/// An engine that can give a video's stream address, to play it online
/// without downloading it.
abstract interface class StreamUrls {
  /// A direct address (https) for [videoId]: its best audio, or a video with
  /// sound when [video]. Throws a [ProbeFailure] when none can be found.
  /// YouTube's addresses expire after a few hours: ask right before playing.
  Future<String> streamUrl(String videoId, {required bool video});
}
