import 'job_event.dart';
import 'link_entry.dart';
import 'probe.dart';

/// Content of `failed.txt`: a links file listing [failed] videos, then
/// [unreadable] links, each with its reason.
String formatFailedLinks(
  List<JobFailed> failed,
  DateTime at, {
  Map<MediaEntry, ProbeFailure> unreadable = const {},
}) {
  final text = StringBuffer()
    ..writeln('# Ka7: failed downloads, ${_minute(at)}')
    ..writeln('# Run `ka7 retry`, or paste these links back into links.txt.');
  void link(String label, FailureReason reason, String message, String url) {
    final words = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    final details = words.isEmpty ? '' : ' ($words)';
    text
      ..writeln()
      ..writeln('# $label: ${reason.name}$details')
      ..writeln(url);
  }

  for (final job in failed) {
    link(
      job.download.item.title,
      job.reason,
      job.message,
      'https://www.youtube.com/watch?v=${job.download.item.videoId}',
    );
  }
  for (final MapEntry(key: entry, value: failure) in unreadable.entries) {
    link(entry.source, failure.reason, failure.message, entry.url);
  }
  return text.toString();
}

String _minute(DateTime at) {
  String two(int n) => '$n'.padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)} '
      '${two(at.hour)}:${two(at.minute)}';
}
