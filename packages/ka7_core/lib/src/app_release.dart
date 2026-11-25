import 'dart:convert';
import 'dart:io';

/// A published version of Ka7 (a GitHub release).
final class AppRelease {
  const AppRelease({required this.version, required this.url});

  /// `0.3.0`, without the `v` of its tag.
  final String version;

  /// The file of the running package, downloaded as soon as it is opened;
  /// the release page when that file is unknown or missing.
  final String url;
}

/// The ways Ka7 is installed, each with the end of its file's name in a
/// release (see `tool/package_linux.sh`, `tool/package_android.sh` and
/// `.github/workflows/windows.yml`).
enum Ka7Package {
  androidArm64('-arm64-v8a.apk'),
  androidArm('-armeabi-v7a.apk'),
  androidX64('-x86_64.apk'),
  appImage('-x86_64.AppImage'),
  deb('_amd64.deb'),
  rpm('.x86_64.rpm'),
  windowsSetup('-windows-setup.exe'),
  windowsZip('-windows-x64.zip');

  const Ka7Package(this.suffix);

  final String suffix;
}

/// How the running Ka7 was installed; null when it cannot be told (a
/// development build, iOS, macOS).
///
/// [os] is `Platform.operatingSystem`, [abi] `Abi.current().toString()`
/// (`android_arm64`), [executable] `Platform.resolvedExecutable`.
Ka7Package? installedPackage({
  required String os,
  required String executable,
  String? abi,
  Map<String, String> environment = const {},
  required bool Function(String path) exists,
}) {
  switch (os) {
    case 'android':
      return switch (abi) {
        'android_arm64' => Ka7Package.androidArm64,
        'android_arm' => Ka7Package.androidArm,
        'android_x64' => Ka7Package.androidX64,
        _ => null,
      };
    case 'linux':
      // Set by the AppImage runtime to the file being run.
      if (environment['APPIMAGE'] != null) return Ka7Package.appImage;
      // The .deb and the .rpm hold the same files under /opt/ka7.
      if (!executable.startsWith('/opt/ka7/')) return null;
      return exists('/usr/bin/dpkg') ? Ka7Package.deb : Ka7Package.rpm;
    case 'windows':
      // Inno Setup leaves its uninstaller beside the app; the zip does not.
      final folder = executable.substring(0, executable.lastIndexOf(r'\') + 1);
      return exists('${folder}unins000.exe')
          ? Ka7Package.windowsSetup
          : Ka7Package.windowsZip;
    default:
      return null;
  }
}

/// Reads GitHub's `releases/latest` answer; null for a draft, a pre-release
/// or an answer that is not a release. With a [package], points at its file.
AppRelease? parseRelease(Map<String, Object?> json, {Ka7Package? package}) {
  final tag = json['tag_name'];
  final page = json['html_url'];
  if (tag is! String || page is! String) return null;
  if (json['draft'] == true || json['prerelease'] == true) return null;
  return AppRelease(
    version: tag.startsWith('v') ? tag.substring(1) : tag,
    url: (package == null ? null : _fileOf(json['assets'], package)) ?? page,
  );
}

String? _fileOf(Object? assets, Ka7Package package) {
  if (assets is! List) return null;
  for (final asset in assets) {
    if (asset is! Map) continue;
    final name = asset['name'];
    final url = asset['browser_download_url'];
    if (name is String && url is String && name.endsWith(package.suffix)) {
      return url;
    }
  }
  return null;
}

/// Whether [candidate] (`0.10.0`) comes after [current] (`0.9.1`).
bool isNewer(String candidate, String current) {
  final a = _numbers(candidate);
  final b = _numbers(current);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// `1.2.3` → [1, 2, 3]; `0.3` → [0, 3, 0]; null when not a version.
List<int>? _numbers(String version) {
  final parts = version.split('.');
  if (parts.isEmpty || parts.length > 3) return null;
  final numbers = [for (final part in parts) int.tryParse(part)];
  if (numbers.contains(null)) return null;
  return [...numbers.cast<int>(), ...List.filled(3 - numbers.length, 0)];
}

/// Where Ka7 is published.
const releasesApi = 'https://api.github.com/repos/jmRakoto/ka7/releases/latest';

/// Asks GitHub for the latest Ka7, pointing at the file of [package]; null
/// when there is none to offer. Throws when GitHub cannot be reached.
Future<AppRelease?> fetchLatestRelease({
  String api = releasesApi,
  Ka7Package? package,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(Uri.parse(api));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Ka7');
    final response = await request.close().timeout(const Duration(seconds: 15));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) return null;
    return parseRelease(
      jsonDecode(body) as Map<String, Object?>,
      package: package,
    );
  } finally {
    client.close();
  }
}
