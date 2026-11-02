/// `4:12`, or `1:02:03` past an hour.
String clock(Duration d) {
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d.inHours == 0) return '${d.inMinutes}:$seconds';
  final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
  return '${d.inHours}:$minutes:$seconds';
}

/// `13 min`, `< 1 min` for a few seconds, or `1 h 05` past an hour.
String span(Duration d) {
  final minutes = (d.inSeconds / 60).round();
  if (minutes == 0 && d > Duration.zero) return '< 1 min';
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
}
