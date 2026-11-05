import 'dart:io';

import 'package:ka7_core/ka7_core.dart';
import 'package:ka7_engine_ytdlp/ka7_engine_ytdlp.dart';
import 'package:test/test.dart';

/// Stands in for the yt-dlp binary: records the call, returns a fixed result.
class FakeYtDlp {
  FakeYtDlp({this.exitCode = 0, this.stdout = '', this.stderr = ''});

  final int exitCode;
  final String stdout, stderr;
  String? executable;
  List<String>? arguments;

  Future<ProcessResult> call(String executable, List<String> arguments) async {
    this.executable = executable;
    this.arguments = arguments;
    return ProcessResult(1, exitCode, stdout, stderr);
  }
}

MediaEntry entryOf(String input) => parseEntry(input) as MediaEntry;

void main() {
  test('asks yt-dlp for JSON metadata only, then reads it', () async {
    final ytDlp = FakeYtDlp(
      stdout: File('test/fixtures/playlist_flat.json').readAsStringSync(),
    );
    final extractor = YtDlpExtractor(
      run: ytDlp.call,
      executable: '/opt/ka7/yt-dlp',
    );

    final probe = await extractor.probe(entryOf('PLe7rK2mErickManana01'));

    expect(ytDlp.executable, '/opt/ka7/yt-dlp');
    expect(ytDlp.arguments, [
      '--dump-single-json',
      '--flat-playlist',
      '--no-warnings',
      'https://www.youtube.com/playlist?list=PLe7rK2mErickManana01',
    ]);
    expect(probe.items, hasLength(6));
  });

  test('reads only the long videos of a channel', () async {
    final ytDlp = FakeYtDlp(
      stdout: File('test/fixtures/channel_videos.json').readAsStringSync(),
    );

    await YtDlpExtractor(
      run: ytDlp.call,
    ).probe(entryOf('https://www.youtube.com/@YouTube'));

    expect(ytDlp.arguments!.last, 'https://www.youtube.com/@YouTube/videos');
  });

  test('caps a YouTube mix at 50 videos', () async {
    final ytDlp = FakeYtDlp(
      stdout: File('test/fixtures/playlist_flat.json').readAsStringSync(),
    );

    await YtDlpExtractor(run: ytDlp.call).probe(entryOf('RDHb8sJ1kP0wE'));

    expect(ytDlp.arguments, containsAllInOrder(['--playlist-end', '50']));
  });

  test('caps a mix at the limit chosen in the settings', () async {
    final ytDlp = FakeYtDlp(
      stdout: File('test/fixtures/playlist_flat.json').readAsStringSync(),
    );
    var limit = 100;
    final extractor = YtDlpExtractor(run: ytDlp.call, mixLimit: () => limit);

    await extractor.probe(entryOf('RDHb8sJ1kP0wE'));
    expect(ytDlp.arguments, containsAllInOrder(['--playlist-end', '100']));

    limit = 25;
    await extractor.probe(entryOf('RDHb8sJ1kP0wE'));
    expect(ytDlp.arguments, containsAllInOrder(['--playlist-end', '25']));
  });

  test('searches YouTube for plain words, videos only', () async {
    final ytDlp = FakeYtDlp(
      stdout: File('test/fixtures/search_flat.json').readAsStringSync(),
    );

    final probe = await YtDlpExtractor(
      run: ytDlp.call,
    ).probe(const SearchEntry('Mahaleo', query: 'Mahaleo'));

    expect(ytDlp.arguments!.last, 'ytsearch20:Mahaleo');
    expect(probe.isSearch, isTrue);
    expect(probe.title, 'Mahaleo');
    expect(probe.playlistId, isNull);
    expect(probe.items.map((i) => i.videoId), ['7MSYzO8Avzk', '-ieWGHvs9xQ']);
    expect(probe.items.first.channel, 'Mahaleo official ');
    expect(probe.items.first.duration, const Duration(seconds: 181));
  });

  test('turns yt-dlp errors into readable reasons', () async {
    const cases = {
      "ERROR: [youtube] rS5tU7vW9xY: Private video. Sign in if you've been granted access to this video":
          FailureReason.private,
      'ERROR: [youtube] zA1bC3dE5fG: Video unavailable. This video has been removed by the uploader':
          FailureReason.unavailable,
      'ERROR: [youtube] Qm7tR2vLx9A: Unable to download API page: <urlopen error [Errno -3] Temporary failure in name resolution>':
          FailureReason.network,
      'ERROR: something new that Ka7 does not know yet': FailureReason.unknown,
    };
    for (final MapEntry(key: stderr, value: reason) in cases.entries) {
      final ytDlp = FakeYtDlp(exitCode: 1, stderr: stderr);

      await expectLater(
        YtDlpExtractor(run: ytDlp.call).probe(entryOf('Qm7tR2vLx9A')),
        throwsA(
          isA<ProbeFailure>()
              .having((f) => f.reason, 'reason', reason)
              .having((f) => f.message, 'message', stderr),
        ),
        reason: stderr,
      );
    }
  });

  test('reports a missing yt-dlp binary instead of crashing', () async {
    final extractor = YtDlpExtractor(
      run: (executable, arguments) async =>
          throw ProcessException(executable, arguments, 'No such file', 2),
    );

    await expectLater(
      extractor.probe(entryOf('Qm7tR2vLx9A')),
      throwsA(
        isA<ProbeFailure>().having(
          (f) => f.reason,
          'reason',
          FailureReason.engineMissing,
        ),
      ),
    );
  });

  group('channel picture', () {
    test('asks for the channel alone and takes its square picture', () async {
      final ytDlp = FakeYtDlp(
        stdout: File('test/fixtures/channel_avatar.json').readAsStringSync(),
      );

      final picture = await YtDlpExtractor(
        run: ytDlp.call,
      ).pictureOf('UCEpStQu-C7FCCv1-P5UyClg');

      expect(
        ytDlp.arguments,
        containsAllInOrder([
          '--playlist-items',
          '0',
          'https://www.youtube.com/channel/UCEpStQu-C7FCCv1-P5UyClg',
        ]),
      );
      expect(picture, startsWith('https://yt3.googleusercontent.com/'));
      expect(picture, contains('=s176'), reason: 'small enough for a row');
      expect(picture, isNot(contains('=s0')), reason: 'not the banner');
    });

    test('gives no picture when yt-dlp fails', () async {
      final ytDlp = FakeYtDlp(exitCode: 1, stderr: 'ERROR: offline');

      expect(await YtDlpExtractor(run: ytDlp.call).pictureOf('UCx'), isNull);
    });
  });
}
