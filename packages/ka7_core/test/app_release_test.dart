import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

void main() {
  group('isNewer', () {
    test('compares each number, not the text', () {
      expect(isNewer('0.10.0', '0.9.1'), isTrue);
      expect(isNewer('1.0.0', '0.99.99'), isTrue);
      expect(isNewer('0.2.1', '0.2.0'), isTrue);
    });

    test('is false for the same or an older version', () {
      expect(isNewer('0.2.0', '0.2.0'), isFalse);
      expect(isNewer('0.1.9', '0.2.0'), isFalse);
    });

    test('reads a missing number as 0', () {
      expect(isNewer('0.3', '0.2.9'), isTrue);
      expect(isNewer('0.3', '0.3.0'), isFalse);
    });

    test('is false when either is not a version', () {
      expect(isNewer('nightly', '0.2.0'), isFalse);
      expect(isNewer('0.3.0', ''), isFalse);
    });
  });

  group('parseRelease', () {
    test('reads the version from the tag, and the page', () {
      final release = parseRelease({
        'tag_name': 'v0.3.0',
        'html_url': 'https://github.com/jmRakoto/ka7/releases/tag/v0.3.0',
        'draft': false,
        'prerelease': false,
      });

      expect(release?.version, '0.3.0');
      expect(
        release?.url,
        'https://github.com/jmRakoto/ka7/releases/tag/v0.3.0',
      );
    });

    test('skips drafts, pre-releases and other answers', () {
      expect(
        parseRelease({
          'tag_name': 'v0.3.0',
          'html_url': 'u',
          'prerelease': true,
        }),
        isNull,
      );
      expect(
        parseRelease({'tag_name': 'v0.3.0', 'html_url': 'u', 'draft': true}),
        isNull,
      );
      expect(parseRelease({'message': 'Not Found'}), isNull);
    });
  });
}
