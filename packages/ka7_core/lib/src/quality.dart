/// MP3 bitrate.
enum AudioQuality {
  kbps128(128),
  kbps192(192),
  kbps320(320);

  const AudioQuality(this.kbps);
  final int kbps;
}

/// Highest video height; [best] has no limit.
enum VideoQuality {
  p480(480),
  p720(720),
  p1080(1080),
  best(null);

  const VideoQuality(this.height);
  final int? height;
}

/// What a download is made at.
final class Quality {
  const Quality({required this.audio, required this.video});

  /// 192 kbit/s and 1080p: good, without the weight of 320 or 4K.
  static const standard = Quality(
    audio: AudioQuality.kbps192,
    video: VideoQuality.p1080,
  );

  final AudioQuality audio;
  final VideoQuality video;
}
