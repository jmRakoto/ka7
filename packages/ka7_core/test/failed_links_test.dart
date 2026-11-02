import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

const _private = ProbeItem(videoId: 'aB3dE5fG7hI', title: 'Tsy Ferana');
const _offline = ProbeItem(videoId: 'jK9lM1nO3pQ', title: 'Lasa');
const _source = Probe(title: 'Mix', items: [_private, _offline]);

final _failed = [
  JobFailed(
    const PlannedDownload(source: _source, item: _private, index: 1),
    FailureReason.private,
    'ERROR: Private video\nSign in',
  ),
  JobFailed(
    const PlannedDownload(source: _source, item: _offline, index: 2),
    FailureReason.network,
  ),
];

void main() {
  test('lists each failed link under its reason, dated', () {
    expect(
      formatFailedLinks(_failed, DateTime(2026, 10, 30, 14, 5)),
      '# Ka7: failed downloads, 2026-10-30 14:05\n'
      '# Run `ka7 retry`, or paste these links back into links.txt.\n'
      '\n'
      '# Tsy Ferana: private (ERROR: Private video Sign in)\n'
      'https://www.youtube.com/watch?v=aB3dE5fG7hI\n'
      '\n'
      '# Lasa: network\n'
      'https://www.youtube.com/watch?v=jK9lM1nO3pQ\n',
    );
  });

  test('reads back as the failed videos only', () {
    final entries = parseLinks(formatFailedLinks(_failed, DateTime(2026)));

    expect(entries.map((e) => (e as VideoEntry).videoId), [
      'aB3dE5fG7hI',
      'jK9lM1nO3pQ',
    ]);
  });

  test('also lists links that could not even be read', () {
    final playlist = parseEntry('PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy');

    final text = formatFailedLinks(
      const [],
      DateTime(2026, 10, 30),
      unreadable: {
        playlist as MediaEntry: const ProbeFailure(
          FailureReason.private,
          'This playlist is private',
        ),
      },
    );

    expect(
      text,
      endsWith(
        '\n# PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy: private '
        '(This playlist is private)\n'
        'https://www.youtube.com/playlist?list=PLFVukuZSVj3z2alpuXaNRsepY1uBpbyLy\n',
      ),
    );
  });
}
