// Real network check of the explode engine (not in the test suite):
//   cd packages/ka7_engine_explode && fvm dart run tool/live_check.dart <folder>
import 'dart:io';

import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_explode/ka7_engine_explode.dart';

Future<void> main(List<String> arguments) async {
  final source = YoutubeExplodeSource();
  final engine = ExplodeEngine(source: source);
  try {
    for (final link in [
      'jNQXAC9IVRw',
      'PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy',
      'https://www.youtube.com/@jawed',
    ]) {
      final probe = await engine.probe(parseEntry(link) as MediaEntry);
      print('$link → ${probe.title}: ${probe.items.length} videos');
    }
    for (final format in [MediaFormat.m4a, MediaFormat.mp4]) {
      try {
        final path = '${arguments.single}/zoo.${format.extension}';
        await engine
            .download(
              DownloadRequest(
                videoId: 'jNQXAC9IVRw',
                format: format,
                destination: path,
                tags: const TrackTags(title: 'Me at the zoo'),
              ),
            )
            .drain<void>();
        print('$format → $path ${File(path).lengthSync()} bytes');
      } on DownloadFailure catch (failure) {
        print('$format → $failure');
      }
    }
  } finally {
    source.close();
  }
}
