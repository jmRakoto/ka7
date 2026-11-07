import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/platform/bundled_libmpv.dart';

void main() {
  test('a packaged app opens its own libmpv, beside it', () {
    expect(
      bundledLibmpv(
        '/opt/ka7/app/ka7',
        exists: (path) => path == '/opt/ka7/app/lib/libmpv.so.2',
      ),
      '/opt/ka7/app/lib/libmpv.so.2',
    );
  });

  test('from source, none: the system\'s is used', () {
    expect(
      bundledLibmpv('/home/me/ka7/app/build/ka7', exists: (_) => false),
      isNull,
    );
  });
}
