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

  group('parseRelease with a package', () {
    Map<String, Object?> release() => {
      'tag_name': 'v0.5.1',
      'html_url': 'https://github.com/jmRakoto/ka7/releases/tag/v0.5.1',
      'draft': false,
      'prerelease': false,
      'assets': [
        for (final name in [
          'ka7-0.5.1-1.x86_64.rpm',
          'Ka7-0.5.1-arm64-v8a.apk',
          'Ka7-0.5.1-armeabi-v7a.apk',
          'Ka7-0.5.1-linux-player-sources.tar.xz',
          'Ka7-0.5.1-windows-setup.exe',
          'Ka7-0.5.1-windows-x64.zip',
          'Ka7-0.5.1-x86_64.AppImage',
          'ka7_0.5.1_amd64.deb',
        ])
          {'name': name, 'browser_download_url': 'https://dl/$name'},
      ],
    };

    test('points straight at the file of that package', () {
      final expected = {
        Ka7Package.androidArm64: 'https://dl/Ka7-0.5.1-arm64-v8a.apk',
        Ka7Package.androidArm: 'https://dl/Ka7-0.5.1-armeabi-v7a.apk',
        Ka7Package.appImage: 'https://dl/Ka7-0.5.1-x86_64.AppImage',
        Ka7Package.deb: 'https://dl/ka7_0.5.1_amd64.deb',
        Ka7Package.rpm: 'https://dl/ka7-0.5.1-1.x86_64.rpm',
        Ka7Package.windowsSetup: 'https://dl/Ka7-0.5.1-windows-setup.exe',
        Ka7Package.windowsZip: 'https://dl/Ka7-0.5.1-windows-x64.zip',
      };
      for (final MapEntry(key: package, value: url) in expected.entries) {
        expect(parseRelease(release(), package: package)?.url, url);
      }
    });

    test('falls back to the page when the file is missing', () {
      expect(
        parseRelease(release(), package: Ka7Package.androidX64)?.url,
        'https://github.com/jmRakoto/ka7/releases/tag/v0.5.1',
      );
      expect(
        parseRelease({
          ...release(),
          'assets': null,
        }, package: Ka7Package.deb)?.url,
        'https://github.com/jmRakoto/ka7/releases/tag/v0.5.1',
      );
    });

    test('falls back to the page without a package', () {
      expect(
        parseRelease(release())?.url,
        'https://github.com/jmRakoto/ka7/releases/tag/v0.5.1',
      );
    });
  });

  group('installedPackage', () {
    Ka7Package? on(
      String os, {
      String executable = '/somewhere/ka7',
      String? abi,
      Map<String, String> environment = const {},
      Set<String> files = const {},
    }) => installedPackage(
      os: os,
      executable: executable,
      abi: abi,
      environment: environment,
      exists: files.contains,
    );

    test('Android: the APK of the processor', () {
      expect(on('android', abi: 'android_arm64'), Ka7Package.androidArm64);
      expect(on('android', abi: 'android_arm'), Ka7Package.androidArm);
      expect(on('android', abi: 'android_x64'), Ka7Package.androidX64);
      expect(on('android', abi: 'android_riscv64'), isNull);
    });

    test('Linux: AppImage, then .deb or .rpm under /opt/ka7', () {
      expect(
        on('linux', environment: {'APPIMAGE': '/home/a/Ka7.AppImage'}),
        Ka7Package.appImage,
      );
      expect(
        on('linux', executable: '/opt/ka7/app/ka7', files: {'/usr/bin/dpkg'}),
        Ka7Package.deb,
      );
      expect(on('linux', executable: '/opt/ka7/app/ka7'), Ka7Package.rpm);
      expect(on('linux', executable: '/home/a/ka7/build/ka7'), isNull);
    });

    test(
      'Windows: the installer when its uninstaller is there, else the zip',
      () {
        expect(
          on(
            'windows',
            executable: r'C:\Users\a\AppData\Local\Programs\Ka7\ka7.exe',
            files: {r'C:\Users\a\AppData\Local\Programs\Ka7\unins000.exe'},
          ),
          Ka7Package.windowsSetup,
        );
        expect(
          on('windows', executable: r'C:\Users\a\Ka7\ka7.exe'),
          Ka7Package.windowsZip,
        );
      },
    );

    test('nothing to pick elsewhere', () {
      expect(on('ios'), isNull);
      expect(on('macos'), isNull);
    });
  });
}
